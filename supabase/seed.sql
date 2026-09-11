-- Palabre — jeu de données de test
--
-- TOUT EST FICTIF. Les personnes, organisations, gouvernements et
-- circonscriptions portent le préfixe « Test » ; les sources pointent vers
-- example.org. Les vraies données sourcées arrivent avec la collecte des
-- étapes 5 et 6. Le jeu exerce chaque mécanisme du schéma : seuil de 30,
-- renommage de portefeuille, suppléance, changement de groupe, trois
-- niveaux de source du quiz.

begin;
select setseed(0.42);

-- ---------------------------------------------------------------------------
-- Pays, régions, modules, configuration
-- ---------------------------------------------------------------------------

insert into public.country (code, nom, fuseau, langue, actif) values
  ('SN', 'Sénégal',       'Africa/Dakar',   'fr', true),
  ('CI', 'Côte d''Ivoire', 'Africa/Abidjan', 'fr', false);

insert into public.region (country_code, code, nom) values
  ('SN', 'DK', 'Dakar'),       ('SN', 'DB', 'Diourbel'),   ('SN', 'FK', 'Fatick'),
  ('SN', 'KA', 'Kaffrine'),    ('SN', 'KL', 'Kaolack'),    ('SN', 'KE', 'Kédougou'),
  ('SN', 'KD', 'Kolda'),       ('SN', 'LG', 'Louga'),      ('SN', 'MT', 'Matam'),
  ('SN', 'SL', 'Saint-Louis'), ('SN', 'SE', 'Sédhiou'),    ('SN', 'TC', 'Tambacounda'),
  ('SN', 'TH', 'Thiès'),       ('SN', 'ZG', 'Ziguinchor'),
  ('CI', 'AB', 'Abidjan');

insert into public.country_module (country_code, module, actif, motif) values
  ('SN', 'poll', true, null), ('SN', 'quiz', true, null),
  ('SN', 'government', true, null), ('SN', 'assembly', true, null),
  ('CI', 'poll', false, 'Période électorale (donnée de test)'), ('CI', 'quiz', false, 'Période électorale (donnée de test)'),
  ('CI', 'government', true, null), ('CI', 'assembly', true, null);

insert into public.app_config (cle, valeur) values
  ('domaine_secours', 'https://secours.example.org'),
  ('version_min_app', '1.0.0');

-- ---------------------------------------------------------------------------
-- Utilisateurs et profils : 300 comptes anonymes, répartition volontairement
-- inégale pour que certaines cellules passent le seuil de 30 et d'autres non.
-- ---------------------------------------------------------------------------

