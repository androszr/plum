"""self_checkout fixture. Geometry lives in the shared builder."""

from . import _build

NAME = "self_checkout"
FRONT_PARTS = _build.FRONT[NAME]


def build(spec, palette, textures):
    return _build.build_asset(NAME, spec, palette, textures)
