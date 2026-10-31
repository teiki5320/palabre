# Les objets retirés du palais — 31 octobre 2026

Le catalogue du palais a été vidé de toutes ses pièces sauf la cour des
voitures, pour être réécrit. Rien n'est perdu : tout ce qui a été retiré
est ici, texte et données, prêt à revenir tel quel.

Ce qui est parti : **20 objets**, **14 cartes** qui dépendaient de leur
drapeau, **1 exploit** et **1 fin**.

Trois mécanismes du moteur restent en place mais ne peuvent plus se
déclencher, faute de l'objet qui les posait : le coffre-fort qui rend dix
caisses une fois (`coffreSiBesoin`), le recul des seuils de la pompe
(`_reculDeLaPompe`), et la plaque du dimanche du quartier. Leurs images
sont toujours au dépôt. Le jour où l'un de ces objets revient, il
retrouve son mécanisme intact.

---

## Les objets

### Le bureau

**Le ventilateur de plafond** — 4 caisses, decor
> Il tourne au-dessus du bureau. La première chose du palais qui bouge toute seule.

**Le fauteuil de cuir** — 5 caisses, decor
> Derrière le bureau. Il se craquellera d'un mandat à l'autre.

**Le poste à ondes courtes** — 6 caisses, contenu
> Pour entendre ce qu'on dit de vous ailleurs, et que personne ne vous répète.

**Le portrait officiel** — 7 caisses, decor
> Votre visage au mur de votre propre bureau. On s'y habitue vite.

décalage du régime : +4

**La bibliothèque** — 8 caisses, decor
> Elle se remplit d'un livre par mandat joué. La remplir prendra une vie.

**Le téléphone rouge** — 9 caisses, contenu
> Une ligne directe avec le voisin. Elle sonne dans les deux sens.

**Le climatiseur** — 10 caisses, contenu, bonus
> La saison sèche cesse d'être une épreuve. Pour vous.

**Le coffre-fort** — 14 caisses, bonus
> Dix points mis de côté. Le jour où les caisses seront vides, il s'ouvrira une fois.

### Le balcon

**Les jardinières** — 4 caisses, decor
> Sur la rambarde. Le maire de la ville finira par les voir.

**Le pupitre et les micros** — 6 caisses, contenu
> De quoi parler à la place depuis chez soi.

**La sono de l'avenue** — 9 caisses, contenu
> La place vous entend. Qu'elle le veuille ou non.

**Le vitrage pare-balles** — 16 caisses, contenu
> Le jour où le palais sera pris, vous aurez le choix de rester.

### La chambre

**L'enceinte** — 4 caisses, contenu
> Ce qu'on écoute le soir en dit plus long qu'un discours.

**Le fauteuil de lecture** — 5 caisses, decor
> Près de la baie. Personne ne s'y assoit jamais très longtemps.

**Le miroir en pied** — 6 caisses, decor
> Vous vous y voyez tel que le mandat vous laisse.

**Le coffret à bijoux** — 12 caisses, contenu, bonus
> Un cadeau qui ne se discute pas, et qui ne s'oublie pas non plus.

### La piscine

**Les transats et le parasol** — 4 caisses, decor
> Au bord du bassin, face au mur d'enceinte.

**Le plongeoir** — 5 caisses, decor
> Il grince. Personne ne s'en sert.

**Le remplissage et la pompe** — 8 caisses, decor
> L'eau redevient claire, tant que les caisses tiennent.

**L'ouverture au quartier le dimanche** — 10 caisses, contenu
> La grille reste ouverte de midi à la nuit. On viendra.

effet d'achat : {"peuple": 4} · décalage du régime : -4

