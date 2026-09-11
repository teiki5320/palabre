-- Palabre — configuration de production : pays, régions, modules, paramètres.
-- À exécuter une fois sur le projet de production, après `supabase db push`.
-- Idempotent : on peut le rejouer sans créer de doublons.
--
-- Ce fichier ne contient que de la configuration, aucune donnée fictive.
-- Ne jamais charger supabase/seed.sql en production.

begin;

insert into public.country (code, nom, fuseau, langue, actif) values
  ('SN', 'Sénégal', 'Africa/Dakar', 'fr', true)
on conflict (code) do update set nom = excluded.nom, fuseau = excluded.fuseau, langue = excluded.langue, actif = excluded.actif;

-- Les 14 régions administratives (codes ISO 3166-2:SN).
insert into public.region (country_code, code, nom) values
  ('SN', 'DK', 'Dakar'),       ('SN', 'DB', 'Diourbel'),   ('SN', 'FK', 'Fatick'),
  ('SN', 'KA', 'Kaffrine'),    ('SN', 'KL', 'Kaolack'),    ('SN', 'KE', 'Kédougou'),
  ('SN', 'KD', 'Kolda'),       ('SN', 'LG', 'Louga'),      ('SN', 'MT', 'Matam'),
  ('SN', 'SL', 'Saint-Louis'), ('SN', 'SE', 'Sédhiou'),    ('SN', 'TC', 'Tambacounda'),
  ('SN', 'TH', 'Thiès'),       ('SN', 'ZG', 'Ziguinchor')
on conflict (country_code, code) do update set nom = excluded.nom;

-- Tous les modules actifs. Pour suspendre un module (période électorale) :
--   update country_module set actif = false, motif = '…' where country_code = 'SN' and module = 'poll';
insert into public.country_module (country_code, module, actif) values
  ('SN', 'poll', true), ('SN', 'quiz', true), ('SN', 'government', true), ('SN', 'assembly', true)
on conflict (country_code, module) do nothing;

insert into public.app_config (cle, valeur) values
  ('version_min_app', '0.1.0')
on conflict (cle) do nothing;

commit;
