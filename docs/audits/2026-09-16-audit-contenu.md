# Audit du contenu — « Président pour 100 jours »

296 cartes, 11 personnages, 10 parcours, 13 fins, 8 exploits, 22 chaînes.
Relu contre `docs/consigne-ecriture-cartes.md` et la conception du 16 septembre.
Aucun fichier modifié.

**Bilan : 12 constats bloquants, 37 importants, 26 mineurs — 75 en tout.**

Le contenu est bon. Le problème n'est pas la plume, il est arithmétique :
**51 cartes sur 296 — une sur six — ne posent pas de choix**, et la famille
« régime » est mécaniquement une punition, ce qui rend la moitié de l'axe
république–dictature injouable. Du très bon texte est posé sur des effets qui
ne tiennent pas.

---

## 1. Les dilemmes ratés

Rappel de la consigne : « Si une réponse est évidemment meilleure, la carte
est ratée. » Un script a comparé les deux réponses de chaque carte sur les
quatre jauges. **31 cartes sur 296 ont une réponse strictement dominante**
(elle gagne plus et perd moins partout), soit une carte sur dix.

### 1.1 Dominance stricte sans contrepartie — BLOQUANT [B1]

Vingt cartes où une réponse est meilleure sur les quatre jauges, sans `style`
ni drapeau pour racheter l'autre. Le joueur qui a compris glisse toujours du
même côté.

| Carte | Gagnante | Effets gagnante | Effets perdante |
|---|---|---|---|
| `general_solde_2` | droite | armée +8, peuple +4 | armée −10, presse −6 |
| `affaire_4x4_1` | droite | presse +8, peuple +4 (+ drapeau) | presse −8, peuple −4 |
| `chef_dot` | gauche | peuple +6, presse +4 | peuple −6, presse −6 |
| `sante_banque_sang` | gauche | peuple +6, caisses −1 | peuple +2, caisses −9 |
| `cabinet_visiteur_rival_1` | gauche | presse +6, peuple +4 (+ drapeau) | presse −6, peuple −3 |
| `cabinet_famille_emploi` | droite | presse +8, peuple +4 | presse −10, peuple −4 |
| `cabinet_voyage_classe` | gauche | caisses +8, presse +4 | caisses −6, presse −4 |
| `emissaire_audit_portuaire_1` | gauche | presse +6, caisses −3 (+ drapeau) | presse −4, caisses −6 |
| `doyen_grace_presidentielle` | droite | presse +8, peuple +4 | presse −6, peuple −8 |
| `general_soldat_tue_1` | gauche | peuple +6, armée +4 (+ drapeau) | armée −6, presse −4 |
| `general_rival_2` | droite | armée +8, peuple +4 | armée −6, peuple −4 |
| `redactrice_marche_1` | droite | presse +6, peuple +4 (+ drapeau) | presse −6, peuple −4 |
| `redactrice_rumeur_sante_1` | droite | presse +8, peuple +4 | presse −8, peuple −6 |
| `redactrice_reseaux_rumeur` | droite | presse +8, peuple +6 | presse −6, peuple −8 |
| `redactrice_reseaux_faux_compte` | droite | presse +6, peuple +4 | presse −8, peuple −4 |
| `redactrice_conference_presse` | gauche | presse +10, peuple +4 | presse −10, peuple −2 |
| `redactrice_prix_international` | gauche | presse +8, peuple +4 | presse −8, peuple −2 |
| `perso_fille_fidele_ministere` | droite | peuple +4, presse +5 | peuple −6, presse −6 |
| `perso_technocrate_accent_discours` | gauche | peuple +6, presse −3 | peuple +2, presse −6 |
| `perso_footballeur_blessure_ancienne` | droite | peuple +6, presse +4, caisses +2 | caisses −5, presse −4 |

Deux cas méritent d'être cités à part :

- **`perso_footballeur_blessure_ancienne`** est la carte la plus ratée du jeu.
  Le genou s'aggrave, « Je me soigne » coûte caisses −5 et presse −4, « Je
  patiente » **rapporte** peuple +6, presse +4 **et** caisses +2. Ne pas se
  soigner remplit les caisses. Il n'y a pas de dilemme, il y a une erreur de
  signe.
- **Cinq cartes de chaîne** (`affaire_4x4_1`, `cabinet_visiteur_rival_1`,
  `emissaire_audit_portuaire_1`, `general_soldat_tue_1`, `redactrice_marche_1`)
  ont leur réponse dominante du côté qui pose le drapeau : la bonne réponse
  est aussi la seule qui ouvre l'histoire. Double récompense.

### 1.2 La famille « régime » est une punition, pas un choix — BLOQUANT [B2]

Onze cartes supplémentaires sont strictement dominées, mais la réponse
perdante porte un `style` positif :

`ministre_cousin`, `redactrice_radio`, `redactrice_visa`,
`redactrice_anniversaire`, `maire_popularite_2`, `cabinet_fuite_reunion`,
`general_rival_3`, `redactrice_photographe_3`,
`redactrice_journaliste_achete_2`, `redactrice_publicite_etat`,
`redactrice_proces_blogueur`.

**Dans les onze, c'est la réponse dictatoriale qui est strictement la plus
mauvaise sur les quatre jauges.** Museler, refuser, saisir ne rapporte
jamais rien : ni armée, ni caisses, ni tranquillité. Or le joueur ne voit pas
l'axe république–dictature pendant la partie — les jauges seules s'illuminent.
Concrètement, la moitié de l'axe est inaccessible sauf à jouer mal exprès, et
les fins `election_gagnee_seul` / `election_perdue_comptee` (style ≥ 72) sont
presque hors d'atteinte.

