"""Backends geométricos con API idéntica (mandato §4: Blender motor principal).

Convención del DSL de la fábrica: **Y-up, metros** (como Godot/glTF).
- `TrimeshBackend`: motor de respaldo 100% CPU. Se corrige la orientación de
  las primitivas (trimesh las crea sobre +Z; el DSL exige +Y).
- `BlenderBackend`: usa la Python API de Blender (bpy; CI: Python 3.11 +
  `pip install bpy`). Construye los mismos meshes (from_pydata), crea los
  materiales Principled y exporta GLB con el exportador oficial de Blender
  (export_yup=True), de modo que el resultado en Godot es idéntico.

Ambos fusionan piezas por material (menos draw calls), normales correctas
(planas en cajas, suaves en cilindros/esferas/conos) y UV por proyección
plana por normal dominante.
"""
from __future__ import annotations

import numpy as np

# =========================================================================
# DSL compartido: construcción de primitivas en el frame Y-up de la fábrica
# =========================================================================
_AXES = [np.array([1.0, 0.0, 0.0]), np.array([0.0, 1.0, 0.0]), np.array([0.0, 0.0, 1.0])]
_RX_MINUS_90 = None  # se inicializa con trimesh.transformations


def _euler_matrix(tft, rot) -> np.ndarray:
    """R = Rz @ Ry @ Rx (convención XYZ) como matriz 4x4."""
    M = np.eye(4)
    for axis_vec, angle in zip(_AXES, rot):
        if angle:
            M = tft.rotation_matrix(float(angle), axis_vec) @ M
    return M


