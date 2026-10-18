"""Geometry for every fixture. Sizes come from the brief; this file only decides the shape."""

from __future__ import annotations

import re

from .. import primitives
from ..brief import Spec
from ..builder import AssetBuilder

SWATCH = [
    "primary", "primaryLight", "accentMint", "mintDeep", "priceRailYellow",
    "cream", "woodLight", "warmLamp", "charcoal",
]

FRONT = {
    "gondola_shelf": ["header_sign"],
    "wall_shelf": [f"price_rail_{i}" for i in range(4)] + ["header_sign"],
    "end_cap": [f"price_rail_{i}" for i in range(3)] + ["promo_sign"],
    "wall_fridge": ["door_left", "door_right", "handle_left", "handle_right"],
    "dairy_chiller": ["open_front_lip"],
    "checkout_counter": ["front_stripe", "card_terminal"],
    "cigarette_cabinet": ["door_left", "door_right", "price_board_left", "price_board_right"],
    "hot_food_counter": ["kick_strip", "case_glass"],
    "coffee_machine": ["screen", "spout_left", "spout_right"],
    "menu_screen": ["screen"],
    "window_ledge": ["ledge_top"],
    "high_stool": [],
    "basket_stack": [],
    "back_room_door": ["door", "push_plate"],
    "pendant_lamp": [],
    "entrance_door": ["leaf_left", "leaf_right", "handle_left", "handle_right"],
    "window_poster": ["poster"],
    "atm_locker": ["atm_screen", "keypad"],
    "a_frame_sign": ["board"],
    "litter_bin": [],
    "bike_rack": [],
    "street_lamp": [],
    "self_checkout": ["screen_left", "screen_right", "card_terminal_left", "card_terminal_right"],
    "alcohol_wall": ["header_sign"],
}


def build_asset(name: str, spec: Spec, palette: dict, textures: dict) -> AssetBuilder:
    builder = AssetBuilder(name, spec)
    BUILDERS[name](builder, spec, palette, textures)
    return builder


def _box(b, name, x, y, z, w, h, d, color, **kw):
    u_span = kw.pop("u_span", (0.0, 1.0))
    b.part(name, primitives.box(w, h, d, u_span=u_span), color=color, at=(x, y, z), **kw)


def _cyl(b, name, x, y, z, r, h, color, segments=8, axis="y", **kw):
    b.part(name, primitives.cylinder(r, h, segments, axis=axis), color=color, at=(x, y, z), **kw)


def _have(spec: Spec, stem: str) -> list[str]:
    found = []
    for name in spec.parts:
        if re.fullmatch(rf"{stem}_\d+", name):
            found.append((int(name.rsplit("_", 1)[-1]), name))
    return [name for _, name in sorted(found)]


def _groups(spec: Spec, stem: str) -> dict[int, list[str]]:
    groups: dict[int, list[tuple[int, str]]] = {}
    for name in spec.parts:
        matched = re.fullmatch(rf"{stem}_(\d+)_(\d+)", name)
        if matched:
            groups.setdefault(int(matched.group(1)), []).append((int(matched.group(2)), name))
    return {key: [name for _, name in sorted(items)] for key, items in groups.items()}


def _swatches(b, palette, n: int):
    colors = []
    for i in range(n):
        if i < min(6, n):
            colors.append(palette[SWATCH[i]])
        else:
            colors.append(palette[SWATCH[b.rng.randrange(len(SWATCH))]])
    return colors


def _goods(b, names, palette, y, z, width, mode="mixed"):
    if not names:
        return
    colors = _swatches(b, palette, len(names))
    pitch = width / len(names)
    for i, name in enumerate(names):
        x = -width / 2 + pitch * (i + 0.5)
        color = colors[i]
        if mode == "carton" or (mode == "mixed" and i % 3 == 0):
            _box(b, name, x, y, z, pitch * 0.7, 0.14, 0.06, color)
        else:
            segments = 6 if i % 3 == 2 else 8
            _cyl(b, name, x, y, z, min(0.035, pitch * 0.32), 0.15 if i % 3 == 2 else 0.11, color, segments=segments)


