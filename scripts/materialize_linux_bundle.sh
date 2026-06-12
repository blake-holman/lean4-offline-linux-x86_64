#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEAN_VERSION="4.30.0"
ASSET="lean-${LEAN_VERSION}-linux.tar.zst"
URL="https://github.com/leanprover/lean4/releases/download/v${LEAN_VERSION}/${ASSET}"

cd "$ROOT"

rm -rf vendor/lean
mkdir -p vendor

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -L --retry 5 --retry-delay 2 -o "$tmp/$ASSET" "$URL"
tar --use-compress-program=unzstd -xf "$tmp/$ASSET" -C "$tmp"
mv "$tmp/lean-${LEAN_VERSION}-linux" vendor/lean

chmod -R u+rwX,go+rX vendor/lean
chmod +x vendor/lean/bin/*

export PATH="$ROOT/vendor/lean/bin:$PATH"
export LEAN_SYSROOT="$ROOT/vendor/lean"

vendor/lean/bin/lean --version
vendor/lean/bin/lake --version

lake update
lake exe cache get
lake build +BundleImports:olean +OfflineBundle.Smoke:olean
lake env lean test/OfflineSmoke.lean
