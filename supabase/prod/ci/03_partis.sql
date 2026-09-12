-- Palabre — production Côte d'Ivoire : partis, coalitions et groupes
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values
  (20001, 'CI', 'parti', 'Rassemblement des houphouëtistes pour la démocratie et la paix', 'RHDP', '#F77F00', '2018-07-16', 'https://fr.wikipedia.org/wiki/Rassemblement_des_houphou%C3%ABtistes_pour_la_d%C3%A9mocratie_et_la_paix'),
  (20002, 'CI', 'parti', 'Parti démocratique de Côte d''Ivoire – Rassemblement démocratique africain', 'PDCI-RDA', '#0FAF32', '1946-04-09', 'https://afriksoir.net/pdci-tidjane-thiam-renforce-lappareil-executif-avec-de-nouvelles-nominations/'),
  (20003, 'CI', 'parti', 'Parti des peuples africains – Côte d''Ivoire', 'PPA-CI', null, '2021-10-17', 'https://www.rfi.fr/fr/afrique/20260515-c%C3%B4te-d-ivoire-r%C3%A9uni-en-congr%C3%A8s-le-ppa-ci-reconduit-laurent-gbagbo-%C3%A0-sa-t%C3%AAte'),
  (20004, 'CI', 'parti', 'Front populaire ivoirien', 'FPI', '#0066CC', '1982-01-01', 'https://www.fpi-ci.com/'),
  (20005, 'CI', 'parti', 'Mouvement des générations capables', 'MGC', null, '2022-08-20', 'https://www.yeclo.com/simone-gbagbo-reorganise-le-mgc-pour-les-defis-de-lannee-2026'),
  (20006, 'CI', 'coalition', 'Congrès démocratique', 'CODE', null, '2025-08-19', 'https://news.abidjan.net/articles/743971/presidentielle-2025-des-partis-politiques-sunissent-derriere-jean-louis-billon-et-appellent-a-un-renouveau-democratique'),
  (20007, 'CI', 'coalition', 'Groupement des partenaires politiques pour la paix', 'GP-PAIX', null, null, 'https://ledemocrateplus.com/presidentielle-doctobre-2025-henriette-lagou-officiellement-designee-candidate-dune-coalition-de-4-partis-politiques/'),
  (20008, 'CI', 'parti', 'Union pour la République', 'UNPR', null, null, 'https://www.aip.ci/302272/legislatives-2025-le-rhdp-remporte-155-circonscriptions-pour-197-sieges-le-pdci-rda-25-circonscriptions-32-sieges-les-independants-22-circonscriptions-23-sieges-un-siege-et-une-circonscription/'),
  (20009, 'CI', 'parti', 'Le Buffle – La victoire pour le développement', 'Le Buffle', null, null, 'https://www.aip.ci/302272/legislatives-2025-le-rhdp-remporte-155-circonscriptions-pour-197-sieges-le-pdci-rda-25-circonscriptions-32-sieges-les-independants-22-circonscriptions-23-sieges-un-siege-et-une-circonscription/'),
  (20010, 'CI', 'coalition', 'Candidature Alassane Ouattara (présidentielle 2025)', 'Ouattara-2025', null, '2025-06-21', 'https://www.lefigaro.fr/international/cote-d-ivoire-alassane-ouattara-designe-candidat-a-la-presidentielle-par-son-parti-20250621'),
  (20011, 'CI', 'coalition', 'Candidature Jean-Louis Billon (présidentielle 2025)', 'Billon-2025', null, '2025-08-19', 'https://news.abidjan.net/articles/743971/presidentielle-2025-des-partis-politiques-sunissent-derriere-jean-louis-billon-et-appellent-a-un-renouveau-democratique'),
  (20012, 'CI', 'coalition', 'Candidature Simone Ehivet Gbagbo (présidentielle 2025)', 'Ehivet-Gbagbo-2025', null, '2024-11-30', 'https://www.rfi.fr/fr/afrique/20241130-pr%C3%A9sidentielle-en-c%C3%B4te-d-ivoire-l-ex-premi%C3%A8re-dame-simone-ehivet-d%C3%A9sign%C3%A9e-candidate-par-son-parti'),
  (20013, 'CI', 'coalition', 'Candidature Ahoua Don Mello (présidentielle 2025)', 'Don-Mello-2025', null, '2025-07-31', 'https://fr.wikipedia.org/wiki/Ahoua_Don_Mello'),
  (20014, 'CI', 'coalition', 'Candidature Henriette Lagou Adjoua (présidentielle 2025)', 'Lagou-2025', null, '2025-03-22', 'https://ledemocrateplus.com/presidentielle-doctobre-2025-henriette-lagou-officiellement-designee-candidate-dune-coalition-de-4-partis-politiques/');

insert into public.org_relation (from_id, to_id, type, date, source_url) values
  (20004, 20003, 'scission', '2021-10-17', 'https://fr.wikipedia.org/wiki/Parti_des_peuples_africains_%E2%80%93_C%C3%B4te_d%27Ivoire'),
  (20001, 20010, 'coalition_membre', '2025-06-21', 'https://www.lefigaro.fr/international/cote-d-ivoire-alassane-ouattara-designe-candidat-a-la-presidentielle-par-son-parti-20250621'),
  (20006, 20011, 'coalition_membre', '2025-08-19', 'https://news.abidjan.net/articles/743971/presidentielle-2025-des-partis-politiques-sunissent-derriere-jean-louis-billon-et-appellent-a-un-renouveau-democratique'),
  (20005, 20012, 'coalition_membre', '2024-11-30', 'https://www.rfi.fr/fr/afrique/20241130-pr%C3%A9sidentielle-en-c%C3%B4te-d-ivoire-l-ex-premi%C3%A8re-dame-simone-ehivet-d%C3%A9sign%C3%A9e-candidate-par-son-parti'),
  (20007, 20014, 'coalition_membre', '2025-03-22', 'https://ledemocrateplus.com/presidentielle-doctobre-2025-henriette-lagou-officiellement-designee-candidate-dune-coalition-de-4-partis-politiques/');

select setval('public.person_id_seq', (select coalesce(max(id), 1) from public.person));
select setval('public.organization_id_seq', (select coalesce(max(id), 1) from public.organization));
select setval('public.portfolio_id_seq', (select coalesce(max(id), 1) from public.portfolio));
select setval('public.role_id_seq', (select coalesce(max(id), 1) from public.role));
select setval('public.government_id_seq', (select coalesce(max(id), 1) from public.government));
select setval('public.mandate_id_seq', (select coalesce(max(id), 1) from public.mandate));
select setval('public.legislature_id_seq', (select coalesce(max(id), 1) from public.legislature));
select setval('public.constituency_id_seq', (select coalesce(max(id), 1) from public.constituency));
select setval('public.quiz_id_seq', (select coalesce(max(id), 1) from public.quiz));
select setval('public.statement_id_seq', (select coalesce(max(id), 1) from public.statement));

commit;
