-- Palabre — production Côte d'Ivoire : gouvernement en exercice
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;


insert into public.person (id, country_code, nom) values
  (20001, 'CI', 'Robert Beugré MAMBÉ'),
  (20002, 'CI', 'Téné Birahima OUATTARA'),
  (20003, 'CI', 'Anne Désirée OULOTO-LAMIZANA'),
  (20004, 'CI', 'Nialé KABA'),
  (20005, 'CI', 'Jean Sansan KAMBILÉ'),
  (20006, 'CI', 'Vagondo DIOMANDÉ'),
  (20007, 'CI', 'Adama COULIBALY'),
  (20008, 'CI', 'Mamadou Sangafowa COULIBALY'),
  (20009, 'CI', 'Bruno Nabagné KONÉ'),
  (20010, 'CI', 'Amadou KONÉ'),
  (20011, 'CI', 'Amedé Koffi KOUAKOU'),
  (20012, 'CI', 'Mamadou TOURÉ'),
  (20013, 'CI', 'Pierre N''Gou DIMBA'),
  (20014, 'CI', 'Moussa SANOGO'),
  (20015, 'CI', 'Sidi Tiémoko TOURÉ'),
  (20016, 'CI', 'Mariatou KONÉ'),
  (20017, 'CI', 'Amadou COULIBALY'),
  (20018, 'CI', 'Jacques Assahoré KONAN'),
  (20019, 'CI', 'Ibrahim Kalil KONATÉ'),
  (20020, 'CI', 'Siandou FOFANA'),
  (20021, 'CI', 'Souleymane DIARRASSOUBA'),
  (20022, 'CI', 'Adama DIAWARA'),
  (20023, 'CI', 'Adama KAMARA'),
  (20024, 'CI', 'N''Guessan KOFFI'),
  (20025, 'CI', 'Yacouba Hien SIÉ'),
  (20026, 'CI', 'Logboh Myss Belmonde DOGO'),
  (20027, 'CI', 'Djibril OUATTARA'),
  (20028, 'CI', 'Nassénéba TOURÉ'),
  (20029, 'CI', 'Françoise REMARCK'),
  (20030, 'CI', 'Adjé Silas METCH'),
  (20031, 'CI', 'Abou BAMBA'),
  (20032, 'CI', 'Célestin Serey DOH'),
  (20033, 'CI', 'Adama DOSSO'),
  (20034, 'CI', 'Jean-Louis MOULOT'),
  (20035, 'CI', 'Bernard Kini COMOÉ');

