# Président pour 100 jours

Un jeu de cartes façon Reigns : vous êtes président d'un pays d'Afrique de
l'Ouest imaginaire. Chaque jour, une carte, glissée à gauche ou à droite.
Quatre jauges — peuple, armée, caisses, presse — tuent à 0 comme à 100, et
une élection vous attend au jour 30.

## Lancer le jeu

```
flutter run
```

## Lancer les tests

```
flutter test
```

## Le contenu

Tout le texte du jeu vit dans `assets/contenu/`, en quatre fichiers JSON :
`cartes.json`, `personnages.json`, `parcours.json` et `fins.json`.

## Page de relecture

Pour fabriquer une page HTML qui rassemble le contenu, les chaînes et
l'équilibrage :

```
flutter test outils/relecture.dart
```

La page est écrite dans `.tmp/relecture.html`.
