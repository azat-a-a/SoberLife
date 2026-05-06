#!/usr/bin/env python3
"""Build s06_locales.json from de.txt … ja.txt (one translation per line, UTF-8, same order as en.lproj keys)."""

from __future__ import annotations

import json
import pathlib
import re
import sys


def main() -> None:
    root = pathlib.Path(__file__).resolve().parents[2]
    en_path = root / "Sources" / "SoberLifeAppShell" / "Resources" / "en.lproj" / "Localizable.strings"
    en_text = en_path.read_text(encoding="utf-8")
    keys = re.findall(r'^"([^"]+)"\s*=', en_text, re.M)
    here = pathlib.Path(__file__).resolve().parent
    bundle: dict[str, dict[str, str]] = {}
    for loc in ["de", "fr", "es", "it", "pl", "zh-Hans", "th", "ja"]:
        path = here / f"{loc}.txt"
        if not path.exists():
            print("Missing", path, file=sys.stderr)
            sys.exit(1)
        lines = path.read_text(encoding="utf-8").splitlines()
        if len(lines) != len(keys):
            print(f"{loc}: expected {len(keys)} lines, got {len(lines)}", file=sys.stderr)
            sys.exit(1)
        bundle[loc] = dict(zip(keys, lines))
    out = here / "s06_locales.json"
    out.write_text(json.dumps(bundle, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Wrote", out)


if __name__ == "__main__":
    main()