```json
[
  {
    "id": "ventilateur",
    "piece": "bureau",
    "nom": "Le ventilateur de plafond",
    "description": "Il tourne au-dessus du bureau. La première chose du palais qui bouge toute seule.",
    "prix": 4,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "fauteuil_cuir",
    "piece": "bureau",
    "nom": "Le fauteuil de cuir",
    "description": "Derrière le bureau. Il se craquellera d'un mandat à l'autre.",
    "prix": 5,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "poste_radio",
    "piece": "bureau",
    "nom": "Le poste à ondes courtes",
    "description": "Pour entendre ce qu'on dit de vous ailleurs, et que personne ne vous répète.",
    "prix": 6,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "portrait_officiel",
    "piece": "bureau",
    "nom": "Le portrait officiel",
    "description": "Votre visage au mur de votre propre bureau. On s'y habitue vite.",
    "prix": 7,
    "natures": [
      "decor"
    ],
    "style_achat": 4
  },
  {
    "id": "bibliotheque",
    "piece": "bureau",
    "nom": "La bibliothèque",
    "description": "Elle se remplit d'un livre par mandat joué. La remplir prendra une vie.",
    "prix": 8,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "telephone_rouge",
    "piece": "bureau",
    "nom": "Le téléphone rouge",
    "description": "Une ligne directe avec le voisin. Elle sonne dans les deux sens.",
    "prix": 9,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "climatiseur",
    "piece": "bureau",
    "nom": "Le climatiseur",
    "description": "La saison sèche cesse d'être une épreuve. Pour vous.",
    "prix": 10,
    "natures": [
      "contenu",
      "bonus"
    ]
  },
  {
    "id": "coffre_fort",
    "piece": "bureau",
    "nom": "Le coffre-fort",
    "description": "Dix points mis de côté. Le jour où les caisses seront vides, il s'ouvrira une fois.",
    "prix": 14,
    "natures": [
      "bonus"
    ]
  },
  {
    "id": "jardinieres",
    "piece": "balcon",
    "nom": "Les jardinières",
    "description": "Sur la rambarde. Le maire de la ville finira par les voir.",
    "prix": 4,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "pupitre",
    "piece": "balcon",
    "nom": "Le pupitre et les micros",
    "description": "De quoi parler à la place depuis chez soi.",
    "prix": 6,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "sono",
    "piece": "balcon",
    "nom": "La sono de l'avenue",
    "description": "La place vous entend. Qu'elle le veuille ou non.",
    "prix": 9,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "vitrage",
    "piece": "balcon",
    "nom": "Le vitrage pare-balles",
    "description": "Le jour où le palais sera pris, vous aurez le choix de rester.",
    "prix": 16,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "enceinte",
    "piece": "chambre",
    "nom": "L'enceinte",
    "description": "Ce qu'on écoute le soir en dit plus long qu'un discours.",
    "prix": 4,
    "natures": [
      "contenu"
    ]
  },
  {
    "id": "fauteuil_lecture",
    "piece": "chambre",
    "nom": "Le fauteuil de lecture",
    "description": "Près de la baie. Personne ne s'y assoit jamais très longtemps.",
    "prix": 5,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "miroir",
    "piece": "chambre",
    "nom": "Le miroir en pied",
    "description": "Vous vous y voyez tel que le mandat vous laisse.",
    "prix": 6,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "coffret",
    "piece": "chambre",
    "nom": "Le coffret à bijoux",
    "description": "Un cadeau qui ne se discute pas, et qui ne s'oublie pas non plus.",
    "prix": 12,
    "natures": [
      "contenu",
      "bonus"
    ]
  },
  {
    "id": "transats",
    "piece": "piscine",
    "nom": "Les transats et le parasol",
    "description": "Au bord du bassin, face au mur d'enceinte.",
    "prix": 4,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "plongeoir",
    "piece": "piscine",
    "nom": "Le plongeoir",
    "description": "Il grince. Personne ne s'en sert.",
    "prix": 5,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "pompe",
    "piece": "piscine",
    "nom": "Le remplissage et la pompe",
    "description": "L'eau redevient claire, tant que les caisses tiennent.",
    "prix": 8,
    "natures": [
      "decor"
    ]
  },
  {
    "id": "dimanche",
    "piece": "piscine",
    "nom": "L'ouverture au quartier le dimanche",
    "description": "La grille reste ouverte de midi à la nuit. On viendra.",
    "prix": 10,
    "natures": [
      "contenu"
    ],
    "effet_achat": {
      "peuple": 4
    },
    "style_achat": -4
  }
]
```

