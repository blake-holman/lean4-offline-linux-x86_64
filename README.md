# Lean 4 Offline Linux x86_64 Bundle

This repo builds an offline Lean 4.30.0 + Mathlib bundle for Linux x86_64.

The practical ChatGPT-web path is a targeted Mathlib import closure. A full
`import Mathlib` bundle is several GB and does not fit normal ChatGPT upload
limits.

## What Gets Bundled

- Linux x86_64 Lean 4.30.0 under `vendor/lean/`
- `lean`, `lake`, and Lean runtime files
- the project files needed by Lake
- selected Mathlib dependency sources
- selected cached `.olean` files needed by `BundleImports.lean`
- wrapper scripts and a smoke test

The default import set is in `BundleImports.lean`:

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Real.Basic
```

Add the exact Mathlib imports your target files need, then rebuild the bundle.
Avoid `import Mathlib` unless you are prepared for a very large multipart upload.

## Build The ChatGPT-Sized Bundle

Run this on Linux x86_64 with internet access:

```bash
sudo apt-get update
sudo apt-get install -y zstd xz-utils
./scripts/build_chatgpt_bundle.sh
```

Outputs are written under `dist/`:

```text
dist/lean-chatgpt-bundle-linux-x86_64/
dist/lean-chatgpt-bundle-linux-x86_64.tar.xz
dist/lean-chatgpt-bundle-linux-x86_64.tar.xz.part.000
dist/lean-chatgpt-bundle-linux-x86_64.tar.xz.part.001
dist/lean-chatgpt-bundle-linux-x86_64.SHA256SUMS
```

The split part size defaults to `480M`. Override it if needed:

```bash
PART_SIZE=200M ./scripts/build_chatgpt_bundle.sh
```

## Use In A No-Internet Linux Sandbox

Upload all `.part.*` files and the checksum file, then:

```bash
cat lean-chatgpt-bundle-linux-x86_64.tar.xz.part.* > lean-chatgpt-bundle-linux-x86_64.tar.xz
sha256sum -c lean-chatgpt-bundle-linux-x86_64.SHA256SUMS --ignore-missing
tar -xJf lean-chatgpt-bundle-linux-x86_64.tar.xz
cd lean-chatgpt-bundle-linux-x86_64

./scripts/lean_version.sh
./scripts/check_file.sh test/OfflineSmoke.lean
./vendor/lean/bin/lake env lean test/OfflineSmoke.lean
```

To check your own file:

```bash
./scripts/check_file.sh path/to/File.lean
```

For best results, make your file import the same narrow modules listed in
`BundleImports.lean`, or import a local module that does.

## Full Local Bundle

For a larger local-only archive of the current repo state:

```bash
./scripts/materialize_linux_bundle.sh
./scripts/verify_offline_clean.sh
./scripts/make_archive.sh
```

This can be too large for ChatGPT web uploads.

## Verification

`scripts/verify_offline_clean.sh` copies a bundle to a temporary directory,
sets `HOME` to an empty directory, uses a minimal `PATH`, and checks:

```bash
./scripts/lean_version.sh
./scripts/check_file.sh test/OfflineSmoke.lean
./vendor/lean/bin/lake env lean test/OfflineSmoke.lean
```

The GitHub Actions workflow writes `verification/clean-linux-x86_64.log` and
publishes it with the release assets.

## Common Failure Modes

- `unknown module 'Mathlib.X.Y'`: add that import to `BundleImports.lean` and rebuild.
- `olean file ... incompatible`: the Lean version or Mathlib revision changed.
- Lake tries to download: use `./scripts/check_file.sh`, which sets paths directly.
- dynamic library load error: rebuild and keep package `.so*` files in the staged bundle.
- sandbox process killed: the import closure is still too large; narrow the imports.

