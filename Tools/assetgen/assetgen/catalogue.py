"""Read the planogram catalogue (the JSON the app reads too). Nothing here is a second copy of it."""

from __future__ import annotations

import json
import math
from dataclasses import dataclass


@dataclass(frozen=True)
class Atlas:
    columns: int
    rows: int
    cell_width: int
    cell_height: int
    art_height: int
    label_height: int

    @property
    def cell_count(self) -> int:
        return self.columns * self.rows

    @property
    def pixels(self) -> tuple[int, int]:
        return (self.columns * self.cell_width, self.rows * self.cell_height)


@dataclass(frozen=True)
class Shape:
    id: str
    width: float
    height: float
    depth: float
    form: str
    heavy: bool


@dataclass(frozen=True)
class Product:
    id: str
    brand: str
    code: str
    shape: str
    price: str
    promo: str | None
    tag: str | None
    cell: int


@dataclass(frozen=True)
class Catalogue:
    atlas: Atlas
    shapes: dict[str, Shape]
    codes: dict[str, tuple[str, str]]
    products: list[Product]

    def art_rect(self, shape: Shape) -> tuple[int, int, int, int]:
        """(x, y, width, height) in pixels inside the cell: the pack aspect scaled by
        min(cell_width / w, art_height / h), floored, centred in the art area. The app does the same sum."""
        scale = min(self.atlas.cell_width / shape.width, self.atlas.art_height / shape.height)
        width = math.floor(shape.width * scale)
        height = math.floor(shape.height * scale)
        return ((self.atlas.cell_width - width) // 2, (self.atlas.art_height - height) // 2, width, height)


def load_catalogue(path: str) -> Catalogue:
    with open(path, encoding="utf-8") as handle:
        raw = json.load(handle)
    a = raw["atlas"]
    atlas = Atlas(a["columns"], a["rows"], a["cellWidth"], a["cellHeight"], a["artHeight"], a["labelHeight"])
    shapes = {
        key: Shape(key, float(v["w"]), float(v["h"]), float(v["d"]), v.get("form", "box"), bool(v.get("heavy", False)))
        for key, v in raw["shapes"].items()
    }
    codes = {key: (v[0], v[1]) for key, v in raw["colourCodes"].items()}
    products: list[Product] = []
    for cell, p in enumerate(raw["products"]):
        if p["shape"] not in shapes:
            raise ValueError(f"{p['id']}: unknown shape {p['shape']}")
        if p["code"] not in codes:
            raise ValueError(f"{p['id']}: unknown colour code {p['code']}")
        products.append(
            Product(p["id"], p.get("brand", ""), p["code"], p["shape"], p.get("price", ""),
                    p.get("promo"), p.get("tag"), cell)
        )
    if len(products) > atlas.cell_count:
        raise ValueError(f"{len(products)} products do not fit {atlas.cell_count} atlas cells")
    return Catalogue(atlas, shapes, codes, products)
