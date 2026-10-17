"""Assemble named meshes into one USDZ with pinned zip timestamps."""

from __future__ import annotations

import os
import random
import shutil
from dataclasses import dataclass

from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils

from . import primitives
from .brief import Spec
from .textures import composite_mark, save_png


_DOS_TIME = 0
_DOS_DATE = 0x0021  # 1980-01-01, the fixed stamp every package shares


@dataclass
class _Part:
    mesh: primitives.Mesh
    color: tuple[float, float, float]
    texture: str | None
    texture_background: tuple[float, float, float] | None
    emissive: bool
    opacity: float
    roughness: float
    u_span: tuple[float, float]


def pin_zip_timestamps(path: str) -> None:
    """Rewrite every local-header and central-directory time in place. Lengths stay put."""
    data = bytearray(open(path, "rb").read())
    time_b = _DOS_TIME.to_bytes(2, "little")
    date_b = _DOS_DATE.to_bytes(2, "little")
    i = 0
    n = len(data)
    while i + 4 <= n:
        sig = int.from_bytes(data[i : i + 4], "little")
        if sig == 0x04034B50:
            data[i + 10 : i + 12] = time_b
            data[i + 12 : i + 14] = date_b
            comp = int.from_bytes(data[i + 18 : i + 22], "little")
            name_len = int.from_bytes(data[i + 26 : i + 28], "little")
            extra_len = int.from_bytes(data[i + 28 : i + 30], "little")
            i += 30 + name_len + extra_len + comp
        elif sig == 0x02014B50:
            data[i + 12 : i + 14] = time_b
            data[i + 14 : i + 16] = date_b
            name_len = int.from_bytes(data[i + 28 : i + 30], "little")
            extra_len = int.from_bytes(data[i + 30 : i + 32], "little")
            comment_len = int.from_bytes(data[i + 32 : i + 34], "little")
            i += 46 + name_len + extra_len + comment_len
        elif sig == 0x06054B50:
            break
        else:
            raise RuntimeError(f"zip walk lost its place at byte {i} in {path}")
    open(path, "wb").write(data)


