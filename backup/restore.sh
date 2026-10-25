#!/usr/bin/env bash
# restore.sh – re-enable all packages disabled during the debloat session
# Generated automatically; edit the list below if you manually changed things.
# Usage: ./backup/restore.sh
set -euo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/tools/tv.py"

re_enable() {
  local pkg="$1"
  echo -n "Re-enabling $pkg ... "
  python3 "$SCRIPT" "pm enable --user 0 $pkg" && echo "OK" || echo "SKIPPED (may already be enabled)"
}

# ── Packages disabled during debloat session ──────────────────────────────────
# (This list will be populated after the debloat step)
# re_enable com.example.bloatware

# ── Stock launcher (re-enable if you want to go back) ────────────────────────
# re_enable com.oneplus.launcher    # OnePlus stock launcher

echo ""
echo "Restore complete. Reboot the TV to apply:"
python3 "$SCRIPT" "reboot" || echo "(reboot command failed; reboot manually)"
