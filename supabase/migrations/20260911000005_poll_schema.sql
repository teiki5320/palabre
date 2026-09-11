-- Palabre — module sondage (poll_schema.sql)
--
-- Tables poll, poll_option, vote, poll_result ; vues poll_public et
-- poll_anomalie ; fonction calculer_resultats ; règles d'immutabilité du vote.
--
-- Règles :
--   - questions rédigées par l'équipe uniquement (écriture réservée au rôle de service) ;
--   - trois options minimum, dont une neutre ;
--   - un vote par utilisateur, définitif ;
--   - vote avant résultats ;
--   - ouverture lundi 8h, fermeture dimanche 20h, dans le fuseau du pays ;
--   - seuil de 30 répondants par cellule avant d'afficher une découpe.

-- ---------------------------------------------------------------------------
-- Constantes
-- ---------------------------------------------------------------------------

create or replace function public.seuil_decoupe()
returns int language sql immutable as $$ select 30 $$;
comment on function public.seuil_decoupe is
  'Nombre minimal de répondants dans une cellule pour publier une découpe. En dessous, on peut ré-identifier des personnes.';

-- ---------------------------------------------------------------------------
-- poll
-- ---------------------------------------------------------------------------

create table public.poll (
  id                bigserial primary key,
  country_code      text not null references public.country(code),
  semaine           date not null,                 -- lundi de la semaine ISO
  question          text not null,
  contexte          text not null,                 -- 2 à 3 phrases, factuel
  sources           jsonb not null default '[]'::jsonb,   -- [{"titre","url","date"}]
  person_id         bigint references public.person(id),
  organization_id   bigint references public.organization(id),
  ouverture         timestamptz not null,
  fermeture         timestamptz not null,
  publie            boolean not null default false,
  suspect           boolean not null default false,
  suspect_motif     text,
  resultat_final_le timestamptz,
  cree              timestamptz not null default now(),
  modifie           timestamptz not null default now(),
  unique (country_code, semaine),
  check (extract(isodow from semaine) = 1),
  check (fermeture > ouverture),
  check (jsonb_typeof(sources) = 'array'),
  check (not suspect or suspect_motif is not null)
);
comment on table public.poll is 'Question de la semaine. L''état (programme / ouvert / ferme) se déduit des horodatages, voir poll_statut().';
comment on column public.poll.suspect is
  'Si un sondage est manifestement brigadé, on le dit publiquement plutôt que de masquer le chiffre (section 13).';

create trigger poll_modifie before update on public.poll
  for each row execute function public.set_modifie();

create index poll_country_semaine_idx on public.poll (country_code, semaine desc);

-- Créneau par défaut : lundi 08:00 → dimanche 20:00 dans le fuseau du pays.
create or replace function public.poll_creneau(p_country text, p_semaine date)
returns table (ouverture timestamptz, fermeture timestamptz)
language sql stable
set search_path = public
as $$
  select (p_semaine + time '08:00') at time zone c.fuseau,
         (p_semaine + 6 + time '20:00') at time zone c.fuseau
  from country c where c.code = p_country;
$$;

create or replace function public.poll_avant_insert()
returns trigger language plpgsql
set search_path = public
as $$
declare c record;
begin
  if new.ouverture is null or new.fermeture is null then
    select * into c from poll_creneau(new.country_code, new.semaine);
    new.ouverture := coalesce(new.ouverture, c.ouverture);
    new.fermeture := coalesce(new.fermeture, c.fermeture);
  end if;
  return new;
end $$;

create trigger poll_avant_insert before insert on public.poll
  for each row execute function public.poll_avant_insert();

-- ---------------------------------------------------------------------------
-- poll_option
-- ---------------------------------------------------------------------------

create table public.poll_option (
  id      bigserial primary key,
  poll_id bigint not null references public.poll(id) on delete cascade,
  ordre   int not null,
  libelle text not null,
  neutre  boolean not null default false,
  unique (poll_id, ordre)
);

-- Trois options minimum, dont une neutre : vérifié à la publication.
create or replace function public.poll_valider(p_poll_id bigint)
returns void language plpgsql stable
set search_path = public
as $$
declare n int; n_neutre int;
begin
  select count(*), count(*) filter (where neutre) into n, n_neutre
  from poll_option where poll_id = p_poll_id;
  if n < 3 then
    raise exception 'Un sondage doit proposer au moins trois options (sondage %, % option(s))', p_poll_id, n
      using errcode = 'check_violation';
  end if;
  if n_neutre < 1 then
    raise exception 'Un sondage doit proposer une option neutre (sondage %)', p_poll_id
      using errcode = 'check_violation';
  end if;
end $$;