insert into public.organization (id, country_code, type, nom, source_url) values
  (20015, 'CI', 'gouvernement', 'Gouvernement Beugré Mambé II', 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/');

insert into public.government (id, country_code, nom, chef_gouv_id, debut, portefeuilles_total, decret_ref, source_url) values
  (20001, 'CI', 'Gouvernement Beugré Mambé II', 20001, '2026-01-23', 34, 'Décret n° 2026-08 du 23 janvier 2026 portant nomination des Membres du Gouvernement', 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/');

insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values
  (20001, 'CI', 'chef_gouvernement', 'Premier Ministre, Chef du Gouvernement', 'premier_ministre__chef_du_gouvernement', 20015),
  (20002, 'CI', 'ministre', 'Ministre', 'ministre', 20015),
  (20003, 'CI', 'depute', 'Député', 'depute', null);

insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values
  (20001, 'CI', 'Vice-Premier Ministre, Ministre de la Défense', 'vice_premier_ministre', 'regalien', 1),
  (20002, 'CI', 'Ministre d''État, Ministre de la Fonction Publique et de la Modernisation de l''Administration', 'etat', 'regalien', 2),
  (20003, 'CI', 'Ministre d''État, Ministre des Affaires Étrangères et de la Coopération Internationale', 'etat', 'regalien', 3),
  (20004, 'CI', 'Garde des Sceaux, Ministre de la Justice et des Droits de l''Homme', 'garde_des_sceaux', 'regalien', 4),
  (20005, 'CI', 'Ministre de l''Intérieur et de la Sécurité', 'interieur', 'regalien', 5),
  (20006, 'CI', 'Ministre de l''Économie, des Finances et du Budget', 'economie', 'economie', 6),
  (20007, 'CI', 'Ministre des Mines, du Pétrole et de l''Énergie', 'mines', 'economie', 7),
  (20008, 'CI', 'Ministre de l''Agriculture, du Développement Rural et des Productions Vivrières', 'agriculture', 'economie', 8),
  (20009, 'CI', 'Ministre des Transports et des Affaires Maritimes', 'transports', 'infrastructure', 9),
  (20010, 'CI', 'Ministre de l''Hydraulique, de l''Assainissement et de la Salubrité', 'hydraulique', 'infrastructure', 10),
  (20011, 'CI', 'Ministre de la Promotion de la Jeunesse, de l''Insertion Professionnelle et du Service Civique, Porte-Parole Adjoint du Gouvernement', 'promotion_de_la_jeunesse', 'social', 11),
  (20012, 'CI', 'Ministre de la Santé, de l''Hygiène Publique et de la Couverture Maladie Universelle', 'sante', 'social', 12),
  (20013, 'CI', 'Ministre de l''Urbanisme, du Logement et du Cadre de Vie', 'urbanisme', 'infrastructure', 13),
  (20014, 'CI', 'Ministre des Ressources Animales et Halieutiques', 'ressources_animales', 'economie', 14),
  (20015, 'CI', 'Ministre du Portefeuille de l''État et des Entreprises Publiques', 'portefeuille_de_l_etat', 'economie', 15),
  (20016, 'CI', 'Ministre de la Communication, Porte-Parole du Gouvernement', 'communication', 'social', 16),
  (20017, 'CI', 'Ministre des Eaux et Forêts', 'eaux', 'infrastructure', 17),
  (20018, 'CI', 'Ministre du Commerce, de l''Industrie et de l''Artisanat', 'commerce', 'economie', 18),
  (20019, 'CI', 'Ministre du Tourisme et des Loisirs', 'tourisme', 'economie', 19),
  (20020, 'CI', 'Ministre du Plan et du Développement', 'plan', 'economie', 20),
  (20021, 'CI', 'Ministre de l''Enseignement Supérieur et de la Recherche Scientifique', 'enseignement_superieur', 'social', 21),
  (20022, 'CI', 'Ministre de l''Emploi, de la Protection Sociale et de la Formation Professionnelle', 'emploi', 'social', 22),
  (20023, 'CI', 'Ministre de l''Éducation Nationale, de l''Alphabétisation et de l''Enseignement Technique', 'education_nationale', 'social', 23),
  (20024, 'CI', 'Ministre des Infrastructures et de l''Entretien Routier', 'infrastructures', 'infrastructure', 24),
  (20025, 'CI', 'Ministre de la Cohésion Nationale, de la Solidarité et de la Lutte contre la Pauvreté', 'cohesion_nationale', 'social', 25),
  (20026, 'CI', 'Ministre de la Transition Numérique et de l''Innovation Technologique', 'transition_numerique', 'infrastructure', 26),
  (20027, 'CI', 'Ministre de la Femme, de la Famille et de l''Enfant', 'femme', 'social', 27),
  (20028, 'CI', 'Ministre de la Culture et de la Francophonie', 'culture', 'social', 28),
  (20029, 'CI', 'Ministre des Sports', 'sports', 'social', 29),
  (20030, 'CI', 'Ministre de l''Environnement et de la Transition Écologique', 'environnement', 'infrastructure', 30),
  (20031, 'CI', 'Ministre Délégué auprès du Ministre des Transports et des Affaires Maritimes, chargé des Affaires Maritimes', 'delegue_aupres_du_ministre_des_transports', 'infrastructure', 31),
  (20032, 'CI', 'Ministre Délégué auprès du Ministre d''État, Ministre des Affaires Étrangères et de la Coopération Internationale, chargé de l''Intégration Africaine et des Ivoiriens de l''Extérieur', 'delegue_aupres_du_ministre_d_etat', 'regalien', 32),
  (20033, 'CI', 'Ministre Délégué auprès du Ministre de l''Éducation Nationale, de l''Alphabétisation et de l''Enseignement Technique, chargé de l''Enseignement Technique', 'delegue_aupres_du_ministre_de_l_education_nationale', 'social', 33),
  (20034, 'CI', 'Ministre Délégué auprès du Ministre de l''Agriculture, du Développement Rural et des Productions Vivrières, chargé des Productions Vivrières', 'delegue_aupres_du_ministre_de_l_agriculture', 'economie', 34);

insert into public.mandate (person_id, role_id, portfolio_id, government_id, debut, acte_ref, source_url, confiance) values
  (20001, 20001, null, 20001, '2026-01-21', 'Décret n° 2026-07 du 21 janvier 2026 portant nomination du Premier Ministre, Chef du Gouvernement', 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-7/', 'communique'),
  (20002, 20002, 20001, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20003, 20002, 20002, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20004, 20002, 20003, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20005, 20002, 20004, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20006, 20002, 20005, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20007, 20002, 20006, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20008, 20002, 20007, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20009, 20002, 20008, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20010, 20002, 20009, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20011, 20002, 20010, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20012, 20002, 20011, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20013, 20002, 20012, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20014, 20002, 20013, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20015, 20002, 20014, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20016, 20002, 20015, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20017, 20002, 20016, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20018, 20002, 20017, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20019, 20002, 20018, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20020, 20002, 20019, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20021, 20002, 20020, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20022, 20002, 20021, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20023, 20002, 20022, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20024, 20002, 20023, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20025, 20002, 20024, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20026, 20002, 20025, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20027, 20002, 20026, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20028, 20002, 20027, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20029, 20002, 20028, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20030, 20002, 20029, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20031, 20002, 20030, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20032, 20002, 20031, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20033, 20002, 20032, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20034, 20002, 20033, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique'),
  (20035, 20002, 20034, 20001, '2026-01-23', null, 'https://www.presidence.ci/communiques-presidence/communique-de-la-presidence-de-la-republique-8/', 'communique');

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
