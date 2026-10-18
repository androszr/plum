"""The pack-fronts atlas: one simple front per product, then its price label and promo band.

Cell layout (the app reads the same numbers from the catalogue): the art rectangle sits in the top
`art_height` rows, the cream price label in the next `label_height` rows, the yellow promo band in the last.
"""

from __future__ import annotations

import os
import re

from PIL import Image, ImageDraw

from ..catalogue import Catalogue, Product, Shape, load_catalogue
from ..textures import canvas, font, rgba, save_png

NAME = "pack_fronts"

BAGS = {"bag", "bagS", "puff", "bagSw"}
BOTTLE_BODY = 0.72  # the lower share of a bottle's art that is body; the app's front card covers just that


def _flavour(code: str) -> str:
    """The word of a colour code: `puffB` and `dark2` read as `PUFF` and `DARK`."""
    return re.sub(r"(?<=[a-z])[A-Z0-9]+$", "", code).upper()


def _fit_font(draw: ImageDraw.ImageDraw, message: str, max_width: int, start: int):
    size = start
    while size > 6:
        f = font(size)
        if draw.textlength(message, font=f) <= max_width:
            return f
        size -= 1
    return font(6)


def _write(draw, centre, message, max_width, start, colour):
    f = _fit_font(draw, message, max_width, start)
    draw.text(centre, message, font=f, fill=rgba(colour), anchor="mm")


def _rect(draw, box, colour):
    x0, y0, x1, y1 = box
    draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=rgba(colour))


