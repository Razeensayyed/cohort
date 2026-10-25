#!/usr/bin/env bash
# disable.sh – safely disable a list of packages via pm disable-user
# Usage: ./tools/disable.sh package1 package2 ...
# Reads from stdin if no args.
# Refuses to disable known-critical Android packages.

set -euo pipefail

FORBIDDEN=(
  com.android.shell
  com.android.systemui
  com.android.settings
  com.android.tv.settings
  android
  com.android.phone
  com.google.android.gms
  com.android.providers.media
  com.android.providers.downloads
  com.android.providers.settings
  com.android.providers.telephony
  com.google.android.permissioncontroller
  com.android.permissioncontroller
  com.android.packageinstaller
  com.google.android.packageinstaller
  com.android.ext.services
  com.android.ext.shared
  com.android.modulemetadata
  com.google.android.overlay.modules
  com.google.android.captiveportallogin
)

is_forbidden() {
  local pkg="$1"
  for f in "${FORBIDDEN[@]}"; do
    if [[ "$pkg" == "$f"* ]]; then
      return 0
    fi
  done
  return 1
}

TV_HOST="${TV_HOST:-127.0.0.1}"
TV_PORT="${TV_PORT:-15555}"

pkgs=("$@")
if [[ ${#pkgs[@]} -eq 0 ]]; then
  mapfile -t pkgs
fi

blocked=()
for pkg in "${pkgs[@]}"; do
  pkg="${pkg//[[:space:]]/}"
  [[ -z "$pkg" ]] && continue
  if is_forbidden "$pkg"; then
    blocked+=("$pkg")
  fi
done

if [[ ${#blocked[@]} -gt 0 ]]; then
  echo "REFUSED: the following packages are on the critical list and will NOT be disabled:"
  for b in "${blocked[@]}"; do echo "  $b"; done
  echo "Aborting entire batch."
  exit 1
fi

for pkg in "${pkgs[@]}"; do
  pkg="${pkg//[[:space:]]/}"
  [[ -z "$pkg" ]] && continue
  echo -n "Disabling $pkg ... "
  python3 "$(dirname "$0")/tv.py" "pm disable-user --user 0 $pkg" && echo "OK" || echo "FAILED (check manually)"
done
