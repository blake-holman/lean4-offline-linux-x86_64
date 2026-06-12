#!/usr/bin/env python3
import json
import os
import shutil
import sys
from pathlib import Path


def usage() -> None:
    print("usage: copy_lean_closure.py lake-query-json-or-dir stage-dir", file=sys.stderr)


if len(sys.argv) != 3:
    usage()
    raise SystemExit(2)

root = Path.cwd().resolve()
query_input = Path(sys.argv[1]).resolve()
stage = Path(sys.argv[2]).resolve()


def copy_path(src: Path) -> None:
    src = src.resolve()
    if not src.exists():
        return
    try:
        rel = src.relative_to(root)
    except ValueError:
        return
    dst = stage / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)


def walk_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from walk_strings(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from walk_strings(item)


if query_input.is_dir():
    data = [json.loads(path.read_text()) for path in sorted(query_input.glob("*.json"))]
else:
    data = json.loads(query_input.read_text())
olean_paths: set[Path] = set()
extra_paths: set[Path] = set()

for raw in walk_strings(data):
    if raw.endswith((".olean", ".so")) or ".so." in raw:
        path = Path(raw)
        if not path.is_absolute():
            path = root / path
        if raw.endswith(".olean"):
            olean_paths.add(path.resolve())
        else:
            extra_paths.add(path.resolve())

if not olean_paths:
    raise SystemExit(
        "lake query did not expose any .olean paths; check the Lake target/facet names"
    )

package_roots: set[Path] = {root}

for olean in sorted(olean_paths):
    copy_path(olean)

    if os.environ.get("INCLUDE_ILEAN") == "1":
        copy_path(olean.with_suffix(".ilean"))

    text = olean.as_posix()
    marker = "/.lake/build/lib/lean/"
    if marker not in text:
        continue

    pkg_root_text, module_rel_text = text.split(marker, 1)
    pkg_root = Path(pkg_root_text)
    package_roots.add(pkg_root)
    copy_path(pkg_root / Path(module_rel_text).with_suffix(".lean"))

    lib_dir = pkg_root / ".lake/build/lib"
    if lib_dir.exists():
        for dynlib in lib_dir.glob("*.so*"):
            copy_path(dynlib)

for path in sorted(extra_paths):
    copy_path(path)

for pkg_root in sorted(package_roots):
    for name in ("lakefile.lean", "lakefile.toml", "lake-manifest.json", "lean-toolchain"):
        copy_path(pkg_root / name)
