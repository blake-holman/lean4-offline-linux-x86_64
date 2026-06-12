#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export PATH="$ROOT/vendor/lean/bin:$PATH"
export LEAN_SYSROOT="$ROOT/vendor/lean"

"$ROOT/vendor/lean/bin/lean" --version
"$ROOT/vendor/lean/bin/lake" --version

