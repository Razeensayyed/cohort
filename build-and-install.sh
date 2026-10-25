#!/usr/bin/env bash
# build-and-install.sh – build the launcher APK and sideload it to the TV
# Usage: ./build-and-install.sh
# Env: TV_HOST (default 127.0.0.1), TV_PORT (default 15555)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER_DIR="$SCRIPT_DIR/launcher"
APK_OUT="$LAUNCHER_DIR/app/build/outputs/apk/debug/app-debug.apk"

echo "=== Building launcher APK ==="
cd "$LAUNCHER_DIR"
if [[ ! -f "./gradlew" ]]; then
  echo "ERROR: gradlew not found. Run 'gradle wrapper' in $LAUNCHER_DIR first."
  exit 1
fi
./gradlew assembleDebug

echo ""
echo "=== APK built: $APK_OUT ==="
ls -lh "$APK_OUT"

echo ""
echo "=== Pushing APK to TV ==="
cd "$SCRIPT_DIR"
python3 tools/tv.py --push "$APK_OUT" /data/local/tmp/launcher.apk

echo ""
echo "=== Installing (pm install) ==="
python3 tools/tv.py "pm install -r /data/local/tmp/launcher.apk"

echo ""
echo "=== Setting as default Home ==="
python3 tools/tv.py "cmd package set-home-activity com.cohort.launcher/.MainActivity"

echo ""
echo "=== Verifying Home activity ==="
python3 tools/tv.py "dumpsys activity activities | grep mFocusedApp" || true
python3 tools/tv.py "cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME"

echo ""
echo "=== Taking screenshot ==="
mkdir -p "$SCRIPT_DIR/shots"
python3 tools/tv.py --screenshot "$SCRIPT_DIR/shots/after-install.png"

echo ""
echo "Done. Check shots/after-install.png"
