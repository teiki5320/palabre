-- Palabre — API applicative : vote en un appel, résultats en JSON,
-- jetons de notification, cron d'appel de l'Edge Function poll-notify.

-- ---------------------------------------------------------------------------
-- Résultats d'un sondage, au format lu par l'app.
-- Applique les mêmes règles que la politique RLS de poll_result :
-- sondage fermé, ou l'appelant y a voté.
-- ---------------------------------------------------------------------------

create or replace function public.poll_resultats(p_poll_id bigint)
returns jsonb language sql stable
set search_path = public
as $$
  with p as (select * from poll where id = p_poll_id and publie),
  autorise as (
    select exists (select 1 from p where now() >= p.fermeture)
        or exists (select 1 from vote v where v.poll_id = p_poll_id and v.user_id = auth.uid()) as ok
  ),
  cellules as (
    select r.dimension, r.valeur, r.n_cellule,
           jsonb_agg(jsonb_build_object('option_id', r.option_id, 'n', r.n) order by r.option_id) as options
    from poll_result r
    where r.poll_id = p_poll_id
    group by r.dimension, r.valeur, r.n_cellule
  )
  select case when (select ok from autorise) then
    jsonb_build_object(
      'poll_id', p_poll_id,
      'repondants', coalesce((select n_cellule from cellules where dimension = 'total'), 0),
      'final', (select resultat_final_le is not null from p),
      'calcule', (select max(calcule) from poll_result where poll_id = p_poll_id),
      'seuil', seuil_decoupe(),
      'cellules', coalesce((select jsonb_agg(jsonb_build_object(
                     'dimension', dimension, 'valeur', valeur, 'n_cellule', n_cellule, 'options', options)
                     order by dimension, valeur) from cellules), '[]'::jsonb)
    )
  else null end;
$$;

-- ---------------------------------------------------------------------------
-- Voter : un appel, et les résultats en retour.
-- ---------------------------------------------------------------------------

create or replace function public.voter(p_poll_id bigint, p_option_id bigint)
returns jsonb language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Session requise' using errcode = 'insufficient_privilege';
  end if;
  insert into vote (poll_id, user_id, option_id) values (p_poll_id, auth.uid(), p_option_id);
  -- les agrégats du sondage ouvert sont recalculés au prochain tour de cron ;
  -- on renvoie tout de suite ceux qui existent
  return poll_resultats(p_poll_id);
end $$;

-- Mon vote sur un sondage (null si aucun).
create or replace function public.mon_vote(p_poll_id bigint)
returns bigint language sql stable
set search_path = public
as $$ select option_id from vote where poll_id = p_poll_id and user_id = auth.uid() $$;

-- ---------------------------------------------------------------------------
-- Notifications : une par semaine, rappel le samedi. Rien d'autre.
-- ---------------------------------------------------------------------------

create table public.device_token (
  token        text primary key,
  user_id      uuid not null,
  country_code text not null references public.country(code),
  langue       text not null default 'fr',
  plateforme   text check (plateforme in ('android', 'ios')),
  maj          timestamptz not null default now()
);
comment on table public.device_token is 'Jetons FCM. Lus uniquement par l''Edge Function poll-notify (rôle de service).';

create index device_token_user_idx on public.device_token (user_id);
create index device_token_country_idx on public.device_token (country_code);

alter table public.device_token enable row level security;

create policy device_token_creation on public.device_token for insert to authenticated
  with check (user_id = auth.uid());
create policy device_token_modification on public.device_token for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy device_token_suppression on public.device_token for delete to authenticated
  using (user_id = auth.uid());
create policy device_token_lecture on public.device_token for select to authenticated
  using (user_id = auth.uid());

-- Destinataires d'une notification, calculés côté base pour que l'Edge
-- Function ne manipule que des jetons.
--   'ouverture' : tous les jetons du pays d'un sondage ouvert depuis moins d'une heure ;
--   'rappel'    : jetons du pays dont l'utilisateur n'a pas voté, si on est
--                 samedi entre 10h et 11h dans le fuseau du pays.
create or replace function public.notification_destinataires(p_type text)
returns table (token text, langue text, poll_id bigint, question text, country_code text)
language sql stable security definer
set search_path = public
as $$
  select d.token, d.langue, p.id, p.question, p.country_code
  from poll p
  join country c on c.code = p.country_code
  join country_module cm on cm.country_code = p.country_code and cm.module = 'poll' and cm.actif
  join device_token d on d.country_code = p.country_code
  where p.publie
    and (
      (p_type = 'ouverture'
        and p.ouverture <= now() and p.ouverture > now() - interval '1 hour')
      or
      (p_type = 'rappel'
        and now() >= p.ouverture and now() < p.fermeture
        and extract(isodow from (now() at time zone c.fuseau)) = 6
        and extract(hour from (now() at time zone c.fuseau)) = 10
        and not exists (select 1 from vote v where v.poll_id = p.id and v.user_id = d.user_id))
    );
$$;

revoke execute on function public.notification_destinataires(text) from public, anon, authenticated;

-- Appel horaire de l'Edge Function. Nécessite pg_net et deux secrets dans
-- Vault : project_url et service_role_key. Sans eux, on n'installe rien.
do $$
declare has_net boolean; has_vault boolean;
begin
  select exists (select 1 from pg_extension where extname = 'pg_net') into has_net;
  select exists (select 1 from pg_namespace where nspname = 'vault') into has_vault;
  if exists (select 1 from pg_extension where extname = 'pg_cron') and has_net and has_vault then
    perform cron.unschedule(jobid) from cron.job where jobname = 'palabre_poll_notify';
    perform cron.schedule('palabre_poll_notify', '5 * * * *', $job$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/poll-notify',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')),
        body := '{"source":"cron"}'::jsonb)
    $job$);
  else
    raise warning 'palabre_poll_notify non planifié : pg_cron, pg_net ou Vault absent';
  end if;
end $$;
