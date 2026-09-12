-- Palabre — configuration de production : Côte d'Ivoire.
-- Pays, districts (utilisés comme régions de découpe), modules.
-- Idempotent : on peut le rejouer sans créer de doublons.
--
-- Ce fichier ne contient que de la configuration, aucune donnée fictive.
-- Ne jamais charger supabase/seed.sql en production.

begin;

insert into public.country (code, nom, fuseau, langue, actif) values
  ('CI', 'Côte d''Ivoire', 'Africa/Abidjan', 'fr', true)
on conflict (code) do update set nom = excluded.nom, fuseau = excluded.fuseau, langue = excluded.langue, actif = excluded.actif;

-- Les 12 districts et 2 districts autonomes (codes ISO 3166-2:CI).
insert into public.region (country_code, code, nom) values
  ('CI', 'AB', 'Abidjan'),           ('CI', 'BS', 'Bas-Sassandra'),       ('CI', 'CM', 'Comoé'),
  ('CI', 'DN', 'Denguélé'),          ('CI', 'GD', 'Gôh-Djiboua'),         ('CI', 'LC', 'Lacs'),
  ('CI', 'LG', 'Lagunes'),           ('CI', 'MG', 'Montagnes'),           ('CI', 'SM', 'Sassandra-Marahoué'),
  ('CI', 'SV', 'Savanes'),           ('CI', 'VB', 'Vallée du Bandama'),   ('CI', 'WR', 'Woroba'),
  ('CI', 'YM', 'Yamoussoukro'),      ('CI', 'ZZ', 'Zanzan')
on conflict (country_code, code) do update set nom = excluded.nom;

-- Tous les modules actifs. Pour suspendre un module (période électorale) :
--   update country_module set actif = false, motif = '…' where country_code = 'CI' and module = 'poll';
insert into public.country_module (country_code, module, actif) values
  ('CI', 'poll', true), ('CI', 'quiz', true), ('CI', 'government', true), ('CI', 'assembly', true)
on conflict (country_code, module) do nothing;

commit;
