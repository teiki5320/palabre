-- Palabre — configuration de production : Bénin.
-- Pays, départements (utilisés comme régions de découpe), modules.
-- Idempotent : on peut le rejouer sans créer de doublons.
--
-- Ce fichier ne contient que de la configuration, aucune donnée fictive.
-- Ne jamais charger supabase/seed.sql en production.

begin;

insert into public.country (code, nom, fuseau, langue, actif) values
  ('BJ', 'Bénin', 'Africa/Porto-Novo', 'fr', true)
on conflict (code) do update set nom = excluded.nom, fuseau = excluded.fuseau, langue = excluded.langue, actif = excluded.actif;

-- Les 12 départements (codes ISO 3166-2:BJ).
insert into public.region (country_code, code, nom) values
  ('BJ', 'AL', 'Alibori'),    ('BJ', 'AK', 'Atacora'),   ('BJ', 'AQ', 'Atlantique'),
  ('BJ', 'BO', 'Borgou'),     ('BJ', 'CO', 'Collines'),  ('BJ', 'KO', 'Couffo'),
  ('BJ', 'DO', 'Donga'),      ('BJ', 'LI', 'Littoral'),  ('BJ', 'MO', 'Mono'),
  ('BJ', 'OU', 'Ouémé'),      ('BJ', 'PL', 'Plateau'),   ('BJ', 'ZO', 'Zou')
on conflict (country_code, code) do update set nom = excluded.nom;

-- Tous les modules actifs. Pour suspendre un module (période électorale) :
--   update country_module set actif = false, motif = '…' where country_code = 'BJ' and module = 'poll';
insert into public.country_module (country_code, module, actif) values
  ('BJ', 'poll', true), ('BJ', 'quiz', true), ('BJ', 'government', true), ('BJ', 'assembly', true)
on conflict (country_code, module) do nothing;

commit;
