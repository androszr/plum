#!/usr/bin/env python3
"""Structural checks for generated models and signage. The brief is the spec."""

from __future__ import annotations

import argparse
import importlib
import os
import re
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image
from pxr import Usd, UsdGeom, UsdShade

from assetgen.brief import load_brief

# A sourced file may embed nothing bigger than this on either side.
MAX_SOURCED_IMAGE = 2048

SIGNAGE = {
    "plum_mark",
    "storefront_sign",
    "price_strip",
    "window_poster_set",
    "menu_board_texture",
}


def _fronts(name: str) -> list[str]:
    module = importlib.import_module(f"assetgen.assets.{name}")
    return list(module.FRONT_PARTS)


# Only these assets carry a packet, a can and a bottle at every spot; the app shows one.
SHAPED_ASSETS = {"gondola_shelf", "wall_shelf", "end_cap"}
SHAPE_MESH = re.compile(r"^(product|product_back)_[0-9]+_[0-9]+_(packet|can|bottle)$")
OLD_PRODUCT_MESH = re.compile(r"^(product|product_back)_[0-9]+_[0-9]+$")
MAX_SHAPE_TRIANGLES = 48


def _fail(asset: str, rule: str) -> None:
    raise RuntimeError(f"{asset}: {rule}")


def _mesh_prims(stage):
    found = {}
    for prim in stage.Traverse():
        if prim.IsA(UsdGeom.Mesh):
            found[prim.GetName()] = prim
    return found


def _triangles(prim) -> int:
    counts = UsdGeom.Mesh(prim).GetFaceVertexCountsAttr().Get() or []
    return sum(count - 2 for count in counts)


def _centroid_z(prim) -> float:
    points = UsdGeom.Mesh(prim).GetPointsAttr().Get() or []
    if not points:
        return 0.0
    return sum(point[2] for point in points) / len(points)


def _texture_paths(stage) -> list[str]:
    paths = []
    for prim in stage.Traverse():
        shader = UsdShade.Shader(prim)
        if not shader:
            continue
        ident = shader.GetIdAttr().Get()
        if ident != "UsdUVTexture":
            continue
        file_input = shader.GetInput("file")
        asset = file_input.Get() if file_input else None
        path = ""
        if asset is not None:
            path = asset.path if hasattr(asset, "path") else str(asset)
        paths.append(path)
    return paths


def _check_model(name: str, spec, models: str) -> None:
    path = os.path.join(models, f"{name}.usdz")
    if not os.path.isfile(path):
        _fail(name, "file missing")
    stage = Usd.Stage.Open(path)
    if stage is None:
        _fail(name, "stage did not open")
    if UsdGeom.GetStageUpAxis(stage) != UsdGeom.Tokens.y:
        _fail(name, "upAxis is not Y")
    if abs(UsdGeom.GetStageMetersPerUnit(stage) - 1.0) > 1e-6:
        _fail(name, "metersPerUnit is not 1")
    default = stage.GetDefaultPrim()
    if not default:
        _fail(name, "no default prim")
    cache = UsdGeom.BBoxCache(Usd.TimeCode.Default(), [UsdGeom.Tokens.default_])
    aligned = cache.ComputeWorldBound(default).ComputeAlignedRange()
    minimum, maximum = aligned.GetMin(), aligned.GetMax()
    width, depth, height = spec.dimensions
    measured = (
        ("width", width, minimum[0], maximum[0]),
        ("depth", depth, minimum[2], maximum[2]),
        ("height", height, minimum[1], maximum[1]),
    )
    for label, span, lo, hi in measured:
        size = hi - lo
        allowance = max(0.05 * span, 0.02)
        if abs(size - span) > allowance:
            _fail(name, f"{label} {size:.3f} is outside {span:.3f} ± {allowance:.3f}")
    if abs(minimum[1]) > 0.01:
        _fail(name, f"bottom y {minimum[1]:.4f} is not on the ground")
    centre_x = (minimum[0] + maximum[0]) / 2
    centre_z = (minimum[2] + maximum[2]) / 2
    if abs(centre_x) > 0.01 or abs(centre_z) > 0.01:
        _fail(name, f"footprint centre is {centre_x:.4f}, {centre_z:.4f}")
    meshes = _mesh_prims(stage)
    for part in spec.parts:
        if part not in meshes:
            _fail(name, f"part {part} is missing")
    # Every mesh counts, hidden shape meshes included: there is no visibility filter here.
    triangles = sum(_triangles(prim) for prim in meshes.values())
    if spec.poly_budget is not None and triangles > spec.poly_budget:
        _fail(name, f"{triangles} triangles over budget {spec.poly_budget}")
    if name in SHAPED_ASSETS:
        for part, prim in meshes.items():
            if OLD_PRODUCT_MESH.match(part):
                _fail(name, f"{part} is a single product mesh; use _packet, _can and _bottle meshes")
            if SHAPE_MESH.match(part) and _triangles(prim) > MAX_SHAPE_TRIANGLES:
                _fail(name, f"{part} has {_triangles(prim)} triangles, over {MAX_SHAPE_TRIANGLES} per shape mesh")
    for part in _fronts(name):
        if part not in meshes:
            _fail(name, f"front part {part} is missing")
        z = _centroid_z(meshes[part])
        if z < 0:
            _fail(name, f"front part {part} centroid z {z:.4f} is behind the origin")
    with zipfile.ZipFile(path) as package:
        packed = set(package.namelist())
    for texture in _texture_paths(stage):
        if os.path.isabs(texture) or texture.startswith("/") or ".." in texture.split("/"):
            _fail(name, f"texture path {texture} is not inside the package")
        relative = texture[2:] if texture.startswith("./") else texture
        if relative not in packed:
            _fail(name, f"texture {texture} is not inside the package")


