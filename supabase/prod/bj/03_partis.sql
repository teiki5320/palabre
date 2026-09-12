-- Palabre — production Bénin : partis, coalitions et groupes
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values
  (10001, 'BJ', 'parti', 'Union progressiste le Renouveau', 'UPR', '#FAC82D', '2018-12-01', 'https://lanouvelletribune.info/2026/08/up-le-renouveau-joseph-djogbenou-designe-les-presidents-de-sections/'),
  (10002, 'BJ', 'parti', 'Bloc républicain', 'BR', '#93C842', '2018-12-08', 'https://www.blocrepublicain.co/notre-histoire/'),
  (10003, 'BJ', 'parti', 'Les Démocrates', 'LD', '#C01108', '2019-01-01', 'https://fr.wikipedia.org/wiki/Les_D%C3%A9mocrates_(B%C3%A9nin)'),
  (10004, 'BJ', 'parti', 'Forces cauris pour un Bénin émergent', 'FCBE', '#56963F', '2003-01-01', 'https://lanouvelletribune.info/2026/06/benin-la-fcbe-defend-son-virage-politique-et-revient-sur-la-demission-de-hounkpe/'),
  (10005, 'BJ', 'parti', 'Mouvement des élites engagées pour l''émancipation du Bénin', 'MOELE-Bénin', null, '2018-01-01', 'https://wadagnitalata.bj/soutiens'),
  (10006, 'BJ', 'parti', 'Mouvement populaire de libération', 'MPL', null, '2019-12-21', 'https://lanouvelletribune.info/2025/09/opposition-beninoise-le-mpl-se-retire-du-cadre-de-concertation/'),
  (10007, 'BJ', 'coalition', 'Duo Wadagni–Talata (présidentielle 2026)', 'Wadagni-Talata', null, null, 'https://fr.allafrica.com/stories/202509010173.html'),
  (10008, 'BJ', 'coalition', 'Duo Hounkpè–Hounwanou (présidentielle 2026)', 'Hounkpè-Hounwanou', null, null, 'https://lanation.bj/actualites/presidentielle-de-2026-le-duo-fcbe-paul-hounkpe-judicael-hounwanou-investi');

insert into public.org_relation (from_id, to_id, type, date, source_url) values
  (10004, 10003, 'scission', '2019-07-01', 'https://fr.wikipedia.org/wiki/Les_D%C3%A9mocrates_(B%C3%A9nin)'),
  (10001, 10007, 'coalition_membre', null, 'https://fr.allafrica.com/stories/202509010173.html'),
  (10002, 10007, 'coalition_membre', null, 'https://fr.allafrica.com/stories/202509010173.html'),
  (10004, 10008, 'coalition_membre', '2025-10-01', 'https://lanation.bj/actualites/presidentielle-de-2026-le-duo-fcbe-paul-hounkpe-judicael-hounwanou-investi');

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
