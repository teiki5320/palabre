-- Palabre — assertions sur le schéma, après seed.
-- Chaque bloc échoue bruyamment ; le script s'arrête au premier échec.

\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- 1. Un vote par utilisateur, définitif
-- ---------------------------------------------------------------------------
do $$
declare uid uuid := '00000000-0000-4000-8000-000000000001'; v record; n int;
begin
  -- l'utilisateur 1 a déjà voté au sondage 3 : second vote refusé
  begin
    insert into vote (poll_id, user_id, option_id)
    values (3, uid, (select id from poll_option where poll_id = 3 and ordre = 2));
    raise exception 'un second vote a été accepté';
  exception when unique_violation then null;
  end;

  select * into v from vote where poll_id = 3 and user_id = uid;
  update vote set option_id = (select id from poll_option where poll_id = 3 and ordre = 3)
    where poll_id = 3 and user_id = uid;
  assert (select option_id from vote where poll_id = 3 and user_id = uid) = v.option_id,
    'update sur vote devrait être ignoré';

  delete from vote where poll_id = 3 and user_id = uid;
  select count(*) into n from vote where poll_id = 3 and user_id = uid;
  assert n = 1, 'delete sur vote devrait être ignoré';
  raise notice 'ok  1. vote unique et définitif';
end $$;

-- ---------------------------------------------------------------------------
-- 2. Fenêtre de vote et cohérence option / sondage
-- ---------------------------------------------------------------------------
do $$
declare uid uuid := '00000000-0000-4000-8000-000000000299';
begin
  begin
    insert into vote (poll_id, user_id, option_id) values (1, uid, (select id from poll_option where poll_id = 1 and ordre = 1));
    raise exception 'vote accepté sur un sondage fermé';
  exception when check_violation then null; end;

  begin
    insert into vote (poll_id, user_id, option_id) values (4, uid, (select id from poll_option where poll_id = 4 and ordre = 1));
    raise exception 'vote accepté sur un sondage programmé';
  exception when check_violation then null; end;

  begin
    insert into vote (poll_id, user_id, option_id) values (3, uid, (select id from poll_option where poll_id = 1 and ordre = 1));
    raise exception 'vote accepté avec une option d''un autre sondage';
  exception when check_violation then null; end;

  raise notice 'ok  2. fenêtre de vote et options';
end $$;

-- ---------------------------------------------------------------------------
-- 3. Créneau : lundi 08:00 → dimanche 20:00 dans le fuseau du pays
-- ---------------------------------------------------------------------------
do $$
begin
  assert (select ouverture from poll where id = 3) = timestamptz '2026-09-07 08:00 Africa/Dakar', 'ouverture';
  assert (select fermeture from poll where id = 3) = timestamptz '2026-09-13 20:00 Africa/Dakar', 'fermeture';
  begin
    insert into poll (country_code, semaine, question, contexte) values ('SN', '2026-09-22', 'x', 'y');
    raise exception 'semaine acceptée alors que ce n''est pas un lundi';
  exception when check_violation then null; end;
  raise notice 'ok  3. créneau hebdomadaire';
end $$;

-- ---------------------------------------------------------------------------
-- 4. Seuil de 30 par cellule, total toujours présent, sommes cohérentes
-- ---------------------------------------------------------------------------
do $$
declare cnt int;
begin
  select count(*) into cnt from poll_result r where r.dimension <> 'total' and r.n_cellule < seuil_decoupe();
  assert cnt = 0, 'cellule publiée sous le seuil';

  select count(*) into cnt from poll_result r where r.poll_id = 2 and r.dimension in ('tranche_age', 'region');
  assert cnt = 0, 'le sondage 2 (40 votes) ne devrait avoir aucune découpe fine';

  select count(*) into cnt from poll_result r where r.poll_id = 1 and r.dimension = 'region';
  assert cnt > 0, 'le sondage 1 (220 votes) devrait avoir au moins une région publiée';

  assert (select count(distinct poll_id) from poll_result where dimension = 'total') = 3, 'dimension total manquante';

  select count(*) into cnt from (
    select r.poll_id, r.dimension, r.valeur
    from poll_result r group by 1, 2, 3 having sum(r.n) <> max(r.n_cellule)) x;
  assert cnt = 0, 'somme des options différente de la taille de cellule';

  assert (select r.n_cellule from poll_result r where r.poll_id = 1 and r.dimension = 'total' limit 1) = 220, 'total sondage 1';
  assert (select resultat_final_le is not null from poll where id = 1), 'sondage 1 non figé';
  assert (select resultat_final_le is null from poll where id = 3), 'sondage 3 figé alors qu''il est ouvert';
  raise notice 'ok  4. seuil de 30 et agrégats';