Il faut que la répression **paie quelque chose** : `general_couvre_feu` le
fait bien (armée +10 contre peuple −12, presse −8), `regime_liste` aussi
(armée +8). Les onze cartes ci-dessus ne le font pas.

### 1.3 Quasi-dominances — IMPORTANT [I1]

Le perdant n'a qu'un avantage de 2 ou 3 points sur une seule jauge, contre un
écart total de 10 à 20 :

`ministre_climatiseurs`, `redactrice_carburant`, `regime_opposition`,
`chef_conflit_villages_1`, `sante_cholera_1`, `sante_medicaments_perimes`,
`sante_vaccination_ecoles`, `cabinet_nomination_ami`,
`cabinet_cadeau_diplomate`.

`sante_medicaments_perimes` est le pire : distribuer des antipaludéens périmés
coûte peuple −10 et presse −8 et ne rapporte que les 3 points de caisses
qu'aurait coûtés la destruction.

### 1.4 Réponses presque identiques — IMPORTANT [I2]

Une seule carte : `perso_technocrate_accent_discours` (peuple +6 / presse −3
contre peuple +2 / presse −6). Les deux réponses touchent les mêmes jauges,
dans le même sens, à 4 points près, sur la plus petite amplitude du jeu.

### 1.5 Ce qui va bien

Aucune signature d'effets n'est répétée à l'identique dans tout le jeu, aucun
libellé ne dépasse 18 caractères, aucun texte ne dépasse 150 caractères une
fois « Madame la Présidente » posé, aucune réponse n'est vide. Le contrôle
automatique fait son travail ; il ne sait simplement pas détecter une
dominance.

---

## 2. Les signes de régime

78 cartes portent un `style`. Relues une par une avec la question « est-ce que
ça ferait plaisir à un dictateur ? ». **Aucune inversion franche**
(répression codée négative) n'a survécu, mais huit signes sont faux, douteux
ou contradictoires.

### 2.1 Contradiction entre deux cartes — BLOQUANT [B5]

Le même levier — la publicité d'État comme laisse sur un journal — est codé
dans les deux sens :

- `redactrice_publicite_menace` : « Coupez-la » (couper la pub pour empêcher un
  article) = **+7**. Correct.
- `redactrice_publicite_etat` : « Vous l'aurez » (verser la pub au journal qui
  allait fermer) = **+8**, « Trouvez ailleurs » (laisser mourir le journal) =
  **−6**.

Dans la seconde, c'est la réponse qui tue le journal qui ramène vers la
république. Test de bon sens : un dictateur préfère « Trouvez ailleurs ». Le
signe est à inverser, ou la carte à réécrire (la corruption par la subvention
est un sujet réel, mais il faut alors que « Vous l'aurez » gagne quelque chose,
par exemple presse +6 contre caisses −6).

### 2.2 Inversion probable — IMPORTANT [I3]

- **`renseignements_rumeur_coup`** : « On observe » = **−5**. Le tableau de la
  consigne range explicitement « écouter, surveiller, ficher » du côté positif.
  Continuer à surveiller trois officiers sans preuve n'est pas un retour à la
  république. « On les arrête » (+9) est juste ; « On observe » devrait être
  +2 ou sans style, la vraie réponse républicaine serait de fermer le dossier.

