-- Palabre — politiques RLS
--
-- Principe : les utilisateurs (anonymes ou identifiés, tous en rôle
-- `authenticated`) lisent les faits publiés et n'écrivent que leur profil,
-- leur vote et une contestation. Tout le reste s'écrit avec le rôle de
-- service, qui contourne RLS.

-- ---------------------------------------------------------------------------
-- Configuration
-- ---------------------------------------------------------------------------

alter table public.country        enable row level security;
alter table public.region         enable row level security;
alter table public.country_module enable row level security;
alter table public.app_config     enable row level security;

create policy country_lecture        on public.country        for select to anon, authenticated using (true);
create policy region_lecture         on public.region         for select to anon, authenticated using (true);
create policy country_module_lecture on public.country_module for select to anon, authenticated using (true);
create policy app_config_lecture     on public.app_config     for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- Profil : chacun le sien
-- ---------------------------------------------------------------------------

alter table public.profile enable row level security;

create policy profile_lecture on public.profile for select to authenticated
  using (user_id = auth.uid());
create policy profile_creation on public.profile for insert to authenticated
  with check (user_id = auth.uid());
create policy profile_modification on public.profile for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
-- pas de delete : la suppression du compte auth cascade

-- ---------------------------------------------------------------------------
-- Base factuelle : lecture publique, écriture équipe
-- ---------------------------------------------------------------------------

alter table public.person          enable row level security;
alter table public.organization    enable row level security;
alter table public.org_relation    enable row level security;
alter table public.government      enable row level security;
alter table public.portfolio       enable row level security;
alter table public.role            enable row level security;
alter table public.mandate         enable row level security;
alter table public.affiliation     enable row level security;
alter table public.career          enable row level security;
alter table public.legislature     enable row level security;
alter table public.constituency    enable row level security;
alter table public.deputy_activity enable row level security;

create policy person_lecture          on public.person          for select to anon, authenticated using (true);
create policy organization_lecture    on public.organization    for select to anon, authenticated using (true);
create policy org_relation_lecture    on public.org_relation    for select to anon, authenticated using (true);
create policy government_lecture      on public.government      for select to anon, authenticated using (true);
create policy portfolio_lecture       on public.portfolio       for select to anon, authenticated using (true);
create policy role_lecture            on public.role            for select to anon, authenticated using (true);
create policy mandate_lecture         on public.mandate         for select to anon, authenticated using (true);
create policy affiliation_lecture     on public.affiliation     for select to anon, authenticated using (true);
create policy career_lecture          on public.career          for select to anon, authenticated using (true);
create policy legislature_lecture     on public.legislature     for select to anon, authenticated using (true);
create policy constituency_lecture    on public.constituency    for select to anon, authenticated using (true);
create policy deputy_activity_lecture on public.deputy_activity for select to anon, authenticated using (true);

-- ---------------------------------------------------------------------------
-- Sondage
-- ---------------------------------------------------------------------------

alter table public.poll        enable row level security;
alter table public.poll_option enable row level security;
alter table public.vote        enable row level security;
alter table public.poll_result enable row level security;

create policy poll_lecture on public.poll for select to anon, authenticated
  using (publie);

create policy poll_option_lecture on public.poll_option for select to anon, authenticated
  using (exists (select 1 from public.poll p where p.id = poll_id and p.publie));

-- Voter : soi-même, une fois (clé primaire), sur un sondage ouvert (trigger).
create policy vote_creation on public.vote for insert to authenticated
  with check (user_id = auth.uid());
create policy vote_lecture on public.vote for select to authenticated
  using (user_id = auth.uid());

-- Vote avant résultats : on lit les agrégats d'un sondage si on y a voté,
-- ou s'il est fermé (archive).
create policy poll_result_lecture on public.poll_result for select to anon, authenticated
  using (
    exists (select 1 from public.poll p
            where p.id = poll_id and p.publie and now() >= p.fermeture)
    or exists (select 1 from public.vote v
               where v.poll_id = poll_result.poll_id and v.user_id = auth.uid())
  );

-- poll_anomalie : équipe uniquement.
revoke all on public.poll_anomalie from anon, authenticated;
grant select on public.poll_anomalie to service_role;

-- poll_tick et calculer_resultats ne s'appellent que depuis le cron ou l'équipe.
revoke execute on function public.poll_tick() from public, anon, authenticated;
revoke execute on function public.calculer_resultats(bigint) from public, anon, authenticated;
revoke execute on function public.poll_valider(bigint) from public, anon, authenticated;
revoke execute on function public.quiz_valider(bigint) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Testez-vous
-- ---------------------------------------------------------------------------

alter table public.quiz                  enable row level security;
alter table public.statement             enable row level security;
alter table public.party_position        enable row level security;
alter table public.position_contestation enable row level security;

create policy quiz_lecture on public.quiz for select to anon, authenticated
  using (publie);

create policy statement_lecture on public.statement for select to anon, authenticated
  using (exists (select 1 from public.quiz q where q.id = quiz_id and q.publie));

create policy party_position_lecture on public.party_position for select to anon, authenticated
  using (exists (select 1 from public.statement s join public.quiz q on q.id = s.quiz_id
                 where s.id = statement_id and q.publie));

-- Contester : n'importe qui peut déposer, personne ne relit sauf l'équipe.
create policy contestation_depot on public.position_contestation for insert to anon, authenticated
  with check (statut = 'en_attente' and traite_le is null);