---

## Les cartes

**`objet_poste_radio_station`** — renseignements

> {titre}, votre poste à ondes courtes donne chaque soir une station qui compte nos morts et nos grèves. Elle émet de chez le voisin.

- *On la brouille* → {"presse": -7, "armee": 6, "caisses": -3}
- *On l'écoute* → {"presse": 5, "peuple": -4, "armee": -4}

**`objet_telephone_rouge_nuit`** — general

> {titre}, le téléphone rouge a sonné à quatre heures. Le voisin dit qu'un de nos convois a franchi sa frontière, et il attend.

- *Je lui parle* → {"armee": -5, "presse": 6, "peuple": 3}
- *Je laisse sonner* → {"armee": 6, "presse": -5, "peuple": -4}

**`objet_climatiseur_groupe`** — cabinet

> {titre}, le climatiseur du bureau tire sur le groupe du quartier. Trois heures de coupure : chez eux, ou ici.

- *Chez eux* → {"peuple": -8, "presse": -4, "armee": 3}
- *Ici* → {"peuple": 6, "presse": 4, "caisses": -4}

**`objet_pupitre_allocution`** — cabinet

> {titre}, le pupitre est prêt pour parler du budget. Dix minutes en direct ce soir, sans qu'aucune rédaction ne vous coupe.

- *Je parle ce soir* → {"peuple": 7, "presse": -5, "armee": 3}
- *Pas ce soir* → {"presse": 5, "peuple": -5, "caisses": 3}

**`objet_sono_place`** — maire

> {titre}, la place est pleine et la sono porte jusqu'au carrefour. Ils attendent depuis deux heures que quelqu'un sorte au balcon.

- *Je sors* → {"peuple": 8, "armee": -5, "presse": 3}
- *Un communiqué* → {"peuple": -5, "armee": 4, "presse": 3}

**`objet_enceinte_disque`** — redactrice

> {titre}, on sait ce que vous écoutez le soir : le disque d'un chanteur que la censure a interdit il y a vingt ans.

- *Je l'assume* → {"peuple": 6, "armee": -6, "presse": 4}
- *Je ne dis rien* → {"presse": -5, "armee": 4, "peuple": -3}

**`objet_coffret_inventaire`** — doyen

> {titre}, le coffret du palais contient encore trois pièces qui appartiennent à l'État. L'inventaire est à faire, et il sera public.

- *On inventorie* → {"presse": 6, "peuple": 4, "armee": -5}
- *Plus tard* → {"presse": -6, "caisses": 4, "peuple": -3}

**`objet_ventilateur_photo`** — redactrice

> {titre}, une photo du bureau a paru : on y voit le ventilateur neuf au-dessus des dossiers. Le titre parle du confort du palais.

- *J'assume* → {"presse": -4, "peuple": -3, "armee": 4}
- *Je le donne* → {"presse": 5, "peuple": 4, "caisses": -2}

**`objet_fauteuil_cuir_facture`** — doyen

> {titre}, le fournisseur du fauteuil réclame son dû. Le palais l'avait reçu en cadeau : je règle la facture, ou je garde ce cadeau ?

- *Gardons le cadeau* → {"armee": 4, "presse": -4, "peuple": -3}
- *Réglez la facture* → {"caisses": -4, "presse": 5, "peuple": 3}

**`objet_jardinieres_ronds_points`** — maire

> {titre}, vos jardinières fleurissent pendant que les ronds-points de la ville sont en friche. Je demande les mêmes plants pour eux.

- *Qu'il les ait* → {"caisses": -5, "peuple": 6, "presse": 3}
- *C'est le palais* → {"peuple": -5, "presse": -3, "armee": 3}

