-- Stub minimal de l'environnement Supabase pour rejouer les migrations sur
-- un Postgres nu : schéma auth, fonction auth.uid(), rôles API et droits
-- par défaut. Jamais appliqué sur un vrai projet Supabase.

create schema if not exists auth;
create schema if not exists extensions;

create table if not exists auth.users (
  instance_id        uuid,
  id                 uuid primary key,
  aud                varchar(255),
  role               varchar(255),
  email              varchar(255),
  encrypted_password varchar(255),
  created_at         timestamptz,
  updated_at         timestamptz,
  is_anonymous       boolean not null default false,
  raw_app_meta_data  jsonb,
  raw_user_meta_data jsonb
);

create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub'
    ), ''
  )::uuid
$$;

create or replace function auth.role() returns text
language sql stable as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.role', true),
      nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'
    ), ''
  )
$$;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin bypassrls; end if;
end $$;

grant usage on schema public, auth, extensions to anon, authenticated, service_role;
grant execute on function auth.uid(), auth.role() to anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
