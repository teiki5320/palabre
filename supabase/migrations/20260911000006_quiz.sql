-- Palabre — module « Testez-vous »
--
-- On ne juge pas les partis, on leur pose les mêmes questions.
-- Aucune table n'associe un utilisateur à une orientation politique :
-- le résultat est calculé côté client et n'est jamais stocké.

create table public.quiz (
  id           bigserial primary key,
  country_code text not null references public.country(code),
  titre        text not null,
  version      int not null default 1,
  publie       boolean not null default false,
  cree         timestamptz not null default now(),
  unique (country_code, titre, version)
);

create table public.statement (
  id      bigserial primary key,
  quiz_id bigint not null references public.quiz(id) on delete cascade,
  ordre   int not null,
  texte   text not null,          -- une affirmation, pas une question
  theme   text,                   -- education, sante, economie…
  unique (quiz_id, ordre)
);

create table public.party_position (
  id             bigserial primary key,
  statement_id   bigint not null references public.statement(id) on delete cascade,
  org_id         bigint not null references public.organization(id),   -- parti ou coalition, jamais une personne
  position       text not null check (position in ('accord', 'desaccord', 'neutre', 'sans_position')),
  -- niveau de source, toujours affiché à côté de la position
  source_type    text not null check (source_type in ('reponse_directe', 'document_public', 'aucune')),
  source_url     text,
  source_extrait text,            -- citation courte, jamais le texte intégral
  date_source    date,
  corrige_le     timestamptz,     -- si le parti a fait valoir son droit de correction
  modifie        timestamptz not null default now(),
  unique (statement_id, org_id),
  -- aucune extrapolation, jamais : sans source ⇔ sans position
  check ((source_type = 'aucune') = (position = 'sans_position')),
  check (source_type <> 'document_public' or (source_url is not null and source_extrait is not null)),
  check (source_type = 'aucune' or date_source is not null),
  check (source_extrait is null or length(source_extrait) <= 600)
);
comment on table public.party_position is
  'Position d''une organisation sur une affirmation. reponse_directe > document_public > aucune. Un parti qui ne répond pas porte lui-même le coût de son silence.';

create trigger party_position_modifie before update on public.party_position
  for each row execute function public.set_modifie();

create index party_position_org_idx on public.party_position (org_id);

-- Droit de correction : formulaire accessible depuis chaque position.
create table public.position_contestation (
  id          bigserial primary key,
  position_id bigint not null references public.party_position(id) on delete cascade,
  auteur      text,               -- contact déclaré (nom, e-mail…), jamais lié à un user_id
  argument    text not null,
  piece_url   text,
  statut      text not null default 'en_attente' check (statut in ('en_attente', 'acceptee', 'rejetee')),
  cree        timestamptz not null default now(),
  traite_le   timestamptz,
  check (length(argument) between 20 and 4000)
);
comment on table public.position_contestation is
  'Contestations déposées par quiconque, pièce à l''appui. Lecture réservée à l''équipe. Une correction acceptée met à jour party_position et son corrige_le.';

-- Un quiz publié doit compter entre 20 et 30 affirmations, et chaque
-- organisation référencée doit avoir une position sur chaque affirmation
-- (quitte à ce qu'elle soit sans_position).
create or replace function public.quiz_valider(p_quiz_id bigint)
returns void language plpgsql stable
set search_path = public
as $$
declare n int; manquantes int;
begin
  select count(*) into n from statement where quiz_id = p_quiz_id;
  if n < 20 or n > 30 then
    raise exception 'Un quiz publié compte entre 20 et 30 affirmations (quiz %, % affirmation(s))', p_quiz_id, n
      using errcode = 'check_violation';
  end if;

  select count(*) into manquantes
  from statement s
  cross join (select distinct pp.org_id from party_position pp
              join statement s2 on s2.id = pp.statement_id where s2.quiz_id = p_quiz_id) orgs
  where s.quiz_id = p_quiz_id
    and not exists (select 1 from party_position pp where pp.statement_id = s.id and pp.org_id = orgs.org_id);
  if manquantes > 0 then
    raise exception 'Quiz % : % position(s) manquante(s). Renseigner sans_position plutôt que laisser un trou.', p_quiz_id, manquantes
      using errcode = 'check_violation';
  end if;
end $$;

create or replace function public.quiz_avant_publication()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.publie and not coalesce(old.publie, false) then
    perform quiz_valider(new.id);
  end if;
  return new;
end $$;

create trigger quiz_avant_publication before update of publie on public.quiz
  for each row execute function public.quiz_avant_publication();
