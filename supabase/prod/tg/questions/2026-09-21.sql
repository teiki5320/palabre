-- Palabre — question de la semaine du lundi 2026-09-21 (Togo).
-- Question d'actualité, générée depuis supabase/prod/sources/tg/poll.json.
-- Créée en brouillon : non publiée.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'TG',
    '2026-09-21',
    'Pour lutter contre les médicaments falsifiés, quelle mesure vous paraît la plus utile ?',
    'Le 7 septembre 2026, le Conseil des ministres a adopté le décret portant création de l''Agence nationale de régulation du médicament et autres produits de santé, structure autonome. Elle est chargée notamment du contrôle de la qualité, de l''inspection pharmaceutique, de la surveillance du marché et de la pharmacovigilance. Le gouvernement cite parmi les motifs le développement du marché illicite et la circulation de produits de santé de qualité inférieure ou falsifiés.',
    '[{"titre": "Le Conseil des ministres a adopté le décret portant création de l''Agence Nationale de Régulation du Médicament et autres Produits de santé", "url": "https://togopresse.tg/le-conseil-a-adopte-le-decret-portant-creation-de-lagence-nationale-de-regulation-du-medicament-et-autres-produits-de-sante/", "date": "2026-09-07"}, {"titre": "Togo : création d''une Agence nationale de régulation du médicament et autres produits de santé", "url": "https://www.togofirst.com/fr/sante/0809-19981-togo-creation-dune-agence-nationale-de-regulation-du-medicament-et-autres-produits-de-sante", "date": "2026-09-08"}, {"titre": "Les grandes décisions du Conseil des ministres du 07 Septembre 2026", "url": "https://presidenceduconseil.gouv.tg/2026/09/08/les-grandes-decisions-du-conseil-des-ministres-du-07-septembre-2026/", "date": "2026-09-08"}, {"titre": "Togo- Compte rendu du Conseil des ministres Lomé, 7 septembre 2026", "url": "https://icilome.com/2026/09/togo-compte-rendu-du-conseil-des-ministres-lome-7-septembre-2026/", "date": "2026-09-08"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, 'Renforcer les contrôles à l''importation et dans les pharmacies', false),
  (2, 'Réduire la vente de médicaments en dehors des pharmacies', false),
  (3, 'Rendre les médicaments vendus en pharmacie plus abordables', false),
  (4, 'Développer la fabrication de médicaments au Togo', false),
  (5, 'Sans avis', true)
) as o(ordre, libelle, neutre);

-- Une fois relu : publier.
-- update public.poll set publie = true where country_code = 'TG' and semaine = '2026-09-21';

commit;