SHAPES = ("packet", "can", "bottle")


def _shape_groups(spec: Spec, stem: str) -> dict[int, list[int]]:
    """Facing indices per shelf for a shaped product stem (`<stem>_<shelf>_<i>_<shape>`)."""
    groups: dict[int, set[int]] = {}
    for name in spec.parts:
        matched = re.fullmatch(rf"{stem}_(\d+)_(\d+)_packet", name)
        if matched:
            groups.setdefault(int(matched.group(1)), set()).add(int(matched.group(2)))
    return {key: sorted(items) for key, items in groups.items()}


def _shaped_goods(b, spec, stem, groups, palette, ys, z, width):
    """A packet, a can and a bottle at every spot, each at most 48 triangles. The app shows one."""
    for shelf, y in enumerate(ys):
        facings = groups.get(shelf, [])
        if not facings:
            continue
        colors = _swatches(b, palette, len(facings))
        pitch = width / len(facings)
        radius = min(0.035, pitch * 0.32)
        for slot, facing in enumerate(facings):
            x = -width / 2 + pitch * (slot + 0.5)
            color = colors[slot]
            base = f"{stem}_{shelf}_{facing}"
            _box(b, f"{base}_packet", x, y, z, pitch * 0.7, 0.14, 0.06, color)
            _cyl(b, f"{base}_can", x, y, z, radius, 0.11, color, segments=8)
            body = primitives.cylinder(radius, 0.13, 8)
            neck = primitives.transform(primitives.cylinder(radius * 0.4, 0.05, 6), at=(0.0, 0.13, 0.0))
            b.part(f"{base}_bottle", primitives.merge(body, neck), color=color, at=(x, y, z))


def _rails(b, spec, palette, textures, ys, z, width):
    tex = textures.get("price_strip")
    for name, y in zip(_have(spec, "price_rail"), ys):
        _box(b, name, 0, y, z, width, 0.04, 0.02, palette["priceRailYellow"], texture=tex)


def _shelves(b, spec, palette, textures, count_prefix, x_span, z, depth, y0, y1):
    names = _have(spec, "shelf")
    if not names:
        return []
    gap = (y1 - y0) / len(names)
    ys = []
    for i, name in enumerate(names):
        y = y0 + gap * i
        _box(b, name, 0, y, z, x_span, 0.03, depth, palette["tileWhite"])
        ys.append(y)
    return ys


def gondola_shelf(b, spec, palette, textures):
    """An empty double-sided carcass. The app draws the shelves, rails and goods from the planogram."""
    w, d, h = spec.dimensions
    header = 0.14
    top = h - header
    _box(b, "base", 0, 0, 0, w, 0.08, d, palette["charcoal"])
    _box(b, "upright_left", -w / 2 + 0.025, 0.08, 0, 0.05, top - 0.08, d - 0.04, palette["primaryDeep"])
    _box(b, "upright_right", w / 2 - 0.025, 0.08, 0, 0.05, top - 0.08, d - 0.04, palette["primaryDeep"])
    _box(b, "back_panel", 0, 0.08, 0, w - 0.1, top - 0.08, 0.02, palette["cream"])
    for i in range(3):
        y = 0.5 + 0.4 * i
        _box(b, f"slot_row_{i}", 0, y, 0.015, w - 0.12, 0.012, 0.01, palette["charcoal"])
        _box(b, f"slot_row_back_{i}", 0, y, -0.015, w - 0.12, 0.012, 0.01, palette["charcoal"])
    _box(b, "header_sign", 0, top, 0, w, header, d, palette["primary"])


