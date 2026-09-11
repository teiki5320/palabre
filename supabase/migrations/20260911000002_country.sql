-- Palabre — pays, régions, interrupteurs de module, profil utilisateur
--
-- Le pays est une donnée de configuration, jamais une branche de code.

create table public.country (
  code    text primary key check (code ~ '^[A-Z]{2}$'),   -- ISO 3166-1 alpha-2
  nom     text not null,
  fuseau  text not null default 'UTC',                    -- identifiant IANA
  langue  text not null default 'fr',
  actif   boolean not null default false,
  cree    timestamptz not null default now()
);
comment on table public.country is 'Pays couverts. Un pays inactif reste invisible dans le sélecteur.';
comment on column public.country.fuseau is 'Fuseau IANA : les créneaux de sondage sont calculés dans ce fuseau, stockés en UTC.';

create table public.region (
  id           bigserial primary key,
  country_code text not null references public.country(code),
  code         text not null,             -- ISO 3166-2 sans préfixe pays quand il existe
  nom          text not null,
  unique (country_code, code),
  unique (id, country_code)               -- cible de clés composites (profil, circonscription)
);
comment on table public.region is 'Régions administratives, utilisées pour la découpe des résultats.';

create table public.country_module (
  country_code text not null references public.country(code),
  module       text not null check (module in ('poll', 'quiz', 'government', 'assembly')),
  actif        boolean not null default true,
  motif        text,
  modifie      timestamptz not null default now(),
  primary key (country_code, module)
);
comment on table public.country_module is
  'Interrupteur par pays et par module (section 13, droit électoral). Suspendre un module ne demande aucune mise à jour de l''app.';

create trigger country_module_modifie
  before update on public.country_module
  for each row execute function public.set_modifie();

create table public.app_config (
  cle     text primary key,
  valeur  text not null,
  modifie timestamptz not null default now()
);
comment on table public.app_config is 'Paramètres lus par l''app au démarrage : domaine de secours, version minimale…';

create trigger app_config_modifie
  before update on public.app_config
  for each row execute function public.set_modifie();

-- Tranches d'âge admises. Tout est facultatif sauf le pays (section 10).
create or replace function public.tranche_age_valide(p text)
returns boolean language sql immutable as $$
  select p is null or p in ('18-24', '25-34', '35-44', '45-54', '55-64', '65+')
$$;

create table public.profile (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  country_code text not null references public.country(code),
  tranche_age  text check (public.tranche_age_valide(tranche_age)),
  region_id    bigint,
  langue       text not null default 'fr',
  cree         timestamptz not null default now(),
  modifie      timestamptz not null default now(),
  -- la région doit appartenir au pays du profil
  foreign key (region_id, country_code) references public.region(id, country_code)
);
comment on table public.profile is
  'Profil minimal : pays (obligatoire), tranche d''âge et région (facultatifs). Ces champs alimentent les découpes du sondage.';

create trigger profile_modifie
  before update on public.profile
  for each row execute function public.set_modifie();

create index profile_country_idx on public.profile (country_code);
