-- Palabre — production Togo : partis, coalitions et groupes
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values
  (30001, 'TG', 'parti', 'Union pour la République', 'UNIR', '#009ADA', '2012-04-14', 'https://unir.tg/le-parti/qui-sommes-nous/'),
  (30002, 'TG', 'parti', 'Alliance nationale pour le changement', 'ANC', '#FF8201', '2010-10-10', 'https://anctogo.org/'),
  (30003, 'TG', 'coalition', 'Dynamique pour la majorité du peuple', 'DMP', null, '2023-04-10', 'https://www.koaci.com/article/2023/04/11/togo/politique/togo-une-nouvelle-dynamique-la-dmp-hissee-dans-larene-pre-electorale-motifs-et-missions_168584.html'),
  (30004, 'TG', 'parti', 'Alliance des démocrates pour le développement intégral', 'ADDI', '#11C925', '1991-10-03', 'https://icilome.com/2025/01/togo-addi-les-priorites-du-parti-pour-2025/'),
  (30005, 'TG', 'parti', 'Union des forces de changement', 'UFC', '#FFCC00', '1992-02-01', 'https://www.koaci.com/article/2026/08/10/togo/politique/togo-lufc-clarifie-sa-vision-dans-le-nouveau-contexte-sociopolitique-avec-gilchrist-olympio_199398.html'),
  (30006, 'TG', 'parti', 'Comité d''action pour le renouveau', 'CAR', null, '1991-04-01', 'https://24heureinfo.com/politique/togo-yao-date-elu-nouveau-president-du-car/'),
  (30007, 'TG', 'parti', 'Nouvel engagement togolais', 'NET', '#7BB61E', '2012-04-28', 'https://www.republicoftogo.com/toutes-les-rubriques/politique/crise-de-leadership-au-net'),
  (30008, 'TG', 'parti', 'Forces démocratiques pour la République', 'FDR', null, '2016-11-26', 'https://togoscoop.tg/23178-2/'),
  (30009, 'TG', 'parti', 'Parti des démocrates panafricains', 'PDP', null, null, 'https://fr.wikipedia.org/wiki/Innocent_Kagbara'),
  (30010, 'TG', 'parti', 'Convention démocratique des peuples africains', 'CDPA', null, '1980-01-01', 'https://fr.wikipedia.org/wiki/Convention_d%C3%A9mocratique_des_peuples_africains'),
  (30011, 'TG', 'parti', 'Bloc alternatif togolais pour une innovation républicaine', 'BATIR', null, null, 'https://jo.gouv.tg/sites/default/files/JO/JOS_24_02_2025%20-%2070E%20ANNEE%20N%C2%B0%2018%20BIS.pdf'),
  (30012, 'TG', 'parti', 'Cercle des leaders émergents', 'CLE', null, null, 'https://jo.gouv.tg/sites/default/files/JO/JOS_24_02_2025%20-%2070E%20ANNEE%20N%C2%B0%2018%20BIS.pdf'),
  (30013, 'TG', 'parti', 'Le Togo autrement', 'LTA', null, null, 'https://jo.gouv.tg/sites/default/files/JO/JOS_24_02_2025%20-%2070E%20ANNEE%20N%C2%B0%2018%20BIS.pdf'),
  (30014, 'TG', 'coalition', 'Cadre national de concertation pour le changement au Togo', 'CNCC', null, '2026-04-13', 'https://icilome.com/2026/04/togo-cncc-voici-ce-que-contient-la-nouvelle-feuille-de-route-de-lopposition-togolaise/');

insert into public.org_relation (from_id, to_id, type, date, source_url) values
  (30005, 30002, 'scission', '2010-10-10', 'https://fr.wikipedia.org/wiki/Alliance_nationale_pour_le_changement'),
  (30006, 30008, 'scission', '2016-11-26', 'https://togobreakingnews.info/me-apevon-lance-les-fdr-pour-recreer-l-espoir-chez-les-togolais/'),
  (30010, 30003, 'coalition_membre', null, 'https://www.republicoftogo.com/toutes-les-rubriques/politique/optimisme-a-la-dmp'),
  (30002, 30014, 'coalition_membre', '2026-04-13', 'https://icilome.com/2026/04/togo-cncc-voici-ce-que-contient-la-nouvelle-feuille-de-route-de-lopposition-togolaise/'),
  (30008, 30014, 'coalition_membre', '2026-04-13', 'https://icilome.com/2026/04/togo-cncc-voici-ce-que-contient-la-nouvelle-feuille-de-route-de-lopposition-togolaise/'),
  (30004, 30014, 'coalition_membre', '2026-04-13', 'https://icilome.com/2026/04/togo-cncc-voici-ce-que-contient-la-nouvelle-feuille-de-route-de-lopposition-togolaise/');

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
