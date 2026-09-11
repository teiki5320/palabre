-- Palabre — base factuelle : personnes, organisations, gouvernements, mandats
--
-- Un gouvernement est une suite de mandats datés, pas un état courant.
-- Chaque fait porte sa source et son niveau de confiance.

create table public.person (
  id            bigserial primary key,
  country_code  text not null references public.country(code),
  nom           text not null,
  naissance     date,
  photo_url     text,
  photo_source  text,
  photo_licence text,
  wikidata_id   text unique check (wikidata_id ~ '^Q[0-9]+$'),
  cree          timestamptz not null default now(),
  modifie       timestamptz not null default now(),
  check (photo_url is null or photo_source is not null)   -- pas de photo sans source
);
comment on table public.person is 'Toute personne affichée dans l''app. Photo absente → repli en initiales côté client.';

create trigger person_modifie before update on public.person
  for each row execute function public.set_modifie();

create table public.organization (
  id           bigserial primary key,
  country_code text not null references public.country(code),
  type         text not null check (type in ('parti', 'coalition', 'gouvernement', 'assemblee', 'groupe_parlementaire')),
  nom          text not null,
  sigle        text,
  couleur      text check (couleur ~ '^#[0-9a-fA-F]{6}$'),   -- couleur d'encodage (groupe parlementaire), jamais décorative
  fondation    date,
  dissolution  date,
  parent_id    bigint references public.organization(id),
  wikidata_id  text unique check (wikidata_id ~ '^Q[0-9]+$'),
  source_url   text,
  cree         timestamptz not null default now(),
  modifie      timestamptz not null default now(),
  check (dissolution is null or fondation is null or dissolution >= fondation)
);
comment on column public.organization.parent_id is 'Ex. un groupe parlementaire rattaché à son assemblée.';

create trigger organization_modifie before update on public.organization
  for each row execute function public.set_modifie();

create table public.org_relation (
  id         bigserial primary key,
  from_id    bigint not null references public.organization(id),
  to_id      bigint not null references public.organization(id),
  type       text not null check (type in ('scission', 'fusion', 'renommage', 'coalition_membre', 'absorption')),
  date       date,
  source_url text,
  check (from_id <> to_id)
);
comment on table public.org_relation is 'Histoire des organisations : scissions, fusions, renommages, appartenance à une coalition.';

create table public.government (
  id                  bigserial primary key,
  country_code        text not null references public.country(code),
  nom                 text not null,
  chef_gouv_id        bigint references public.person(id),
  debut               date not null,
  fin                 date,
  portefeuilles_total int,          -- nombre de portefeuilles selon le décret ; sert à afficher « 8 des 25 renseignés »
  decret_ref          text,
  source_url          text,
  cree                timestamptz not null default now(),
  check (fin is null or fin > debut),
  -- un seul gouvernement à une date donnée dans un pays
  exclude using gist (country_code with =, daterange(debut, fin, '[)') with &&)
);

create table public.portfolio (
  id            bigserial primary key,
  country_code  text not null references public.country(code),
  intitule      text not null,
  intitule_norm text not null,      -- suit un portefeuille à travers ses renommages
  bloc          text not null check (bloc in ('regalien', 'economie', 'social', 'infrastructure')),
  rang          int not null default 100,
  unique (country_code, intitule)
);
comment on column public.portfolio.intitule_norm is
  'Clé stable d''un portefeuille (ex. « sante ») : les intitulés changent à chaque remaniement, la clé non.';

create index portfolio_norm_idx on public.portfolio (country_code, intitule_norm);

create table public.role (
  id              bigserial primary key,
  country_code    text not null references public.country(code),
  type            text not null check (type in ('chef_gouvernement', 'ministre', 'depute', 'president_assemblee', 'dirigeant_parti')),
  intitule        text not null,
  intitule_norm   text not null,
  organization_id bigint references public.organization(id),
  unique (country_code, intitule_norm)
);

