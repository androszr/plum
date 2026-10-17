"""hot_food_counter fixture. Geometry lives in the shared builder."""

from . import _build

NAME = "hot_food_counter"
FRONT_PARTS = _build.FRONT[NAME]


def build(spec, palette, textures):
    return _build.build_asset(NAME, spec, palette, textures)