**`objet_fauteuil_lecture_liste`** — redactrice

> {titre}, on raconte que vous lisez tard. Une revue veut publier la liste de ce qui traîne sur la table, à côté de votre fauteuil.

- *Qu'elle la publie* → {"presse": 6, "armee": -4, "peuple": 3}
- *C'est ma chambre* → {"presse": -5, "peuple": -3, "armee": 4}

**`objet_miroir_protocole`** — cabinet

> {titre}, le protocole a fait poser le miroir en pied dans votre chambre. Il demande maintenant qui vous habille pour les cérémonies.

- *Le protocole* → {"caisses": -4, "armee": 4, "presse": -3}
- *Personne* → {"peuple": 5, "presse": 3, "armee": -3}

**`objet_transats_couverture`** — marchande

> {titre}, une photo des transats du palais est passée en couverture, à côté du prix du sac de riz. La légende tient en deux mots.

- *Je l'ignore* → {"presse": -5, "peuple": -4, "armee": 4}
- *J'ouvre le bassin* → {"peuple": 7, "armee": -5, "caisses": -3}

**`objet_plongeoir_federation`** — sante

> {titre}, le plongeoir du palais est le seul du pays aux normes. La fédération veut y entraîner ses plongeurs deux fois par semaine.

- *Qu'ils viennent* → {"peuple": 6, "caisses": -3, "armee": -3}
- *C'est chez moi* → {"peuple": -5, "armee": 3, "presse": -3}

