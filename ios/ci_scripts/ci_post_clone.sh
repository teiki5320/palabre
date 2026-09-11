#!/bin/sh
# Xcode Cloud — préparation d'un projet Flutter.
#
# Variables d'environnement à définir dans le workflow Xcode Cloud :
#   SUPABASE_URL, SUPABASE_ANON_KEY   (obligatoires pour une build utilisable)
#   FLUTTER_VERSION                   (facultatif, défaut : stable)
#
# Le script installe Flutter, génère les fichiers Dart (l10n, Drift), prépare
# la configuration iOS avec les dart-defines, puis installe les pods.
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_DIR="$HOME/flutter"

echo "▸ Flutter $FLUTTER_VERSION"
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "▸ Dépendances et génération"
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

echo "▸ Configuration iOS"
# Numéro de build = numéro de build Xcode Cloud : unique et croissant, la
# version (0.1.0) reste celle de pubspec.yaml.
flutter build ios --release --no-codesign --config-only \
  --build-number="${CI_BUILD_NUMBER:-1}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=PALABRE_COUNTRY="${PALABRE_COUNTRY:-SN}"

echo "▸ CocoaPods"
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods >/dev/null 2>&1 || true
cd ios
pod install