def wall_shelf(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "base", 0, 0, 0, w, 0.08, d, palette["charcoal"])
    _box(b, "header_sign", 0, h - 0.16, 0, w, 0.16, d, palette["primary"])
    _box(b, "upright_left", -w / 2 + 0.03, 0.08, 0, 0.04, h - 0.24, d - 0.02, palette["primaryDeep"])
    _box(b, "upright_right", w / 2 - 0.03, 0.08, 0, 0.04, h - 0.24, d - 0.02, palette["primaryDeep"])
    _box(b, "back_panel", 0, 0.1, -d / 2 + 0.02, w - 0.1, h - 0.3, 0.02, palette["cream"])
    for i, name in enumerate(_have(spec, "slot_row")):
        _box(b, name, 0, 0.4 + 0.32 * i, -d / 2 + 0.04, w - 0.14, 0.012, 0.008, palette["charcoal"])
    ys = _shelves(b, spec, palette, textures, "shelf", w - 0.1, 0.02, d - 0.08, 0.16, h - 0.28)
    _rails(b, spec, palette, textures, ys, d / 2 - 0.01, w - 0.12)
    _box(b, "wall_rail", 0, h - 0.22, -d / 2 + 0.03, w - 0.04, 0.03, 0.02, palette["woodLight"])
    _shaped_goods(b, spec, "product", _shape_groups(spec, "product"), palette, [y + 0.03 for y in ys], d / 2 - 0.08, w - 0.18)


def end_cap(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "base", 0, 0, 0, w, 0.1, d, palette["charcoal"])
    _box(b, "promo_sign", 0, h - 0.18, 0, w, 0.18, d, palette["mintDeep"])
    _box(b, "back", 0, 0.1, -d / 2 + 0.02, w - 0.06, h - 0.32, 0.02, palette["cream"])
    ys = _shelves(b, spec, palette, textures, "shelf", w - 0.08, 0.0, d - 0.06, 0.16, h - 0.28)
    _rails(b, spec, palette, textures, ys, d / 2 - 0.01, w - 0.1)
    _shaped_goods(b, spec, "product", _shape_groups(spec, "product"), palette, [y + 0.03 for y in ys], d / 2 - 0.08, w - 0.16)


def wall_fridge(b, spec, palette, textures):
    """An empty carcass centred on its footprint. The app draws the shelves and bottles from the planogram.

    It is built 5 mm inside the brief's footprint on every side, so it never shares a face with the wall."""
    w, d, h = spec.dimensions
    w, d = w - 0.01, d - 0.01
    header = 0.16
    top = h - header
    _box(b, "plinth", 0, 0, 0, w, 0.10, d, palette["primaryDeep"])
    _box(b, "header", 0, top, 0, w, header, d, palette["primary"], texture=textures.get("plum_mark"), texture_background=palette["primary"])
    _box(b, "frame", 0, 0.10, -d / 2 + 0.02, w, top - 0.10, 0.04, palette["charcoal"])
    _box(b, "frame_side_left", -w / 2 + 0.02, 0.10, 0, 0.04, top - 0.10, d, palette["charcoal"])
    _box(b, "frame_side_right", w / 2 - 0.02, 0.10, 0, 0.04, top - 0.10, d, palette["charcoal"])
    _box(b, "interior_glow", 0, 0.12, -d / 2 + 0.05, w - 0.1, top - 0.14, 0.01, palette["tileWhite"], emissive=True)
    door_h = top - 0.10
    _box(b, "door_left", -w / 4, 0.10, d / 2 - 0.012, w / 2 - 0.02, door_h, 0.02, palette["skyPastel"], opacity=0.35, roughness=0.1)
    _box(b, "door_right", w / 4, 0.10, d / 2 - 0.012, w / 2 - 0.02, door_h, 0.02, palette["skyPastel"], opacity=0.35, roughness=0.1)
    _box(b, "handle_left", -0.04, 0.8, d / 2 + 0.007, 0.025, 0.5, 0.02, palette["cream"], roughness=0.3)
    _box(b, "handle_right", 0.04, 0.8, d / 2 + 0.007, 0.025, 0.5, 0.02, palette["cream"], roughness=0.3)
    _box(b, "compressor_vent", 0, 0.02, d / 2, w - 0.2, 0.05, 0.01, palette["charcoal"])


