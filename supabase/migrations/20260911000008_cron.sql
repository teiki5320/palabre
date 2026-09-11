-- Palabre — crons
--
-- Un seul tour : toutes les cinq minutes, poll_tick() recalcule les
-- résultats des sondages ouverts et fige ceux qui viennent de fermer.
-- L'ouverture et la fermeture ne dépendent d'aucun cron : elles se
-- déduisent des horodatages, donc aucun décalage possible.
--
-- La notification d'ouverture (étape 4) sera un second cron du lundi
-- appelant une Edge Function.

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'palabre_poll_tick';
    perform cron.schedule('palabre_poll_tick', '*/5 * * * *', $job$ select public.poll_tick() $job$);
  else
    raise warning 'pg_cron absent : palabre_poll_tick non planifié (normal en test local)';
  end if;
end $$;
