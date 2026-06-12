#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "${1:-$SCRIPT_ROOT}" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

COPY="$TMP/$(basename "$ROOT")"
EMPTY_HOME="$TMP/empty-home"
mkdir -p "$COPY" "$EMPTY_HOME"

tar \
  --exclude='./.git' \
  --exclude='dist' \
  --exclude='tmp' \
  -C "$ROOT" -cf - . | tar -C "$COPY" -xf -

echo "== clean environment versions =="
env -i HOME="$EMPTY_HOME" PATH="/usr/bin:/bin" bash -lc '
  set -euo pipefail
  cd "$1"
  ./scripts/lean_version.sh
' bash "$COPY"

echo
echo "== wrapper check =="
env -i HOME="$EMPTY_HOME" PATH="/usr/bin:/bin" bash -lc '
  set -euo pipefail
  cd "$1"
  ./scripts/check_file.sh test/OfflineSmoke.lean
' bash "$COPY"

echo
echo "== direct lake env lean check =="
env -i HOME="$EMPTY_HOME" PATH="/usr/bin:/bin" bash -lc '
  set -euo pipefail
  cd "$1"
  ./vendor/lean/bin/lake env lean test/OfflineSmoke.lean
' bash "$COPY"

echo
echo "offline clean verification succeeded"
