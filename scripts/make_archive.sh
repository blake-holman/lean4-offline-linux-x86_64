#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${BUNDLE_NAME:-lean4-offline-linux-x86_64}"
DIST="$ROOT/dist"
ARCHIVE="$DIST/$NAME.tar.gz"

mkdir -p "$DIST"
rm -f "$ARCHIVE"

tar \
  --exclude="$NAME/.git" \
  --exclude='dist' \
  --exclude='tmp' \
  -C "$(dirname "$ROOT")" \
  -czf "$ARCHIVE" \
  "$NAME"

echo "$ARCHIVE"