def dairy_chiller(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "body", 0, 0, 0, w, h - 0.04, d, palette["primaryLight"])
    _box(b, "back_riser", 0, h - 0.42, -d / 2 + 0.04, w, 0.42, 0.06, palette["primary"])
    _box(b, "open_front_lip", 0, 0.72, d / 2 - 0.03, w, 0.05, 0.05, palette["primaryDeep"])
    _box(b, "glow", 0, h - 0.5, -0.05, w - 0.2, 0.04, d * 0.4, palette["tileWhite"], emissive=True, texture=textures.get("plum_mark"), texture_background=palette["tileWhite"])
    _box(b, "riser_text", 0, h - 0.28, -d / 2 + 0.075, w * 0.4, 0.1, 0.012, palette["cream"])
    ys = _shelves(b, spec, palette, textures, "shelf", w - 0.16, -0.02, 0.46, 0.55, h - 0.5)
    groups = _groups(spec, "carton")
    for i, y in enumerate(ys):
        _goods(b, groups.get(i, []), palette, y + 0.03, -0.02, w - 0.24, mode="carton")


def checkout_counter(b, spec, palette, textures):
    """The counter without its sweets rack: the app draws the stepped rack on the counter top."""
    w, d, h = spec.dimensions
    _box(b, "counter", 0, 0, 0, w, 0.96, d, palette["primary"])
    _box(b, "counter_top", 0, 0.96, 0, w - 0.02, 0.045, d - 0.02, palette["woodLight"])
    _box(b, "front_stripe", 0, 0.32, d / 2 - 0.012, w - 0.12, 0.1, 0.016, palette["accentMint"])
    _box(b, "conveyor_belt", -0.42, 1.005, -0.02, 0.7, 0.02, 0.32, palette["charcoal"])
    _box(b, "till", 0.35, 1.005, -0.12, 0.36, 0.1, 0.28, palette["charcoal"])
    _box(b, "till_screen", 0.35, h - 0.2, -0.16, 0.22, 0.2, 0.02, palette["accentMint"], emissive=True)
    _box(b, "card_terminal", 0.50, 1.005, 0.28, 0.1, 0.05, 0.14, palette["asphalt"])
    _box(b, "receipt_printer", 0.72, 1.005, -0.08, 0.12, 0.1, 0.14, palette["cream"])
    _box(b, "bag_dispenser", 0.78, 1.005, 0.16, 0.1, 0.16, 0.1, palette["mintDeep"])


def cigarette_cabinet(b, spec, palette, textures):
    """Closed and plain: solid doors, nothing inside, a cream price board on each door.

    Laid out like the code-built stand-in (the app's price lines are written on the boards at the same depth)."""
    w, d, h = spec.dimensions
    _box(b, "cabinet", 0, 0, -0.025, w - 0.05, h, d - 0.05, palette["charcoal"])
    _box(b, "door_left", -0.36, 0.9, 0.21, 0.7, 0.95, 0.02, palette["primary"])
    _box(b, "door_right", 0.36, 0.9, 0.21, 0.7, 0.95, 0.02, palette["primary"])
    _box(b, "price_board_left", -0.36, 1.05, 0.225, 0.5, 0.4, 0.01, palette["cream"])
    _box(b, "price_board_right", 0.36, 1.05, 0.225, 0.5, 0.4, 0.01, palette["cream"])
    _box(b, "lottery_screen", 0, 0.35, 0.21, w * 0.34, 0.3, 0.02, palette["priceRailYellow"], emissive=True)
    _box(b, "scratchcard_rack", -0.5, 0.35, 0.22, 0.3, 0.3, 0.03, palette["warmLamp"])


