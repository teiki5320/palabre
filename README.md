# Président pour 100 jours

Un jeu de cartes façon Reigns : vous êtes président d'un pays d'Afrique de
l'Ouest imaginaire. Chaque jour, une carte, glissée à gauche ou à droite.
Quatre jauges — peuple, armée, caisses, presse — tuent à 0 comme à 100, et
une élection vous attend au jour 100.

Rien de réel n'y est nommé : ni pays, ni ville, ni monnaie, ni institution.
Le décor est inventé de bout en bout.

## Lancer le jeu

```
flutter run
```

## Lancer les tests

```
flutter test
```

`flutter analyze` doit rester silencieux. Les deux tournent à chaque poussée
sur `main` (`.github/workflows/ci.yml`).

## Le contenu

Tout le texte du jeu vit dans `assets/contenu/`, en huit fichiers JSON :

| Fichier | Ce qu'il tient |
|---|---|
| `cartes.json` | les cartes, leurs deux réponses, leurs effets et leurs chaînes |
| `personnages.json` | qui parle, et ses trois humeurs |
| `parcours.json` | les départs de partie |
| `fins.json` | les dénouements |
| `exploits.json` | ce qui se débloque d'un mandat à l'autre |
| `objets.json` | ce qui s'achète au palais |
| `adversaires.json` | qui se présente contre vous au jour 100 |
| `chambre.json` | ce qui se dit dans la chambre |

Le moteur (`lib/moteur/`) est du Dart pur, sans aucun import Flutter : les
règles se testent et se simulent sans écran. `lib/contenu/validation.dart`
refuse un contenu mal formé au chargement — longueur des textes, chaînes
sans maillon, fins qui se disputent un cas.

Rien ne part sur le réseau. L'application n'a aucun client HTTP, ne déclare
aucune permission Android, et garde la partie sur l'appareil avec
`shared_preferences`.

## Les outils d'atelier

Ils vivent dans `outils/` et ne sont pas embarqués dans l'application.

```
python3 outils/audit_cartes.py          # les contrôles que le moteur ne peut pas faire
python3 outils/planche_relecture.py     # une page HTML pour relire les cartes une par une
python3 outils/planche_jeu.py           # le jeu entier : cartes, histoires, images, décors
flutter test outils/mesure_par_histoire.dart   # mille mandats, taux d'achèvement par histoire
```

Les pages fabriquées sont écrites dans `sources/`, qui n'est pas versionné.

## Les fiches du tableau de bord

- [docs/INFRA.md](docs/INFRA.md) — la fiche technique
- [docs/MARKETING.md](docs/MARKETING.md) — positionnement et rémunération
- [docs/PUBLICATION.md](docs/PUBLICATION.md) — l'état des deux boutiques
- [docs/BOUTIQUE.md](docs/BOUTIQUE.md) — les textes de fiche et les réponses aux questionnaires
