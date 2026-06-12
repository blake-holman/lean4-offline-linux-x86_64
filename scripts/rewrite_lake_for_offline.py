#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path


def usage() -> None:
    print("usage: rewrite_lake_for_offline.py bundle-root", file=sys.stderr)


if len(sys.argv) != 2:
    usage()
    raise SystemExit(2)

root = Path(sys.argv[1]).resolve()

lakefile = root / "lakefile.lean"
if lakefile.exists():
    text = lakefile.read_text()
    text = re.sub(
        r'require\s+mathlib\s+from\s+git\s*\n\s*"https://github\.com/leanprover-community/mathlib4\.git"\s*@\s*"v4\.30\.0"',
        'require mathlib from "./.lake/packages/mathlib"',
        text,
    )
    lakefile.write_text(text)

manifest_path = root / "lake-manifest.json"
if manifest_path.exists():
    manifest = json.loads(manifest_path.read_text())
    for pkg in manifest.get("packages", []):
        name = pkg.get("name")
        if not name:
            continue
        pkg["type"] = "path"
        pkg["dir"] = f".lake/packages/{name}"
        for key in ("url", "rev", "inputRev", "subDir", "scope", "source"):
            pkg.pop(key, None)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")

