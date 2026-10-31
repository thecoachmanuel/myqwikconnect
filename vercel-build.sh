#!/bin/bash
set -e

echo "============================================="
echo "  Deploying Orange Flutter Web to Vercel"
echo "============================================="

# 1. If pre-built web bundle exists in build/web, deploy it instantly
if [ -d "build/web" ] && [ -f "build/web/index.html" ] && [ -z "$FORCE_FLUTTER_REBUILD" ]; then
  echo "==> Production Flutter Web bundle detected in build/web."
  echo "==> Deploying pre-built bundle directly (instant deployment)."
  echo "============================================="
  exit 0
fi

# 2. Otherwise install Flutter SDK and build from source
echo "==> Checking for Flutter SDK..."
if ! command -v flutter &> /dev/null; then
  echo "==> Flutter not found in PATH. Checking cache or installing..."
  FLUTTER_DIR="$HOME/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    echo "==> Cloning Flutter SDK (stable branch)..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
  fi
  export PATH="$PATH:$FLUTTER_DIR/bin"
fi

echo "==> Flutter version:"
flutter --version

echo "==> Enabling Flutter Web support..."
flutter config --enable-web --no-analytics

echo "==> Resolving Flutter dependencies..."
flutter pub get

BUILD_ARGS="--release --no-tree-shake-icons"
if [ -n "$BACKEND_URL" ]; then
  echo "==> Custom BACKEND_URL detected: $BACKEND_URL"
  BUILD_ARGS="$BUILD_ARGS --dart-define=BACKEND_URL=$BACKEND_URL"
fi

echo "==> Compiling Flutter Web bundle ($BUILD_ARGS)..."
flutter build web $BUILD_ARGS

echo "============================================="
echo "  Flutter Web release build complete!"
echo "  Output directory: build/web"
echo "============================================="
