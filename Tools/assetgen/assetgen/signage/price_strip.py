"""Tileable yellow shelf-edge strip. Left and right columns match so it repeats in U."""

from __future__ import annotations

import os

from PIL import ImageDraw

from ..textures import canvas, rgba, save_png

NAME = "price_strip"


def build(spec, palette, brand, out_dir: str) -> None:
    del brand
    width, height = spec.pixels
    yellow = palette["priceRailYellow"]
    charcoal = palette["charcoal"]
    cream = palette["cream"]
    image = canvas(width, height, yellow)
    draw = ImageDraw.Draw(image)
    draw.rectangle((0, 0, width - 1, 3), fill=rgba(charcoal))
    period = 128
    for start in range(0, width, period):
        x = start + 16
        draw.rectangle((x, 18, x + 96, height - 10), fill=rgba(cream))
        draw.rectangle((x + 8, 26, x + 44, height - 18), fill=rgba(charcoal))
    left = [image.getpixel((0, y)) for y in range(height)]
    right = [image.getpixel((width - 1, y)) for y in range(height)]
    if left != right:
        raise RuntimeError("price_strip edges do not tile")
    os.makedirs(out_dir, exist_ok=True)
    save_png(image, os.path.join(out_dir, f"{NAME}.png"))
