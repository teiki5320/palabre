-- Palabre — production Sénégal : gouvernement en exercice
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.person (id, country_code, nom) values
  (1, 'SN', 'Ahmadou Al Aminou Mohamed LO'),
  (2, 'SN', 'Yankoba DIEME'),
  (3, 'SN', 'Cheikh DIBA'),
  (4, 'SN', 'Mouhamadou Makhtar CISSE'),
  (5, 'SN', 'Cheikh NIANG'),
  (6, 'SN', 'Moussa SARR'),
  (7, 'SN', 'Marie Angélique Mame Selbé DIOUF'),
  (8, 'SN', 'Boubacar CAMARA'),
  (9, 'SN', 'El Hadji Abdourahmane DIOUF'),
  (10, 'SN', 'Serigne Guèye DIOP'),
  (11, 'SN', 'Cheikh Tidiane DIEYE'),
  (12, 'SN', 'Moustapha Mamba GUIRASSY'),
  (13, 'SN', 'Ibrahima SY'),
  (14, 'SN', 'Moussa Bala FOFANA'),
  (15, 'SN', 'Déthié FALL'),
  (16, 'SN', 'Bacary SARR'),
  (17, 'SN', 'Alioune DIONE'),
  (18, 'SN', 'Cheikhou Oumar BA'),
  (19, 'SN', 'Samba DIOUF'),
  (20, 'SN', 'Mamadou Lamine DIANTE'),
  (21, 'SN', 'Djirèye Clotilde COLY'),
  (22, 'SN', 'Alpha THIAM'),
  (23, 'SN', 'Idrissa SAMB'),
  (24, 'SN', 'Cheikhou Oumar SECK'),
  (25, 'SN', 'Aliou Gori DIOUF'),
  (26, 'SN', 'Abdoul Ahad NDIAYE'),
  (27, 'SN', 'Amy MARA'),
  (28, 'SN', 'Bassirou SARR'),
  (29, 'SN', 'Allé Nar DIOP'),
  (30, 'SN', 'Ousmane DIAGNE'),
  (31, 'SN', 'Mame Coumba DIOP'),
  (32, 'SN', 'Papa Assane TOURE');