end $$;

-- ---------------------------------------------------------------------------
-- 5. Trois options minimum dont une neutre, vérifié à la publication
-- ---------------------------------------------------------------------------
do $$
declare pid bigint;
begin
  insert into poll (country_code, semaine, question, contexte) values ('SN', '2026-10-05', 'Deux options ?', 'ctx') returning id into pid;
  insert into poll_option (poll_id, ordre, libelle, neutre) values (pid, 1, 'Oui', false), (pid, 2, 'Non', false);
  begin
    update poll set publie = true where id = pid;
    raise exception 'publication acceptée avec deux options';
  exception when check_violation then null; end;

  insert into poll_option (poll_id, ordre, libelle, neutre) values (pid, 3, 'Peut-être', false);
  begin
    update poll set publie = true where id = pid;
    raise exception 'publication acceptée sans option neutre';
  exception when check_violation then null; end;

  update poll_option set neutre = true where poll_id = pid and ordre = 3;
  update poll set publie = true where id = pid;
  delete from poll where id = pid;
  raise notice 'ok  5. validation des options';
end $$;

-- ---------------------------------------------------------------------------
-- 6. Gouvernement à une date : renommage suivi par intitule_norm, couverture
-- ---------------------------------------------------------------------------
do $$
declare n int; r record;
begin
  select count(*) into n from gouvernement_a('SN', '2025-01-01');
  assert n = 7, format('gouvernement I au 2025-01-01 : %s membres, 7 attendus', n);

  select person_id into r from gouvernement_a('SN', '2025-04-01') where intitule_norm = 'education';
  assert r.person_id = 8, 'remplacement en cours de gouvernement non pris en compte';

  select count(*) into n from gouvernement_a('SN', '2026-01-01');
  assert n = 6, format('gouvernement II au 2026-01-01 : %s membres, 6 attendus', n);

  select intitule, intitule_norm, person_id into r from gouvernement_a('SN', '2026-01-01') where intitule_norm = 'sante';
  assert r.intitule = 'Santé, Hygiène publique et Action sociale' and r.person_id = 5, 'renommage du portefeuille santé';
  select intitule into r from gouvernement_a('SN', '2025-01-01') where intitule_norm = 'sante';
  assert r.intitule = 'Santé et Action sociale', 'intitulé historique de la santé';

  assert not exists (select 1 from gouvernement_a('SN', '2026-01-01') where intitule_norm = 'infrastructures'),
    'les infrastructures ne sont pas pourvues dans le gouvernement II';

  select renseignes, total into r from gouvernement_couverture('SN', '2026-01-01');
  assert r.renseignes = 5 and r.total = 25, format('couverture %s/%s, attendu 5/25', r.renseignes, r.total);

  assert (select count(*) from gouvernement_a('SN', '2020-01-01')) = 0, 'aucun gouvernement en 2020';

  begin
    insert into government (country_code, nom, debut, fin) values ('SN', 'Chevauchement', '2025-01-01', '2025-02-01');
    raise exception 'deux gouvernements simultanés acceptés';
  exception when exclusion_violation then null; end;
  raise notice 'ok  6. composition datée du gouvernement';
end $$;