create or replace function public.poll_avant_publication()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.publie and not coalesce(old.publie, false) then
    perform poll_valider(new.id);
  end if;
  return new;
end $$;

create trigger poll_avant_publication before update of publie on public.poll
  for each row execute function public.poll_avant_publication();

-- État déduit des horodatages, à un instant donné.
create or replace function public.poll_statut(p public.poll, p_instant timestamptz default now())
returns text language sql stable as $$
  select case
    when not p.publie then 'brouillon'
    when p_instant < p.ouverture then 'programme'
    when p_instant < p.fermeture then 'ouvert'
    else 'ferme'
  end
$$;

-- ---------------------------------------------------------------------------
-- vote
-- ---------------------------------------------------------------------------

create table public.vote (
  poll_id      bigint not null references public.poll(id) on delete restrict,
  user_id      uuid not null,                     -- pas de FK vers auth.users : un compte supprimé laisse un vote anonyme
  option_id    bigint not null references public.poll_option(id) on delete restrict,
  -- instantané du profil au moment du vote : un changement de profil ultérieur
  -- ne réécrit pas les découpes
  country_code text references public.country(code),
  tranche_age  text check (public.tranche_age_valide(tranche_age)),
  region_id    bigint references public.region(id),
  cree         timestamptz not null default now(),
  primary key (poll_id, user_id)
);
comment on table public.vote is 'Un vote par utilisateur, définitif. Les règles ci-dessous rendent update et delete inopérants : ne pas les retirer.';

create rule vote_no_update as on update to public.vote do instead nothing;
create rule vote_no_delete as on delete to public.vote do instead nothing;

create index vote_poll_option_idx on public.vote (poll_id, option_id);
create index vote_poll_cree_idx on public.vote (poll_id, cree);

create or replace function public.vote_avant_insert()
returns trigger language plpgsql security definer
set search_path = public
as $$
declare
  p   public.poll%rowtype;
  pr  public.profile%rowtype;
  via_api boolean := auth.uid() is not null;
begin
  select * into p from poll where id = new.poll_id;
  if not found then
    raise exception 'Sondage inconnu' using errcode = 'foreign_key_violation';
  end if;

  if via_api then
    -- un client ne choisit ni son identité ni l'horodatage
    new.user_id := auth.uid();
    new.cree := now();
  else
    new.cree := coalesce(new.cree, now());
  end if;

  if poll_statut(p, new.cree) <> 'ouvert' then
    raise exception 'Le sondage % n''est pas ouvert au vote', new.poll_id using errcode = 'check_violation';
  end if;

  if not exists (select 1 from poll_option o where o.id = new.option_id and o.poll_id = new.poll_id) then
    raise exception 'Option % étrangère au sondage %', new.option_id, new.poll_id using errcode = 'check_violation';
  end if;

  select * into pr from profile where user_id = new.user_id;
  new.country_code := pr.country_code;
  new.tranche_age  := pr.tranche_age;
  new.region_id    := pr.region_id;
  return new;
end $$;

create trigger vote_avant_insert before insert on public.vote
  for each row execute function public.vote_avant_insert();

-- ---------------------------------------------------------------------------
-- poll_result
-- ---------------------------------------------------------------------------

create table public.poll_result (
  poll_id   bigint not null references public.poll(id) on delete cascade,
  dimension text not null check (dimension in ('total', 'pays', 'tranche_age', 'region')),
  valeur    text not null default '',            -- '' pour la dimension total
  option_id bigint not null references public.poll_option(id) on delete cascade,
  n         int not null check (n >= 0),         -- votes pour cette option dans la cellule
  n_cellule int not null check (n_cellule >= 0), -- répondants dans la cellule
  calcule   timestamptz not null default now(),
  primary key (poll_id, dimension, valeur, option_id)
);
comment on table public.poll_result is
  'Agrégats publiés. Seules les cellules d''au moins seuil_decoupe() répondants existent ; la dimension total est toujours présente. Le pourcentage se calcule côté client : n / n_cellule.';

