#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -lt 1 ]; then
  echo "usage: $0 path/to/File.lean [lean-args...]" >&2
  exit 2
fi

export LEAN_SYSROOT="$ROOT/vendor/lean"
export PATH="$LEAN_SYSROOT/bin:$PATH"

if [ ! -x "$LEAN_SYSROOT/bin/lean" ]; then
  echo "missing vendored lean at $LEAN_SYSROOT/bin/lean" >&2
  exit 1
fi

lean_paths=()
for d in "$ROOT/.lake/build/lib/lean" "$ROOT"/.lake/packages/*/.lake/build/lib/lean; do
  [ -d "$d" ] && lean_paths+=("$d")
done
lean_paths+=("$LEAN_SYSROOT/lib/lean")
export LEAN_PATH="$(IFS=:; echo "${lean_paths[*]}")"

src_paths=("$ROOT")
for d in "$ROOT"/.lake/packages/*; do
  [ -d "$d" ] && src_paths+=("$d")
done
export LEAN_SRC_PATH="$(IFS=:; echo "${src_paths[*]}")"

lib_paths=("$LEAN_SYSROOT/lib")
for d in "$ROOT/.lake/build/lib" "$ROOT"/.lake/packages/*/.lake/build/lib; do
  [ -d "$d" ] && lib_paths+=("$d")
done
export LD_LIBRARY_PATH="$(IFS=:; echo "${lib_paths[*]}")${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$ROOT"
exec "$LEAN_SYSROOT/bin/lean" "$@"
