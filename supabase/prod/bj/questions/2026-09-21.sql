-- Palabre — question de la semaine du lundi 2026-09-21 (Bénin).
-- Question d'actualité, générée depuis supabase/prod/sources/bj/poll.json.
-- Créée en brouillon : non publiée.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'BJ',
    '2026-09-21',
    'Pour les cantines scolaires, quelle priorité vous paraît la plus importante cette année ?',
    'Le Conseil des ministres du 2 septembre 2026 a décidé de porter le nombre d''écoliers bénéficiaires des cantines scolaires dans les écoles publiques d''environ 1,4 million à 1,9 million, soit environ 500 000 enfants de plus. Le gouvernement a demandé que les cantines soient ouvertes partout dès le premier jour de classe et que les vivres soient conservés dans de bonnes conditions, sous la supervision de l''Agence nationale de l''alimentation et de la nutrition (Anan). L''année scolaire 2026-2027 commence le 14 septembre 2026.',
    '[{"titre": "Compte rendu du Conseil des Ministres du 02 sept. 2026", "url": "https://sgg.gouv.bj/cm/2026-09-02/", "date": "2026-09-02"}, {"titre": "Les mesures phares du gouvernement pour l''éducation à la rentrée", "url": "https://srtb.bj/les-mesures-phares-du-gouvernement-pour-leducation-a-la-rentree/", "date": "2026-09-03"}, {"titre": "Cantines scolaires au Bénin : Les attentes du gouvernement pour la rentrée 2026-2027", "url": "https://lematinal.bj/cantines-scolaires-au-benin-les-attentes-du-gouvernement-pour-la-rentree-2026-2027/", "date": "2026-09-04"}, {"titre": "Rentrée au Bénin : 1,9 million d''écoliers visés par les cantines, que prévoir à la maison ?", "url": "https://beninwebtv.com/rentree-au-benin-19-million-decoliers-vises-par-les-cantines-que-prevoir-a-la-maison", "date": "2026-09-08"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, 'Faire bénéficier encore plus d''écoliers', false),
  (2, 'Améliorer la qualité et la variété des repas', false),
  (3, 'Garantir que les cantines fonctionnent dès la rentrée et toute l''année', false),
  (4, 'Associer davantage les parents et les communautés au fonctionnement', false),
  (5, 'Sans avis', true)
) as o(ordre, libelle, neutre);

-- Une fois relu : publier.
-- update public.poll set publie = true where country_code = 'BJ' and semaine = '2026-09-21';

commit;
