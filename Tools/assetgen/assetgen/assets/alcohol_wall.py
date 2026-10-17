"""alcohol_wall fixture. Geometry lives in the shared builder."""

from . import _build

NAME = "alcohol_wall"
FRONT_PARTS = _build.FRONT[NAME]


def build(spec, palette, textures):
    return _build.build_asset(NAME, spec, palette, textures)
