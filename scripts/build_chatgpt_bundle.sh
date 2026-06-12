#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
STAGE_NAME="${STAGE_NAME:-lean-chatgpt-bundle-linux-x86_64}"
STAGE="$DIST/$STAGE_NAME"
ARCHIVE="$DIST/$STAGE_NAME.tar.xz"
PART_SIZE="${PART_SIZE:-480M}"

cd "$ROOT"

./scripts/materialize_linux_bundle.sh

export LEAN_SYSROOT="$ROOT/vendor/lean"
export PATH="$LEAN_SYSROOT/bin:$PATH"

mkdir -p "$DIST" "$ROOT/tmp"
rm -rf "$STAGE" "$ARCHIVE" "$ARCHIVE".part.*
mkdir -p "$STAGE/vendor/lean" "$STAGE/scripts"

QUERY_DIR="$ROOT/tmp/bundle-imports.query"
rm -rf "$QUERY_DIR"
mkdir -p "$QUERY_DIR"
query_targets=(
  "+OfflineBundle.BundleImports:importInfo"
  "+OfflineBundle.BundleImports:importArts"
  "+OfflineBundle.BundleImports:importAllArts"
  "+OfflineBundle.BundleImports:setup"
  "+OfflineBundle.BundleImports:olean"
  "+OfflineBundle.Smoke:importInfo"
  "+OfflineBundle.Smoke:importArts"
  "+OfflineBundle.Smoke:importAllArts"
  "+OfflineBundle.Smoke:setup"
  "+OfflineBundle.Smoke:olean"
  "test/OfflineSmoke.lean:importInfo"
  "test/OfflineSmoke.lean:importArts"
  "test/OfflineSmoke.lean:importAllArts"
  "test/OfflineSmoke.lean:setup"
  "test/OfflineSmoke.lean:olean"
)

idx=0
for target in "${query_targets[@]}"; do
  lake query --json "$target" > "$QUERY_DIR/$idx.json"
  idx=$((idx + 1))
done

tar \
  --exclude='./src' \
  --exclude='./doc' \
  --exclude='./include' \
  --exclude='*.a' \
  --exclude='*.c' \
  --exclude='*.o' \
  --exclude='*.bc' \
  -C "$ROOT/vendor/lean" \
  -cf - . | tar -C "$STAGE/vendor/lean" -xf -

for f in \
  lean-toolchain \
  lakefile.lean \
  lake-manifest.json \
  BundleImports.lean \
  OfflineBundle.lean; do
  [ -e "$f" ] && cp -a "$f" "$STAGE/"
done

cp -a OfflineBundle test "$STAGE/"
cp -a scripts/check_file.sh scripts/lean_version.sh scripts/verify_offline_clean.sh "$STAGE/scripts/"
chmod +x "$STAGE"/scripts/*.sh "$STAGE"/vendor/lean/bin/*

python3 scripts/copy_lean_closure.py "$QUERY_DIR" "$STAGE"
python3 scripts/rewrite_lake_for_offline.py "$STAGE"

find "$STAGE/.lake/packages" -type d -name .git -prune -exec rm -rf {} + 2>/dev/null || true

"$STAGE/scripts/verify_offline_clean.sh" "$STAGE"

tar -C "$DIST" -cJf "$ARCHIVE" "$STAGE_NAME"
split -b "$PART_SIZE" -d -a 3 "$ARCHIVE" "$ARCHIVE.part."
sha256sum "$ARCHIVE" "$ARCHIVE".part.* > "$DIST/$STAGE_NAME.SHA256SUMS"

du -sh "$STAGE" "$ARCHIVE" "$ARCHIVE".part.*
echo "$ARCHIVE"