insert into public.organization (id, country_code, type, nom, source_url) values
  (14, 'SN', 'gouvernement', 'Gouvernement Ahmadou Al Aminou Lô', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3');

insert into public.government (id, country_code, nom, chef_gouv_id, debut, portefeuilles_total, decret_ref, source_url) values
  (1, 'SN', 'Gouvernement Ahmadou Al Aminou Lô', 1, '2026-06-01', 31, 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3');

insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values
  (1, 'SN', 'chef_gouvernement', 'Premier ministre', 'premier_ministre', 14),
  (2, 'SN', 'ministre', 'Ministre', 'ministre', 14),
  (3, 'SN', 'depute', 'Député', 'depute', null);

insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values
  (1, 'SN', 'Ministre des Forces Armées', 'forces_armees', 'regalien', 1),
  (2, 'SN', 'Ministre de l''Economie, des Finances et du Plan', 'economie', 'economie', 2),
  (3, 'SN', 'Ministre de l''Intérieur et de la Sécurité publique', 'interieur', 'regalien', 3),
  (4, 'SN', 'Ministre de l''Intégration Africaine, des Affaires étrangères et des Sénégalais de l''Extérieur', 'integration_africaine', 'regalien', 4),
  (5, 'SN', 'Ministre de la Justice, Garde des Sceaux', 'justice', 'regalien', 5),
  (6, 'SN', 'Ministre de la Famille, de l''Action sociale et des Solidarités', 'famille', 'social', 6),
  (7, 'SN', 'Ministre de l''Enseignement supérieur, de la Recherche et de l''Innovation', 'enseignement_superieur', 'social', 7),
  (8, 'SN', 'Ministre de l''Energie et du Pétrole', 'energie', 'economie', 8),
  (9, 'SN', 'Ministre de l''Industrie et du Commerce', 'industrie', 'economie', 9),
  (10, 'SN', 'Ministre de l''Hydraulique et de l''Assainissement', 'hydraulique', 'infrastructure', 10),
  (11, 'SN', 'Ministre de l''Éducation Nationale', 'education_nationale', 'social', 11),
  (12, 'SN', 'Ministre de la Santé et de l''Hygiène Publique', 'sante', 'social', 12),
  (13, 'SN', 'Ministre de l''Urbanisme, des Collectivités Territoriales et de l''Aménagement des Territoires', 'urbanisme', 'infrastructure', 13),
  (14, 'SN', 'Ministre des Infrastructures', 'infrastructures', 'infrastructure', 14),
  (15, 'SN', 'Ministre de la Communication et des Relations avec les Institutions, Porte-Parole du Gouvernement', 'communication', 'regalien', 15),
  (16, 'SN', 'Ministre de la Microfinance et de l''Economie Sociale et Solidaire', 'microfinance', 'economie', 16),
  (17, 'SN', 'Ministre de l''Agriculture, de la Souveraineté Alimentaire et de l''Elevage', 'agriculture', 'economie', 17),
  (18, 'SN', 'Ministre des Télécommunications et du Numérique', 'telecommunications', 'infrastructure', 18),
  (19, 'SN', 'Ministre de la Fonction Publique, du Travail et de la Réforme du Service Public', 'fonction_publique', 'social', 19),
  (20, 'SN', 'Ministre de la Jeunesse et des Sports', 'jeunesse', 'social', 20),
  (21, 'SN', 'Ministre de la Culture, de l''Artisanat et du Tourisme', 'culture', 'social', 21),
  (22, 'SN', 'Ministre de l''Emploi et de la Formation Professionnelle et Technique', 'emploi', 'social', 22),
  (23, 'SN', 'Ministre des Mines et de la Géologie', 'mines', 'economie', 23),
  (24, 'SN', 'Ministre de l''Environnement et de la Transition Ecologique', 'environnement', 'infrastructure', 24),
  (25, 'SN', 'Ministre des Transports terrestres et aériens', 'transports_terrestres', 'infrastructure', 25),
  (26, 'SN', 'Ministre des Pêches et de l''Economie maritime', 'peches', 'economie', 26),
  (27, 'SN', 'Ministre auprès du Ministre de l''Economie, des Finances et du Plan, chargé du Budget', 'aupres_du_ministre_de_l_economie', 'economie', 27),
  (28, 'SN', 'Ministre auprès du Ministre de l''Economie, des Finances et du Plan, chargé de l''Economie, du Plan et de la Coopération', 'aupres_du_ministre_de_l_economie', 'economie', 28),
  (29, 'SN', 'Ministre auprès du Ministre de l''Agriculture, de la Souveraineté alimentaire et de l''Elevage, chargé de l''Elevage', 'aupres_du_ministre_de_l_agriculture', 'economie', 29),
  (30, 'SN', 'Ministre auprès du Ministre de la Culture, de l''Artisanat et du Tourisme, chargé de la Culture, des Industries créatives et du Patrimoine historique', 'aupres_du_ministre_de_la_culture', 'social', 30),
  (31, 'SN', 'Ministre, Secrétaire général du Gouvernement', 'ministre', 'regalien', 31);

insert into public.mandate (person_id, role_id, portfolio_id, government_id, debut, acte_ref, source_url, confiance) values
  (1, 1, null, 1, '2026-05-25', 'Décret n° 2026-1129', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (2, 2, 1, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (3, 2, 2, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (4, 2, 3, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (5, 2, 4, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (6, 2, 5, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (7, 2, 6, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (8, 2, 7, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (9, 2, 8, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (10, 2, 9, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (11, 2, 10, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (12, 2, 11, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (13, 2, 12, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (14, 2, 13, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (15, 2, 14, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (16, 2, 15, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (17, 2, 16, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (18, 2, 17, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (19, 2, 18, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (20, 2, 19, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (21, 2, 20, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (22, 2, 21, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (23, 2, 22, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (24, 2, 23, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (25, 2, 24, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (26, 2, 25, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (27, 2, 26, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (28, 2, 27, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (29, 2, 28, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (30, 2, 29, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (31, 2, 30, 1, '2026-06-01', 'Décret n° 2026-1130 du 1er juin 2026', 'https://primature.sn/publications/actualites/composition-du-nouveau-gouvernement-3', 'communique'),
  (32, 2, 31, 1, '2026-06-01', null, 'https://primature.sn/le-gouvernement', 'communique');

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
