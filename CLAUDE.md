# Palabre — consignes pour Claude

## Fiches à jour à chaque changement (règle de Jean, 22 octobre 2026)

Le Studio de Jean affiche les fiches de ce dépôt (docs/INFRA.md, docs/MARKETING.md, docs/PUBLICATION.md) et le README. Elles doivent toujours dire la vérité d'aujourd'hui.

- Dès qu'un travail change un fait affiché par ces fiches — version envoyée ou en ligne (App Store, Google Play, site), date de mise en ligne, hébergement ou domaine, service ajouté ou retiré, code Amazon Partenaires, état AdSense ou Pinterest, monétisation, nombre de contenus publiés —, mets à jour **dans le même envoi** toutes les phrases concernées des trois fiches (En bref, Parcours, Boutiques, Vue d'ensemble, Ce qui reste…) et du README.
- Une ancienne valeur ne reste qu'au passé, datée (« la 1.0.4 a été mise en ligne le 15 octobre »).
- Ne recopie jamais de secret ni de clé dans ces fichiers.
- Chaque matin, la tâche « Fiches Mes Apps » du Studio vérifie derrière toi, compare les versions avec ce que servent réellement les boutiques et signale toute phrase fausse.

## Garde-fou de version (depuis le 10 novembre 2026)

Même mécanisme que dans Erea : Apple ferme une version approuvée à tout
nouveau build (ITMS-90186 et ITMS-90062), et chaque poussée suivante finit en
build Xcode Cloud échoué. Deux hooks git versionnés dans `.githooks/`, qui
s'appuient sur `scripts/garde-version.sh` et sur
[`version-approuvee.txt`](version-approuvee.txt) (dernière version de Palabre
approuvée par Apple ou Google, et son numéro de build).

- **`pre-commit`** : si `pubspec.yaml` porte une version égale ou plus
  ancienne que celle de `version-approuvee.txt`, ou un numéro de build qui ne
  la dépasse pas, il la monte lui-même (patch +1, build +1) **dans le même
  commit**.
- **`pre-push`** : filet de sécurité. Il refuse de pousser sur `main` un
  commit dont la version est périmée et indique la commande de correction :
  `scripts/garde-version.sh --corriger`, puis commit et nouvelle poussée.

**À faire une fois par clone** : `scripts/installer-hooks.sh` (règle
`core.hooksPath` sur `.githooks`).

**Le déclencheur est `version-approuvee.txt`** : le hook ne sait pas qu'Apple
a approuvé une version, il faut le lui dire. **Quand une version est
approuvée (ou publiée sur Google Play), mets ce fichier à jour dans le même
commit que les fiches** : le hook monte alors la version dans ce commit. Après
une montée automatique, saisis la nouvelle version dans App Store Connect
avant de soumettre : elle doit être identique à celle de `pubspec.yaml`.

*État au 10 novembre 2026 : aucune version approuvée ni publiée, `version-approuvee.txt` vaut `0.0.0` et le garde-fou ne monte donc rien pour l'instant.*

Limites : les hooks tournent sur la machine qui commit, pas sur Xcode Cloud ni
sur l'interface web de GitHub ; `git commit --no-verify` contourne le
`pre-commit`, `git push --no-verify` le `pre-push`. Pendant un rebase, un
merge ou un cherry-pick, le `pre-commit` ne touche à rien.
