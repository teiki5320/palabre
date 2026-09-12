-- Palabre — corrections Sénégal (12 septembre 2026), après relecture croisée.
--
-- 1. Ousmane Sonko et Amadou Ba figuraient sur la liste nationale ET sur une liste
--    départementale (Bignona, Thiès) ; le chargement leur avait créé un siège pour
--    chacune. Le siège retenu est le départemental (vie-publique.sn : « Député Pastef
--    BIGNONA titulaire » ; réintégration d'Amadou Ba à Thiès le 22 juin 2026). Les
--    mandats « Liste nationale » de ces deux personnes et de leurs suppléants sont
--    supprimés ; la présidence de l'Assemblée de Sonko, créée deux fois, est dédoublée.
--    Les deux sièges de liste nationale revenus aux suivants de liste restent non
--    documentés (absence assumée).
-- 2. Deux députés homonymes « Amadou DIALLO » (Ranérou Ferlo et Europe du Sud) avaient
--    été fusionnés en une seule personne : on sépare celui d'Europe du Sud.

begin;

delete from public.mandate where id in (169, 147, 146, 148, 103, 102, 104)
  and person_id in (76, 77, 34, 35);

insert into public.person (id, country_code, nom) values (199, 'SN', 'Amadou DIALLO');
update public.mandate set person_id = 199 where id = 280 and person_id = 166;
insert into public.affiliation (person_id, organization_id, debut, fin, source_url)
  select 199, organization_id, debut, fin, source_url from public.affiliation where person_id = 166
  on conflict do nothing;
select setval('public.person_id_seq', (select max(id) from public.person));

select r.type, count(*) filter (where m.fin is null) en_cours from public.mandate m join public.role r on r.id = m.role_id
  where r.country_code = 'SN' group by 1;

commit;
