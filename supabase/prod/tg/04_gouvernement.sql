-- Palabre — production Togo : gouvernement en exercice
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.person (id, country_code, nom) values
  (30001, 'TG', 'Faure Essozimna GNASSINGBÉ'),
  (30002, 'TG', 'Kodjo Sévon-Tépé ADEDZE'),
  (30003, 'TG', 'Gilbert BAWARA'),
  (30004, 'TG', 'Essowè Georges BARCOLA'),
  (30005, 'TG', 'Cina LAWSON'),
  (30006, 'TG', 'Robert Komlan Edo DUSSEY'),
  (30007, 'TG', 'Antoine Lékpa GBEGBENI'),
  (30008, 'TG', 'Hodabalo AWATE'),
  (30009, 'TG', 'Komla Dodzi KOKOROKO'),
  (30010, 'TG', 'Mama OMOROU'),
  (30011, 'TG', 'Yawa KOUIGAN'),
  (30012, 'TG', 'Mazamesso ASSIH'),
  (30013, 'TG', 'Calixte Batossie MADJOULBA'),
  (30014, 'TG', 'Jean-Marie Koffi TESSI'),
  (30015, 'TG', 'Badanam PATOKI'),
  (30016, 'TG', 'Pacôme ADJOUROUVI'),
  (30017, 'TG', 'Isaac TCHIAKPE'),
  (30018, 'TG', 'Martine Moni SANKAREDJA'),
  (30019, 'TG', 'Komlan Luku KADJÉ'),
  (30020, 'TG', 'Sani YAYA'),
  (30021, 'TG', 'Arthur Lilas TRIMUA'),
  (30022, 'TG', 'Koami GOMADO'),
  (30023, 'TG', 'Robert Koffi Messan EKLO'),
  (30024, 'TG', 'Tchin DARRE'),
  (30025, 'TG', 'Abdul-Fahd FOFANA'),
  (30026, 'TG', 'Séna ALIPUI'),
  (30027, 'TG', 'Yackoley Kokou JOHNSON'),
  (30028, 'TG', 'Gado TCHANGBEDJI'),
  (30029, 'TG', 'Edem Kokou TENGUE');

