# Écrire des cartes pour Palabre

Consigne durable. Toute personne — humaine ou non — qui écrit des cartes lit
ce document d'abord.

## Le jeu en trois phrases

Vous êtes président d'un pays d'Afrique de l'Ouest **qui n'est nommé nulle
part et n'existe pas**. Chaque jour, quelqu'un entre dans votre bureau avec un
problème et deux issues. Vous glissez sa carte à gauche ou à droite, et quatre
jauges bougent.

## Les quatre jauges

| Jauge | Ce qu'elle mesure | Elle tombe à 0 | Elle monte à 100 |
|---|---|---|---|
| `peuple` | ce que la rue pense de vous | l'avenue vous chasse | on vous croit providentiel, puis on vous en veut |
| `armee` | ce que la caserne pense de vous | le palais est pris | l'armée gouverne à votre place |
| `caisses` | l'état des finances | les guichets ferment | un trésor et plus rien d'autre |
| `presse` | ce qu'on écrit sur vous | démoli en première page | plus personne ne vous informe |

**Les deux bouts tuent.** Une carte qui ne fait que du bien est une mauvaise
carte : toute réponse doit coûter quelque chose à quelqu'un.

## Le ton

Fond sérieux, personnages hauts en couleur, absurde occasionnel. On ne
ricane pas de l'Afrique de l'Ouest : on écrit une politique réelle, avec ses
arbitrages impossibles, ses fidélités encombrantes et ses petites lâchetés.
Le comique vient de la situation, jamais de la caricature.

Le joueur est vouvoyé et appelé `{titre}` (« Monsieur le Président » ou
« Madame la Présidente ») ; `{nom}` est le nom qu'il s'est donné. Les deux
marques sont remplacées à l'affichage.

## Ce qu'on n'écrit jamais

Aucun pays, ville, monnaie, institution ou personnalité réels. Le contrôle
automatique refuse entre autres : les noms de pays d'Afrique de l'Ouest, la
France, Paris, le FMI, la Banque mondiale, l'ONU, l'Union africaine, la
CEDEAO, l'Union européenne, le franc CFA, la BCEAO, l'UEMOA, et les grandes
villes de la région. Écrivez « la capitale », « le nord », « les bailleurs »,
« la monnaie ».

Pas de religion nommée, pas d'ethnie nommée, pas de parti réel.

## La forme d'une carte

```json
{
  "id": "douane_port_nuit",
  "personnage": "ministre",
  "humeur": "fache",
  "texte": "{titre}, le port travaille la nuit sans que rien n'entre dans les caisses. Je peux envoyer quelqu'un. Il ne reviendra pas content.",
  "gauche": {"libelle": "Envoyez-le", "effets": {"caisses": 8, "armee": -6}},
  "droite": {"libelle": "Laissez le port", "effets": {"caisses": -5, "peuple": 3}}
}
```

### Les règles que le contrôle automatique vérifie

- `id` : unique, sans accent, en minuscules, mots séparés par `_`.
- `personnage` : un identifiant de `assets/contenu/personnages.json`.
- `humeur` : `neutre`, `fache` ou `content`. Toujours renseignée, et choisie
  pour la carte — un ministre qui annonce une bonne nouvelle est `content`.
- `texte` : **150 caractères au plus une fois `{titre}` remplacé** par
  « Madame la Présidente », qui en vaut vingt. Deux phrases au plus.
- `libelle` : **18 caractères au plus.** C'est un verbe ou un groupe court,
  pas une phrase. Les deux libellés d'une carte doivent s'opposer clairement.
- `effets` : de 1 à 3 jauges par réponse, valeurs entre −20 et 20, jamais 0.
  Les deux réponses doivent avoir des effets, et des effets différents.
- `style` (facultatif) : de −10 à 10, **seulement si la carte parle du
  régime**. La plupart des cartes n'en ont pas.

  **Le signe se trompe facilement, alors lisez ce tableau avant d'en écrire un.**
  L'axe va de 0 (république) à 100 (dictature). Un `style` **positif pousse vers
  la dictature**, un `style` **négatif ramène vers la république**.

  | Ce que fait la réponse | Signe | Exemple |
  |---|---|---|
  | museler, censurer, saisir, bloquer | **positif** | « Saisie du tirage » `+8` |
  | écouter, surveiller, ficher | **positif** | « Écoutez » `+10` |
  | enterrer une affaire, protéger un proche | **positif** | « Dossier fermé » `+8` |
  | truquer, maquiller, démentir un fait vrai | **positif** | « On maquille » `+8` |
  | laisser publier, laisser parler, laisser manifester | **négatif** | « Qu'il publie » `−6` |
  | laisser un juge juger, rouvrir une affaire | **négatif** | « Qu'on le juge » `−8` |
  | rendre des comptes, accepter un contrôle | **négatif** | « J'y vais » `−6` |
  | dire la vérité quand elle coûte | **négatif** | « Le vrai chiffre » `−6` |

  Vérification de bon sens : **si la réponse ferait plaisir à un dictateur, le
  signe est positif.** Deux rédacteurs sur six se sont trompés sur ce point ;
  relisez chacune de vos cartes à style avec cette phrase en tête.