def _build_primitive(tm, tft, kind: str, *, size, radius, depth, segments, smooth):
    """Primitiva alineada al eje +Y del DSL (corrección de +Z -> +Y)."""
    global _RX_MINUS_90
    if _RX_MINUS_90 is None:
        _RX_MINUS_90 = tft.rotation_matrix(-np.pi / 2.0, _AXES[0])
    if kind == "box":
        mesh = tm.creation.box(extents=np.asarray(size, dtype=np.float64))
        mesh = _flat_shade(tm, mesh)
        return mesh, None
    if kind == "cylinder":
        mesh = tm.creation.cylinder(radius=radius, height=depth, sections=max(3, segments))
        mesh.apply_transform(_RX_MINUS_90)          # eje +Z -> +Y (centrado)
        return mesh, smooth
    if kind == "cone":
        mesh = tm.creation.cone(radius=radius, height=depth, sections=max(3, segments))
        mesh.apply_transform(_RX_MINUS_90)          # base en loc, punta hacia +Y
        return mesh, smooth
    if kind == "sphere":
        mesh = tm.creation.uv_sphere(radius=radius,
                                      count=[max(4, segments), max(3, segments // 2)])
        return mesh, smooth
    raise ValueError(f"Primitiva desconocida: {kind}")


def _transform_part(mesh, tft, loc, rot):
    M = _euler_matrix(tft, np.asarray(rot, dtype=np.float64))
    M[0:3, 3] = np.asarray(loc, dtype=np.float64)
    mesh.apply_transform(M)
    return mesh


def _flat_shade(tm, mesh):
    """Duplica vértices por cara para sombreado plano (bordes nítidos)."""
    V = mesh.vertices[mesh.faces]            # (F, 3, 3)
    F = np.arange(len(mesh.faces) * 3).reshape(-1, 3)
    return tm.Trimesh(vertices=V.reshape(-1, 3), faces=F, process=False)


def _planar_uv(mesh) -> np.ndarray:
    """UV por proyección plana según la normal dominante de cada vértice."""
    if len(mesh.vertices) == 0:
        return np.zeros((0, 2))
    normals = np.asarray(mesh.vertex_normals)
    verts = np.asarray(mesh.vertices)
    dom = np.argmax(np.abs(normals), axis=1)
    uv = np.zeros((len(verts), 2))
    for axis, (i, j) in {0: (1, 2), 1: (0, 2), 2: (0, 1)}.items():
        m = dom == axis
        if not m.any():
            continue
        uv[m, 0] = verts[m, i]
        uv[m, 1] = verts[m, j]
    rng = uv.max(axis=0) - uv.min(axis=0)
    rng[rng < 1e-9] = 1.0
    uv = (uv - uv.min(axis=0)) / rng
    return uv


def _global_bounds(parts) -> list:
    boxes = []
    for m in parts:
        b = m.bounds
        if b is not None and len(b) == 2:
            boxes.append(b)
    if not boxes:
        return [0.0, 0.0, 0.0]
    mn = np.min([b[0] for b in boxes], axis=0)
    mx = np.max([b[1] for b in boxes], axis=0)
    return [float(v) for v in (mx - mn)]


# =============================================================== Trimesh
class TrimeshBackend:
    name = "trimesh"

    def __init__(self) -> None:
        import trimesh
        import trimesh.transformations as tft

        self._tm = trimesh
        self._tft = tft
        self.parts: list = []          # [(mesh, uv, mat_name)]
        self.mats: dict[str, dict] = {}

    def mat(self, name: str, base_color, roughness: float = 0.8, metallic: float = 0.0):
        self.mats[name] = {
            "name": name,
            "base_color": tuple(float(c) for c in base_color),
            "roughness": float(roughness),
            "metallic": float(metallic),
        }
        return name

    def part(self, kind: str, mat: str, *, location=(0, 0, 0), rotation=(0, 0, 0),
             size=(1.0, 1.0, 1.0), radius: float = 0.5, depth: float = 1.0,
             segments: int = 12, smooth: bool = False, name: str | None = None):
        mesh, _ = _build_primitive(self._tm, self._tft, kind, size=size, radius=radius,
                                   depth=depth, segments=segments, smooth=smooth)
        _transform_part(mesh, self._tft, location, rotation)
        uv = _planar_uv(mesh)
        self.parts.append((mesh, uv, mat))
        return len(self.parts) - 1

    def stats(self) -> dict:
        v = sum(len(m.vertices) for m, _, _ in self.parts)
        t = sum(len(m.faces) for m, _, _ in self.parts)
        return {"vertices": v, "triangles": t, "meshes": len(set(p[2] for p in self.parts)),
                "materials": len(self.mats)}

    def export_glb(self, path) -> dict:
        tm = self._tm
        by_mat: dict[str, list] = {}
        for mesh, uv, mat in self.parts:
            by_mat.setdefault(mat, []).append((mesh, uv))
        scene = tm.Scene()
        for mat_name, group in by_mat.items():
            faces = []
            offset = 0
            for m, _ in group:
                faces.append(m.faces + offset)
                offset += len(m.vertices)
            vertices = np.concatenate([m.vertices for m, _ in group], axis=0)
            fcs = np.concatenate(faces, axis=0)
            uvs = np.concatenate([u for _, u in group], axis=0)
            merged = tm.Trimesh(vertices=vertices, faces=fcs, process=False)
            spec = self.mats[mat_name]
            material = tm.visual.material.PBRMaterial(
                baseColorFactor=(spec["base_color"][0], spec["base_color"][1],
                                 spec["base_color"][2], 1.0),
                metallicFactor=spec["metallic"],
                roughnessFactor=spec["roughness"],
                name=mat_name,
            )
            merged.visual = tm.visual.texture.TextureVisuals(uv=uvs, material=material)
            scene.add_geometry(merged, node_name=mat_name, geom_name=mat_name)
        from pathlib import Path
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        data = scene.export(path)
        if isinstance(data, bytes):
            path.write_bytes(data)
        stats = self.stats()
        bounds = _global_bounds([m for m, _, _ in self.parts])
        return {**stats, "bounds": bounds}

    def materials_info(self) -> list[dict]:
        return [dict(m) for m in self.mats.values()]


# ============================================================== Blender
class BlenderBackend:
    """Motor principal (CI). Mismas primitivas del DSL; bpy crea los meshes
    (from_pydata en frame Z-up de Blender), materiales Principled y exporta
    GLB con el exportador oficial (export_yup=True) -> Y-up en Godot."""

    name = "blender"

    def __init__(self) -> None:
        import bpy  # requiere Python 3.11 (CI: pip install bpy)
        import trimesh
        import trimesh.transformations as tft

        self._bpy = bpy
        self._tm = trimesh
        self._tft = tft
        try:
            bpy.ops.wm.read_factory_settings(use_empty=True)
        except Exception:
            pass
        self.parts: list = []          # [(mesh_yup, uv, mat_name, smooth)]
        self.mats: dict[str, dict] = {}
        self._bpy_mats: dict = {}

    def mat(self, name: str, base_color, roughness: float = 0.8, metallic: float = 0.0):
        bpy = self._bpy
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (
            float(base_color[0]), float(base_color[1]), float(base_color[2]), 1.0
        )
        bsdf.inputs["Roughness"].default_value = float(roughness)
        bsdf.inputs["Metallic"].default_value = float(metallic)
        self._bpy_mats[name] = mat
        self.mats[name] = {
            "name": name, "base_color": tuple(float(c) for c in base_color),
            "roughness": float(roughness), "metallic": float(metallic),
        }
        return name

    def part(self, kind: str, mat: str, *, location=(0, 0, 0), rotation=(0, 0, 0),
             size=(1.0, 1.0, 1.0), radius: float = 0.5, depth: float = 1.0,
             segments: int = 12, smooth: bool = False, name: str | None = None):
        mesh, _ = _build_primitive(self._tm, self._tft, kind, size=size, radius=radius,
                                   depth=depth, segments=segments, smooth=smooth)
        _transform_part(mesh, self._tft, location, rotation)
        uv = _planar_uv(mesh)
        self.parts.append((mesh, uv, mat, bool(smooth)))
        return len(self.parts) - 1

    def stats(self) -> dict:
        v = sum(len(m.vertices) for m, _, _, _ in self.parts)
        t = sum(len(m.faces) for m, _, _, _ in self.parts)
        return {"vertices": v, "triangles": t, "meshes": len(set(p[2] for p in self.parts)),
                "materials": len(self.mats)}

    def export_glb(self, path) -> dict:
        bpy = self._bpy
        collection = bpy.context.collection
        objects_by_mat: dict[str, list] = {}
        for mesh, uv, mat_name, smooth in self.parts:
            # Y-up -> Z-up de Blender: p_bl = (x, -z, y)
            V = np.asarray(mesh.vertices)
            V_bl = np.stack([V[:, 0], -V[:, 2], V[:, 1]], axis=1)
            me = bpy.data.meshes.new("f")
            me.from_pydata(V_bl.tolist(), [], np.asarray(mesh.faces).tolist())
            me.validate()
            ob = bpy.data.objects.new("f", me)
            collection.objects.link(ob)
            ob.data.materials.append(self._bpy_mats[mat_name])
            if smooth:
                for p in me.polygons:
                    p.use_smooth = True
            # UV
            if uv is not None and len(uv) == len(V):
                uv_layer = me.uv_layers.new()
                for i, loop in enumerate(me.loops):
                    u, v = uv[loop.vertex_index]
                    uv_layer.data[i].uv = (float(u), float(v))
            objects_by_mat.setdefault(mat_name, []).append(ob)

        # fusión por material (menos draw calls)
        for mat_name, obs in objects_by_mat.items():
            if len(obs) > 1:
                bpy.ops.object.select_all(action="DESELECT")
                for o in obs:
                    o.select_set(True)
                bpy.context.view_layer.objects.active = obs[0]
                bpy.ops.object.join()

        from pathlib import Path
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB",
                                  export_yup=True, use_selection=False)
        stats = self.stats()
        bounds = _global_bounds([m for m, _, _, _ in self.parts])
        return {**stats, "bounds": bounds}

    def materials_info(self) -> list[dict]:
        return [dict(m) for m in self.mats.values()]


def make_backend(which: str):
    if which == "blender":
        return BlenderBackend()
    if which == "trimesh":
        return TrimeshBackend()
    raise ValueError(f"backend desconocido: {which}")
