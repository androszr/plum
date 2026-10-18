"""Read sizes, budgets and part names from the asset brief. Nothing here is a second copy of those numbers."""

from __future__ import annotations

import re
from dataclasses import dataclass, field


_HEX_ROW = re.compile(r"#[0-9A-Fa-f]{6}")
_DIM = re.compile(
    r"Dimensions:\s*(?:(\d+)\s+posters,\s*)?"
    r"(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)"
    r"(?:\s*x\s*(\d+(?:\.\d+)?))?\s*(m|px)",
    re.IGNORECASE,
)


@dataclass
class Spec:
    name: str
    dimensions: tuple[float, float, float] | None
    pixels: tuple[int, int] | None
    panels: int
    poly_budget: int | None
    parts: list[str]
    format: str
    palette_names: list[str] = field(default_factory=list)
    # True when the section says `Status: stand-in only`: no model yet, generator and checker skip it.
    pending: bool = False
    sourced: bool = False
    # True when the section says `Status: external ...`: made outside the generator and shipped in
    # App/Resources/Characters/, so the generator and the checker skip it.
    external: bool = False

    @property
    def is_signage(self) -> bool:
        return self.dimensions is None


@dataclass
class Brief:
    palette: dict[str, tuple[float, float, float]]
    specs: dict[str, Spec]