### Champs facultatifs

- `poids` : 3 pour une carte qu'on veut voir souvent, 1 par défaut.
- `repetable` : `true` pour une carte qui peut revenir dans le même mandat.
- `conditions` : `jour_min`, `jour_max`, `mandat_min`, `parcours`,
  `peuple_min`, `peuple_max` (idem pour les autres jauges), `style_min`,
  `style_max`, `drapeaux_requis`, `drapeaux_interdits`.
- `chaine` : `{"id": "affaire_x", "rang": 1, "delai_min": 3}` pour une
  histoire en plusieurs cartes. Les rangs se suivent sans trou.
- `drapeaux` sur une réponse : une marque que d'autres cartes exigeront.

## Ce qui fait une bonne carte

1. **Un vrai dilemme.** Si une réponse est évidemment meilleure, la carte est
   ratée. Les deux doivent faire mal quelque part.
2. **Une voix.** Le ministre des Finances ne parle pas comme la marchande. On
   doit reconnaître qui parle sans lire son titre.
3. **Du concret.** « Les infrastructures sont insuffisantes » ne vaut rien.
   « Le pont du marché est fermé depuis un an, les camions font le tour par le
   fleuve » vaut quelque chose.
4. **Un coût différé quand c'est possible.** Les meilleures cartes se paient
   trois jours plus tard, par une chaîne.
5. **Pas de morale.** Le jeu ne dit jamais au joueur qu'il a bien ou mal fait.

## Vérifier son travail

```bash
flutter test test/contenu/
```

Le contrôle du contenu refuse une carte mal formée et dit pourquoi. Aucune
carte n'entre dans le jeu sans passer ce test.

## Ce que l'autorité achète (doctrine du régime, septembre 2026)

Mesure faite sur le sac livré : la réponse autoritaire valait en moyenne
−5,4 au total des jauges, la républicaine +3,4, et l'autoritaire n'était la
moins chère que dans 15 cas sur 160. Autrement dit la dictature était une
amende, pas un chemin — la moitié de l'axe ne servait qu'à perdre. Ce qui
suit corrige ce déséquilibre. **Il ne s'agit pas de rendre la dictature
bonne, mais de la rendre chère autrement.**

### L'autorité achète trois choses, et les paie en presse

1. **De l'ordre.** Quand le désordre est dans la carte — émeute, grève
   sauvage, pillage, barrage bloqué, rumeur qui enfle — la réponse ferme
   **gagne du peuple**, pas l'inverse : une partie du pays veut qu'on
   calme la rue, et le dit. Ne faites perdre du peuple à la répression que
   lorsqu'elle frappe des gens qu'on reconnaît (un quartier, des femmes du
   marché, des étudiants nommés). Réprimer l'anonyme rassure ; réprimer le
   voisin révolte.
2. **De l'argent.** Saisir, confisquer, taxer sans passer par l'Assemblée,
   classer un audit, reprendre une concession, cesser d'indemniser : la
   voie autoritaire est la voie riche. C'est elle qui doit remplir les
   caisses quand la voie régulière les vide.
3. **Du temps.** Décider sans consulter fait avancer le chantier, la
   route, la loi. Consulter coûte des jours et de l'argent.

Ce qu'elle paie, toujours : **la presse**, et souvent l'extérieur (les
bailleurs, les voisins). C'est le prix unique et lisible de l'autorité.

### Et la liberté coûte, elle aussi

Une réponse républicaine n'est pas gratuite. Elle doit perdre quelque part :
- **laisser publier, laisser parler** fâche la caserne (l'officier se sent
  exposé) ;
- **laisser un juge juger** coûte des caisses (indemnités, procédures) et
  de l'armée quand l'accusé porte l'uniforme ;
- **consulter, concerter, respecter la procédure** coûte des caisses et
  laisse le désordre durer un peu : le peuple s'impatiente ;
- **rendre des comptes** coûte du peuple quand les comptes sont mauvais.

### La règle chiffrée

Sur une carte qui oppose une réponse autoritaire à une réponse
républicaine, les deux totaux doivent rester **à cinq points l'un de
l'autre**. Si l'autoritaire fait −8, la républicaine ne fait pas +6 : elle
fait −4 ou −3. L'un n'est jamais le bon choix et l'autre le mauvais ; ce
sont deux façons de payer.