```json
[
 {
  "id": "objet_poste_radio_station",
  "personnage": "renseignements",
  "humeur": "neutre",
  "texte": "{titre}, votre poste à ondes courtes donne chaque soir une station qui compte nos morts et nos grèves. Elle émet de chez le voisin.",
  "gauche": {
   "libelle": "On la brouille",
   "effets": {
    "presse": -7,
    "armee": 6,
    "caisses": -3
   },
   "journal": "Le brouillage a commencé jeudi soir. Deux stations de musique du pays ont disparu de la bande à la même heure."
  },
  "droite": {
   "libelle": "On l'écoute",
   "effets": {
    "presse": 5,
    "peuple": -4,
    "armee": -4
   },
   "journal": "La station a été citée nommément au conseil des ministres. Son audience a doublé dans la semaine qui a suivi."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_poste_radio"
   ]
  }
 },
 {
  "id": "objet_telephone_rouge_nuit",
  "personnage": "general",
  "humeur": "fache",
  "texte": "{titre}, le téléphone rouge a sonné à quatre heures. Le voisin dit qu'un de nos convois a franchi sa frontière, et il attend.",
  "gauche": {
   "libelle": "Je lui parle",
   "effets": {
    "armee": -5,
    "presse": 6,
    "peuple": 3
   },
   "journal": "L'appel a duré dix-neuf minutes. Le convoi est rentré avant l'aube, et aucun communiqué n'a parlé d'incident."
  },
  "droite": {
   "libelle": "Je laisse sonner",
   "effets": {
    "armee": 6,
    "presse": -5,
    "peuple": -4
   },
   "journal": "La ligne a sonné trois nuits de suite. Le quatrième jour, le voisin a fermé son poste-frontière du nord."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_telephone_rouge"
   ]
  }
 },
 {
  "id": "objet_climatiseur_groupe",
  "personnage": "cabinet",
  "humeur": "neutre",
  "texte": "{titre}, le climatiseur du bureau tire sur le groupe du quartier. Trois heures de coupure : chez eux, ou ici.",
  "gauche": {
   "libelle": "Chez eux",
   "effets": {
    "peuple": -8,
    "presse": -4,
    "armee": 3
   },
   "journal": "Le quartier a été coupé de treize à seize heures. Les fenêtres du palais sont restées fermées, et fraîches."
  },
  "droite": {
   "libelle": "Ici",
   "effets": {
    "peuple": 6,
    "presse": 4,
    "caisses": -4
   },
   "journal": "Le palais a coupé la climatisation aux heures chaudes. Deux conseillers ont demandé à travailler depuis chez eux."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_climatiseur"
   ]
  }
 },
 {
  "id": "objet_pupitre_allocution",
  "personnage": "cabinet",
  "humeur": "neutre",
  "texte": "{titre}, le pupitre est prêt pour parler du budget. Dix minutes en direct ce soir, sans qu'aucune rédaction ne vous coupe.",
  "gauche": {
   "libelle": "Je parle ce soir",
   "effets": {
    "peuple": 7,
    "presse": -5,
    "armee": 3
   },
   "journal": "L'allocution a duré douze minutes. Deux stations l'ont reprise en entier, une troisième l'a commentée avant la fin."
  },
  "droite": {
   "libelle": "Pas ce soir",
   "effets": {
    "presse": 5,
    "peuple": -5,
    "caisses": 3
   },
   "journal": "Le créneau est resté vide. Une radio privée l'a occupé avec un débat sur le même sujet, à la même heure."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_pupitre"
   ]
  }
 },
 {
  "id": "objet_sono_place",
  "personnage": "maire",
  "humeur": "neutre",
  "texte": "{titre}, la place est pleine et la sono porte jusqu'au carrefour. Ils attendent depuis deux heures que quelqu'un sorte au balcon.",
  "gauche": {
   "libelle": "Je sors",
   "effets": {
    "peuple": 8,
    "armee": -5,
    "presse": 3
   },
   "journal": "Le balcon s'est ouvert à dix-huit heures. La place a repris la dernière phrase deux fois, puis s'est vidée d'elle-même."
  },
  "droite": {
   "libelle": "Un communiqué",
   "effets": {
    "peuple": -5,
    "armee": 4,
    "presse": 3
   },
   "journal": "Le communiqué a été lu par un porte-parole, à la sono, devant une place qui se clairsemait déjà."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_sono"
   ]
  }
 },
 {
  "id": "objet_enceinte_disque",
  "personnage": "redactrice",
  "humeur": "content",
  "texte": "{titre}, on sait ce que vous écoutez le soir : le disque d'un chanteur que la censure a interdit il y a vingt ans.",
  "gauche": {
   "libelle": "Je l'assume",
   "effets": {
    "peuple": 6,
    "armee": -6,
    "presse": 4
   },
   "journal": "Le palais a confirmé. Le disque s'est vendu comme jamais, et le chanteur est passé à la radio nationale le dimanche."
  },
  "droite": {
   "libelle": "Je ne dis rien",
   "effets": {
    "presse": -5,
    "armee": 4,
    "peuple": -3
   },
   "journal": "Le palais n'a pas répondu. Le disque circule en copie, avec « écouté en haut lieu » écrit à la main sur les pochettes."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_enceinte"
   ]
  }
 },
 {
  "id": "objet_coffret_inventaire",
  "personnage": "doyen",
  "humeur": "neutre",
  "texte": "{titre}, le coffret du palais contient encore trois pièces qui appartiennent à l'État. L'inventaire est à faire, et il sera public.",
  "gauche": {
   "libelle": "On inventorie",
   "effets": {
    "presse": 6,
    "peuple": 4,
    "armee": -5
   },
   "journal": "L'inventaire a paru en annexe du budget. Les trois pièces sont parties au musée national, vitrine du fond."
  },
  "droite": {
   "libelle": "Plus tard",
   "effets": {
    "presse": -6,
    "caisses": 4,
    "peuple": -3
   },
   "journal": "L'inventaire a été reporté à la session suivante. Le greffier qui l'avait demandé a été affecté aux archives."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_coffret"
   ]
  }
 },
 {
  "id": "objet_ventilateur_photo",
  "personnage": "redactrice",
  "humeur": "neutre",
  "texte": "{titre}, une photo du bureau a paru : on y voit le ventilateur neuf au-dessus des dossiers. Le titre parle du confort du palais.",
  "gauche": {
   "libelle": "J'assume",
   "effets": {
    "presse": -4,
    "peuple": -3,
    "armee": 4
   },
   "style": 5,
   "journal": "Le palais n'a pas répondu à la photo. Le journal l'a reprise le lendemain, en plus grand, avec le prix de l'appareil."
  },
  "droite": {
   "libelle": "Je le donne",
   "effets": {
    "presse": 5,
    "peuple": 4,
    "caisses": -2
   },
   "style": -4,
   "journal": "Le ventilateur a été remonté dans une classe du quartier des Palmiers. Le bureau a rouvert ses fenêtres sur la cour."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_ventilateur"
   ]
  }
 },
 {
  "id": "objet_fauteuil_cuir_facture",
  "personnage": "doyen",
  "humeur": "neutre",
  "texte": "{titre}, le fournisseur du fauteuil réclame son dû. Le palais l'avait reçu en cadeau : je règle la facture, ou je garde ce cadeau ?",
  "gauche": {
   "libelle": "Gardons le cadeau",
   "effets": {
    "armee": 4,
    "presse": -4,
    "peuple": -3
   },
   "style": 5,
   "journal": "La facture est restée au dossier, sans suite. Deux archivistes ont demandé leur mutation dans la même semaine."
  },
  "droite": {
   "libelle": "Réglez la facture",
   "effets": {
    "caisses": -4,
    "presse": 5,
    "peuple": 3
   },
   "style": -4,
   "journal": "Le fauteuil a été payé sur les deniers de la Présidence. Le reçu a été affiché à l'entrée du palais, en grand."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_fauteuil_cuir"
   ]
  }
 },
 {
  "id": "objet_jardinieres_ronds_points",
  "personnage": "maire",
  "humeur": "neutre",
  "texte": "{titre}, vos jardinières fleurissent pendant que les ronds-points de la ville sont en friche. Je demande les mêmes plants pour eux.",
  "gauche": {
   "libelle": "Qu'il les ait",
   "effets": {
    "caisses": -5,
    "peuple": 6,
    "presse": 3
   },
   "style": -4,
   "journal": "Les ronds-points ont été replantés en trois jours. Les jardiniers du palais ont fait le travail, sans heures supplémentaires."
  },
  "droite": {
   "libelle": "C'est le palais",
   "effets": {
    "peuple": -5,
    "presse": -3,
    "armee": 3
   },
   "style": 5,
   "journal": "Les jardinières du balcon ont été changées pour la saison. Au rond-point du marché, l'herbe atteint le pare-chocs."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_jardinieres"
   ]
  }
 },
 {
  "id": "objet_fauteuil_lecture_liste",
  "personnage": "redactrice",
  "humeur": "neutre",
  "texte": "{titre}, on raconte que vous lisez tard. Une revue veut publier la liste de ce qui traîne sur la table, à côté de votre fauteuil.",
  "gauche": {
   "libelle": "Qu'elle la publie",
   "effets": {
    "presse": 6,
    "armee": -4,
    "peuple": 3
   },
   "style": -5,
   "journal": "La liste a paru en page deux : sept livres, dont deux interdits sous le régime d'avant. Les libraires les ont tous vendus."
  },
  "droite": {
   "libelle": "C'est ma chambre",
   "effets": {
    "presse": -5,
    "peuple": -3,
    "armee": 4
   },
   "style": 5,
   "journal": "La revue a paru avec un encadré vide à la place de la liste. Personne n'a expliqué l'encadré, et tout le monde l'a vu."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_fauteuil_lecture"
   ]
  }
 },
 {
  "id": "objet_miroir_protocole",
  "personnage": "cabinet",
  "humeur": "neutre",
  "texte": "{titre}, le protocole a fait poser le miroir en pied dans votre chambre. Il demande maintenant qui vous habille pour les cérémonies.",
  "gauche": {
   "libelle": "Le protocole",
   "effets": {
    "caisses": -4,
    "armee": 4,
    "presse": -3
   },
   "style": 5,
   "journal": "Le protocole a engagé deux habilleuses et un tailleur. La note du mois a été réglée par le budget des réceptions."
  },
  "droite": {
   "libelle": "Personne",
   "effets": {
    "peuple": 5,
    "presse": 3,
    "armee": -3
   },
   "style": -4,
   "journal": "Le protocole s'est incliné. À la cérémonie du port, la tenue n'était pas neuve, et trois journaux l'ont remarqué."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_miroir"
   ]
  }
 },
 {
  "id": "objet_transats_couverture",
  "personnage": "marchande",
  "humeur": "fache",
  "texte": "{titre}, une photo des transats du palais est passée en couverture, à côté du prix du sac de riz. La légende tient en deux mots.",
  "gauche": {
   "libelle": "Je l'ignore",
   "effets": {
    "presse": -5,
    "peuple": -4,
    "armee": 4
   },
   "style": 5,
   "journal": "La couverture est restée affichée chez les vendeuses du marché pendant une semaine, à côté de la pancarte des prix."
  },
  "droite": {
   "libelle": "J'ouvre le bassin",
   "effets": {
    "peuple": 7,
    "armee": -5,
    "caisses": -3
   },
   "style": -5,
   "journal": "Le bassin a reçu les écoles du quartier de la Cuvette le samedi. La garde a demandé deux hommes de plus à l'entrée."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_transats"
   ]
  }
 },
 {
  "id": "objet_plongeoir_federation",
  "personnage": "sante",
  "humeur": "neutre",
  "texte": "{titre}, le plongeoir du palais est le seul du pays aux normes. La fédération veut y entraîner ses plongeurs deux fois par semaine.",
  "gauche": {
   "libelle": "Qu'ils viennent",
   "effets": {
    "peuple": 6,
    "caisses": -3,
    "armee": -3
   },
   "style": -4,
   "journal": "Douze plongeurs s'entraînent au palais le mardi et le jeudi. Le plus jeune a réussi son premier double saut devant la garde."
  },
  "droite": {
   "libelle": "C'est chez moi",
   "effets": {
    "peuple": -5,
    "armee": 3,
    "presse": -3
   },
   "style": 5,
   "journal": "Les plongeurs sont retournés au bassin du port, dont le tremplin est fendu. Leur demande a été classée sans réponse."
  },
  "poids": 5,
  "conditions": {
   "drapeaux_requis": [
    "objet_plongeoir"
   ]
  }
 }
]
```