create table public.mandate (
  id              bigserial primary key,
  person_id       bigint not null references public.person(id),
  role_id         bigint not null references public.role(id),
  portfolio_id    bigint references public.portfolio(id),
  government_id   bigint references public.government(id),
  constituency_id bigint,           -- FK posée dans la migration assemblée
  debut           date not null,
  fin             date,
  motif_fin       text check (motif_fin in (
                    'fin_gouvernement', 'remaniement', 'demission', 'revocation', 'deces',
                    'nomination_gouvernement', 'fin_legislature', 'invalidation', 'autre')),
  acte_ref        text,
  source_url      text,
  confiance       text not null default 'presse'
                  check (confiance in ('journal_officiel', 'communique', 'agence', 'wikidata', 'presse')),
  cree            timestamptz not null default now(),
  modifie         timestamptz not null default now(),
  check (fin is null or fin >= debut),
  check (fin is null or motif_fin is not null)   -- une fin de mandat a toujours un motif
);
comment on column public.mandate.confiance is
  'Niveau de la source, par ordre d''autorité (section 6) : journal_officiel > communique > agence > wikidata > presse.';

create trigger mandate_modifie before update on public.mandate
  for each row execute function public.set_modifie();

create index mandate_person_idx on public.mandate (person_id);
create index mandate_government_idx on public.mandate (government_id);
create index mandate_periode_idx on public.mandate (debut, fin);

create table public.affiliation (
  id              bigserial primary key,
  person_id       bigint not null references public.person(id),
  organization_id bigint not null references public.organization(id),
  debut           date not null,
  fin             date,
  source_url      text,
  check (fin is null or fin >= debut)
);
comment on table public.affiliation is
  'Séparée de mandate : un élu peut changer de groupe ou de parti en cours de mandat.';

create index affiliation_person_idx on public.affiliation (person_id);
create index affiliation_org_idx on public.affiliation (organization_id);

create table public.career (
  id           bigserial primary key,
  person_id    bigint not null references public.person(id),
  periode      text not null,
  fonction     text not null,
  organisation text,
  source_url   text
);

-- Composition d'un gouvernement à une date donnée. C'est l'écran signature :
-- on fait glisser le curseur, la grille se recompose.
create or replace function public.gouvernement_a(p_country text, p_date date)
returns table (
  government_id  bigint,
  government_nom text,
  mandate_id     bigint,
  person_id      bigint,
  person_nom     text,
  photo_url      text,
  role_type      text,
  intitule       text,
  portfolio_id   bigint,
  intitule_norm  text,
  bloc           text,
  rang           int,
  debut          date,
  fin            date,
  source_url     text,
  confiance      text
)
language sql stable
set search_path = public
as $$
  select g.id, g.nom, m.id, p.id, p.nom, p.photo_url, r.type,
         coalesce(pf.intitule, r.intitule),
         pf.id, coalesce(pf.intitule_norm, r.intitule_norm), pf.bloc,
         case when r.type = 'chef_gouvernement' then 0 else coalesce(pf.rang, 100) end,
         m.debut, m.fin, m.source_url, m.confiance
  from government g
  join mandate m on m.government_id = g.id
  join person p on p.id = m.person_id
  join role r on r.id = m.role_id
  left join portfolio pf on pf.id = m.portfolio_id
  where g.country_code = p_country
    and g.debut <= p_date and (g.fin is null or g.fin > p_date)
    and m.debut <= p_date and (m.fin is null or m.fin > p_date)
    and r.type in ('chef_gouvernement', 'ministre')
  order by 12, 5;
$$;

-- Couverture : « 8 des 25 portefeuilles renseignés ».
create or replace function public.gouvernement_couverture(p_country text, p_date date)
returns table (government_id bigint, renseignes int, total int)
language sql stable
set search_path = public
as $$
  select g.id,
         (select count(distinct m.portfolio_id)::int
            from mandate m
            where m.government_id = g.id and m.portfolio_id is not null
              and m.debut <= p_date and (m.fin is null or m.fin > p_date)),
         g.portefeuilles_total
  from government g
  where g.country_code = p_country
    and g.debut <= p_date and (g.fin is null or g.fin > p_date);
$$;
