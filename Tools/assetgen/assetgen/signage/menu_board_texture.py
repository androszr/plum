"""Hot-food menu. Aubergine ground, six pastel tiles, English names, price dots."""

from __future__ import annotations

import os

from PIL import ImageDraw

from ..textures import canvas, rgba, save_png, text

NAME = "menu_board_texture"

# Same order as the procedural menu tiles.
_ITEMS = (
    ("Hot dog", "priceRailYellow"),
    ("Coffee", "accentMint"),
    ("Zapiekanka", "primaryLight"),
    ("Pastry", "warmLamp"),
    ("Tea", "mintDeep"),
    ("Soup", "cream"),
)


def build(spec, palette, brand, out_dir: str) -> None:
    del brand
    width, height = spec.pixels
    image = canvas(width, height, palette["primaryDeep"])
    draw = ImageDraw.Draw(image)
    tile_w, tile_h = 560, 240
    origin_x, origin_y = 150, 80
    gap_x, gap_y = 40, 40
    for index, (label, color_name) in enumerate(_ITEMS):
        column, row = index % 3, index // 3
        x = origin_x + column * (tile_w + gap_x)
        y = origin_y + row * (tile_h + gap_y)
        draw.rectangle((x, y, x + tile_w, y + tile_h), fill=rgba(palette[color_name]))
        text(draw, (x + tile_w / 2, y + tile_h / 2 - 16), label, 42, palette["primaryDeep"])
        dot = (x + tile_w - 70, y + tile_h - 48)
        draw.ellipse((dot[0], dot[1], dot[0] + 28, dot[1] + 28), fill=rgba(palette["primaryDeep"]))
    os.makedirs(out_dir, exist_ok=True)
    save_png(image, os.path.join(out_dir, f"{NAME}.png"))
