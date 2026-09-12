-- Palabre — configuration de production : Togo.
-- Pays, régions, modules.
-- Idempotent : on peut le rejouer sans créer de doublons.
--
-- Ce fichier ne contient que de la configuration, aucune donnée fictive.
-- Ne jamais charger supabase/seed.sql en production.

begin;

insert into public.country (code, nom, fuseau, langue, actif) values
  ('TG', 'Togo', 'Africa/Lome', 'fr', true)
on conflict (code) do update set nom = excluded.nom, fuseau = excluded.fuseau, langue = excluded.langue, actif = excluded.actif;

-- Les 5 régions (codes ISO 3166-2:TG).
insert into public.region (country_code, code, nom) values
  ('TG', 'M', 'Maritime'), ('TG', 'P', 'Plateaux'), ('TG', 'C', 'Centrale'), ('TG', 'K', 'Kara'), ('TG', 'S', 'Savanes')
on conflict (country_code, code) do update set nom = excluded.nom;

-- Tous les modules actifs. Pour suspendre un module (période électorale) :
--   update country_module set actif = false, motif = '…' where country_code = 'TG' and module = 'poll';
insert into public.country_module (country_code, module, actif) values
  ('TG', 'poll', true), ('TG', 'quiz', true), ('TG', 'government', true), ('TG', 'assembly', true)
on conflict (country_code, module) do nothing;

commit;
