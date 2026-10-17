#!/usr/bin/env python3
"""Build signage and fixture files from the asset brief."""

from __future__ import annotations

import argparse
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from assetgen.brand import load_brand
from assetgen.brief import load_brief

SIGNAGE_ORDER = (
    "plum_mark",
    "storefront_sign",
    "price_strip",
    "window_poster_set",
    "menu_board_texture",
)

# Fixtures embed these pictures, so a partial run still has to draw them.
TEXTURE_USERS = {
    "price_strip": {"gondola_shelf", "wall_shelf", "end_cap"},
    "window_poster_set": {"window_poster"},
    "menu_board_texture": {"menu_screen"},
    "plum_mark": {"wall_fridge", "dairy_chiller", "a_frame_sign"},
}


def _signage(name: str):
    return importlib.import_module(f"assetgen.signage.{name}")


def _fixture(name: str):
    return importlib.import_module(f"assetgen.assets.{name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--brief", required=True)
    parser.add_argument("--brand", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    only = set(args.only) if args.only else None
    brief = load_brief(args.brief)
    brand = load_brand(args.brand)
    names = list(brief.specs)
    signage_names = [name for name in SIGNAGE_ORDER if name in brief.specs]
    fixture_names = [name for name in names if name not in set(SIGNAGE_ORDER)]
    if only and not only.issubset(set(names)):
        unknown = sorted(only.difference(names))[0]
        raise RuntimeError(f"unknown --only name {unknown}")
    chosen_fixtures = [name for name in fixture_names if not only or name in only]
    chosen_signage = [name for name in signage_names if not only or name in only]
    if only:
        # A requested fixture still needs the picture it embeds.
        extras = {
            texture
            for texture, users in TEXTURE_USERS.items()
            if users.intersection(chosen_fixtures)
        }
        chosen_signage = [name for name in signage_names if name in set(chosen_signage).union(extras)]
    os.makedirs(args.out, exist_ok=True)
    written: list[str] = []
    textures: dict[str, str] = {}
    for name in signage_names:
        if name not in chosen_signage and only:
            continue
        spec = brief.specs[name]
        _signage(name).build(spec, brief.palette, brand, args.out)
        png = os.path.join(args.out, f"{name}.png")
        textures[name] = png
        if not only or name in only:
            print(f"{name} generated")
            written.append(name)
    for name in fixture_names:
        if only and name not in only:
            continue
        spec = brief.specs[name]
        module = _fixture(name)
        if module.NAME != name:
            raise RuntimeError(f"{name}: module NAME is {module.NAME}")
        module.build(spec, brief.palette, textures).write(args.out)
        print(f"{name} generated")
        written.append(name)
    print(f"{len(written)} assets generated")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"generate.py: {exc}", file=sys.stderr)
        sys.exit(1)
