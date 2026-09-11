-- Palabre — question de la semaine du lundi 14 septembre 2026 (Sénégal).
-- Copie remplie de supabase/prod/02_question_modele.sql. Exécutée en
-- production le 11 septembre 2026, publiée le même jour.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'SN',
    '2026-09-14',
    'La Déclaration de politique générale du Premier ministre répond-elle à vos préoccupations ?',
    'Le Premier ministre Ahmadou Al Aminou Lô a présenté sa Déclaration de politique générale devant l''Assemblée nationale le mardi 8 septembre 2026. Selon le communiqué du Conseil des ministres du 10 septembre, elle s''articule autour de cinq engagements : redressement des comptes publics, restauration de l''État de droit, renforcement de la souveraineté, résolution des difficultés des Sénégalais, équité territoriale et sociale.',
    '[{"titre": "Primature — Suivez en direct la Déclaration de politique générale du Premier ministre", "url": "https://primature.sn/publications/actualites/suivez-en-direct-la-declaration-de-politique-generale-du-premier-ministre-1", "date": "2026-09-08"},
      {"titre": "Communiqué du Conseil des ministres du 10 septembre 2026", "url": "https://actusen.sn/221732-2/", "date": "2026-09-10"},
      {"titre": "Le Soleil — Les députés convoqués le 8 septembre pour la Déclaration de politique générale", "url": "https://lesoleil.sn/actualites/politique/assemblee-nationale-les-deputes-convoques-le-8-septembre-pour-la-declaration-de-politique-generale-du-premier-ministre/", "date": "2026-09-04"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, 'Oui, en grande partie', false),
  (2, 'En partie seulement', false),
  (3, 'Non, pas vraiment', false),
  (4, 'Je ne l''ai pas suivie', false),
  (5, 'Sans avis', true)
) as o(ordre, libelle, neutre);

update public.poll set publie = true where country_code = 'SN' and semaine = '2026-09-14';

commit;
