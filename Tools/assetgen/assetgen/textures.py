"""Picture helpers. The bundled Pillow font is the only typeface, so every machine draws the same pixels."""

from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont


def rgb(color: tuple[float, float, float]) -> tuple[int, int, int]:
    return tuple(int(round(channel * 255)) for channel in color)  # type: ignore[return-value]


def rgba(color: tuple[float, float, float], alpha: int = 255) -> tuple[int, int, int, int]:
    r, g, b = rgb(color)
    return (r, g, b, alpha)


def canvas(w: int, h: int, color: tuple[float, float, float] | None) -> Image.Image:
    fill = (0, 0, 0, 0) if color is None else rgba(color)
    return Image.new("RGBA", (w, h), fill)


def font(size: int) -> ImageFont.ImageFont:
    return ImageFont.load_default(size=size)


def text(draw: ImageDraw.ImageDraw, xy, message: str, size: int, color: tuple[float, float, float]) -> None:
    draw.text(xy, message, font=font(size), fill=rgba(color), anchor="mm")


def plum_mark(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, body, leaf, highlight) -> None:
    cx, cy = center
    draw.ellipse((cx - radius, cy - radius * 0.92, cx + radius, cy + radius * 1.05), fill=rgba(body))
    leaf_w, leaf_h = radius * 0.42, radius * 0.72
    lx, ly = cx + radius * 0.42, cy - radius * 0.85
    draw.ellipse((lx - leaf_w, ly - leaf_h, lx + leaf_w, ly + leaf_h), fill=rgba(leaf))
    hx, hy = cx - radius * 0.28, cy - radius * 0.22
    draw.ellipse((hx - radius * 0.28, hy - radius * 0.16, hx + radius * 0.28, hy + radius * 0.16), fill=rgba(highlight))


def save_png(image: Image.Image, path: str) -> None:
    image.save(path, format="PNG", optimize=True)


def composite_mark(mark_path: str, background: tuple[float, float, float], size: tuple[int, int]) -> Image.Image:
    """Opaque panel with the mark sitting at the left, used inside a model."""
    image = canvas(size[0], size[1], background)
    mark = Image.open(mark_path).convert("RGBA")
    side = int(min(size[1] * 0.86, size[0] * 0.28))
    mark = mark.resize((side, side), Image.Resampling.NEAREST)
    image.alpha_composite(mark, (int(size[0] * 0.03), (size[1] - side) // 2))
    return image