-- ---------------------------------------------------------------------------
-- 7. Assemblée : suppléance et changement de groupe
-- ---------------------------------------------------------------------------
do $$
declare r record;
begin
  select person_id, qualite into r from assemblee_a('SN', '2025-01-01') where constituency_nom = 'Dakar';
  assert r.person_id = 9 and r.qualite = 'titulaire', 'Dakar 2025 : titulaire attendue';

  select person_id, qualite into r from assemblee_a('SN', '2026-01-01') where constituency_nom = 'Dakar';
  assert r.person_id = 10 and r.qualite = 'suppleant', 'Dakar 2026 : suppléante attendue';
  assert (select remplace_mandate_id from mandate where id = 21) = 20, 'lien suppléant → titulaire';
  assert (select motif_fin from mandate where id = 20) = 'nomination_gouvernement', 'motif de fin du titulaire';

  begin
    insert into mandate (person_id, role_id, constituency_id, qualite, debut) values (13, 3, 2, 'suppleant', '2026-01-01');
    raise exception 'suppléant accepté sans mandat remplacé';
  exception when check_violation then null; end;

  select groupe_id into r from assemblee_a('SN', '2025-01-01') where person_id = 11;
  assert r.groupe_id = 7, 'groupe initial';
  select groupe_id into r from assemblee_a('SN', '2026-01-01') where person_id = 11;
  assert r.groupe_id = 8, 'groupe après changement';

  assert (select scrutins_nominatifs from legislature where id = 1) = false, 'scrutins nominatifs doivent être indisponibles';
  assert (select seances_presentes is null from deputy_activity where mandate_id = 24), 'activité non publiée doit rester nulle';
  raise notice 'ok  7. suppléance et affiliations';
end $$;

-- ---------------------------------------------------------------------------
-- 8. Testez-vous : sans source ⇔ sans position, validation à la publication
-- ---------------------------------------------------------------------------
do $$
begin
  begin
    insert into party_position (statement_id, org_id, position, source_type) values (1, 4, 'accord', 'aucune');
    raise exception 'position sans source acceptée';
  exception when check_violation then null; end;

  begin
    insert into party_position (statement_id, org_id, position, source_type, date_source) values (1, 4, 'accord', 'document_public', '2025-01-01');
    raise exception 'document_public accepté sans lien ni extrait';
  exception when check_violation then null; end;

  -- le quiz du jeu de test (25 affirmations) est publié ; un brouillon de 5 ne peut pas l'être
  assert (select publie from quiz where id = 1), 'quiz de test non publié';
  assert (select count(*) from statement where quiz_id = 1) between 20 and 30, 'quiz de test hors bornes';
  insert into quiz (id, country_code, titre, version, publie) values (2, 'SN', 'Brouillon de test', 1, false);
  insert into statement (quiz_id, ordre, texte) select 2, g, 'Affirmation brouillon ' || g from generate_series(1, 5) g;
  begin
    update quiz set publie = true where id = 2;
    raise exception 'quiz de 5 affirmations publié';
  exception when check_violation then null; end;

  assert not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name in ('quiz', 'statement', 'party_position', 'position_contestation')
      and column_name = 'user_id'), 'aucune table du quiz ne doit porter de user_id';
  raise notice 'ok  8. quiz';
end $$;

-- ---------------------------------------------------------------------------
-- 9. Pays : interrupteur de module, région du bon pays
-- ---------------------------------------------------------------------------
do $$
begin
  assert (select actif from country_module where country_code = 'CI' and module = 'poll') = false, 'interrupteur CI';
  begin
    insert into profile (user_id, country_code, region_id)
    values ('00000000-0000-4000-8000-000000000001', 'SN', (select id from region where country_code = 'CI' limit 1));
    raise exception 'région d''un autre pays acceptée';
  exception when foreign_key_violation or unique_violation then null; end;
  raise notice 'ok  9. configuration pays';
end $$;

