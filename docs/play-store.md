# Fiche Google Play — Palabre

Textes et réponses à copier dans la Play Console. Identifiant : `sn.palabre.app`. Catégorie : Actualités et magazines. Gratuite, sans achat intégré, sans publicité.

## Fiche (français)

**Nom** : Palabre

**Description courte** (80 caractères max) :
La vie politique de votre pays, sans opinion, avec les sources.

**Description complète** :

Palabre présente la vie politique de votre pays de façon neutre : pas de score, pas de classement, aucune opinion. Chaque fait affiché renvoie à sa source.

• Question de la semaine : un fait d'actualité, une question neutre, des résultats agrégés une fois le vote fermé.
• Testez-vous : 25 affirmations sur les grands débats du pays. Votre concordance avec ce que chaque parti a écrit, citation et page à l'appui. Quand un parti n'a rien écrit, l'app le dit : rien n'est extrapolé. Le calcul se fait sur votre téléphone et n'est jamais envoyé.
• Gouvernement : qui occupe quel poste aujourd'hui, avec l'acte de nomination.
• Assemblée : la liste des députés en exercice, leur circonscription, leur groupe, les remplacements, d'après la décision officielle de proclamation.

Pays couverts : Sénégal, Bénin, Côte d'Ivoire, Togo.

Aucun compte, aucune adresse e-mail, aucune publicité, aucun suivi. Pays, tranche d'âge et région sont facultatifs et ne servent qu'à découper les résultats des sondages, jamais en dessous de 30 répondants.

## Liens

- Politique de confidentialité : https://teiki5320.github.io/palabre/site/confidentialite.html
- Site : https://teiki5320.github.io/palabre/site/
- Contact : github.com/teiki5320/palabre/issues (adresse e-mail de contact obligatoire dans la console : la tienne)

## Sécurité des données (formulaire « Data safety »)

| Question | Réponse |
|---|---|
| L'app collecte ou partage des données utilisateur ? | Oui (collecte), pas de partage |
| Données chiffrées en transit ? | Oui (HTTPS) |
| L'utilisateur peut demander la suppression ? | Oui (via le contact) |
| Localisation approximative | Collectée, facultative, fonctionnalité de l'app (région administrative choisie par l'utilisateur, pas de GPS) |
| Informations personnelles | Aucune (pas de nom, e-mail, téléphone) |
| Infos démographiques : tranche d'âge | Collectée, facultative, fonctionnalité (découpe des résultats) |
| Messages / contenu utilisateur : réponses aux sondages | Collectées, facultatives, fonctionnalité, reliées à un identifiant anonyme |
| Identifiants d'appareil : jeton de notification | Collecté, facultatif, fonctionnalité (notifications) |
| Historique de navigation, contacts, photos, fichiers, santé, finances | Non collectés |
| Analyse d'audience, publicité | Non |

## Classification du contenu

Questionnaire IARC : aucune violence, aucun contenu sexuel, pas de jeux d'argent, pas d'achats, interaction entre utilisateurs : non (les votes sont anonymes et agrégés). Résultat attendu : Tous publics / PEGI 3.

## Accès à l'app

Aucune connexion requise : cocher « Toutes les fonctionnalités sont accessibles sans identifiants ».

## Publicités

Aucune.

## Actualités

L'app affiche des informations d'actualité : déclarer « application d'actualités », avec les sources citées dans l'app et la page de confidentialité.

## Éléments graphiques

- Icône 512 × 512 : `icone-512.png` (généré depuis `assets/icon/icon.png`).
- Bannière 1024 × 500 : `banniere-1024x500.png`.
- Captures d'écran téléphone : au moins 2, format 16:9 ou 9:16, 320 à 3840 px (captures de l'émulateur Pixel 7 ou d'un téléphone).

## Fichier à envoyer

`build/app/outputs/bundle/release/app-release.aab`, signé avec la clé de téléversement `android/app/upload-keystore.jks` (mot de passe dans le trousseau macOS « Palabre Android upload keystore »). Activer Play App Signing à la première mise en ligne. Version : `version` dans pubspec.yaml (0.2.0+1 → versionName 0.2.0, versionCode 1) ; incrémenter le `+N` à chaque envoi.

## Parcours conseillé

1. Créer l'app dans la console, remplir la fiche, la confidentialité, la sécurité des données, la classification.
2. Test interne : envoyer l'AAB, ajouter tes testeurs par e-mail, lien d'installation immédiat.
3. Test fermé : Google exige, pour un compte personnel, 12 testeurs pendant 14 jours avant de demander l'accès à la production.
4. Production.