def _draw_pack(draw, rect, shape: Shape, product: Product, base, accent, palette) -> None:
    x, y, w, h = rect
    x1, y1 = x + w, y + h
    brand = product.brand.upper()
    cream, charcoal = palette["cream"], palette["charcoal"]
    if shape.form == "bottle":
        neck_h = round(h * (1 - BOTTLE_BODY))
        body_top = y + neck_h
        glass = palette["brownGlass"] if shape.id == "btl" else palette["clearPet"]
        neck_w = max(4, round(w * 0.4))
        nx = x + (w - neck_w) // 2
        _rect(draw, (nx, y, nx + neck_w, body_top + 2), glass)
        _rect(draw, (nx, y, nx + neck_w, y + max(4, neck_h // 3)), accent)
        draw.rounded_rectangle((x, body_top, x1 - 1, y1 - 1), radius=max(3, w // 6), fill=rgba(glass))
        # The label is most of the body, so a bottle reads as its brand colour from the aisle.
        label_top = body_top + round((y1 - body_top) * 0.15)
        label_bottom = y1 - round((y1 - body_top) * 0.08)
        _rect(draw, (x, label_top, x1, label_bottom), base)
        _write(draw, (x + w // 2, (label_top + label_bottom) // 2), brand, w - 6, 15, accent)
        return
    if shape.form == "cylinder" and shape.id.startswith("can"):
        # A silver lid at the top only; the bottom is a thin rim, so the picture is not symmetric top to bottom.
        rim = max(4, h // 14)
        _rect(draw, (x, y, x1, y1), base)
        _rect(draw, (x, y, x1, y + rim), palette["canSilver"])
        _rect(draw, (x, y + rim, x1, y + rim + 2), palette["canRim"])
        _rect(draw, (x, y1 - 3, x1, y1), palette["canRim"])
        band_top = y + h * 3 // 10
        band_h = h // 4
        _rect(draw, (x, band_top, x1, band_top + band_h), accent)
        _write(draw, (x + w // 2, band_top + band_h // 2), brand, w - 6, 16, base)
        _write(draw, (x + w // 2, y + h * 4 // 5), _flavour(product.code), w - 8, 11, accent)
        return
    if shape.id == "tube":
        lid = max(6, h // 8)
        _rect(draw, (x, y, x1, y1), base)
        _rect(draw, (x, y, x1, y + lid), palette["canSilver"])
        _rect(draw, (x, y + lid, x1, y + lid + 2), palette["canRim"])
        _rect(draw, (x, y + h // 2 - 12, x1, y + h // 2 + 12), accent)
        _write(draw, (x + w // 2, y + h // 2), brand, w - 4, 11, base)
        _write(draw, (x + w // 2, y + h * 4 // 5), _flavour(product.code), w - 4, 9, accent)
        return
    if shape.id in BAGS:
        crimp = max(5, h // 14)
        _rect(draw, (x, y, x1, y1), base)
        for k in range(0, crimp, 2):
            _rect(draw, (x, y + k, x1, y + k + 1), accent)
            _rect(draw, (x, y1 - crimp + k, x1, y1 - crimp + k + 1), accent)
        window = palette["puffWindow"] if shape.id == "puff" else palette["crispWindow"]
        cy = y + h * 0.58
        draw.ellipse((x + w * 0.2, cy - h * 0.16, x + w * 0.8, cy + h * 0.16), fill=rgba(window))
        _write(draw, (x + w // 2, y + h * 0.28), brand, w - 8, 18, accent)
        _write(draw, (x + w // 2, cy), _flavour(product.code), int(w * 0.55), 12, base)
        return
    if shape.id == "tray":
        _rect(draw, (x, y, x1, y1), palette["woodLight"])
        bars = 4
        gap = 2
        bar_w = (w - gap * (bars + 1)) // bars
        for k in range(bars):
            bx = x + gap + k * (bar_w + gap)
            _rect(draw, (bx, y + 3, bx + bar_w, y1 - 3), base)
            _rect(draw, (bx, y + 3, bx + bar_w, y + 8), accent)
        _rect(draw, (x, y + h // 2 - 9, x1, y + h // 2 + 9), cream)
        _write(draw, (x + w // 2, y + h // 2), brand, w - 6, 13, charcoal)
        return
    # tablets, rolls, boxes, cartons, bricks and tea boxes: a body with a brand band.
    _rect(draw, (x, y, x1, y1), base)
    band_h = max(10, h // 5)
    band_top = y + h // 3
    _rect(draw, (x, band_top, x1, band_top + band_h), accent)
    _write(draw, (x + w // 2, band_top + band_h // 2), brand, w - 4, 16, base)
    _write(draw, (x + w // 2, y + h * 4 // 5), _flavour(product.code), w - 4, 11, accent)
    _rect(draw, (x, y, x1, y + 3), accent)
    _rect(draw, (x, y1 - 3, x1, y1), accent)


def _draw_cell(image: Image.Image, catalogue: Catalogue, product: Product, palette) -> None:
    atlas = catalogue.atlas
    col, row = product.cell % atlas.columns, product.cell // atlas.columns
    ox, oy = col * atlas.cell_width, row * atlas.cell_height
    shape = catalogue.shapes[product.shape]
    base_name, accent_name = catalogue.codes[product.code]
    base, accent = palette[base_name], palette[accent_name]
    draw = ImageDraw.Draw(image)
    ax, ay, aw, ah = catalogue.art_rect(shape)
    _draw_pack(draw, (ox + ax, oy + ay, aw, ah), shape, product, base, accent, palette)
    if product.tag:
        r = 17
        cx, cy = ox + ax + aw - r - 2, oy + ay + ah - r - 2
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba(palette["priceRailYellow"]), outline=rgba(palette["charcoal"]))
        _write(draw, (cx, cy), product.tag, 2 * r - 4, 14, palette["charcoal"])
    label_top = oy + atlas.art_height
    _rect(draw, (ox, label_top, ox + atlas.cell_width, label_top + atlas.label_height), palette["cream"])
    _write(draw, (ox + atlas.cell_width // 2, label_top + atlas.label_height // 2), product.price,
           atlas.cell_width - 16, 24, palette["charcoal"])
    if product.promo:
        promo_top = label_top + atlas.label_height
        _rect(draw, (ox, promo_top, ox + atlas.cell_width, promo_top + atlas.label_height), palette["priceRailYellow"])
        _write(draw, (ox + atlas.cell_width // 2, promo_top + atlas.label_height // 2), product.promo,
               atlas.cell_width - 12, 22, palette["charcoal"])


def build(spec, palette, brand, out_dir: str, catalogue_path: str | None = None) -> None:
    del brand
    if catalogue_path is None:
        raise RuntimeError("pack_fronts needs --catalogue <planograms.json>")
    catalogue = load_catalogue(catalogue_path)
    width, height = spec.pixels
    if (width, height) != catalogue.atlas.pixels:
        raise RuntimeError(f"brief wants {width} x {height} px, the catalogue's atlas is {catalogue.atlas.pixels}")
    image = canvas(width, height, None)
    for product in catalogue.products:
        _draw_cell(image, catalogue, product, palette)
    os.makedirs(out_dir, exist_ok=True)
    save_png(image, os.path.join(out_dir, f"{NAME}.png"))