create temp table seed_user as
select i,
       ('00000000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid as id,
       random() as r_age, random() as r_region, random() as r_null
from generate_series(1, 300) i;

insert into auth.users (instance_id, id, aud, role, created_at, updated_at, is_anonymous,
                        raw_app_meta_data, raw_user_meta_data,
                        confirmation_token, recovery_token, email_change_token_new, email_change)
select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
       now() - interval '60 days' + (i || ' hours')::interval, now(), true,
       '{"provider":"anonymous","providers":["anonymous"]}', '{}', '', '', '', ''
from seed_user;

insert into public.profile (user_id, country_code, tranche_age, region_id, cree)
select u.id, 'SN',
       case when u.r_null < 0.10 then null
            when u.r_age < 0.30 then '18-24'
            when u.r_age < 0.60 then '25-34'
            when u.r_age < 0.70 then '35-44'
            when u.r_age < 0.80 then '45-54'
            when u.r_age < 0.90 then '55-64'
            else '65+' end,
       case when u.r_null < 0.10 then null
            when u.r_region < 0.40 then (select id from public.region where country_code = 'SN' and code = 'DK')
            when u.r_region < 0.55 then (select id from public.region where country_code = 'SN' and code = 'TH')
            else (select id from public.region r where r.country_code = 'SN'
                  order by md5(u.i::text || r.code) limit 1) end,
       now() - interval '60 days' + (u.i || ' hours')::interval
from seed_user u;

-- ---------------------------------------------------------------------------
-- Organisations (fictives)
-- ---------------------------------------------------------------------------

insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values
  (1, 'SN', 'parti',      'Parti Test Alpha',      'PTA', '#3B82F6', '2010-03-01', 'https://example.org/pta'),
  (2, 'SN', 'parti',      'Union Test Bêta',       'UTB', '#F59E0B', '2005-06-15', 'https://example.org/utb'),
  (3, 'SN', 'parti',      'Mouvement Test Gamma',  'MTG', '#10B981', '2018-11-20', 'https://example.org/mtg'),
  (4, 'SN', 'coalition',  'Coalition Test Alpha-Gamma', 'CTAG', '#6366F1', '2023-09-01', 'https://example.org/ctag'),
  (5, 'SN', 'assemblee',  'Assemblée nationale (test)', null, null, null, 'https://example.org/assemblee'),
  (6, 'SN', 'gouvernement', 'Gouvernement de la République (test)', null, null, null, 'https://example.org/gouv');
insert into public.organization (id, country_code, type, nom, sigle, couleur, parent_id, fondation) values
  (7, 'SN', 'groupe_parlementaire', 'Groupe Test Alpha',      'G-PTA', '#3B82F6', 5, '2024-12-02'),
  (8, 'SN', 'groupe_parlementaire', 'Groupe Test Bêta-Gamma', 'G-BG',  '#F59E0B', 5, '2024-12-02');
select setval('public.organization_id_seq', 8);

insert into public.org_relation (from_id, to_id, type, date, source_url) values
  (1, 4, 'coalition_membre', '2023-09-01', 'https://example.org/ctag'),
  (3, 4, 'coalition_membre', '2023-09-01', 'https://example.org/ctag');

-- ---------------------------------------------------------------------------
-- Personnes (fictives)
-- ---------------------------------------------------------------------------

insert into public.person (id, country_code, nom, naissance, photo_url, photo_source, photo_licence) values
  (1,  'SN', 'Test Awa Diallo',        '1968-02-11', 'https://example.org/photos/1.jpg', 'Présidence (test)', 'CC BY 4.0'),
  (2,  'SN', 'Test Moussa Ndiaye',     '1961-07-30', null, null, null),
  (3,  'SN', 'Test Fatou Sarr',        '1972-12-05', null, null, null),
  (4,  'SN', 'Test Ibrahima Fall',     '1975-04-18', 'https://example.org/photos/4.jpg', 'Ministère (test)', 'CC BY-SA 4.0'),
  (5,  'SN', 'Test Mariama Ba',        '1970-09-09', null, null, null),
  (6,  'SN', 'Test Ousmane Sy',        '1979-01-23', null, null, null),
  (7,  'SN', 'Test Aïssatou Gueye',    '1966-05-02', null, null, null),
  (8,  'SN', 'Test Cheikh Diouf',      '1973-10-14', null, null, null),
  (9,  'SN', 'Test Ndèye Faye',        '1981-03-27', null, null, null),
  (10, 'SN', 'Test Abdou Kane',        '1985-08-08', null, null, null),
  (11, 'SN', 'Test Rokhaya Mbaye',     '1977-06-19', null, null, null),
  (12, 'SN', 'Test Lamine Cissé',      '1969-11-11', null, null, null),
  (13, 'SN', 'Test Khady Thiam',       '1983-02-02', null, null, null);
select setval('public.person_id_seq', 13);

insert into public.career (person_id, periode, fonction, organisation, source_url) values
  (1, '2012-2019', 'Directrice générale', 'Agence test de développement', 'https://example.org/cv/1'),
  (1, '2019-2024', 'Députée', 'Assemblée nationale (test)', 'https://example.org/cv/1');

-- ---------------------------------------------------------------------------
-- Rôles, portefeuilles, gouvernements
-- ---------------------------------------------------------------------------

insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values
  (1, 'SN', 'chef_gouvernement',   'Premier ministre',            'premier_ministre',      6),
  (2, 'SN', 'ministre',            'Ministre',                    'ministre',              6),
  (3, 'SN', 'depute',              'Député',                      'depute',                5),
  (4, 'SN', 'president_assemblee', 'Président de l''Assemblée',   'president_assemblee',   5),
  (5, 'SN', 'dirigeant_parti',     'Dirigeant de parti',          'dirigeant_parti',       null);
select setval('public.role_id_seq', 5);

insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values
  (1, 'SN', 'Intérieur et Sécurité publique',            'interieur',       'regalien',       10),
  (2, 'SN', 'Justice',                                    'justice',         'regalien',       11),
  (3, 'SN', 'Finances et Budget',                         'finances',        'economie',       20),
  (4, 'SN', 'Économie, Plan et Coopération',              'economie',        'economie',       21),
  (5, 'SN', 'Santé et Action sociale',                    'sante',           'social',         30),
  (6, 'SN', 'Santé, Hygiène publique et Action sociale',  'sante',           'social',         30),  -- renommage du 5
  (7, 'SN', 'Éducation nationale',                        'education',       'social',         31),
  (8, 'SN', 'Infrastructures et Transports',              'infrastructures', 'infrastructure', 40),
  (9, 'SN', 'Hydraulique et Assainissement',              'eau',             'infrastructure', 41);
select setval('public.portfolio_id_seq', 9);

insert into public.government (id, country_code, nom, chef_gouv_id, debut, fin, portefeuilles_total, decret_ref, source_url) values
  (1, 'SN', 'Gouvernement test I',  1, '2024-04-05', '2025-09-06', 25, 'Décret test 2024-001', 'https://example.org/jo/2024-001'),
  (2, 'SN', 'Gouvernement test II', 1, '2025-09-06', null,         25, 'Décret test 2025-017', 'https://example.org/jo/2025-017');
select setval('public.government_id_seq', 2);

-- Gouvernement I
insert into public.mandate (id, person_id, role_id, portfolio_id, government_id, debut, fin, motif_fin, acte_ref, source_url, confiance) values
  (1, 1, 1, null, 1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  (2, 2, 2, 1,    1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  (3, 3, 2, 2,    1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  (4, 4, 2, 3,    1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  (5, 5, 2, 5,    1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  (6, 6, 2, 7,    1, '2024-04-05', '2025-03-15', 'demission',        'Décret test 2025-004', 'https://example.org/jo/2025-004', 'communique'),
  (7, 7, 2, 8,    1, '2024-04-05', '2025-09-06', 'fin_gouvernement', 'Décret test 2024-001', 'https://example.org/jo/2024-001', 'journal_officiel'),
  -- remplacement en cours de gouvernement après la démission du 6
  (8, 8, 2, 7,    1, '2025-03-15', '2025-09-06', 'fin_gouvernement', 'Décret test 2025-004', 'https://example.org/jo/2025-004', 'agence');
-- Gouvernement II : santé renommée (portefeuille 6, même intitule_norm),
-- éducation confiée à une députée (9), infrastructures non pourvues.
insert into public.mandate (id, person_id, role_id, portfolio_id, government_id, debut, fin, motif_fin, acte_ref, source_url, confiance) values
  (9,  1, 1, null, 2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel'),
  (10, 8, 2, 1,    2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel'),
  (11, 3, 2, 2,    2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel'),
  (12, 4, 2, 3,    2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel'),
  (13, 5, 2, 6,    2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel'),
  (14, 9, 2, 7,    2, '2025-09-06', null, null, 'Décret test 2025-017', 'https://example.org/jo/2025-017', 'journal_officiel');

-- ---------------------------------------------------------------------------
-- Assemblée
-- ---------------------------------------------------------------------------

insert into public.legislature (id, country_code, numero, debut, fin, sieges_total, scrutins_nominatifs, source_url) values
  (1, 'SN', 15, '2024-12-02', null, 165, false, 'https://example.org/assemblee/15');
select setval('public.legislature_id_seq', 1);

insert into public.constituency (id, country_code, legislature_id, nom, type, sieges, region_id) values
  (1, 'SN', 1, 'Dakar',                     'departement',     7,  (select id from public.region where country_code = 'SN' and code = 'DK')),
  (2, 'SN', 1, 'Thiès',                     'departement',     5,  (select id from public.region where country_code = 'SN' and code = 'TH')),
  (3, 'SN', 1, 'Liste nationale',           'liste_nationale', 53, null),
  (4, 'SN', 1, 'Diaspora — Europe du Nord', 'diaspora',        2,  null);
select setval('public.constituency_id_seq', 4);

-- Députés. La 9 (Dakar) est nommée ministre le 2025-09-06 : son mandat se
-- clôt et sa suppléante (10) siège en pointant sur son mandat.
insert into public.mandate (id, person_id, role_id, constituency_id, qualite, remplace_mandate_id, debut, fin, motif_fin, source_url, confiance) values
  (20, 9,  3, 1, 'titulaire', null, '2024-12-02', '2025-09-06', 'nomination_gouvernement', 'https://example.org/assemblee/15', 'journal_officiel'),
  (21, 10, 3, 1, 'suppleant', 20,   '2025-09-06', null, null, 'https://example.org/assemblee/15/suppleances', 'communique'),
  (22, 11, 3, 2, 'titulaire', null, '2024-12-02', null, null, 'https://example.org/assemblee/15', 'journal_officiel'),
  (23, 12, 3, 3, 'titulaire', null, '2024-12-02', null, null, 'https://example.org/assemblee/15', 'journal_officiel'),
  (24, 13, 3, 4, 'titulaire', null, '2024-12-02', null, null, 'https://example.org/assemblee/15', 'journal_officiel'),
  (25, 12, 4, null, 'titulaire', null, '2024-12-02', null, null, 'https://example.org/assemblee/15/bureau', 'journal_officiel');
select setval('public.mandate_id_seq', 25);

-- Affiliations : partis et groupes. La 11 change de groupe le 2025-06-01.
insert into public.affiliation (person_id, organization_id, debut, fin, source_url) values
  (1,  1, '2010-03-01', null, 'https://example.org/pta/membres'),
  (9,  1, '2015-01-01', null, 'https://example.org/pta/membres'),
  (9,  7, '2024-12-02', '2025-09-06', 'https://example.org/assemblee/15/groupes'),
  (10, 1, '2019-01-01', null, 'https://example.org/pta/membres'),
  (10, 7, '2025-09-06', null, 'https://example.org/assemblee/15/groupes'),
  (11, 3, '2018-11-20', null, 'https://example.org/mtg/membres'),
  (11, 7, '2024-12-02', '2025-06-01', 'https://example.org/assemblee/15/groupes'),
  (11, 8, '2025-06-01', null, 'https://example.org/assemblee/15/groupes'),
  (12, 2, '2005-06-15', null, 'https://example.org/utb/membres'),
  (12, 8, '2024-12-02', null, 'https://example.org/assemblee/15/groupes'),
  (13, 2, '2012-01-01', null, 'https://example.org/utb/membres'),
  (13, 8, '2024-12-02', null, 'https://example.org/assemblee/15/groupes'),
  (5,  3, '2018-11-20', null, 'https://example.org/mtg/membres');

-- Activité : ce que l'assemblée publie. La 13 n'a rien de publié (nulls).
insert into public.deputy_activity (mandate_id, periode, seances_presentes, seances_total, questions_ecrites, questions_orales, propositions, commissions, source_url) values
  (22, 'session 2024-2025', 31, 38, 4, 2, 1, 12, 'https://example.org/assemblee/15/activite'),
  (23, 'session 2024-2025', 36, 38, 1, 5, 0, 9,  'https://example.org/assemblee/15/activite'),
  (24, 'session 2024-2025', null, null, null, null, null, null, 'https://example.org/assemblee/15/activite');

-- ---------------------------------------------------------------------------
-- Sondages : deux fermés (220 et 40 votes), un ouvert (55), un programmé.
-- Le 2026-09-07 est le lundi de la semaine en cours au moment du seed.
-- ---------------------------------------------------------------------------

insert into public.poll (id, country_code, semaine, question, contexte, sources, person_id, publie) values
  (1, 'SN', '2026-08-24',
   'Faut-il rendre obligatoire une assurance maladie pour tous les actifs ?',
   'Une couverture maladie universelle existe depuis 2013 et repose sur l''adhésion volontaire aux mutuelles de santé. Le taux de couverture déclaré par le ministère était de 53 % en 2024. (Contexte de test.)',
   '[{"titre":"Rapport annuel ANACMU (test)","url":"https://example.org/anacmu/2024","date":"2025-03-01"}]',
   5, true),
  (2, 'SN', '2026-08-31',
   'La durée du mandat des députés doit-elle passer de cinq à quatre ans ?',
   'Le mandat parlementaire dure cinq ans depuis la révision constitutionnelle de 2016. Une proposition de loi déposée en 2025 suggère de l''aligner sur un cycle plus court. (Contexte de test.)',
   '[{"titre":"Proposition de loi n° 12 (test)","url":"https://example.org/assemblee/pl-12","date":"2025-06-10"}]',
   null, true),
  (3, 'SN', '2026-09-07',
   'L''État doit-il subventionner le prix du carburant à la pompe ?',
   'Le prix du litre de super est administré. En 2025, la subvention a représenté 1,2 % du budget selon la loi de finances. (Contexte de test.)',
   '[{"titre":"Loi de finances 2025 (test)","url":"https://example.org/lf-2025","date":"2024-12-20"},{"titre":"Note de conjoncture (test)","url":"https://example.org/dpee/2025-q2","date":"2025-07-15"}]',
   null, true),
  (4, 'SN', '2026-09-14',
   'Le vote des Sénégalais de l''étranger doit-il être étendu au vote par correspondance ?',
   'La diaspora élit des députés depuis 2017 et vote dans les consulats. Le vote par correspondance n''est pas prévu par le code électoral. (Contexte de test.)',
   '[{"titre":"Code électoral, art. L.xx (test)","url":"https://example.org/code-electoral","date":"2021-01-01"}]',
   null, true);
select setval('public.poll_id_seq', 4);

insert into public.poll_option (poll_id, ordre, libelle, neutre) values
  (1, 1, 'Oui, pour tous les actifs', false),
  (1, 2, 'Oui, mais seulement pour les salariés du formel', false),
  (1, 3, 'Non, l''adhésion doit rester volontaire', false),
  (1, 4, 'Sans avis', true),
  (2, 1, 'Oui', false), (2, 2, 'Non', false), (2, 3, 'Sans avis', true),
  (3, 1, 'Oui, quel que soit le coût', false),
  (3, 2, 'Oui, mais ciblée sur les transports collectifs', false),
  (3, 3, 'Non', false),
  (3, 4, 'Sans avis', true),
  (4, 1, 'Oui', false), (4, 2, 'Non', false), (4, 3, 'Sans avis', true);

-- Votes. Le seed s'exécute sans auth.uid() : le trigger accepte alors un
-- horodatage explicite, à condition qu'il tombe dans le créneau du sondage.
do $$
declare p record; u record; opts bigint[]; k int; nb int;
begin
  for p in select * from public.poll where id in (1, 2, 3) loop
    nb := case p.id when 1 then 220 when 2 then 40 else 55 end;
    select array_agg(id order by ordre) into opts from public.poll_option where poll_id = p.id;
    for u in select id, i from seed_user order by i limit nb loop
      -- répartition biaisée : première option favorisée, neutre minoritaire
      k := case when random() < 0.42 then 1
                when random() < 0.60 then 2
                when random() < 0.80 then array_length(opts, 1) - 1
                else array_length(opts, 1) end;
      k := least(k, array_length(opts, 1));
      insert into public.vote (poll_id, user_id, option_id, cree)
      values (p.id, u.id, opts[k],
              p.ouverture + (random() * extract(epoch from least(p.fermeture, now()) - p.ouverture) * 0.95) * interval '1 second');
    end loop;
  end loop;
end $$;

-- Un tour de cron : calcule les résultats, fige les sondages fermés.
do $$ begin perform public.poll_tick(); end $$;

-- ---------------------------------------------------------------------------
-- Testez-vous : quiz de test, 25 affirmations fictives, publié en local
-- seulement. Le vrai quiz arrive avec le contenu réel.
-- ---------------------------------------------------------------------------

insert into public.quiz (id, country_code, titre, version, publie) values
  (1, 'SN', 'Quiz de test', 1, false);
select setval('public.quiz_id_seq', 1);

insert into public.statement (id, quiz_id, ordre, texte, theme) values
  (1, 1, 1, 'L''école publique doit être gratuite jusqu''au baccalauréat.', 'education'),
  (2, 1, 2, 'Les mutuelles de santé doivent être obligatoires pour tous les actifs.', 'sante'),
  (3, 1, 3, 'L''État doit céder ses parts dans les entreprises publiques déficitaires.', 'economie'),
  (4, 1, 4, 'Le mandat présidentiel doit être limité à un seul renouvellement.', 'institutions'),
  (5, 1, 5, 'Les collectivités locales doivent lever leurs propres impôts.', 'decentralisation');
select setval('public.statement_id_seq', 5);

-- Trois niveaux de source, chacun représenté.
insert into public.party_position (statement_id, org_id, position, source_type, source_url, source_extrait, date_source) values
  (1, 1, 'accord',        'reponse_directe', null, 'Réponse écrite au questionnaire Palabre (test).', '2026-06-01'),
  (1, 2, 'desaccord',     'document_public', 'https://example.org/utb/programme#education', 'Nous proposons une contribution des familles au-delà du collège. (extrait test)', '2024-10-12'),
  (1, 3, 'sans_position', 'aucune',          null, null, null),
  (2, 1, 'accord',        'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (2, 2, 'neutre',        'document_public', 'https://example.org/utb/programme#sante', 'La question mérite une concertation nationale. (extrait test)', '2024-10-12'),
  (2, 3, 'accord',        'document_public', 'https://example.org/mtg/declaration-2025', 'Une couverture obligatoire est la seule voie. (extrait test)', '2025-02-03'),
  (3, 1, 'desaccord',     'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (3, 2, 'accord',        'document_public', 'https://example.org/utb/programme#economie', 'Cession progressive des participations non stratégiques. (extrait test)', '2024-10-12'),
  (3, 3, 'sans_position', 'aucune',          null, null, null),
  (4, 1, 'accord',        'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (4, 2, 'accord',        'document_public', 'https://example.org/utb/programme#institutions', 'Un seul renouvellement, sans exception. (extrait test)', '2024-10-12'),
  (4, 3, 'accord',        'document_public', 'https://example.org/mtg/declaration-2025', 'Nous défendons la limitation stricte. (extrait test)', '2025-02-03'),
  (5, 1, 'neutre',        'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (5, 2, 'sans_position', 'aucune',          null, null, null),
  (5, 3, 'sans_position', 'aucune',          null, null, null);

-- Vingt affirmations fictives de plus : le quiz atteint les 25 requises
-- pour être publié en local et exercer le balayage de bout en bout.
insert into public.statement (id, quiz_id, ordre, texte, theme) values
  (6, 1, 6, 'Le service militaire civique doit être rétabli pour les 18-25 ans.', 'institutions'),
  (7, 1, 7, 'Les députés doivent publier leur présence en séance chaque mois.', 'institutions'),
  (8, 1, 8, 'Le prix du carburant doit être plafonné par l''État.', 'economie'),
  (9, 1, 9, 'Les jeunes entreprises doivent être exonérées d''impôt trois ans.', 'economie'),
  (10, 1, 10, 'L''agriculture familiale doit être prioritaire dans les subventions.', 'agriculture'),
  (11, 1, 11, 'La pêche industrielle étrangère doit être interdite dans les eaux nationales.', 'agriculture'),
  (12, 1, 12, 'Les langues nationales doivent être enseignées dès le primaire.', 'education'),
  (13, 1, 13, 'Les universités publiques doivent sélectionner à l''entrée.', 'education'),
  (14, 1, 14, 'Les médicaments essentiels doivent être gratuits pour les enfants.', 'sante'),
  (15, 1, 15, 'Chaque département doit avoir un hôpital de référence d''ici cinq ans.', 'sante'),
  (16, 1, 16, 'Le transport public urbain doit être gratuit pour les étudiants.', 'infrastructure'),
  (17, 1, 17, 'Les autoroutes doivent rester à péage pour financer leur entretien.', 'infrastructure'),
  (18, 1, 18, 'Les communes doivent élire directement leur maire.', 'decentralisation'),
  (19, 1, 19, 'Les régions doivent gérer elles-mêmes leur budget d''éducation.', 'decentralisation'),
  (20, 1, 20, 'Les déchets plastiques à usage unique doivent être interdits.', 'environnement'),
  (21, 1, 21, 'L''énergie solaire doit couvrir la moitié des besoins d''ici 2035.', 'environnement'),
  (22, 1, 22, 'Le salaire minimum doit être revalorisé chaque année selon l''inflation.', 'social'),
  (23, 1, 23, 'Une allocation doit être versée aux familles sans revenu.', 'social'),
  (24, 1, 24, 'La justice doit publier toutes ses décisions en ligne.', 'justice'),
  (25, 1, 25, 'La détention provisoire doit être limitée à six mois.', 'justice');
select setval('public.statement_id_seq', 25);

insert into public.party_position (statement_id, org_id, position, source_type, source_url, source_extrait, date_source) values
  (6, 1, 'sans_position', 'aucune', null, null, null),
  (6, 2, 'neutre', 'document_public', 'https://example.org/org2/programme#institutions', 'Extrait de programme (test).', '2025-02-03'),
  (6, 3, 'sans_position', 'aucune', null, null, null),
  (7, 1, 'neutre', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (7, 2, 'desaccord', 'document_public', 'https://example.org/org2/programme#institutions', 'Extrait de programme (test).', '2025-02-03'),
  (7, 3, 'accord', 'document_public', 'https://example.org/org3/programme#institutions', 'Extrait de programme (test).', '2025-02-03'),
  (8, 1, 'desaccord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (8, 2, 'accord', 'document_public', 'https://example.org/org2/programme#economie', 'Extrait de programme (test).', '2025-02-03'),
  (8, 3, 'sans_position', 'aucune', null, null, null),
  (9, 1, 'accord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (9, 2, 'sans_position', 'aucune', null, null, null),
  (9, 3, 'neutre', 'document_public', 'https://example.org/org3/programme#economie', 'Extrait de programme (test).', '2025-02-03'),
  (10, 1, 'sans_position', 'aucune', null, null, null),
  (10, 2, 'neutre', 'document_public', 'https://example.org/org2/programme#agriculture', 'Extrait de programme (test).', '2025-02-03'),
  (10, 3, 'sans_position', 'aucune', null, null, null),
  (11, 1, 'neutre', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (11, 2, 'desaccord', 'document_public', 'https://example.org/org2/programme#agriculture', 'Extrait de programme (test).', '2025-02-03'),
  (11, 3, 'accord', 'document_public', 'https://example.org/org3/programme#agriculture', 'Extrait de programme (test).', '2025-02-03'),
  (12, 1, 'desaccord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (12, 2, 'accord', 'document_public', 'https://example.org/org2/programme#education', 'Extrait de programme (test).', '2025-02-03'),
  (12, 3, 'sans_position', 'aucune', null, null, null),
  (13, 1, 'accord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (13, 2, 'sans_position', 'aucune', null, null, null),
  (13, 3, 'neutre', 'document_public', 'https://example.org/org3/programme#education', 'Extrait de programme (test).', '2025-02-03'),
  (14, 1, 'sans_position', 'aucune', null, null, null),
  (14, 2, 'neutre', 'document_public', 'https://example.org/org2/programme#sante', 'Extrait de programme (test).', '2025-02-03'),
  (14, 3, 'sans_position', 'aucune', null, null, null),
  (15, 1, 'neutre', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (15, 2, 'desaccord', 'document_public', 'https://example.org/org2/programme#sante', 'Extrait de programme (test).', '2025-02-03'),
  (15, 3, 'accord', 'document_public', 'https://example.org/org3/programme#sante', 'Extrait de programme (test).', '2025-02-03'),
  (16, 1, 'desaccord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (16, 2, 'accord', 'document_public', 'https://example.org/org2/programme#infrastructure', 'Extrait de programme (test).', '2025-02-03'),
  (16, 3, 'sans_position', 'aucune', null, null, null),
  (17, 1, 'accord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (17, 2, 'sans_position', 'aucune', null, null, null),
  (17, 3, 'neutre', 'document_public', 'https://example.org/org3/programme#infrastructure', 'Extrait de programme (test).', '2025-02-03'),
  (18, 1, 'sans_position', 'aucune', null, null, null),
  (18, 2, 'neutre', 'document_public', 'https://example.org/org2/programme#decentralisation', 'Extrait de programme (test).', '2025-02-03'),
  (18, 3, 'sans_position', 'aucune', null, null, null),
  (19, 1, 'neutre', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (19, 2, 'desaccord', 'document_public', 'https://example.org/org2/programme#decentralisation', 'Extrait de programme (test).', '2025-02-03'),
  (19, 3, 'accord', 'document_public', 'https://example.org/org3/programme#decentralisation', 'Extrait de programme (test).', '2025-02-03'),
  (20, 1, 'desaccord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (20, 2, 'accord', 'document_public', 'https://example.org/org2/programme#environnement', 'Extrait de programme (test).', '2025-02-03'),
  (20, 3, 'sans_position', 'aucune', null, null, null),
  (21, 1, 'accord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (21, 2, 'sans_position', 'aucune', null, null, null),
  (21, 3, 'neutre', 'document_public', 'https://example.org/org3/programme#environnement', 'Extrait de programme (test).', '2025-02-03'),
  (22, 1, 'sans_position', 'aucune', null, null, null),
  (22, 2, 'neutre', 'document_public', 'https://example.org/org2/programme#social', 'Extrait de programme (test).', '2025-02-03'),
  (22, 3, 'sans_position', 'aucune', null, null, null),
  (23, 1, 'neutre', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (23, 2, 'desaccord', 'document_public', 'https://example.org/org2/programme#social', 'Extrait de programme (test).', '2025-02-03'),
  (23, 3, 'accord', 'document_public', 'https://example.org/org3/programme#social', 'Extrait de programme (test).', '2025-02-03'),
  (24, 1, 'desaccord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (24, 2, 'accord', 'document_public', 'https://example.org/org2/programme#justice', 'Extrait de programme (test).', '2025-02-03'),
  (24, 3, 'sans_position', 'aucune', null, null, null),
  (25, 1, 'accord', 'reponse_directe', null, 'Réponse écrite (test).', '2026-06-01'),
  (25, 2, 'sans_position', 'aucune', null, null, null),
  (25, 3, 'neutre', 'document_public', 'https://example.org/org3/programme#justice', 'Extrait de programme (test).', '2025-02-03');

update public.quiz set publie = true where id = 1;

insert into public.position_contestation (position_id, auteur, argument, piece_url) values
  ((select id from public.party_position where statement_id = 1 and org_id = 2),
   'Secrétariat UTB (test)', 'Notre programme 2025 a modifié cette position, voir page 14 de la version révisée.', 'https://example.org/utb/programme-2025.pdf');

drop table seed_user;
commit;
