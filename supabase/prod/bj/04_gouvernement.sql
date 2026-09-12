-- Palabre — production Bénin : gouvernement en exercice
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.person (id, country_code, nom) values
  (10001, 'BJ', 'Romuald WADAGNI'),
  (10002, 'BJ', 'Yvon DETCHENOU'),
  (10003, 'BJ', 'Aristide MEDENOU'),
  (10004, 'BJ', 'Corinne AMORI BRUNET'),
  (10005, 'BJ', 'Djibril MAMA CISSE MOUSSA'),
  (10006, 'BJ', 'Gildas Habib Bignon AGONKAN'),
  (10007, 'BJ', 'Olushegun ADJADI BAKARI'),
  (10008, 'BJ', 'Adin Yeton BLOUKOUNON GOUBALAN'),
  (10009, 'BJ', 'Benjamin Ignace Bodounrin HOUNKPATIN'),
  (10010, 'BJ', 'Sèdami Romarique MEDEGAN FAGLA'),
  (10011, 'BJ', 'Adéyèmi Clément KOUCHADE'),
  (10012, 'BJ', 'Armand Kuyema NATTA'),
  (10013, 'BJ', 'Véronique TOGNIFODE'),
  (10014, 'BJ', 'François Janvier YAHOUÉDÉOU'),
  (10015, 'BJ', 'Yassine LATOUNDJI'),
  (10016, 'BJ', 'Alimatou Shadiya ASSOUMAN'),
  (10017, 'BJ', 'Mahuna AKPLOGAN'),
  (10018, 'BJ', 'Edouard DAHOME'),
  (10019, 'BJ', 'Georges ALE'),
  (10020, 'BJ', 'Awaou BACO'),
  (10021, 'BJ', 'Aurelie Adam SOULE épouse ZOUMAROU'),
  (10022, 'BJ', 'Benoît K. M. DATO'),
  (10023, 'BJ', 'Nicolas YENOUSSI'),
  (10024, 'BJ', 'Rodrigue CHAOU'),
  (10025, 'BJ', 'Hugues Oscar LOKOSSOU');

insert into public.organization (id, country_code, type, nom, source_url) values
  (10009, 'BJ', 'gouvernement', 'Gouvernement Wadagni I', 'https://sgg.gouv.bj/doc/decret-2026-314/');

insert into public.government (id, country_code, nom, chef_gouv_id, debut, portefeuilles_total, decret_ref, source_url) values
  (10001, 'BJ', 'Gouvernement Wadagni I', 10001, '2026-05-24', 24, 'Décret N° 2026-314 du 24 mai 2026 portant composition du Gouvernement', 'https://sgg.gouv.bj/doc/decret-2026-314/');

insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values
  (10001, 'BJ', 'chef_gouvernement', 'Président de la République', 'president_de_la_republique', 10009),
  (10002, 'BJ', 'ministre', 'Ministre', 'ministre', 10009),
  (10003, 'BJ', 'depute', 'Député', 'depute', null);

insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values
  (10001, 'BJ', 'Garde des Sceaux, Ministre de la Justice et de la Législation', 'garde_des_sceaux', 'regalien', 1),
  (10002, 'BJ', 'Ministre de l''Economie et des Finances, chargé de la Coopération', 'economie', 'economie', 2),
  (10003, 'BJ', 'Ministre des Affaires étrangères, chargé de l''intégration des afrodescendants', 'affaires_etrangeres', 'regalien', 3),
  (10004, 'BJ', 'Ministre délégué auprès du Président de la République, chargé de l''Intérieur et de la Sécurité publique', 'delegue_aupres_du_president_de_la_republique', 'regalien', 4),
  (10005, 'BJ', 'Ministre délégué auprès du Président de la République, chargé de la Défense nationale', 'delegue_aupres_du_president_de_la_republique', 'regalien', 5),
  (10006, 'BJ', 'Ministre du Tourisme et du Commerce extérieur, chargé de l''Intégration africaine, de l''Industrie et de la Promotion de l''investissement privé', 'tourisme', 'economie', 6),
  (10007, 'BJ', 'Ministre de l''Agriculture, de l''Élevage et de la Pêche', 'agriculture', 'economie', 7),
  (10008, 'BJ', 'Ministre de la Santé', 'sante', 'social', 8),
  (10009, 'BJ', 'Ministre de l''Enseignement supérieur et de la Recherche scientifique, chargé de la Formation technique', 'enseignement_superieur', 'social', 9),
  (10010, 'BJ', 'Ministre de l''Enseignement secondaire', 'enseignement_secondaire', 'social', 10),
  (10011, 'BJ', 'Ministre des Enseignements maternel et primaire', 'enseignements_maternel', 'social', 11),
  (10012, 'BJ', 'Ministre de la Famille et de l''Action sociale', 'famille', 'social', 12),
  (10013, 'BJ', 'Ministre de la Décentralisation et de la Gouvernance locale', 'decentralisation', 'regalien', 13),
  (10014, 'BJ', 'Ministre de la Culture, des Arts et du Patrimoine', 'culture', 'social', 14),
  (10015, 'BJ', 'Ministre du Commerce intérieur, chargé de la formalisation de l''économie', 'commerce_interieur', 'economie', 15),
  (10016, 'BJ', 'Ministre de la Transformation digitale et de l''Innovation, chargé de la stratégie nationale d''intelligence artificielle', 'transformation_digitale', 'infrastructure', 16),
  (10017, 'BJ', 'Ministre de l''Énergie, de l''Eau et des Mines', 'energie', 'economie', 17),
  (10018, 'BJ', 'Ministre du Cadre de Vie et des Transports, chargé du Développement durable', 'cadre_de_vie', 'infrastructure', 18),
  (10019, 'BJ', 'Ministre des Petites et Moyennes Entreprises et de la Promotion de l''Emploi, chargé de la Formation professionnelle', 'petites', 'economie', 19),
  (10020, 'BJ', 'Ministre de la Communication, chargé des Médias', 'communication', 'social', 20),
  (10021, 'BJ', 'Ministre des Sports et de l''Engagement civique', 'sports', 'social', 21),
  (10022, 'BJ', 'Ministre délégué auprès du Ministre de l''Économie et des Finances, chargé des finances et de la microfinance', 'delegue_aupres_du_ministre_de_l_economie', 'economie', 22),
  (10023, 'BJ', 'Ministre délégué auprès du Ministre de l''Économie et des Finances, chargé du budget et de la fonction publique', 'delegue_aupres_du_ministre_de_l_economie', 'economie', 23),
  (10024, 'BJ', 'Ministre délégué auprès du Ministre de l''Économie et des Finances, chargé de la mobilisation des ressources extérieures et de la gestion de la dette', 'delegue_aupres_du_ministre_de_l_economie', 'economie', 24);

insert into public.mandate (person_id, role_id, portfolio_id, government_id, debut, acte_ref, source_url, confiance) values
  (10001, 10001, null, 10001, '2026-05-24', 'Décision EP 26-002 du 23 avril 2026 de la Cour constitutionnelle (proclamation des résultats définitifs de l''élection présidentielle du 12 avril 2026) ; prestation de serment le 24 mai 2026 au Palais des Congrès de Cotonou', 'https://beninwebtv.com/benin-romuald-wadagni-prete-serment-et-devient-officiellement-president-de-la-republique/', 'communique'),
  (10002, 10002, 10001, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10003, 10002, 10002, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10004, 10002, 10003, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10005, 10002, 10004, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10006, 10002, 10005, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10007, 10002, 10006, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10008, 10002, 10007, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10009, 10002, 10008, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10010, 10002, 10009, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10011, 10002, 10010, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10012, 10002, 10011, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10013, 10002, 10012, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10014, 10002, 10013, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10015, 10002, 10014, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10016, 10002, 10015, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10017, 10002, 10016, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10018, 10002, 10017, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10019, 10002, 10018, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10020, 10002, 10019, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10021, 10002, 10020, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10022, 10002, 10021, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10023, 10002, 10022, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10024, 10002, 10023, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique'),
  (10025, 10002, 10024, 10001, '2026-05-24', null, 'https://sgg.gouv.bj/doc/decret-2026-314/', 'communique');

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