def hot_food_counter(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "tile_wall", 0, 0, -d / 2 + 0.02, w, h, 0.04, palette["tileWhite"])
    _box(b, "kick_strip", 0, 0, d / 2 - 0.01, w, 0.08, 0.02, palette["charcoal"])
    _box(b, "counter", 0, 0, 0.02, w - 0.08, 0.86, d - 0.16, palette["primary"])
    _box(b, "counter_top", 0, 0.86, 0.02, w - 0.06, 0.04, d - 0.14, palette["woodLight"])
    _box(b, "roller_grill", -0.82, 0.9, 0.02, 0.7, 0.1, 0.42, palette["charcoal"])
    _box(b, "grill_base", -0.82, 1.0, 0.02, 0.64, 0.04, 0.36, palette["asphalt"])
    for i, name in enumerate(_have(spec, "roller")):
        _cyl(b, name, -0.82, 1.05, -0.14 + 0.055 * i, 0.02, 0.58, palette["asphalt"], segments=8, axis="x")
    for i, name in enumerate(_have(spec, "sausage")):
        _cyl(b, name, -0.95 + 0.12 * i, 1.09, -0.1 + 0.07 * i, 0.018, 0.18, palette["woodLight"] if i % 2 == 0 else palette["primaryLight"], segments=6, axis="x")
    _box(b, "heated_case", -0.05, 0.9, 0.02, 0.78, 0.08, 0.46, palette["charcoal"])
    _box(b, "case_base", -0.05, 0.98, 0.0, 0.72, 0.04, 0.4, palette["asphalt"])
    _box(b, "case_glass", -0.05, 1.02, 0.2, 0.74, 0.32, 0.016, palette["skyPastel"], opacity=0.35, roughness=0.1)
    _box(b, "case_roof", -0.05, 1.34, 0.02, 0.78, 0.03, 0.46, palette["charcoal"])
    _box(b, "case_glow", -0.05, 1.3, 0.02, 0.66, 0.015, 0.34, palette["warmLamp"], emissive=True)
    for i, name in enumerate(_have(spec, "pastry")):
        _box(b, name, -0.28 + 0.18 * i, 1.02, 0.0, 0.12, 0.06, 0.12, palette["warmLamp"] if i != 1 else palette["woodLight"])
    for i, name in enumerate(_have(spec, "baguette")):
        _cyl(b, name, -0.05, 1.1, -0.08 + 0.12 * i, 0.03, 0.5, palette["woodLight"], segments=6, axis="x")
    _box(b, "bun_warmer", 0.58, 0.9, 0.02, 0.36, 0.22, 0.36, palette["mintDeep"])
    _box(b, "warmer_body", 0.58, 0.9, 0.02, 0.32, 0.18, 0.32, palette["mintDeep"])
    _box(b, "warmer_lid", 0.58, 1.08, 0.02, 0.36, 0.03, 0.36, palette["charcoal"])
    _box(b, "condiment_station", 1.02, 0.9, 0.04, 0.28, 0.05, 0.36, palette["charcoal"])
    _box(b, "station_tray", 1.02, 0.9, 0.04, 0.26, 0.03, 0.32, palette["asphalt"])
    for i, name in enumerate(_have(spec, "pump")):
        tint = [palette["priceRailYellow"], palette["primaryLight"], palette["accentMint"]][i]
        _cyl(b, name, 1.02, 0.93, -0.08 + 0.1 * i, 0.025, 0.16, tint, segments=6)
    _box(b, "napkin_box", 1.02, 0.93, 0.16, 0.1, 0.08, 0.07, palette["cream"])


def coffee_machine(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "stand", 0, 0, 0, w, 0.34, d, palette["woodLight"])
    _box(b, "body", 0, 0.34, -0.02, w - 0.08, 0.26, d - 0.1, palette["charcoal"])
    _box(b, "screen", 0, 0.46, d / 2 - 0.03, 0.16, 0.1, 0.016, palette["accentMint"], emissive=True)
    _box(b, "spout_left", -0.06, 0.34, d / 2 - 0.04, 0.025, 0.06, 0.025, palette["asphalt"])
    _box(b, "spout_right", 0.06, 0.34, d / 2 - 0.04, 0.025, 0.06, 0.025, palette["asphalt"])
    _box(b, "drip_tray", 0, 0.34, d / 2 - 0.06, 0.22, 0.02, 0.06, palette["asphalt"])
    for i, name in enumerate(_have(spec, "cup_stack")):
        _cyl(b, name, -0.12 + 0.12 * i, 0.6, 0.0, 0.03, h - 0.6 - 0.02 * i, palette["cream"], segments=8)