def _rgb(hex_text: str) -> tuple[float, float, float]:
    h = hex_text[1:]
    return tuple(int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def _line_value(body: str, label: str, section: str) -> str:
    for i, line in enumerate(body.splitlines(), start=1):
        if line.startswith(label):
            return line.split(":", 1)[1].strip()
    raise ValueError(f"{section}: missing {label} line")


def _optional_line_value(body: str, label: str) -> str | None:
    for line in body.splitlines():
        if line.startswith(label):
            return line.split(":", 1)[1].strip()
    return None


def _split_commas(text: str) -> list[str]:
    parts: list[str] = []
    buf: list[str] = []
    depth = 0
    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth = max(0, depth - 1)
        if ch == "," and depth == 0:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append("".join(buf))
    return parts


def _expand_range(token: str) -> list[str] | None:
    matched = re.fullmatch(r"([a-z][a-z0-9_]*?)_(\d+)-(\d+)", token)
    if matched:
        stem, a, b = matched.group(1), int(matched.group(2)), int(matched.group(3))
        return [f"{stem}_{i}" for i in range(a, b + 1)]
    if re.fullmatch(r"[a-z][a-z0-9_]*", token):
        return [token]
    return None


def _at_least(text: str) -> int | None:
    matched = re.search(r"at least (\d+)", text)
    return int(matched.group(1)) if matched else None


def _expand_template(token: str, count: int | None, shelves: list[int], hoops: list[int]) -> list[str]:
    matched = re.fullmatch(r"([a-z][a-z0-9_]*)_<shelf>_<i>", token) or re.fullmatch(
        r"([a-z][a-z0-9_]*)_<shelf>_<facing>", token
    )
    if matched:
        stem = matched.group(1)
        rows = shelves or [0]
        per = max(1, -(-(count or len(rows)) // len(rows)))
        return [f"{stem}_{shelf}_{i}" for shelf in rows for i in range(per)]
    matched = re.fullmatch(r"hoop_<i>_([a-z0-9_]+)", token)
    if matched:
        return [f"hoop_{i}_{matched.group(1)}" for i in hoops]
    matched = re.fullmatch(r"([a-z][a-z0-9_]*)_<i>", token)
    if matched:
        return [f"{matched.group(1)}_{i}" for i in range(count or 1)]
    return []


def part_names(parts_line: str) -> list[str]:
    """Concrete prim names from a brief Parts line. Ranges expand; prose does not."""
    text = parts_line.split(".", 1)[0]
    shelves: list[int] = []
    shelf_match = re.search(r"shelf_(\d+)-(\d+)", text)
    if shelf_match:
        shelves = list(range(int(shelf_match.group(1)), int(shelf_match.group(2)) + 1))
    hoops: list[int] = []
    hoop_match = re.search(r"hoop_(\d+)-(\d+)", text)
    if hoop_match:
        hoops = list(range(int(hoop_match.group(1)), int(hoop_match.group(2)) + 1))

    names: list[str] = []
    seen: set[str] = set()

    def add_many(found: list[str]) -> None:
        for name in found:
            if name not in seen:
                seen.add(name)
                names.append(name)

    def take_segment(segment: str) -> None:
        segment = segment.strip()
        if not segment:
            return
        matched = re.match(r"^([^(]*?)(?:\((.*)\))?$", segment)
        head = (matched.group(1) if matched else segment).strip()
        paren = (matched.group(2) or "").strip() if matched else ""
        first = head.split()[0] if head else ""
        if re.match(r"product rows\b", head):
            count = _at_least(paren) or _at_least(head) or 16
            rows = shelves or [0]
            per = max(1, -(-count // len(rows)))
            add_many([f"product_{shelf}_{i}" for shelf in rows for i in range(per)])
        else:
            expanded = _expand_range(first)
            # A bare word followed by more words is prose ("six dish tiles"), not a prim.
            prose_phrase = bool(head.split()[1:]) and "_" not in first and not re.search(r"\d+-\d+", first)
            if expanded is not None and "<" not in first and not prose_phrase:
                add_many(expanded)
            for token in re.findall(r"[a-z][a-z0-9_]*_<[^>]+>(?:_[a-z0-9_<>]+)*", head):
                add_many(_expand_template(token, _at_least(head) or _at_least(paren), shelves, hoops))
        if not paren:
            return
        for piece in _split_commas(paren):
            piece = piece.strip()
            templates = re.findall(r"[a-z][a-z0-9_]*_<[^>]+>(?:_[a-z0-9_<>]+)*", piece)
            if templates:
                count = _at_least(piece) or _at_least(paren)
                for token in templates:
                    add_many(_expand_template(token, count, shelves, hoops))
                continue
            lead = piece.split()[0]
            expanded = _expand_range(lead)
            # A parenthetical is a name list only when the token looks like a prim, not prose.
            if expanded is not None and ("_" in lead or re.search(r"\d+-\d+", lead)):
                add_many(expanded)

    for segment in _split_commas(text):
        take_segment(segment)
    return names


# The three shelf assets carry a packet, a can and a bottle at every spot; the app shows one.
SHAPED_ASSETS = ("gondola_shelf", "wall_shelf", "end_cap")
SHAPES = ("packet", "can", "bottle")


def shaped_parts(name: str, parts: list[str]) -> list[str]:
    """Replace each `product_<shelf>_<i>` of a shelf asset with its three shape meshes.

    The gondola is double-sided, so it also gets a `product_back_<shelf>_<i>` row.
    """
    if name not in SHAPED_ASSETS:
        return parts
    out: list[str] = []
    for part in parts:
        matched = re.fullmatch(r"product_(\d+)_(\d+)", part)
        if not matched:
            out.append(part)
            continue
        stems = ["product", "product_back"] if name == "gondola_shelf" else ["product"]
        for stem in stems:
            out.extend(f"{stem}_{matched.group(1)}_{matched.group(2)}_{shape}" for shape in SHAPES)
    return out


def _palette_names(palette_line: str) -> list[str]:
    return re.findall(r"\b([a-z][A-Za-z0-9]*)\b", palette_line)


def _is_sourced(body: str) -> bool:
    """True when the section has a `Source:` line that is not `generated`."""
    for line in body.splitlines():
        if line.startswith("Source:"):
            value = line.split(":", 1)[1].strip()
            return bool(value) and value.lower() != "generated"
    return False


def load_brief(path: str) -> Brief:
    text = open(path, encoding="utf-8").read()
    palette: dict[str, tuple[float, float, float]] = {}
    for line in text.splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        hexes = [cell for cell in cells if _HEX_ROW.fullmatch(cell)]
        names = [cell for cell in cells if re.fullmatch(r"[A-Za-z][A-Za-z0-9]+", cell)]
        if hexes and names:
            palette[names[0]] = _rgb(hexes[0])
    if not palette:
        raise ValueError(f"{path}: palette table has no colours")

    specs: dict[str, Spec] = {}
    chunks = text.split("\n### ")
    for chunk in chunks[1:]:
        name = chunk.splitlines()[0].strip()
        body = chunk
        dim_line = _line_value(body, "Dimensions:", name)
        dim = _DIM.search("Dimensions: " + dim_line)
        if not dim:
            raise ValueError(f"{name}: Dimensions line {dim_line!r} is not w x d x h or a pixel size")
        panels = int(dim.group(1) or 1)
        a, b, c = dim.group(2), dim.group(3), dim.group(4)
        unit = dim.group(5).lower()
        dimensions = None
        pixels = None
        if unit == "m":
            if c is None:
                raise ValueError(f"{name}: model dimensions need three numbers (line: {dim_line})")
            dimensions = (float(a), float(b), float(c))
        else:
            width = int(float(a)) * panels
            height = int(float(b if c is None else c))
            # "3 posters, 1024 x 1448 px each" → one atlas, panels side by side.
            pixels = (width, height)
        budget_line = _line_value(body, "Poly budget:", name)
        budget_match = re.search(r"\d+", budget_line)
        budget = int(budget_match.group(0)) if budget_match and "not applicable" not in budget_line.lower() else None
        if unit == "m" and budget is None:
            raise ValueError(f"{name}: missing Poly budget integer")
        parts_line = _line_value(body, "Parts:", name)
        format_line = _line_value(body, "Format:", name)
        _line_value(body, "Pivot:", name)
        _line_value(body, "Palette:", name)
        _line_value(body, "Prompt:", name)
        status = _optional_line_value(body, "Status:")
        specs[name] = Spec(
            name=name,
            dimensions=dimensions,
            pixels=pixels,
            panels=panels,
            poly_budget=budget,
            parts=shaped_parts(name, part_names(parts_line)),
            format=format_line,
            palette_names=_palette_names(_line_value(body, "Palette:", name)),
            pending=status is not None and "stand-in only" in status,
            sourced=_is_sourced(body),
            external=status is not None and status.strip().lower().startswith("external"),
        )
    return Brief(palette=palette, specs=specs)
