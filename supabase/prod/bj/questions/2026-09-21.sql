-- Palabre — question de la semaine du lundi 2026-09-21 (Bénin).
-- Copie remplie de supabase/prod/02_question_modele.sql, générée depuis
-- supabase/prod/sources/bj/poll.json. Créée en brouillon : non publiée.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'BJ',
    '2026-09-21',
    'L''obligation faite aux employeurs privés de financer au moins 80 % de l''assurance maladie de leurs salariés vous paraît-elle une bonne mesure ?',
    'La loi de 2020 sur le programme ARCH rend l''assurance maladie obligatoire. Le décret du 29 octobre 2025 impose aux employeurs du secteur privé d''affilier leurs salariés et de financer au moins 80 % de la prime, avec un délai de mise en conformité de douze mois et une amende de 200 000 FCFA par salarié non couvert.',
    '[{"titre": "La Marina BJ — Comment l''exécutif muscle l''assurance maladie obligatoire", "url": "https://lamarinabj.com/index.php/2025/12/02/au-benin-comment-lexecutif-muscle-lassurance-maladie-obligatoire-pour-passer-du-principe-a-la-contrainte/", "date": "2025-12-02"}, {"titre": "Gouvernement du Bénin — Assurance maladie obligatoire : syndicats, patronat et assureurs informés du décret d''application", "url": "https://www.gouv.bj/article/2309/assurance-maladie-obligatoire-syndicats-patronat-assureurs-informes-contenu-decret-application/", "date": "2023-07-18"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, 'Plutôt une bonne mesure', false),
  (2, 'Bonne mesure, mais le délai est trop court', false),
  (3, 'Plutôt une mauvaise mesure', false),
  (4, 'Je ne connaissais pas cette mesure', false),
  (5, 'Sans avis', true)
) as o(ordre, libelle, neutre);

-- Une fois relu : publier.
-- update public.poll set publie = true where country_code = 'BJ' and semaine = '2026-09-21';

commit;