create or replace function public.calculer_resultats(p_poll_id bigint)
returns void language plpgsql security definer
set search_path = public
as $$
declare seuil int := seuil_decoupe();
begin
  delete from poll_result where poll_id = p_poll_id;

  with cellules as (
    select 'total'::text as dimension, ''::text as valeur, user_id, option_id from vote where poll_id = p_poll_id
    union all
    select 'pays', country_code, user_id, option_id from vote where poll_id = p_poll_id and country_code is not null
    union all
    select 'tranche_age', tranche_age, user_id, option_id from vote where poll_id = p_poll_id and tranche_age is not null
    union all
    select 'region', region_id::text, user_id, option_id from vote where poll_id = p_poll_id and region_id is not null
  ),
  tailles as (
    select dimension, valeur, count(*)::int as n_cellule
    from cellules group by dimension, valeur
    having dimension = 'total' or count(*) >= seuil
  )
  insert into poll_result (poll_id, dimension, valeur, option_id, n, n_cellule)
  select p_poll_id, t.dimension, t.valeur, o.id,
         (select count(*)::int from cellules c
            where c.dimension = t.dimension and c.valeur = t.valeur and c.option_id = o.id),
         t.n_cellule
  from tailles t
  cross join poll_option o
  where o.poll_id = p_poll_id;

  -- la dimension total existe même sans aucun vote
  insert into poll_result (poll_id, dimension, valeur, option_id, n, n_cellule)
  select p_poll_id, 'total', '', o.id, 0, 0
  from poll_option o
  where o.poll_id = p_poll_id
    and not exists (select 1 from poll_result r where r.poll_id = p_poll_id and r.dimension = 'total');
end $$;

-- Tour de cron : recalcule les sondages ouverts, fige ceux qui viennent de fermer.
create or replace function public.poll_tick()
returns int language plpgsql security definer
set search_path = public
as $$
declare r record; n int := 0;
begin
  for r in
    select p.* from poll p
    where p.publie
      and (poll_statut(p) = 'ouvert'
           or (poll_statut(p) = 'ferme' and p.resultat_final_le is null))
  loop
    perform calculer_resultats(r.id);
    if poll_statut(r) = 'ferme' then
      update poll set resultat_final_le = now() where id = r.id;
    end if;
    n := n + 1;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------------------
-- Vues
-- ---------------------------------------------------------------------------

-- Nombre de répondants, lisible avant de voter (ce n'est pas le score).
create or replace function public.poll_repondants(p_poll_id bigint)
returns int language sql stable security definer
set search_path = public
as $$ select count(*)::int from vote where poll_id = p_poll_id $$;

create or replace view public.poll_public
with (security_invoker = true)
as
select p.id, p.country_code, p.semaine, p.question, p.contexte, p.sources,
       p.person_id, p.organization_id, p.ouverture, p.fermeture,
       poll_statut(p) as statut,
       p.suspect, p.suspect_motif,
       p.resultat_final_le is not null as resultat_final,
       poll_repondants(p.id) as repondants,
       (select coalesce(jsonb_agg(jsonb_build_object(
                 'id', o.id, 'ordre', o.ordre, 'libelle', o.libelle, 'neutre', o.neutre)
               order by o.ordre), '[]'::jsonb)
          from poll_option o where o.poll_id = p.id) as options
from poll p
where p.publie;
comment on view public.poll_public is 'Ce que l''app lit : sondages publiés, options, état, nombre de répondants. Jamais les scores.';

-- Signaux de manipulation. La vue signale, elle ne bloque pas.
-- Lecture réservée à l'équipe (rôle de service).
create or replace view public.poll_anomalie
with (security_invoker = false)
as
with v as (
  select v.poll_id, v.user_id, v.cree, pr.cree as profil_cree
  from vote v
  left join profile pr on pr.user_id = v.user_id
),
par_minute as (
  select poll_id, date_trunc('minute', cree) as minute, count(*) as n
  from v group by 1, 2
),
agg as (
  select p.id as poll_id,
         count(v.user_id)::int as votes,
         count(v.user_id) filter (where v.profil_cree is null)::int as votes_sans_profil,
         count(v.user_id) filter (where v.profil_cree > v.cree - interval '1 hour')::int as votes_comptes_recents,
         coalesce((select max(n) from par_minute pm where pm.poll_id = p.id), 0)::int as pic_par_minute
  from poll p
  left join v on v.poll_id = p.id
  group by p.id
)
select p.id as poll_id, p.country_code, p.semaine, p.question, poll_statut(p) as statut,
       a.votes, a.votes_sans_profil, a.votes_comptes_recents, a.pic_par_minute,
       round(100.0 * a.votes_comptes_recents / nullif(a.votes, 0), 1) as part_comptes_recents,
       round(100.0 * a.pic_par_minute / nullif(a.votes, 0), 1) as part_pic,
       array_remove(array[
         case when a.votes >= 100 and a.votes_comptes_recents * 2 > a.votes then 'comptes_recents' end,
         case when a.votes >= 100 and a.pic_par_minute * 5 > a.votes then 'pic' end,
         case when a.votes_sans_profil > 0 then 'sans_profil' end
       ], null) as signaux,
       p.suspect, p.suspect_motif
from poll p
join agg a on a.poll_id = p.id;
comment on view public.poll_anomalie is
  'Signaux par sondage : part de votes venant de comptes créés moins d''une heure avant, pic par minute. Ne bloque rien ; l''équipe décide de poll.suspect.';
