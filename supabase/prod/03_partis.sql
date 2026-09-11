-- Palabre — production Sénégal : partis, coalitions et groupes
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values
  (1, 'SN', 'parti', 'Patriotes africains du Sénégal pour le travail, l''éthique et la fraternité', 'PASTEF', '#CC2B3A', '2014-01-01', 'https://www.france24.com/fr/afrique/20260606-s%C3%A9n%C3%A9gal-ousmane-sonko-largement-r%C3%A9%C3%A9lu-%C3%A0-la-t%C3%AAte-du-pastef-parti-majoritaire'),
  (2, 'SN', 'parti', 'Alliance pour la République (APR-Yaakaar)', 'APR', '#5C482F', '2008-12-01', 'https://fr.wikipedia.org/wiki/Alliance_pour_la_R%C3%A9publique'),
  (3, 'SN', 'parti', 'Parti démocratique sénégalais', 'PDS', '#427BBE', '1974-07-31', 'https://fr.wikipedia.org/wiki/Parti_d%C3%A9mocratique_s%C3%A9n%C3%A9galais'),
  (4, 'SN', 'parti', 'Taxawu Sénégal', 'TS', null, '2026-05-10', 'https://fr.allafrica.com/stories/202605110836.html'),
  (5, 'SN', 'parti', 'Rewmi', 'Rewmi', '#E68F3F', '2006-01-01', 'https://en.wikipedia.org/wiki/Idrissa_Seck'),
  (6, 'SN', 'parti', 'Parti de l''Unité et du Rassemblement', 'PUR', '#349A51', '1998-02-03', 'https://fr.wikipedia.org/wiki/Parti_de_l''unit%C3%A9_et_du_rassemblement'),
  (7, 'SN', 'parti', 'Parti socialiste', 'PS', null, '1976-01-01', 'https://fr.allafrica.com/stories/202606150409.html'),
  (8, 'SN', 'parti', 'Alliance des forces de progrès', 'AFP', null, '1999-08-13', 'https://aps.sn/mbaye-dione-succede-a-moustapha-niasse-a-la-tete-de-lafp/'),
  (9, 'SN', 'parti', 'Kiiraay – Les Patriotes républicains', 'Kiiraay', '#1E9BD9', '2026-07-25', 'https://www.france24.com/fr/afrique/20260726-au-s%C3%A9n%C3%A9gal-le-pr%C3%A9sident-faye-lance-son-nouveau-parti-et-confirme-la-rupture-avec-ousmane-sonko'),
  (10, 'SN', 'coalition', 'Takku Wallu Sénégal', 'TWS', '#724F39', '2024-09-25', 'https://fr.wikipedia.org/wiki/Takku_Wallu_S%C3%A9n%C3%A9gal'),
  (11, 'SN', 'coalition', 'Jàmm ak Njariñ', 'JAN', '#005F35', '2024-09-24', 'https://fr.wikipedia.org/wiki/J%C3%A0mm_ak_Njari%C3%B1'),
  (12, 'SN', 'coalition', 'Sàmm Sa Kàddu', 'SSK', '#FFC704', '2024-09-23', 'https://fr.wikipedia.org/wiki/S%C3%A0mm_Sa_K%C3%A0ddu'),
  (13, 'SN', 'coalition', 'Coalition Diomaye Président', 'DP', null, '2024-01-01', 'https://web.archive.org/web/20250407124403id_/https://diomayepresident.org/wp-content/uploads/2024/03/Livre-Programme-Bassirou-Diomaye-Faye.pdf');

insert into public.org_relation (from_id, to_id, type, date, source_url) values
  (3, 2, 'scission', '2008-12-01', 'https://fr.wikipedia.org/wiki/Alliance_pour_la_R%C3%A9publique'),
  (3, 5, 'scission', '2006-09-24', 'https://en.wikipedia.org/wiki/Idrissa_Seck'),
  (7, 8, 'scission', '1999-08-13', 'https://fr.wikipedia.org/wiki/Alliance_des_forces_de_progr%C3%A8s'),
  (7, 4, 'scission', '2017-01-01', 'https://fr.wikipedia.org/wiki/Parti_socialiste_(S%C3%A9n%C3%A9gal)'),
  (1, 9, 'scission', '2026-07-25', 'https://www.france24.com/fr/afrique/20260726-au-s%C3%A9n%C3%A9gal-le-pr%C3%A9sident-faye-lance-son-nouveau-parti-et-confirme-la-rupture-avec-ousmane-sonko'),
  (2, 10, 'coalition_membre', '2024-09-25', 'https://fr.wikipedia.org/wiki/Takku_Wallu_S%C3%A9n%C3%A9gal'),
  (3, 10, 'coalition_membre', '2024-09-25', 'https://fr.wikipedia.org/wiki/Takku_Wallu_S%C3%A9n%C3%A9gal'),
  (5, 10, 'coalition_membre', '2024-09-25', 'https://fr.wikipedia.org/wiki/Takku_Wallu_S%C3%A9n%C3%A9gal'),
  (7, 11, 'coalition_membre', '2024-09-24', 'https://fr.wikipedia.org/wiki/J%C3%A0mm_ak_Njari%C3%B1'),
  (8, 11, 'coalition_membre', '2024-09-24', 'https://fr.wikipedia.org/wiki/J%C3%A0mm_ak_Njari%C3%B1'),
  (4, 12, 'coalition_membre', '2024-09-23', 'https://fr.wikipedia.org/wiki/S%C3%A0mm_Sa_K%C3%A0ddu'),
  (6, 12, 'coalition_membre', '2024-09-23', 'https://fr.wikipedia.org/wiki/S%C3%A0mm_Sa_K%C3%A0ddu'),
  (1, 13, 'coalition_membre', '2024-01-01', 'https://fr.wikipedia.org/wiki/%C3%89lection_pr%C3%A9sidentielle_s%C3%A9n%C3%A9galaise_de_2024');

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