---

## L'exploit

**La bibliothèque pleine** — Acheter la bibliothèque, et atteindre un quatrième mandat : elle se remplit d'un livre par mandat joué.

```json
[
 {
  "id": "bibliotheque_pleine",
  "titre": "La bibliothèque pleine",
  "description": "Acheter la bibliothèque, et atteindre un quatrième mandat : elle se remplit d'un livre par mandat joué.",
  "condition": {
   "mandat_min": 4,
   "drapeaux_requis": [
    "objet_bibliotheque"
   ]
  }
 }
]
```

---

## La fin

**Derrière la baie**

> Les blindés sont entrés à l'aube. Vous êtes resté au bureau, derrière le vitrage, et c'est par la porte qu'ils ont fini par passer, quatre heures plus tard. Le pays a eu le temps de voir.

```json
[
 {
  "id": "armee_bas_vitrage",
  "jauge": "armee",
  "vers_le_haut": false,
  "titre": "Derrière la baie",
  "texte": "Les blindés sont entrés à l'aube. Vous êtes resté au bureau, derrière le vitrage, et c'est par la porte qu'ils ont fini par passer, quatre heures plus tard. Le pays a eu le temps de voir.",
  "image": "fins/coup.jpg",
  "drapeaux_requis": [
   "objet_vitrage"
  ]
 }
]
```