def menu_screen(b, spec, palette, textures):
    w, d, h = spec.dimensions
    t = 0.012
    bars = primitives.merge(
        primitives.transform(primitives.box(w, t, d), at=(0, h - t, 0)),
        primitives.transform(primitives.box(w, t, d), at=(0, 0, 0)),
        primitives.transform(primitives.box(t, h, d), at=(-w / 2 + t / 2, 0, 0)),
        primitives.transform(primitives.box(t, h, d), at=(w / 2 - t / 2, 0, 0)),
    )
    b.part("bezel", bars, color=palette["charcoal"])
    _box(b, "screen", 0, 0.03, d / 2 - 0.016, w - 0.06, h - 0.06, 0.008, palette["primaryDeep"], emissive=True, texture=textures.get("menu_board_texture"))
    tiles = ["priceRailYellow", "accentMint", "primaryLight", "warmLamp", "mintDeep", "cream"]
    for i, name in enumerate(_have(spec, "menu_tile")):
        col, row = i % 3, i // 3
        _box(b, name, -0.72 + 0.72 * col, 0.1 + 0.38 * (1 - row), d / 2 - 0.008, 0.58, 0.28, 0.006, palette[tiles[i]])
    for i, name in enumerate(_have(spec, "price_dot")):
        col, row = i % 3, i // 3
        _cyl(b, name, -0.48 + 0.72 * col, 0.28 + 0.38 * (1 - row), d / 2 - 0.006, 0.02, 0.006, palette["charcoal"], segments=6)


def window_ledge(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "ledge_top", 0, h - 0.05, 0, w, 0.05, d, palette["woodLight"])
    _box(b, "support_left", -w / 2 + 0.04, 0, 0, 0.05, h - 0.05, d - 0.04, palette["charcoal"])
    _box(b, "support_right", w / 2 - 0.04, 0, 0, 0.05, h - 0.05, d - 0.04, palette["charcoal"])


