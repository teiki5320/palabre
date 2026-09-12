-- Palabre — production Sénégal : couleur d'encodage des groupes parlementaires,
-- reprise du parti ou de la coalition dont ils portent le nom. La couleur
-- encode l'appartenance, elle ne décore pas.
begin;
update public.organization g set couleur = p.couleur
from public.organization p
where g.type = 'groupe_parlementaire' and g.country_code = 'SN' and g.couleur is null
  and p.type in ('parti', 'coalition') and p.couleur is not null
  and ((g.nom ilike 'Pastef%' and p.sigle = 'PASTEF') or (g.nom ilike 'Takku Wallu%' and p.sigle = 'TWS'));
select id, nom, couleur from public.organization where type = 'groupe_parlementaire' and country_code = 'SN';
commit;
