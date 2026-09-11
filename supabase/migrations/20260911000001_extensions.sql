-- Palabre — extensions
--
-- pg_cron n'est pas disponible sur un Postgres nu (tests locaux) : on ne
-- l'installe que s'il est présent, et 0008_cron.sql ne planifie rien sinon.

create extension if not exists pgcrypto;
create extension if not exists citext;
create extension if not exists btree_gist;

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    execute 'create extension if not exists pg_cron with schema pg_catalog';
    execute 'grant usage on schema cron to postgres';
  else
    raise warning 'pg_cron indisponible : aucun cron ne sera planifié';
  end if;
end $$;

-- Horodatage de modification générique.
create or replace function public.set_modifie()
returns trigger language plpgsql as $$
begin
  new.modifie := now();
  return new;
end $$;