def high_stool(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _cyl(b, "base_disc", 0, 0, 0, w / 2, 0.02, palette["charcoal"], segments=10)
    _cyl(b, "post", 0, 0.02, 0, 0.025, h - 0.1, palette["asphalt"], segments=8)
    _cyl(b, "foot_ring", 0, 0.22, 0, w * 0.28, 0.02, palette["asphalt"], segments=10)
    _cyl(b, "seat", 0, h - 0.06, 0, w * 0.34, 0.06, palette["primary"], segments=10)


def basket_stack(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "stand", 0, 0, 0, w, 0.04, d, palette["charcoal"])
    names = _have(spec, "basket")
    each = (h - 0.04) / len(names)
    for i, name in enumerate(names):
        color = palette["charcoal"] if i % 2 == 0 else palette["accentMint"]
        _box(b, name, 0, 0.04 + each * i, 0, w - 0.06, each - 0.008, d - 0.1, color)


def back_room_door(b, spec, palette, textures):
    w, d, h = spec.dimensions
    jamb = primitives.merge(
        primitives.transform(primitives.box(0.06, h, d), at=(-w / 2 + 0.03, 0, 0)),
        primitives.transform(primitives.box(0.06, h, d), at=(w / 2 - 0.03, 0, 0)),
        primitives.transform(primitives.box(w, 0.08, d), at=(0, h - 0.08, 0)),
    )
    b.part("frame", jamb, color=palette["charcoal"])
    _box(b, "door", 0, 0, 0.01, w - 0.12, h - 0.08, d - 0.06, palette["woodLight"])
    _box(b, "push_plate", 0.28, 0.9, d / 2 - 0.012, 0.1, 0.22, 0.016, palette["asphalt"])
    _box(b, "staff_only_sign", 0, 1.65, d / 2 - 0.014, 0.36, 0.12, 0.012, palette["primaryDeep"])


def pendant_lamp(b, spec, palette, textures):
    w, _, h = spec.dimensions
    _cyl(b, "bulb", 0, 0, 0, 0.06, 0.12, palette["warmLamp"], segments=8, emissive=True)
    b.part("shade", primitives.cone(w / 2, 0.32, segments=10), color=palette["primary"], at=(0, 0.1, 0))
    _cyl(b, "cord", 0, 0.4, 0, 0.012, h - 0.4, palette["charcoal"], segments=6)


def entrance_door(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "frame", 0, h - 0.08, 0, w, 0.08, d, palette["charcoal"])
    _box(b, "leaf_left", -w / 4, 0, 0, w / 2 - 0.02, h - 0.08, 0.05, palette["skyPastel"], opacity=0.35, roughness=0.1)
    _box(b, "leaf_right", w / 4, 0, 0, w / 2 - 0.02, h - 0.08, 0.05, palette["skyPastel"], opacity=0.35, roughness=0.1)
    _box(b, "handle_left", -0.06, 0.9, d / 2 - 0.03, 0.025, 0.36, 0.025, palette["cream"])
    _box(b, "handle_right", 0.06, 0.9, d / 2 - 0.03, 0.025, 0.36, 0.025, palette["cream"])
    _box(b, "mat", 0, 0, d / 2 - 0.12, w - 0.3, 0.02, 0.16, palette["primaryDeep"])


def window_poster(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "poster", 0, 0, 0, w, h - 0.22, d, palette["priceRailYellow"], texture=textures.get("window_poster_set"), u_span=(0.0, 1.0 / 3.0))
    _box(b, "headline_block", 0, h - 0.22, 0, w, 0.22, d, palette["primary"])


def atm_locker(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "atm_body", -w / 4, 0, -0.01, w / 2, h - 0.16, d - 0.02, palette["primaryDeep"])
    _box(b, "locker_body", w / 4, 0, -0.01, w / 2, h, d - 0.02, palette["primary"])
    _box(b, "atm_screen", -w / 4, 1.25, d / 2 - 0.012, w * 0.28, 0.28, 0.02, palette["accentMint"], emissive=True)
    _box(b, "keypad", -w / 4, 0.95, d / 2 - 0.016, 0.22, 0.12, 0.02, palette["asphalt"])
    doors = _have(spec, "locker_door")
    for i, name in enumerate(doors):
        color = palette["primaryLight"] if i % 2 == 0 else palette["accentMint"]
        _box(b, name, w / 4, 0.08 + (h - 0.16) / len(doors) * i, d / 2 - 0.012, w / 2 - 0.08, (h - 0.2) / len(doors), 0.02, color)


def a_frame_sign(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "leg_left", -w / 2 + 0.02, 0, 0, 0.04, h, d, palette["woodLight"])
    _box(b, "leg_right", w / 2 - 0.02, 0, 0, 0.04, h, d, palette["woodLight"])
    mark = textures.get("plum_mark")
    _box(b, "board", 0, 0.22, 0.04, w - 0.1, 0.5, 0.03, palette["charcoal"], texture=mark, texture_background=palette["charcoal"])
    _box(b, "board_text", 0, 0.34, 0.065, w - 0.16, 0.22, 0.012, palette["cream"], texture=mark, texture_background=palette["charcoal"])


def litter_bin(b, spec, palette, textures):
    w, _, h = spec.dimensions
    _cyl(b, "post", 0, 0, 0, 0.04, 0.32, palette["charcoal"], segments=8)
    _cyl(b, "body", 0, 0.28, 0, w / 2, h - 0.36, palette["mintDeep"], segments=10)
    _cyl(b, "lid", 0, h - 0.08, 0, w / 2, 0.08, palette["charcoal"], segments=10)


def bike_rack(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "base", 0, 0, 0, w, 0.04, d, palette["asphalt"])
    hoops = _have(spec, "hoop")
    for i, name in enumerate(hoops):
        x = -0.46 + 0.46 * i
        _box(b, name, x, 0.04, 0, 0.24, 0.03, d - 0.04, palette["charcoal"])
        _box(b, f"hoop_{i}_post_left", x - 0.09, 0.07, 0, 0.03, h - 0.14, 0.03, palette["charcoal"])
        _box(b, f"hoop_{i}_post_right", x + 0.09, 0.07, 0, 0.03, h - 0.14, 0.03, palette["charcoal"])
        _box(b, f"hoop_{i}_bar", x, h - 0.04, 0, 0.21, 0.04, 0.03, palette["charcoal"])


def street_lamp(b, spec, palette, textures):
    _, _, h = spec.dimensions
    _cyl(b, "post", -0.3, 0, 0, 0.1, h - 0.2, palette["charcoal"], segments=8)
    _box(b, "arm", -0.02, h - 0.28, 0, 0.55, 0.05, 0.05, palette["charcoal"])
    _box(b, "head", 0.26, h - 0.16, 0, 0.28, 0.16, 0.3, palette["charcoal"])
    _box(b, "glow", 0.26, h - 0.22, 0, 0.2, 0.04, 0.18, palette["warmLamp"], emissive=True)


def self_checkout(b, spec, palette, textures):
    w, d, h = spec.dimensions
    _box(b, "base", 0, 0, 0, w - 0.05, 0.1, d, palette["charcoal"])
    for side, x in (("left", -0.2), ("right", 0.2)):
        _box(b, f"body_{side}", x, 0.1, 0, 0.3, 0.9, 0.4, palette["primary"])
        _box(b, f"screen_{side}", x, 1.0, d / 2 - 0.03, 0.3, 0.3, 0.02, palette["accentMint"], emissive=True)
        _box(b, f"scanner_{side}", x, 1.0, 0, 0.24, 0.03, 0.2, palette["asphalt"])
        _box(b, f"card_terminal_{side}", x, 0.6, d / 2 - 0.05, 0.1, 0.05, 0.1, palette["charcoal"])
    for side, x in (("left", -0.4), ("right", 0.4)):
        _box(b, f"bagging_shelf_{side}", x, 0.85, 0, 0.2, 0.03, d - 0.1, palette["woodLight"])
    for side, x in (("left", -0.2), ("right", 0.2)):
        _cyl(b, f"light_pole_{side}", x, 1.0, -d / 2 + 0.06, 0.015, 0.5, palette["charcoal"], segments=8)
        _cyl(b, f"beacon_{side}", x, 1.5, -d / 2 + 0.06, 0.03, 0.1, palette["priceRailYellow"], segments=8, emissive=True)


def alcohol_wall(b, spec, palette, textures):
    """A thin empty frame, one bottle deep. The app draws the shelves, rails, bottles and labels from the planogram."""
    w, d, h = spec.dimensions
    header = 0.16
    top = h - header
    _box(b, "base", 0, 0, 0, w, 0.10, d, palette["charcoal"])
    _box(b, "upright_left", -w / 2 + 0.02, 0.10, 0, 0.04, top - 0.10, d, palette["charcoal"])
    _box(b, "upright_right", w / 2 - 0.02, 0.10, 0, 0.04, top - 0.10, d, palette["charcoal"])
    _box(b, "back_panel", 0, 0.10, -d / 2 + 0.01, w - 0.08, top - 0.10, 0.02, palette["cream"])
    _box(b, "header_sign", 0, top, 0, w, header, d, palette["primary"])


BUILDERS = {
    "gondola_shelf": gondola_shelf,
    "wall_shelf": wall_shelf,
    "end_cap": end_cap,
    "wall_fridge": wall_fridge,
    "dairy_chiller": dairy_chiller,
    "checkout_counter": checkout_counter,
    "cigarette_cabinet": cigarette_cabinet,
    "hot_food_counter": hot_food_counter,
    "coffee_machine": coffee_machine,
    "menu_screen": menu_screen,
    "window_ledge": window_ledge,
    "high_stool": high_stool,
    "basket_stack": basket_stack,
    "back_room_door": back_room_door,
    "pendant_lamp": pendant_lamp,
    "entrance_door": entrance_door,
    "window_poster": window_poster,
    "atm_locker": atm_locker,
    "a_frame_sign": a_frame_sign,
    "litter_bin": litter_bin,
    "bike_rack": bike_rack,
    "street_lamp": street_lamp,
    "self_checkout": self_checkout,
    "alcohol_wall": alcohol_wall,
}
