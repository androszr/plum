"""Three posters in one atlas, left to right, matching the variant headlines."""

from __future__ import annotations

import os

from PIL import ImageDraw

from ..textures import canvas, plum_mark, rgba, save_png, text

NAME = "window_poster_set"

# Panel colours follow the procedural poster tints, in atlas order.
_PANELS = (
    ("Hot coffee?", "priceRailYellow"),
    ("Hungry?", "accentMint"),
    ("Open 6-23", "cream"),
)


def build(spec, palette, brand, out_dir: str) -> None:
    del brand
    width, height = spec.pixels
    panel_width = width // spec.panels
    image = canvas(width, height, palette["cream"])
    draw = ImageDraw.Draw(image)
    ink = palette["primary"]
    for index, (message, color_name) in enumerate(_PANELS):
        x0 = index * panel_width
        draw.rectangle((x0, 0, x0 + panel_width - 1, height - 1), fill=rgba(palette[color_name]))
        text(draw, (x0 + panel_width / 2, height * 0.42), message, 72, ink)
        plum_mark(
            draw,
            (x0 + 120, 120),
            70,
            palette["primary"],
            palette["mintDeep"],
            palette["primaryLight"],
        )
    os.makedirs(out_dir, exist_ok=True)
    save_png(image, os.path.join(out_dir, f"{NAME}.png"))