insert into public.organization (id, country_code, type, nom, source_url) values
  (30015, 'TG', 'gouvernement', 'Premier gouvernement de la Cinquième République (gouvernement Gnassingbé)', 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/');

insert into public.government (id, country_code, nom, chef_gouv_id, debut, portefeuilles_total, decret_ref, source_url) values
  (30001, 'TG', 'Premier gouvernement de la Cinquième République (gouvernement Gnassingbé)', 30001, '2025-10-08', 28, 'Décret du Président du Conseil signé le 8 octobre 2025 fixant la composition du gouvernement (numéro et publication au Journal officiel non trouvés)', 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/');

insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values
  (30001, 'TG', 'chef_gouvernement', 'Président du Conseil', 'president_du_conseil', 30015),
  (30002, 'TG', 'ministre', 'Ministre', 'ministre', 30015),
  (30003, 'TG', 'depute', 'Député', 'depute', null);

insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values
  (30001, 'TG', 'Ministre de l’aménagement du territoire, de l’urbanisme et de l’habitat', 'lamenagement_du_territoire', 'infrastructure', 1),
  (30002, 'TG', 'Ministre des relations avec le parlement et les Institutions', 'relations_avec_le_parlement', 'regalien', 2),
  (30003, 'TG', 'Ministre des finances et du budget', 'finances', 'economie', 3),
  (30004, 'TG', 'Ministre de l’efficacité du service public et de la transformation numérique', 'lefficacite_du_service_public', 'infrastructure', 4),
  (30005, 'TG', 'Ministre des affaires étrangères, de la coopération, de l’intégration africaine et des togolais de l’extérieur', 'affaires_etrangeres', 'regalien', 5),
  (30006, 'TG', 'Ministre de l’agriculture, de la pêche, des ressources animales et de la souveraineté alimentaire', 'lagriculture', 'economie', 6),
  (30007, 'TG', 'Ministre de l’administration territoriale, de la gouvernance locale et des affaires coutumières', 'ladministration_territoriale', 'regalien', 7),
  (30008, 'TG', 'Ministre de l’environnement, des ressources forestières, de la protection côtière et du changement climatique', 'lenvironnement', 'infrastructure', 8),
  (30009, 'TG', 'Ministre de l’Education nationale', 'leducation_nationale', 'social', 9),
  (30010, 'TG', 'Ministre de la communication', 'communication', 'social', 10),
  (30011, 'TG', 'Ministre du développement à la base et de l’économie sociale et solidaire', 'developpement_a_la_base', 'social', 11),
  (30012, 'TG', 'Ministre de la sécurité', 'securite', 'regalien', 12),
  (30013, 'TG', 'Ministre de la santé, de l’hygiène publique, de la couverture sanitaire universelle et des assurances', 'sante', 'social', 13),
  (30014, 'TG', 'Ministre de l’économie et de la veille stratégique', 'leconomie', 'economie', 14),
  (30015, 'TG', 'Garde des Sceaux, ministre de la justice et des droits humains', 'garde_des_sceaux', 'regalien', 15),
  (30016, 'TG', 'Ministre du tourisme, de la culture et des arts', 'tourisme', 'economie', 16),
  (30017, 'TG', 'Ministre des solidarités, du genre, de la famille et de la protection de l’enfance', 'solidarites', 'social', 17),
  (30018, 'TG', 'Ministre des Transports, du Désenclavement et des Pistes rurales', 'transports', 'infrastructure', 18),
  (30019, 'TG', 'Ministre délégué auprès du ministre de l’aménagement du territoire chargé des travaux publics et des infrastructures', 'delegue_aupres_du_ministre_de_lamenagement_du_territoire_cha', 'infrastructure', 19),
  (30020, 'TG', 'Ministre délégué auprès du ministre de l’Economie et de la Veille stratégique, chargé de la promotion des investissements et de la souveraineté économique', 'delegue_aupres_du_ministre_de_leconomie', 'economie', 20),
  (30021, 'TG', 'Ministre délégué auprès du ministre de l’aménagement du territoire, chargé du développement local', 'delegue_aupres_du_ministre_de_lamenagement_du_territoire', 'regalien', 21),
  (30022, 'TG', 'Ministre délégué auprès du ministre de l’économie, chargé de l’énergie et des ressources minières', 'delegue_aupres_du_ministre_de_leconomie', 'economie', 22),
  (30023, 'TG', 'Ministre délégué auprès du ministre de la Santé', 'delegue_aupres_du_ministre_de_la_sante', 'social', 23),
  (30024, 'TG', 'Ministre délégué auprès du ministre du développement à la base et de l’économie sociale et solidaire, chargé de la jeunesse et des sports', 'delegue_aupres_du_ministre_du_developpement_a_la_base', 'social', 24),
  (30025, 'TG', 'Ministre délégué auprès du ministre de l’aménagement du territoire chargé de l’eau et de l’assainissement', 'delegue_aupres_du_ministre_de_lamenagement_du_territoire_cha', 'infrastructure', 25),
  (30026, 'TG', 'Ministre délégué auprès du ministre des affaires étrangères et de la coopération, chargé de la coopération et des togolais de l’extérieur', 'delegue_aupres_du_ministre_des_affaires_etrangeres', 'regalien', 26),
  (30027, 'TG', 'Ministre délégué auprès du ministre de l’éducation nationale, chargé de l’enseignement supérieur et de la recherche scientifique', 'delegue_aupres_du_ministre_de_leducation_nationale', 'social', 27),
  (30028, 'TG', 'Ministre délégué auprès du ministre des Transports, du Désenclavement et des pistes rurales, chargé de l’Economie maritime', 'delegue_aupres_du_ministre_des_transports', 'economie', 28);

insert into public.mandate (person_id, role_id, portfolio_id, government_id, debut, acte_ref, source_url, confiance) values
  (30001, 30001, null, 30001, '2025-05-03', 'Pas de décret : désignation de plein droit comme chef du parti majoritaire (art. 47 de la Constitution du 6 mai 2024). UNIR a transmis son nom au bureau de l''Assemblée nationale le 30 avril 2025. La désignation a été annoncée en séance plénière de l''Assemblée nationale le 3 mai 2025, et le serment prêté le même jour devant la Cour constitutionnelle.', 'https://presidenceduconseil.gouv.tg/2025/05/03/renouveau-institutionnel-au-togo-faure-essozimna-gnassingbe-investi-president-du-conseil/', 'communique'),
  (30002, 30002, 30001, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30003, 30002, 30002, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30004, 30002, 30003, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30005, 30002, 30004, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30006, 30002, 30005, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30007, 30002, 30006, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30008, 30002, 30007, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30009, 30002, 30008, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30010, 30002, 30009, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30011, 30002, 30010, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30012, 30002, 30011, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30013, 30002, 30012, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30014, 30002, 30013, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30015, 30002, 30014, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30016, 30002, 30015, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30017, 30002, 30016, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30018, 30002, 30017, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30019, 30002, 30018, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2026/01/23/deux-nouvelles-nominations-au-sein-du-gouvernement-togolais/', 'communique'),
  (30020, 30002, 30019, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30021, 30002, 30020, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/11/09/nomination-dun-nouveau-ministre-charge-de-la-promotion-des-investissements/', 'communique'),
  (30022, 30002, 30021, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30023, 30002, 30022, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30024, 30002, 30023, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30025, 30002, 30024, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30026, 30002, 30025, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30027, 30002, 30026, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30028, 30002, 30027, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2025/10/08/premier-gouvernement-de-la-cinquieme-republique-une-nouvelle-ere-institutionnelle-placee-sous-le-signe-de-linnovation/', 'communique'),
  (30029, 30002, 30028, 30001, '2025-10-08', null, 'https://presidenceduconseil.gouv.tg/2026/01/23/deux-nouvelles-nominations-au-sein-du-gouvernement-togolais/', 'communique');

-- Remaniement signalé, à modéliser à la main : 2025-11-09 — Décret du 9 novembre 2025 : Arthur Lilas TRIMUA est nommé « ministre délégué auprès du ministre de l’Economie et de la Veille stratégique, chargé de la promotion des investissements et de la souveraineté économique ». Il remplace Manuella Modoukpè SANTOS, ministre déléguée chargée de la promotion des investissements, de l’industrie et de la souveraineté économique depuis le 8 octobre 2025 ; l'industrie disparaît de l'intitulé. Le remplacement est tiré de Wikipédia FR et du trombinoscope officiel : le communiqué de la Présidence ne nomme pas Santos. (https://presidenceduconseil.gouv.tg/2025/11/09/nomination-dun-nouveau-ministre-charge-de-la-promotion-des-investissements/)

-- Remaniement signalé, à modéliser à la main : 2025-11-25 — Départ de Kossi TENOU, ministre délégué auprès du ministre de l’économie, chargé du commerce et du contrôle qualité : le Conseil des ministres de l’UMOA le désigne président de l’AMF-UMOA. Ni décret de fin de fonctions ni successeur trouvés ; depuis décembre 2025, le ministre de l’Économie Badanam Patoki conduit les activités du ministère délégué au commerce (commerce.gouv.tg). La date retenue est celle de l'annonce UMOA ; la date effective de sortie du gouvernement est inconnue. (https://www.togofirst.com/fr/gouvernance-economique/2611-17641-kossi-tenou-prend-la-tete-de-l-amf-uemoa-en-remplacement-de-badanam-patoki)

-- Remaniement signalé, à modéliser à la main : 2026-01-23 — Décrets du 23 janvier 2026 : Komlan Luku KADJÉ devient Ministre des Transports, du Désenclavement et des Pistes rurales, portefeuille jusque-là rattaché à la Présidence du Conseil ; Edem Kokou TENGUE devient Ministre délégué auprès du ministre des Transports, du Désenclavement et des pistes rurales, chargé de l’Economie maritime. Passations de service le 26 janvier 2026 : Sani Yaya a remis les pistes rurales, Richard Gbalgueboa Kangbeni l'économie maritime (ATOP, https://atop.tg/121344-2/). Confirmé par republiquetogolaise.tg (https://www.republiquetogolaise.tg/politique/2401-11533-transports-desenclavement-economie-maritime-nouvelles-nominations-au-gouvernement) et par Republicoftogo, pour qui « l’équipe gouvernementale est désormais au complet ». (https://presidenceduconseil.gouv.tg/2026/01/23/deux-nouvelles-nominations-au-sein-du-gouvernement-togolais/)

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
