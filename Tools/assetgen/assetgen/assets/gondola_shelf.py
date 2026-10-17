"""gondola_shelf fixture. Geometry lives in the shared builder."""

from . import _build

NAME = "gondola_shelf"
FRONT_PARTS = _build.FRONT[NAME]


def build(spec, palette, textures):
    return _build.build_asset(NAME, spec, palette, textures)