-- ---------------------------------------------------------------------------
-- 10. RLS : vote avant résultats, identité imposée, écriture réservée
-- ---------------------------------------------------------------------------
do $$
declare uid uuid := '00000000-0000-4000-8000-000000000250'; n int; v record; pos_id bigint;
begin
  -- le quiz de test n'est pas publié : la position est invisible pour un utilisateur, on la lit avant de changer de rôle
  select id into pos_id from party_position where statement_id = 1 and org_id = 1;
  execute 'set local role authenticated';
  perform set_config('request.jwt.claim.sub', uid::text, true);

  -- l'utilisateur 250 n'a pas voté au sondage 3 : pas de résultats
  select count(*) into n from poll_result where poll_id = 3;
  assert n = 0, 'résultats visibles avant le vote';
  -- mais l'archive (sondage 1, fermé) est lisible
  select count(*) into n from poll_result where poll_id = 1;
  assert n > 0, 'archive illisible';
  -- l'état et le nombre de répondants sont lisibles sans voter
  assert (select repondants from poll_public where id = 3) = 55, 'poll_public.repondants';
  assert (select statut from poll_public where id = 3) = 'ouvert', 'poll_public.statut';

  -- on vote en tentant d'usurper une identité : le trigger impose auth.uid()
  insert into vote (poll_id, user_id, option_id)
  values (3, '00000000-0000-4000-8000-000000000251', (select id from poll_option where poll_id = 3 and ordre = 1));
  select * into v from vote where poll_id = 3;
  assert v.user_id = uid, 'identité du votant non imposée';
  assert v.region_id = (select region_id from profile where user_id = uid), 'instantané du profil absent';

  select count(*) into n from poll_result where poll_id = 3;
  assert n > 0, 'résultats invisibles après le vote';

  -- lecture des seuls votes de soi-même
  select count(*) into n from vote;
  assert n = 1, format('un utilisateur voit %s votes, 1 attendu', n);

  -- profil d'autrui invisible
  select count(*) into n from profile;
  assert n = 1, 'profils d''autrui visibles';

  -- écriture éditoriale refusée
  begin
    insert into poll (country_code, semaine, question, contexte) values ('SN', '2026-10-12', 'x', 'y');
    raise exception 'insertion de sondage acceptée pour un utilisateur';
  exception when insufficient_privilege then null; end;

  -- brouillons invisibles, quiz publié visible
  select count(*) into n from quiz where id = 2;
  assert n = 0, 'quiz non publié visible';
  select count(*) into n from quiz where id = 1;
  assert n = 1, 'quiz publié invisible';

  -- vue d'anomalies interdite
  begin
    select count(*) into n from poll_anomalie;
    raise exception 'poll_anomalie lisible par un utilisateur';
  exception when insufficient_privilege then null; end;

  -- contestation : dépôt possible, lecture impossible
  insert into position_contestation (position_id, auteur, argument)
  values (pos_id, 'test', 'Argument de test suffisamment long pour passer la contrainte.');
  select count(*) into n from position_contestation;
  assert n = 0, 'contestations lisibles par un utilisateur';

  execute 'reset role';
  raise notice 'ok 10. RLS';
end $$;

-- ---------------------------------------------------------------------------
-- 11. Anonyme non connecté : faits lisibles, aucune écriture
-- ---------------------------------------------------------------------------
do $$
declare n int;
begin
  execute 'set local role anon';
  select count(*) into n from country where actif; assert n = 1, 'pays actifs';
  select count(*) into n from poll_public;       assert n = 4, 'sondages publiés';
  select count(*) into n from person;            assert n = 13, 'personnes';
  select count(*) into n from vote;              assert n = 0, 'votes visibles en anonyme';
  begin
    insert into vote (poll_id, user_id, option_id) values (3, gen_random_uuid(), (select id from poll_option where poll_id = 3 and ordre = 1));
    raise exception 'vote accepté sans session';
  exception when insufficient_privilege then null; end;
  execute 'reset role';
  raise notice 'ok 11. rôle anon';
end $$;
