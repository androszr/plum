"""Shop mark, as SVG text and a transparent PNG. Sizes come from the brief."""

from __future__ import annotations

import os

from PIL import ImageDraw

from ..textures import canvas, plum_mark, save_png

NAME = "plum_mark"


def _svg_fill(color) -> str:
    red, green, blue = (int(round(channel * 255)) for channel in color)
    return f"rgb({red},{green},{blue})"


def build(spec, palette, brand, out_dir: str) -> None:
    if not brand.name or not brand.tagline:
        raise RuntimeError("brand name or tagline is empty")
    width, height = spec.pixels
    body = palette["primary"]
    leaf = palette["mintDeep"]
    highlight = palette["primaryLight"]
    cx, cy, radius = width / 2, height / 2, width * 0.34
    leaf_w, leaf_h = radius * 0.42, radius * 0.72
    lx, ly = cx + radius * 0.42, cy - radius * 0.85
    hx, hy = cx - radius * 0.28, cy - radius * 0.22
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        f'  <ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{radius:.1f}" ry="{radius * 0.985:.1f}" '
        f'fill="{_svg_fill(body)}"/>\n'
        f'  <ellipse cx="{lx:.1f}" cy="{ly:.1f}" rx="{leaf_w:.1f}" ry="{leaf_h:.1f}" '
        f'fill="{_svg_fill(leaf)}"/>\n'
        f'  <ellipse cx="{hx:.1f}" cy="{hy:.1f}" rx="{radius * 0.28:.1f}" ry="{radius * 0.16:.1f}" '
        f'fill="{_svg_fill(highlight)}"/>\n'
        f"</svg>\n"
    )
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "plum_mark.svg"), "w", encoding="utf-8") as handle:
        handle.write(svg)
    image = canvas(width, height, None)
    plum_mark(ImageDraw.Draw(image), (cx, cy), radius, body, leaf, highlight)
    save_png(image, os.path.join(out_dir, "plum_mark.png"))
