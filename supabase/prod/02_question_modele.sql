-- Palabre — modèle de question de la semaine.
--
-- Copier ce fichier, remplacer chaque valeur entre chevrons, puis l'exécuter
-- sur le projet de production. Une question par semaine, par pays.
--
-- Rappels de rédaction :
--   - question d'actualité : un fait rapporté dans les jours qui précèdent la
--     semaine, avec au moins deux sources datées de cette période ;
--   - formulation neutre, une seule question ;
--   - contexte factuel de 2 à 3 phrases, chaque fait sourcé ;
--   - trois options minimum, dont une neutre ;
--   - « semaine » est le lundi ; ouverture lundi 08:00 et fermeture dimanche
--     20:00 (heure de Dakar) sont calculées automatiquement.
--
-- Le sondage est créé en brouillon (publie = false). Le passage à
-- publie = true vérifie les options et rend la question visible.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values (
    'SN',
    '<AAAA-MM-JJ, un lundi>',
    '<Question, neutre, terminée par un point d''interrogation ?>',
    '<Deux à trois phrases de contexte factuel.>',
    '[{"titre": "<Titre de la source>", "url": "<https://…>", "date": "<AAAA-MM-JJ>"}]'::jsonb
  )
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
  (1, '<Option 1>', false),
  (2, '<Option 2>', false),
  (3, '<Option 3>', false),
  (4, 'Sans avis', true)
) as o(ordre, libelle, neutre);

-- Une fois relu : publier.
-- update public.poll set publie = true where country_code = 'SN' and semaine = '<AAAA-MM-JJ>';

commit;