class AssetBuilder:
    def __init__(self, name: str, spec: Spec):
        self.name = name
        self.spec = spec
        self.rng = random.Random(name)
        self._parts: dict[str, _Part] = {}

    def part(
        self,
        name: str,
        mesh: primitives.Mesh,
        color: tuple[float, float, float],
        texture: str | None = None,
        texture_background: tuple[float, float, float] | None = None,
        emissive: bool = False,
        opacity: float = 1.0,
        at=(0.0, 0.0, 0.0),
        yaw: float = 0.0,
        roughness: float = 0.6,
        u_span: tuple[float, float] | None = None,
    ) -> None:
        if u_span is not None:
            mesh = primitives.Mesh(mesh.points, mesh.counts, mesh.indices, _retile(mesh.uvs, u_span), mesh.normals)
        self._parts[name] = _Part(
            mesh=primitives.transform(mesh, at=at, yaw=yaw),
            color=color,
            texture=texture,
            texture_background=texture_background,
            emissive=emissive,
            opacity=opacity,
            roughness=roughness,
            u_span=u_span or (0.0, 1.0),
        )

    def write(self, out_dir: str) -> str:
        missing = [name for name in self.spec.parts if name not in self._parts]
        extra = [name for name in self._parts if name not in self.spec.parts]
        if missing or extra:
            raise RuntimeError(f"{self.name}: missing parts {missing}, extra parts {extra}")
        self._require_bounds()
        # Tools/assetgen/assetgen/builder.py → Tools/assetgen/.staging
        staging = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".staging"))
        os.makedirs(staging, exist_ok=True)
        asset_dir = os.path.join(staging, self.name)
        if os.path.isdir(asset_dir):
            shutil.rmtree(asset_dir)
        os.makedirs(asset_dir)
        try:
            usdc = os.path.join(asset_dir, f"{self.name}.usdc")
            stage = Usd.Stage.CreateNew(usdc)
            UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
            UsdGeom.SetStageMetersPerUnit(stage, 1.0)
            root = UsdGeom.Xform.Define(stage, f"/{self.name}")
            stage.SetDefaultPrim(root.GetPrim())
            copied: dict[str, str] = {}
            for name in self.spec.parts:
                part = self._parts[name]
                tex_file = None
                if part.texture:
                    tex_file = copied.get((part.texture, part.texture_background))
                    if tex_file is None:
                        tex_file = _stage_texture(part, asset_dir, name)
                        copied[(part.texture, part.texture_background)] = tex_file
                _define_mesh(stage, self.name, name, part, tex_file)
            stage.GetRootLayer().Save()
            del stage
            usdz = os.path.join(asset_dir, f"{self.name}.usdz")
            if not UsdUtils.CreateNewUsdzPackage(usdc, usdz):
                raise RuntimeError(f"{self.name}: CreateNewUsdzPackage failed")
            pin_zip_timestamps(usdz)
            dest = os.path.join(out_dir, f"{self.name}.usdz")
            os.makedirs(out_dir, exist_ok=True)
            os.replace(usdz, dest)
            return dest
        finally:
            shutil.rmtree(asset_dir, ignore_errors=True)

    def _require_bounds(self) -> None:
        assert self.spec.dimensions is not None
        w, d, h = self.spec.dimensions
        mn, mx = _bounds(self._parts)
        for label, span, lo, hi in (
            ("width", w, mn[0], mx[0]),
            ("depth", d, mn[2], mx[2]),
            ("height", h, mn[1], mx[1]),
        ):
            size = hi - lo
            allowance = max(0.05 * span, 0.02)
            if abs(size - span) > allowance:
                raise RuntimeError(f"{self.name}: {label} {size:.3f} is not {span:.3f} (±{allowance:.3f})")
        if abs(mn[1]) > 0.01:
            raise RuntimeError(f"{self.name}: bottom y {mn[1]:.4f} is not on the ground")
        if abs((mn[0] + mx[0]) / 2) > 0.01 or abs((mn[2] + mx[2]) / 2) > 0.01:
            raise RuntimeError(f"{self.name}: footprint centre is {(mn[0] + mx[0]) / 2:.4f}, {(mn[2] + mx[2]) / 2:.4f}")
        tris = sum(count - 2 for part in self._parts.values() for count in part.mesh.counts)
        if self.spec.poly_budget is not None and tris > self.spec.poly_budget:
            raise RuntimeError(f"{self.name}: {tris} triangles over budget {self.spec.poly_budget}")


def _retile(uvs, u_span):
    u0, u1 = u_span
    return [((1 - uv[0]) * u0 + uv[0] * u1, uv[1]) for uv in uvs]


def _bounds(parts: dict[str, _Part]):
    xs, ys, zs = [], [], []
    for part in parts.values():
        for x, y, z in part.mesh.points:
            xs.append(x)
            ys.append(y)
            zs.append(z)
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))


def _stage_texture(part: _Part, asset_dir: str, part_name: str) -> str:
    assert part.texture is not None
    base = os.path.basename(part.texture)
    if part.texture_background is not None:
        image = composite_mark(part.texture, part.texture_background, (1024, 512))
        # Keep the mark's file name so the package references the signage asset.
        dest_name = base
        dest = os.path.join(asset_dir, dest_name)
        if os.path.exists(dest):
            dest_name = f"{part_name}_{base}"
            dest = os.path.join(asset_dir, dest_name)
        save_png(image, dest)
        return dest_name
    dest = os.path.join(asset_dir, base)
    if not os.path.exists(dest):
        shutil.copyfile(part.texture, dest)
    return base


