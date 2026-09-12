-- Palabre — photos, complément (12 septembre 2026) : rapprochement élargi aux noms de la base
-- plus longs que le libellé Wikidata (ex. « Ahmadou Al Aminou Mohamed LO » ↔ « Ahmadou Al Aminou Lo »).
-- Même méthode et mêmes licences que 09_photos.sql.

begin;

update public.person p set photo_url = v.url, photo_source = v.source, photo_licence = v.licence,
  wikidata_id = case when exists (select 1 from public.person o where o.wikidata_id = v.wikidata and o.id <> p.id) then p.wikidata_id else v.wikidata end
from (values
  (20160, 'https://commons.wikimedia.org/wiki/Special:FilePath/Marcel_Amon-Tanoh_2018.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:Marcel_Amon-Tanoh_2018.jpg — U.S. Department of State  [State Department Photo by Michael Gross]', 'Public domain', 'Q3288607'),
  (20003, 'https://commons.wikimedia.org/wiki/Special:FilePath/Anne_D%C3%A9sir%C3%A9e_Ouloto_02.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:Anne_D%C3%A9sir%C3%A9e_Ouloto_02.jpg — ACPascal81', 'CC BY-SA 4.0', 'Q30728030'),
  (20180, 'https://commons.wikimedia.org/wiki/Special:FilePath/St%C3%A9phane_Kipr%C3%A9_PSK.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:St%C3%A9phane_Kipr%C3%A9_PSK.jpg — Michelet GTD', 'CC BY-SA 4.0', 'Q114855812'),
  (20296, 'https://commons.wikimedia.org/wiki/Special:FilePath/Albert_Toikeusse_Mabri_%28cropped%29.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:Albert_Toikeusse_Mabri_(cropped).jpg — Mark Neyman', 'CC BY-SA 3.0', 'Q1304104'),
  (20231, 'https://commons.wikimedia.org/wiki/Special:FilePath/Naya_Jarvis_Zambl%C3%A9.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:Naya_Jarvis_Zambl%C3%A9.jpg — Aristidek5maya', 'CC BY 4.0', 'Q110726754'),
  (1, 'https://commons.wikimedia.org/wiki/Special:FilePath/Ahmadou_Al_Aminou_Lo_in_February_2020.jpg?width=256', 'https://commons.wikimedia.org/wiki/File:Ahmadou_Al_Aminou_Lo_in_February_2020.jpg — DAKARACTU TV HD', 'CC BY 3.0', 'Q139921464'),
  (30044, 'https://commons.wikimedia.org/wiki/Special:FilePath/Myriam_Dossou-D%27Almeida%2C_Ministre_du_D%C3%A9veloppement_%C3%A0_la_Base%2C_de_la_Jeunesse_et_de_l%27Emploi_des_Jeunes_du_Togo.png?width=256', 'https://commons.wikimedia.org/wiki/File:Myriam_Dossou-D%27Almeida,_Ministre_du_D%C3%A9veloppement_%C3%A0_la_Base,_de_la_Jeunesse_et_de_l%27Emploi_des_Jeunes_du_Togo.png — Fdimpact', 'CC BY-SA 4.0', 'Q112179612')
) as v(id, url, source, licence, wikidata)
where p.id = v.id;

select count(*) filter (where photo_url is not null) avec_photo from public.person;

commit;
