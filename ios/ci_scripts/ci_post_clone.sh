#!/bin/sh
# Xcode Cloud — préparation d'un projet Flutter sans génération de code.
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.3}"
FLUTTER_DIR="$HOME/flutter"

echo "▸ Flutter $FLUTTER_VERSION"
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version
flutter precache --ios

cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "▸ Dépendances"
flutter pub get

echo "▸ Configuration iOS"
flutter build ios --release --no-codesign --config-only --build-number="${CI_BUILD_NUMBER:-1}"

echo "▸ CocoaPods"
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods >/dev/null 2>&1 || true
cd ios
pod install
