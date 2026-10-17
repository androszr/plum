"""street_lamp fixture. Geometry lives in the shared builder."""

from . import _build

NAME = "street_lamp"
FRONT_PARTS = _build.FRONT[NAME]


def build(spec, palette, textures):
    return _build.build_asset(NAME, spec, palette, textures)