def _check_sourced(name: str, spec, shipped: str) -> None:
    """A sourced file is made elsewhere: prove it is there, opens and is within budget."""
    path = os.path.join(shipped, f"{name}.usdz")
    if not os.path.isfile(path):
        _fail(name, "sourced file missing")
    stage = Usd.Stage.Open(path)
    if stage is None:
        _fail(name, "stage did not open")
    triangles = sum(_triangles(prim) for prim in _mesh_prims(stage).values())
    if triangles == 0:
        _fail(name, "no triangles")
    if spec.poly_budget is not None and triangles > spec.poly_budget:
        _fail(name, f"{triangles} triangles over budget {spec.poly_budget}")
    with zipfile.ZipFile(path) as package:
        for member in package.namelist():
            if not member.lower().endswith((".png", ".jpg", ".jpeg")):
                continue
            with package.open(member) as handle, Image.open(handle) as image:
                if max(image.size) > MAX_SOURCED_IMAGE:
                    _fail(name, f"embedded image {member} is {image.size[0]} x {image.size[1]}, limit {MAX_SOURCED_IMAGE}")


def _check_signage(name: str, spec, models: str) -> None:
    png = os.path.join(models, f"{name}.png")
    if not os.path.isfile(png):
        _fail(name, "png missing")
    with Image.open(png) as image:
        if image.size != spec.pixels:
            _fail(name, f"png is {image.size[0]} x {image.size[1]}, brief wants {spec.pixels[0]} x {spec.pixels[1]}")
    if "svg" in spec.format.lower():
        svg = os.path.join(models, f"{name}.svg")
        if not os.path.isfile(svg):
            _fail(name, "svg missing")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--brief", required=True)
    parser.add_argument("--models", required=True)
    parser.add_argument("--shipped", help="folder holding the sourced files (App/Resources/Models)")
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()
    only = set(args.only) if args.only else None
    brief = load_brief(args.brief)
    checked = 0
    sourced = 0
    for name, spec in brief.specs.items():
        if only and name not in only:
            continue
        if spec.pending or spec.external:
            continue
        if spec.sourced:
            if not args.shipped:
                _fail(name, "sourced: pass --shipped <dir> to check it")
            _check_sourced(name, spec, args.shipped)
            sourced += 1
        elif spec.is_signage or name in SIGNAGE:
            _check_signage(name, spec, args.models)
        else:
            _check_model(name, spec, args.models)
            checked += 1
    print(f"{checked} models checked, {sourced} sourced")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"check.py: {exc}", file=sys.stderr)
        sys.exit(1)