def _define_mesh(stage, asset: str, name: str, part: _Part, tex_file: str | None) -> None:
    mesh = UsdGeom.Mesh.Define(stage, f"/{asset}/{name}")
    points = [Gf.Vec3f(*p) for p in part.mesh.points]
    mesh.CreatePointsAttr(points)
    mesh.CreateFaceVertexCountsAttr(part.mesh.counts)
    mesh.CreateFaceVertexIndicesAttr(part.mesh.indices)
    mesh.CreateNormalsAttr([Gf.Vec3f(*n) for n in part.mesh.normals])
    mesh.SetNormalsInterpolation(UsdGeom.Tokens.faceVarying)
    mesh.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)
    mesh.CreateDoubleSidedAttr(True)
    xs = [p[0] for p in part.mesh.points]
    ys = [p[1] for p in part.mesh.points]
    zs = [p[2] for p in part.mesh.points]
    mesh.CreateExtentAttr([Gf.Vec3f(min(xs), min(ys), min(zs)), Gf.Vec3f(max(xs), max(ys), max(zs))])
    primvar = UsdGeom.PrimvarsAPI(mesh.GetPrim()).CreatePrimvar(
        "st", Sdf.ValueTypeNames.TexCoord2fArray, UsdGeom.Tokens.faceVarying
    )
    primvar.Set([Gf.Vec2f(*uv) for uv in part.mesh.uvs])
    _bind(stage, asset, name, mesh.GetPrim(), part, tex_file)


def _bind(stage, asset: str, name: str, prim, part: _Part, tex_file: str | None) -> None:
    material = UsdShade.Material.Define(stage, f"/{asset}/Materials/{name}")
    shader = UsdShade.Shader.Define(stage, f"/{asset}/Materials/{name}/Surface")
    shader.CreateIdAttr("UsdPreviewSurface")
    shader.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(part.roughness)
    shader.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(0.0)
    shader.CreateInput("opacity", Sdf.ValueTypeNames.Float).Set(float(part.opacity))
    shader.CreateInput("ior", Sdf.ValueTypeNames.Float).Set(1.5)
    color = Gf.Vec3f(*part.color)
    if tex_file:
        reader = UsdShade.Shader.Define(stage, f"/{asset}/Materials/{name}/St")
        reader.CreateIdAttr("UsdPrimvarReader_float2")
        reader.CreateInput("varname", Sdf.ValueTypeNames.String).Set("st")
        reader.CreateOutput("result", Sdf.ValueTypeNames.Float2)
        tex = UsdShade.Shader.Define(stage, f"/{asset}/Materials/{name}/Tex")
        tex.CreateIdAttr("UsdUVTexture")
        tex.CreateInput("file", Sdf.ValueTypeNames.Asset).Set(Sdf.AssetPath(f"./{tex_file}"))
        tex.CreateInput("st", Sdf.ValueTypeNames.Float2).ConnectToSource(reader.ConnectableAPI(), "result")
        tex.CreateInput("wrapS", Sdf.ValueTypeNames.Token).Set("clamp" if part.texture_background else "repeat")
        tex.CreateInput("wrapT", Sdf.ValueTypeNames.Token).Set("clamp" if part.texture_background else "repeat")
        tex.CreateInput("sourceColorSpace", Sdf.ValueTypeNames.Token).Set("sRGB")
        tex.CreateOutput("rgb", Sdf.ValueTypeNames.Float3)
        shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).ConnectToSource(tex.ConnectableAPI(), "rgb")
        if part.emissive:
            shader.CreateInput("emissiveColor", Sdf.ValueTypeNames.Color3f).ConnectToSource(tex.ConnectableAPI(), "rgb")
    else:
        shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(color)
        if part.emissive:
            shader.CreateInput("emissiveColor", Sdf.ValueTypeNames.Color3f).Set(color)
    shader.CreateOutput("surface", Sdf.ValueTypeNames.Token)
    material.CreateSurfaceOutput().ConnectToSource(shader.ConnectableAPI(), "surface")
    UsdShade.MaterialBindingAPI.Apply(prim)
    UsdShade.MaterialBindingAPI(prim).Bind(material)
