"""Lit canopy backdrop. The picture has the mark and no lettering; the 3D name stays in the scene."""

from __future__ import annotations

import os

from PIL import ImageDraw

from ..textures import canvas, plum_mark, rgba, save_png

NAME = "storefront_sign"


def build(spec, palette, brand, out_dir: str) -> None:
    if not brand.name or not brand.tagline:
        raise RuntimeError("brand name or tagline is empty")
    width, height = spec.pixels
    deep = palette["primaryDeep"]
    primary = palette["primary"]
    image = canvas(width, height, deep)
    pixels = image.load()
    span = max(1, width - 1)
    for x in range(width):
        blend = x / span
        color = tuple(deep[i] + (primary[i] - deep[i]) * blend for i in range(3))
        filled = rgba(color)
        for y in range(height):
            pixels[x, y] = filled
    glow = canvas(width, height, None)
    band = max(8, height // 7)
    ImageDraw.Draw(glow).rectangle((0, height // 2 - band, width, height // 2 + band), fill=rgba(palette["warmLamp"], 70))
    image.alpha_composite(glow)
    plum_mark(
        ImageDraw.Draw(image),
        (height * 0.55, height * 0.5),
        height * 0.36,
        palette["primary"],
        palette["mintDeep"],
        palette["primaryLight"],
    )
    os.makedirs(out_dir, exist_ok=True)
    save_png(image, os.path.join(out_dir, f"{NAME}.png"))
