-- Palabre — question de la semaine du lundi 2026-09-21 (Côte d'Ivoire).
-- Question d'actualité, générée depuis supabase/prod/sources/ci/poll.json.
-- Créée en brouillon : non publiée.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'CI',
    '2026-09-21',
    'Êtes-vous favorable à un manuel scolaire unique par matière et par niveau pour toutes les écoles du pays ?',
    'Le ministère justifie cette mesure par la multiplicité des manuels utilisés pour une même matière, l''instabilité des listes remises aux familles et les dépenses supplémentaires des parents. Selon le ministère, aucun établissement public ou privé ne peut exiger d''ouvrages hors de la liste officielle des manuels autorisés. L''année scolaire 2026-2027 a débuté le lundi 14 septembre 2026.',
    '[{"titre": "Côte d''Ivoire-AIP/ Année scolaire 2026-2027: le manuel scolaire unique fait son retour pour harmoniser les apprentissages", "url": "https://www.aip.ci/cote-divoire-aip-annee-scolaire-2026-2027-le-manuel-scolaire-unique-fait-son-retour-pour-harmoniser-les-apprentissages/", "date": "2026-09-04"}, {"titre": "Rentrée 2026-2027 : l''ambitieuse feuille de route du ministère de l''Éducation nationale", "url": "https://www.nordsud.info/rentree-2026-2027-lambitieuse-feuille-de-route-du-ministere-de-leducation-nationale/", "date": "2026-09-07"}, {"titre": "Rentrée 2026-2027 : manuel scolaire unique en Côte d''Ivoire (ce qu''il faut savoir)", "url": "https://www.yeclo.com/rentree-2026-2027-cote-divoire-un-manuel-scolaire-unique-impose-ce-quil-faut-savoir/", "date": "2026-09-07"}, {"titre": "Rentrée scolaire 2026-2027 le 14 septembre : tout savoir sur les nouvelles mesures", "url": "https://www.yeclo.com/rentree-scolaire-2026-2027-le-14-septembre-tout-savoir-sur-les-nouvelles-mesures/", "date": "2026-09-09"}, {"titre": "Côte d''Ivoire-AIP/ L''année scolaire 2026-2027 s''étend du 14 septembre 2026 au 30 juillet 2027 (Ministère)", "url": "https://www.aip.ci/cote-divoire-aip-lannee-scolaire-2026-2027-setend-du-14-septembre-2026-au-30-juillet-2027-ministere/", "date": "2026-09-04"}, {"titre": "Côte d''Ivoire : Rentrée Scolaire 2026-2027, voici le découpage de l''année, dates des congés et vacances", "url": "https://www.koaci.com/article/2026/09/04/cote-divoire/societe/cote-divoire-rentree-scolaire-2026-2027-voici-le-decoupage-de-lannee-dates-des-conges-et-vacances_200209.html", "date": "2026-09-04"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, 'Favorable', false),
  (2, 'Plutôt favorable', false),
  (3, 'Plutôt défavorable', false),
  (4, 'Défavorable', false),
  (5, 'Sans avis', true)
) as o(ordre, libelle, neutre);

-- Une fois relu : publier.
-- update public.poll set publie = true where country_code = 'CI' and semaine = '2026-09-21';

commit;
