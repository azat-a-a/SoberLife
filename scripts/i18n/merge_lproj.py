#!/usr/bin/env python3
"""Merge per-locale JSON overrides into en.lproj template → <locale>.lproj/Localizable.strings."""

from __future__ import annotations

import json
import pathlib
import sys


def esc_apple(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def split_kv_line(line: str) -> tuple[str, str] | None:
    stripped = line.strip()
    if not stripped.startswith('"'):
        return None
    if '" = "' not in stripped or not stripped.endswith('";'):
        return None
    head, _, tail = stripped.partition('" = "')
    key = head[1:]  # leading "
    val = tail[:-2]  # trailing ";
    return key, val


def merge_template(en_text: str, overrides: dict[str, str]) -> str:
    out: list[str] = []
    for line in en_text.splitlines():
        kv = split_kv_line(line)
        if kv is None:
            out.append(line)
            continue
        key, en_val = kv
        val = overrides.get(key, en_val)
        out.append(f'"{key}" = "{esc_apple(val)}";')
    return "\n".join(out) + "\n"


def main() -> None:
    root = pathlib.Path(__file__).resolve().parents[2]
    res = root / "Sources" / "SoberLifeAppShell" / "Resources"
    en_path = res / "en.lproj" / "Localizable.strings"
    en_text = en_path.read_text(encoding="utf-8")

    data_path = pathlib.Path(__file__).with_name("s06_locales.json")
    if not data_path.exists():
        print("Missing", data_path, file=sys.stderr)
        sys.exit(1)
    bundle = json.loads(data_path.read_text(encoding="utf-8"))

    folder_by_locale = {
        "de": "de.lproj",
        "fr": "fr.lproj",
        "es": "es.lproj",
        "it": "it.lproj",
        "pl": "pl.lproj",
        "zh-Hans": "zh-Hans.lproj",
        "th": "th.lproj",
        "ja": "ja.lproj",
    }

    for loc, folder in folder_by_locale.items():
        overrides = bundle.get(loc)
        if not isinstance(overrides, dict):
            print("Missing locale block:", loc, file=sys.stderr)
            sys.exit(1)
        merged = merge_template(en_text, overrides)
        dest = res / folder / "Localizable.strings"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(merged, encoding="utf-8")
        print("Wrote", dest.relative_to(root))


if __name__ == "__main__":
    main()