- **`general_deserteurs_tribunal`** : « Tribunal militaire » = **+8**, « Simple
  radiation » = **−4**. Ailleurs dans le jeu, laisser un juge juger est codé
  négatif (`affaire_4x4_3` « Qu'il juge » −6, `perso_putschiste_proces_president`
  « Qu'on le juge » −8). Ici saisir une juridiction devient dictatorial. Les
  deux lectures ne peuvent pas coexister. Soit la sévérité militaire n'est pas
  un fait de régime (retirer le style), soit le libellé doit dire la
  brutalité, pas la procédure.

### 2.3 Signes douteux — IMPORTANT [I4] à [I7]

- **`cabinet_visiteur_rival_2`** [I4] : donner un bureau permanent au palais à
  son ancien rival = **−8**, le plus fort score républicain du jeu avec
  `chef_liste_electorale`. Refuser un bureau à un rival = **+5**. C'est une
  générosité personnelle, pas une institution. Valeurs à diviser par deux, ou
  style à retirer.
- **`renseignements_service_echange`** [I5] : livrer un homme à un service
  étranger = **+5**, moins que six heures d'émission d'anniversaire
  (`redactrice_anniversaire`, +7). L'échelle est cassée par le haut.
- **Échelle générale** [I6] : `regime_troisieme` (tordre la Constitution pour
  un troisième mandat) vaut ±10, `redactrice_anniversaire` (une émission de
  flagornerie) vaut +7, `doyen_juges_independance` (supprimer le contrôle des
  juges) vaut +8. Trois ordres de gravité différents pour trois points
  d'écart. Il faudrait réserver 9–10 aux actes irréversibles, 5–7 aux abus
  ordinaires, 2–4 aux poses.
- **`general_parcours_presse`** [I7] : « Je démens » (qu'on vous appelle « le
  général ») = +2 et rapporte presse **+6**. Démentir une chose vraie devrait
  coûter à la presse, pas lui plaire. Signe et effet à revoir ensemble.

### 2.4 Styles à supprimer — MINEUR [M1] à [M4]

- `ministre_fantomes` [M1] (−3 / +3) : effacer douze mille fonctionnaires
  fictifs est un arbitrage budgétaire et clientéliste, pas un fait de régime.
- `marchande_taxes` [M2] : « Laissez faire » = +2 alors qu'il s'agit de
  tolérer un racket — c'est une faiblesse d'État, pas une reprise en main.
- `chef_respect_anciens` [M3] (−5 / +6) : l'axe réel est centralisation contre
  coutume, pas république contre dictature.
- `perso_fille_discours_pere` [M4] : « Je l'assume » = +6 pour une ressemblance
  de discours.

### 2.5 Styles asymétriques — MINEUR [M5]

`riz_3` et `marchande_taxes` ne portent un `style` que sur une réponse (+2 d'un
côté, rien de l'autre). Ailleurs les deux réponses en portent toujours. À
uniformiser.

---

## 3. Les doublons et quasi-doublons

Six rédacteurs ont labouré les mêmes terrains sans le savoir. Les grappes
ci-dessous racontent la même situation.

### 3.1 Doublon quasi verbatim — BLOQUANT [B6]

**`general_garde` et `general_garde_presidentielle`.**
« Votre garde rapprochée veut doubler ses effectifs. Par prudence, dit-elle. »
contre « La garde présidentielle veut doubler les postes autour du palais.
Deux fois plus d'hommes, deux fois plus sûr, dit-elle. »
Mêmes réponses (doubler / refuser), mêmes effets à un point près (armée +8,
peuple −8, caisses −4 contre armée +8, peuple −8, caisses −4), mêmes styles
(+5/−2 et +6/−3). L'une des deux doit disparaître.

### 3.2 Le forage, trois fois — BLOQUANT [B7]

- `chef_puits_1` : « le puits de mon village est à sec… **les femmes marchent
  trois heures pour l'eau** »
- `sante_eau_potable_village` : « le seul forage de trois villages est cassé.
  **Les femmes marchent deux heures pour de l'eau** »
- `chef_puits_3` : « la pompe du forage est cassée »

La deuxième est la première avec un chiffre changé, portée par un autre
personnage. `chef_puits_3` recoupe encore les deux. Garder la chaîne
`puits`, supprimer `sante_eau_potable_village`.

### 3.3 Grappes à dégraisser — IMPORTANT [I8] à [I16]

- **Couvre-feu, trois cartes** [I8] : `general_couvre_feu` (l'instaurer),
  `general_attentat` (l'instaurer après une bombe), `general_couvre_feu_dure`
  (le lever après six semaines). Deux suffisent, et il faut les enchaîner
  (voir §7).
- **Racket au barrage, deux cartes** [I9] : `general_frontiere_convoi` (le poste
  du pont rançonne les convois humanitaires) et `general_racket_barrages` (les
  soldats du barrage prélèvent leur péage). Même situation, mêmes réponses
  (sanctionner presse +8 / armée −8, fermer les yeux armée +6). En ajoutant
  `marchande_taxes` (les jeunes en gilet qui taxent deux fois), le jeu a trois
  cartes de racket.
- **Carburant qui passe la frontière, deux cartes** [I10] :
  `general_frontiere_contrebande` (des motos chargées de carburant, la nuit) et
  `ministre_essence_frontaliere` (nos pompes se vident vers là-bas, chaque
  nuit).
- **Supprimer la subvention au carburant, deux cartes** [I11] :
  `ministre_carburant` (caisses +16 / peuple −16) et
  `emissaire_subvention_carburant` (caisses +12 / peuple −14). La seconde
  n'ajoute que la pression du fonds.
- **Auditer les comptes du port, trois cartes** [I12] : `ministre_bailleurs`
  (« Ils demandent à voir les comptes du port »), `ministre_douane` (« la douane
  du port rapporte moins… On audite ») et `emissaire_audit_portuaire_1` (« le
  programme veut auditer les recettes du port »). Seule la troisième ouvre une
  chaîne.
- **Nommer un fidèle ou un indépendant à la justice, deux cartes** [I13] :
  `doyen_magistrat_1` (un siège de la Cour) et `doyen_nomination_procureur`
  (procureur général). Même dilemme, mêmes effets (armée +4 / presse −6 contre
  presse +8 / peuple +4). La seconde est la première sans la chaîne.
- **La Cour examine un texte, quatre cartes** [I14] : `doyen_recours_electoral`,
  `doyen_constitutionnalite_loi`, `doyen_recours_opposant`,
  `doyen_conseil_constitutionnel`. Toutes du même moule : céder = presse +6/+8
  et peuple +4, tenir = presse −6/−8 et armée +3/+4. Deux à fondre.
- **Une fausseté circule, quatre cartes** [I15] : `redactrice_dementi`,
  `redactrice_dementi_photo`, `redactrice_reseaux_rumeur`,
  `redactrice_reseaux_faux_compte`. Démentir ou laisser dire, quatre fois.
- **Un proche non qualifié veut un poste, quatre cartes** [I16] :
  `cabinet_nomination_ami` (camarade de promotion),
  `cabinet_famille_emploi` (neveu), `perso_fille_fidele_ministere`,
  `perso_affaires_associe_ruine`. Les deux premières sont génériques et
  interchangeables.

### 3.4 Recoupements plus légers — MINEUR [M6] à [M10]

- `redactrice_radio` (refuser une licence radio) et
  `redactrice_site_bloque_demande` (bloquer un site) — museler un média hostile,
  deux fois [M6].
- `redactrice_publicite_etat` et `redactrice_publicite_menace` — la publicité
  d'État comme levier, deux fois, en miroir [M7].
- `doyen_grace_presidentielle`, `doyen_grace_collective`,
  `perso_militante_amie_emprisonnee` — trois grâces [M8].
- `general_retraites` (anciens combattants, huit mois d'arriérés) et
  `ministre_retraites_arriere` (retraités enseignants, quatre mois) — même
  carte, deux corps de métier [M9].
- `maire_ecole_urbaine` (école sans toit) et `chef_ecole_brousse` (école sans
  maître) — même forme, mêmes effets [M10].
- `general_soldat_tue_2` et `perso_general_veuve_soldat` — la veuve du caporal
  réclame sa pension, deux fois (la seconde est une carte de parcours, c'est
  donc acceptable, mais le texte est presque le même).

---

## 4. Les fausses voix

### 4.1 Le général parle de lui à la troisième personne — BLOQUANT [B8]

Trois cartes portées par `general` désignent « le général » comme un tiers :

- `general_medaille` : « le général veut décorer un capitaine pour une victoire
  qui n'a jamais vraiment eu lieu. Bon pour le moral, **dit-il**. »
- `general_anniversaire` : « les cinquante ans de l'armée méritent un monument,
  **dit le général**. »
- `general_chantier_prive` : « une société minière loue nos soldats… **Le
  général touche une commission, dit-on.** » — le chef d'état-major se dénonce
  lui-même.

Ces trois cartes ont été écrites pour un autre personnage (le cabinet, les
renseignements) et recollées sur le général. Soit on change le `personnage`,
soit on met le texte à la première personne (« Je veux décorer un capitaine… »).

### 4.2 Le joueur répond à la place de la journaliste — BLOQUANT [B9]

`redactrice_journaliste_achete_2` : « le palais me propose la même enveloppe
mensuelle qu'à mon confrère. » Les deux libellés sont **« Je refuse »** et
**« J'accepte »** — au nom de la rédactrice. Le joueur est le président : il ne
choisit pas ce qu'elle fait de son enveloppe. Et « J'accepte » donne presse
**−14** alors qu'acheter un journal devrait, à court terme, améliorer ce qu'on
écrit sur vous. La carte est à reprendre du point de vue du palais
(« On l'arrose » / « On arrête tout »).

### 4.3 Personnages mal choisis — IMPORTANT [I17] à [I20]

- `professeure_universite` [I17] : porté par le **ministre des Finances**, qui
  parle d'autonomie universitaire et de vingt ans de combat académique. Le
  doyen ou la directrice de cabinet conviendraient.
- `perso_fille_opposant_exile` [I18] : porté par l'**émissaire du fonds**, qui
  vient parler du retour et de la réhabilitation d'un opposant exilé par le
  père du joueur. Rien à voir avec son mandat. À donner au doyen ou au cabinet.
- `perso_militante_mentor_radical` [I19] : porté par le **chef traditionnel**,
  qui relaie les exigences du mentor de lutte d'une militante urbaine.
- `perso_putschiste_famille_disparu` [I20] : porté par le **chef traditionnel**,
  pour une famille de soldat disparu qui campe devant le palais dans la
  capitale. Le cabinet ou le général.

### 4.4 Voix diluée — MINEUR [M11] à [M13]

- **L'émissaire n'a pas de voix** [M11]. Ses dix-huit cartes parlent le même
  dialecte administratif : « C'est la clause quatre de l'accord »,
  « C'est écrit dans l'accord que vous avez signé », « C'est non négociable »,
  « pas un de plus ». Aucune n'a le détail concret que la consigne exige. Elle
  est le seul personnage qu'on ne reconnaîtrait pas sans son titre.
- **Le doyen a un tic** [M12] : quatre cartes se terminent sur la même figure —
  « Le texte est clair », « Il ne dit rien d'autre », « Rien de plus »,
  « Il ne visait que le texte, dit-il ».
- **Genre de l'émissaire** [M13] : `emissaire_audit_portuaire_1` écrit « Simple
  vérification, **dit-elle** », seule marque de genre des dix-huit cartes.
  `personnages.json` la nomme « L'émissaire », sans genre. À trancher avant de
  produire le portrait.

---

## 5. Les ruptures de ton

### 5.1 Les personnages connaissent les jauges — IMPORTANT [I21]

- `maire_stationnement` : « Les gens vont hurler, **les caisses vont sourire**. »
- `maire_taxe_veranda` : « Les commerçants vont crier fort. »

Le premier nomme une jauge du jeu dans la bouche d'un personnage : le maire
sait qu'il est dans un jeu. C'est le seul clin d'œil de ce type, il détonne.

### 5.2 Des dates réelles ancrent le pays imaginaire — IMPORTANT [I22]

- `perso_footballeur_selectionneur_rival` : « l'équipe nationale perd le match
  qui vous aurait qualifié **en 94** » — et la phrase mélange les temps
  (présent + conditionnel passé), on ne sait pas si le match a lieu aujourd'hui
  ou il y a trente ans.
- `perso_general_regiment_retraite` : « la retraite promise **en 90** ».
- `general_anniversaire` : « les cinquante ans de l'armée ».

Un pays qui n'existe pas n'a pas besoin de millésimes empruntés à l'histoire
réelle. « la saison d'avant », « il y a trente ans » suffisent.

### 5.3 Morale inversée — IMPORTANT [I23]

`chef_ecole_fille` : une famille retire sa fille de l'école pour la marier.
« On laisse faire » rapporte **peuple +4**. La consigne dit « pas de morale » ;
ici le jeu en fait une, à l'envers, en récompensant l'inaction par
l'approbation populaire. Le sujet mérite d'être traité, mais la réponse
passive doit coûter quelque chose d'autre que la presse.

### 5.4 Platitude administrative — MINEUR [M14]

Cartes où la situation n'est pas rendue concrète, contre la règle 3 de la
consigne : `emissaire_fonctionnaires_gel` (« C'est la clause quatre de
l'accord »), `emissaire_reforme_retraites_2` (« Le programme relit simplement
les termes de l'accord signé »), `emissaire_decaissement_gele` (« Deux
engagements sur trois n'ont pas été tenus »), `maire_recensement` (« sans
numéros de rue, la mairie ne sait plus qui taxer » — sauvé de justesse par le
détail des numéros).

### 5.5 Ce qui marche — pour mémoire

« Je dis ça, je dis rien » (`general_solde_1`), « il connaissait le prix des
autres » (`ministre_cousin`), « ça rapporte gros, et ça ne se voit pas »
(`ministre_taxe`), « Payez les bennes, ou je dirai que c'est vous »
(`maire_ordures`), « Les mères l'ont su avant vous » (`marchande_cantines`),
« un billet qui vous compare à un iguane » (`redactrice_proces_blogueur`),
« Personne ne l'a demandé » (`redactrice_tv_documentaire`). Le comique vient
bien de la situation.

---

## 6. Les risques

### 6.1 Le franc passe le filtre — BLOQUANT [B12]

`lib/contenu/validation.dart` refuse « cfa », « bceao », « uemoa », mais pas
« franc ». Deux cartes nomment donc la monnaie réelle de la région :

- `riz_1` : « Le sac de riz a pris **mille francs** en une semaine. »
- `general_frontiere_contrebande` : « sans payer **un franc** de taxe. »

La consigne impose « la monnaie ». Corriger les deux cartes **et** ajouter
`franc` à `_interdits`.

### 6.2 Contenus que le classement d'un store peut relever — IMPORTANT [I24] à [I27]

Aucun n'est disqualifiant, tous sont traités sérieusement, mais il faut les
avoir vus avant de remplir le questionnaire de classification :

- `renseignements_opposant_exil` [I24] : « Une **visite discrète** réglerait la
  question sans bruit », style +10 contre un opposant réfugié à l'étranger.
  Assassinat ou enlèvement politique suggéré. C'est la carte la plus dure du
  jeu.
- `renseignements_service_echange` [I25] : « Il demande juste **un homme**,
  discrètement, en retour » — livraison d'une personne à un service étranger.
- `general_mineurs` [I26] : « des **mineurs de quinze ans** figurent dans nos
  rangs », avec l'option « On dément tout ». Enfants soldats.
- `chef_ecole_fille` [I27] : mariage d'une fille retirée de l'école (voir aussi
  §5.3).

`regime_liste` (« on les ramasse cette nuit »), `perso_putschiste_repression_manif`
(« Comme avant ») et `sante_medicaments_perimes` (distribuer des médicaments
périmés) sont durs mais restent dans le registre politique attendu.

### 6.3 Aucune allusion religieuse ni ethnique

Vérifié mot à mot : pas une occurrence de religion, de culte, d'ethnie, de
tribu (les seules correspondances sont « tribunal », « distribué », « tribune »,
« attribué »). Pas un nom propre de pays, de ville, de personne ou
d'institution réelle ; les seuls mots capitalisés du corpus sont « État »,
« Cour », « Constitution », « Assemblée », « Finances ». Le filtre fait son
travail — c'est même, par contraste, un vide (voir §9).

### 6.4 Trous du filtre — MINEUR [M15]

`_interdits` ne couvre pas : Sierra Leone, Liberia, Gambie, Mauritanie,
Guinée-Bissau, Cap-Vert, Sahel, Françafrique, ni aucun nom de dirigeant réel.
Rien n'en abuse aujourd'hui, mais la liste sera relue par le prochain
rédacteur comme une définition du terrain autorisé.

---

## 7. La cohérence du monde

### 7.1 Des cartes qui parlent d'un passé qui n'a pas eu lieu — BLOQUANT [B3] [B4]

Le moteur (`lib/moteur/tirage.dart`) ne pose aucune condition sur ces cartes,
elles peuvent donc sortir n'importe quand :

- **`general_couvre_feu_dure`** [B3] : « **le couvre-feu dure depuis six
  semaines** ». Aucune condition. Ni `general_couvre_feu` ni `general_attentat`
  — les deux cartes qui instaurent un couvre-feu — ne posent de drapeau. La
  carte peut donc tomber alors que le joueur n'a jamais décrété de couvre-feu,
  et lui proposer de « le lever ».
- **`redactrice_site_debloque`** [B4] : « **mon site est bloqué depuis trois
  semaines**. Les renseignements ont oublié pourquoi. » Aucune condition.
  `redactrice_site_bloque_demande` ne pose pas de drapeau.

Correctif : un drapeau `couvre_feu_decrete` / `site_bloque` posé par la
réponse répressive, exigé par la carte suivante. Le jeu le fait déjà très bien
ailleurs (`ecoutes_autorisees` → `redactrice_reporter`, `milice_armee` →
`general_milice_2`).

### 7.2 Paires écrites comme des suites mais non chaînées — IMPORTANT [I28] à [I31]

- `maire_inondations_1` / `maire_inondations_2` [I28] : la seconde dit « **un
  autre quartier** est sous l'eau **à son tour** » et « la mairie ne fait
  rien ». Aucun champ `chaine`, aucun drapeau : elle peut sortir avant la
  première.
- `redactrice_journaliste_achete_1` / `_2` [I29] : la seconde dit « **la même**
  enveloppe mensuelle **qu'à mon confrère** ». Non chaînée.
- `redactrice_dessin_1` / `_2` [I30] : la seconde dit « **le même** dessinateur…
  **cette fois** ». Non chaînée — et la première est conditionnée
  `style_max: 45` alors que la seconde ne l'est pas : un joueur autoritaire ne
  verra que la suite.
- `redactrice_interview_opposant_1` / `_2` [I31] : « le même temps d'antenne que
  vous avez eu la semaine dernière » — rien ne garantit qu'il y ait eu une
  antenne.

Plus léger, même défaut : `renseignements_micro_bureau` (« un micro dans **mon
propre** bureau, **cette fois** ») qui suppose `renseignements_ecoutes_palais`,
et `redactrice_tv_flagornerie` (« un **second** reportage élogieux ») qui
suppose `redactrice_anniversaire`.

### 7.3 Géographie et objets — MINEUR [M16] à [M19]

- **Trois ponts** [M16] : « le pont du marché » (`marchande_pont`, fermé depuis
  un an), « le pont du fleuve » (`ministre_marche_pont`, en appel d'offres),
  « le pont du nord » (`perso_general_camarade_marche`). Aucun ne se contredit,
  mais le joueur qui répare le pont du marché puis voit passer un marché de
  pont croira à une incohérence. Nommer les lieux une fois pour toutes.
- **L'or et le lithium** [M17] : `ministre_or` (concession aurifère au nord,
  trente ans), `ministre_mine_redevances` (mine de lithium au nord),
  `ministre_reserves_or_1` (réserves d'or du trésor, vendues aux trois quarts),
  `perso_affaires_parts_minieres` (concession minière). Quatre mines, jamais
  reliées ; `reserves_or_1` vide le coffre et aucune autre carte ne s'en
  aperçoit hors de la chaîne.
- **La monnaie** [M18] : `emissaire_taux_change` la dit surévaluée de quinze
  pour cent et propose de l'ajuster ; `ministre_monnaie_contrefacon` suppose
  que le palais peut « retirer la coupure ». Le pays a donc une monnaie
  souveraine et une banque centrale, ce qui est cohérent mais n'est jamais dit
  ailleurs. À fixer dans une note de monde.
- **Le choléra disparaît** [M19] : si le joueur répond « Quarantaine » à
  `sante_cholera_2`, l'épidémie sort du jeu sans conclusion.

### 7.4 Genre — RAS, sauf la conception

Aucun « élu », « présidente » en dur, aucun participe accordé au masculin dans
les 296 textes : `{titre}` porte tout le travail, et les cartes de parcours
genrées (`votre père`, `votre neveu`) sont bien conditionnées au bon parcours.

En revanche `parcours.json` a divergé de la spec : le technocrate y est un
homme (« Le technocrate ») alors que la conception prévoyait « La technocrate
revenue de l'étranger », et deux parcours ont été remplacés (l'ancien
international et la militante). **MINEUR [M20]** — c'est la spec qu'il faut
mettre à jour, pas le contenu.

---

## 8. Les chaînes

22 chaînes : 12 de trois rangs, 10 de deux. Le moteur n'autorise un rang que
si le précédent a été joué (`tirage.dart`, `ch.rang != rangAtteint + 1`), donc
aucun rang orphelin. Les délais (3 à 6 jours) sont respectés partout.

### 8.1 Le rang 3 contredit le rang 2 — BLOQUANT [B10]

**`dossier_ministre`** : au rang 2 (`renseignements_dossier_ministre_2`), la
réponse droite est « **On le libère** » — on renonce au chantage. Le rang 3
(`renseignements_dossier_ministre_3`) n'exige que le drapeau `dossier_ouvert`
du rang 1, et s'ouvre sur « le ministre **que vous tenez** veut maintenant un
poste plus haut ». On tient un homme qu'on vient de relâcher.
Correctif : poser un drapeau `ministre_tenu` sur « On l'utilise » et l'exiger
au rang 3.

Même défaut, plus discret : **`affaire_4x4`** — au rang 2 le joueur peut faire
retenir la photo (« Retenez-la »), et le rang 3 annonce quand même que
« L'affaire des 4×4 arrive au tribunal ». Rien ne l'a portée au tribunal.
**IMPORTANT [I32]**

### 8.2 Cinq branches qui ne mènent nulle part — IMPORTANT [I33]

Drapeaux posés par une réponse et exigés par **aucune** carte ni aucun
exploit :

| Drapeau | Posé par | Conséquence |
|---|---|---|
| `magistrat_loyal` | `doyen_magistrat_1` gauche | nommer le fidèle tue la chaîne `magistrat_doyen` d'un coup |
| `marche_etouffe` | `redactrice_marche_2` gauche | étouffer le marché scolaire tue la chaîne `marche` |
| `rumeur_sante_dementie` | `redactrice_rumeur_sante_1` droite | le démenti tue la chaîne `rumeur_sante` |
| `cousin_servi` | `ministre_cousin` gauche | ne sert à rien nulle part |
| `liste_ramassee` | `regime_liste` gauche | rafler trente personnes n'a aucune suite |

Les trois premiers sont des fins de chaîne assumables, mais la consigne promet
qu'« une chaîne peut se terminer différemment selon les réponses » : ici la
branche autoritaire ne se termine pas, elle s'éteint. `liste_ramassee` est le
plus dommageable : c'est l'acte le plus grave du jeu et il ne produit rien.

Seul `photo_etouffee` est utilisé — par l'exploit `scoop_des_4x4`, en drapeau
interdit. Bon usage.

### 8.3 Une chaîne inachevable pour la moitié des joueurs — IMPORTANT [I34]

**`rival_colonel`** : le rang 3 (`general_rival_3`) exige `style_min: 60`. Un
joueur qui joue républicain voit le colonel devenir populaire (rang 1), voit
les casernes vouloir le fêter (rang 2, réponse dominée au passage) et n'a
jamais de conclusion. Il faudrait un rang 3 alternatif à bas style (le colonel
se présente contre vous, par exemple).

### 8.4 Aucune chaîne n'est calée dans le mandat — IMPORTANT [I35]

Aucune carte de rang 1 ne porte de `jour_max`. Une chaîne de trois rangs qui
démarre au jour 95 (délais 3 + 4 = 7 jours minimum) ne se terminera jamais.
Un `jour_max: 85` sur les rangs 1 des chaînes longues règle la question.

### 8.5 Rangs 3 interchangeables — MINEUR [M21]

Dans `solde`, `penurie_riz`, `materiel`, `perte` et `puits`, le rang 3 se lit
exactement pareil quelle qu'ait été la réponse au rang 2. Les chaînes qui
bifurquent vraiment — `cholera`, `magistrat_doyen`, `photographe`, `marche`,
`audit_emissaire` — sont nettement meilleures et devraient servir de modèle.

---

## 9. Les trous

### 9.1 Le mandat n'a pas de forme — BLOQUANT [B11]

Sur 296 cartes, **aucune** ne porte `jour_min`, `jour_max` ou `mandat_min`.
Les conditions se répartissent ainsi : `parcours` 66, `drapeaux_requis` 29,
`style_min` 14, `style_max` 10, `caisses_max` 3, `peuple_max` 1, `armee_min` 1.
174 cartes n'ont aucune condition.

Conséquences :

1. **Le jour 3 et le jour 97 tirent dans le même sac.** Rien ne distingue la
   prise de fonction (une seule carte, `serment`, marquée `ouverture`) de la
   fin de mandat. Aucune carte de campagne, aucun bilan des cent jours, aucune
   veille d'élection, alors que l'élection du jour 100 est le cœur du jeu.
2. **Le second mandat n'existe pas.** La conception promet des « cartes de
   second mandat » ; il y en a zéro. L'exploit `longevite_du_pouvoir`
   (mandat ≥ 2) récompense donc un mandat identique au premier.
3. **Le jeu ne réagit pas aux crises.** Cinq conditions de jauge au total : le
   contenu ne sait pas qu'on est à 8 de peuple ou à 92 de presse. Aucune carte
   ne se déclenche quand une jauge frôle un bout — c'est pourtant là que le
   jeu devient intéressant.

### 9.2 Sujets manquants — IMPORTANT [I36] / MINEUR [M22]

Manquent complètement, pour un pays d'Afrique de l'Ouest gouverné cent jours :

- **L'élection elle-même** [I36] : commission électorale, inscription des
  partis, financement de campagne, observateurs, dépouillement. Une seule
  carte y touche (`chef_liste_electorale`), et c'est l'une des meilleures.
- **La famille présidentielle proche** [I36] : le jeu a un cousin, un neveu, un
  frère, un père — mais **aucune carte d'époux ou d'épouse**. C'est le manque
  le plus visible pour un jeu présidentiel.
- **La jeunesse** [M22] : chômage, départs en mer, diaspora au-delà de la taxe
  sur les transferts, service civique.
- **L'agriculture** : coton, cacao, anacarde, prix de campagne, engrais,
  soudure. Le jeu ne connaît que le riz.
- **Le climat** : les inondations sont là, pas la sécheresse, pas les pêcheurs
  face aux chalutiers étrangers.
- **Les voisins** : un sommet régional est cité deux fois, mais aucune crise
  frontalière, aucun afflux de réfugiés, aucune frontière fermée par l'autre.
- **Le numérique** : une coupure d'internet, une taxe sur les données, le
  mobile money au-delà de `ministre_taxe_mobile`.
- **La police ordinaire** : une seule arrestation (le photographe) ; aucune
  bavure, aucune prison hors des deux cartes du doyen.
- **La religion et la coutume au-delà du chef** : l'absence totale de religion
  est un choix défendable pour les stores, mais elle laisse le chef
  traditionnel porter seul tout le poids du pays réel.

### 9.3 Personnages sous-utilisés — IMPORTANT [I37]

| Personnage | Cartes | Part |
|---|---|---|
| `redactrice` | 52 | 17,6 % |
| `general` | 49 | 16,6 % |
| `ministre` | 41 | 13,9 % |
| `cabinet` | 29 | 9,8 % |
| `doyen` | 23 | 7,8 % |
| `maire` | 18 | 6,1 % |
| `chef` | 18 | 6,1 % |
| `sante` | 18 | 6,1 % |
| `emissaire` | 18 | 6,1 % |
| `renseignements` | 17 | 5,7 % |
| **`marchande`** | **13** | **4,4 %** |

La marchande est la voix du Peuple — la jauge la plus meurtrière — et c'est le
personnage le moins présent du jeu, deux fois moins que le doyen et quatre
fois moins que la rédactrice. Il lui faut vingt cartes de plus : le prix du
poisson, les jeunes qui vendent aux carrefours, le marché qui brûle, les taxis
en grève, les transferts de la diaspora vue du marché.

Corollaire mécanique : la presse apparaît dans **395** effets, le peuple dans
385, les caisses dans 283, **l'armée dans 201** — moitié moins, alors que la
caserne est le danger le plus brutal du jeu. Les 49 cartes du général
dépensent beaucoup de peuple et de caisses, peu d'armée.

### 9.4 Réglages inutilisés — MINEUR [M23] à [M26]

- `repetable` : **aucune** carte [M23]. 296 cartes pour 100 jours laisse de la
  marge, mais les cartes de routine (budget, coupures de courant) gagneraient
  à revenir.
- `poids` : 11 cartes seulement en portent un (toutes à 2) [M24]. Le tirage est
  donc quasi uniforme ; les cartes d'ouverture de chaîne devraient peser plus.
- `drapeaux_interdits` : jamais utilisé dans `cartes.json` [M25], uniquement
  dans un exploit.
- `jour_min` / `jour_max` / `mandat_min` : jamais utilisés [M26] (voir §9.1).

---

## Les dix meilleures cartes du jeu

1. **`ministre_taxe`** — « Une petite taxe sur l'argent envoyé par ceux qui sont
   partis. Ça rapporte gros, et ça ne se voit pas. » Le cynisme exact, +14/−14.
2. **`regime_troisieme`** — « Elle ne l'autorise pas. Je peux la relire, si vous
   insistez. » La meilleure phrase du jeu, et le seul ±10 mérité.
3. **`ministre_fantomes`** — douze mille fonctionnaires qui n'existent pas ;
   les effacer coûte la rue, les garder coûte le trésor.
4. **`ministre_budget`** — les routes ou les bourses. Simple, net, les deux font
   mal.
5. **`general_solde_1`** — « Je dis ça, je dis rien. » Une menace en six mots,
   et l'ouverture de chaîne la plus propre du jeu.
6. **`sante_cholera_3`** — quarante morts contre six dans le communiqué. Le
   rang 3 d'une chaîne qui bifurque vraiment.
7. **`maire_titre_foncier`** — raser pour un boulevard ou régulariser :
   peuple −16 d'un côté, caisses −6 de l'autre. Le vrai arbitrage urbain.
8. **`chef_terres_societe`** — vendre les terres coutumières sans consulter :
   caisses +14, peuple −14.
9. **`ministre_reserves_or_1`** → **`_2`** — vider le coffre en silence, puis
   recevoir les auditeurs. Le meilleur coût différé du jeu.
10. **`chef_liste_electorale`** — quarante villages hors des listes ; les
    inscrire « vous coûtera des voix ailleurs ». Le seul vrai sujet électoral,
    et il est excellent.

Mentions : `ministre_cousin` (« il connaissait le prix des autres »),
`general_milice_1`/`_2`, `marchande_cantines`, `redactrice_tv_documentaire`.

## Les dix cartes à réécrire en priorité

1. **`perso_footballeur_blessure_ancienne`** — ne pas se soigner rapporte sur
   trois jauges. Erreur de signe pure.
2. **`redactrice_journaliste_achete_2`** — le joueur répond à la place de la
   rédactrice, et l'effet presse va dans le mauvais sens.
3. **`general_couvre_feu_dure`** — parle d'un couvre-feu qui n'a peut-être
   jamais existé ; à conditionner à un drapeau, ou à fondre avec
   `general_couvre_feu`.
4. **`redactrice_site_debloque`** — même défaut, même correctif.
5. **`general_garde_presidentielle`** — doublon quasi verbatim de
   `general_garde` ; à supprimer ou à déplacer sur un autre sujet.
6. **`sante_eau_potable_village`** — doublon de `chef_puits_1` jusqu'aux femmes
   qui marchent pour l'eau.
7. **`redactrice_publicite_etat`** — signe de régime probablement inversé, et
   réponse dominée par-dessus.
8. **`general_medaille`** — le général parle du général à la troisième personne
   (même correctif pour `general_anniversaire` et `general_chantier_prive`).
9. **`redactrice_conference_presse`** — « Pas maintenant » ne rapporte rien du
   tout : presse −10 et peuple −2 contre presse +10 et peuple +4.
10. **`renseignements_dossier_ministre_3`** — « le ministre que vous tenez »
    alors qu'on a pu le relâcher au rang 2 ; à conditionner à un drapeau.

Juste derrière : `doyen_nomination_procureur` (doublon de `doyen_magistrat_1`),
`cabinet_voyage_classe`, `redactrice_reseaux_rumeur`, `chef_dot`,
`riz_1` (« mille francs »), `general_deserteurs_tribunal`.
