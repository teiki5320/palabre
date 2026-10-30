#!/bin/sh
# Xcode Cloud — préparation d'un projet Flutter sans génération de code.
#
# Xcode Cloud coupe un script qui n'écrit rien pendant un quart d'heure. Ce
# script a deux étapes qui peuvent dépasser ce délai sans rien dire — le
# téléchargement de Flutter et l'installation de CocoaPods — et c'est ce qui
# a tué la build 172 du 28 octobre 2026. Chacune tourne donc sous `bat`, qui
# écrit une ligne par minute tant que la commande travaille. Plus rien ici
# n'est muet, et rien n'est redirigé vers /dev/null.
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.3}"
FLUTTER_DIR="$HOME/flutter"

# Fait battre le cœur pendant une commande longue : une ligne par minute,
# pour que le service voie que le script est vivant. Rend le code de sortie
# de la commande, et le `set -e` du dessus s'en charge.
bat() {
  etiquette="$1"
  shift
  ( while true; do sleep 60; echo "  … $etiquette, toujours en cours"; done ) &
  pouls=$!
  # On récolte le code nous-mêmes plutôt que de laisser `set -e` couper ici :
  # sinon l'échec saute l'arrêt du pouls, qui continue de battre quelques
  # secondes après la dernière ligne du journal — de quoi lire l'erreur de
  # travers au moment où l'on en a le plus besoin.
  issue=0
  "$@" || issue=$?
  kill "$pouls" 2>/dev/null || true
  wait "$pouls" 2>/dev/null || true
  if [ "$issue" -ne 0 ]; then
    echo "✖ $etiquette : échec (code $issue)"
    exit "$issue"
  fi
}

echo "▸ Flutter $FLUTTER_VERSION"
bat "téléchargement de Flutter" \
  git clone --depth 1 --branch "$FLUTTER_VERSION" --progress \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
bat "préparation des outils iOS" flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "▸ Dépendances"
bat "récupération des paquets" flutter pub get

echo "▸ Configuration iOS"
flutter build ios --release --no-codesign --config-only --build-number="${CI_BUILD_NUMBER:-1}"

echo "▸ CocoaPods"
# L'image de Xcode Cloud fournit CocoaPods : on ne l'installe que s'il manque
# vraiment, et jamais par Homebrew, qui peut partir compiler pendant un quart
# d'heure. `gem install` est une poignée de secondes.
if pod --version; then
  echo "  CocoaPods est déjà là"
else
  echo "  CocoaPods manque, installation"
  bat "installation de CocoaPods" gem install cocoapods --no-document
fi
cd ios
bat "résolution des pods" pod install
