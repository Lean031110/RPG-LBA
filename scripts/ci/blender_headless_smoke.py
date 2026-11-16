#!/usr/bin/env python3
"""Blender headless smoke test — process a factory GLB and export a verifiable GLB.

Runs either as `blender --background --python blender_headless_smoke.py -- --input X --output Y`
or under a pip-installed `bpy` (python3 blender_headless_smoke.py ...).

Processing steps (mirrors the factory's normalization contract):
- import GLB, report objects/verts/tris/materials;
- triangulate faces, remove duplicate vertices, recalculate outward normals;
- apply transforms and set origin at the mesh base (feet on the ground);
- export GLB 2.0 with materials;
- print a machine-readable BLENDER_SMOKE_REPORT line.

Exit codes: 0 = PASS, 1 = FAIL, 77 = SKIPPED (bpy unavailable — e.g. sandbox
without Blender). A SKIPPED never counts as PASS (AGENTS.md §8).
"""
from __future__ import annotations

import argparse
import json
import sys


def parse_args() -> argparse.Namespace:
    # Blender passes extra args after '--'; plain python does not.
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    return parser.parse_args(argv)


def main() -> int:
    try:
        import bpy  # noqa: PLC0415
    except ImportError:
        print("SKIPPED: bpy is not available in this environment (no Blender).")
        return 77

    args = parse_args()

    # fresh scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    before = {"objects": 0, "verts": 0, "tris": 0, "materials": 0}
    try:
        bpy.ops.import_scene.gltf(filepath=args.input)
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL: glTF import error: {exc}")
        return 1

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    mats = set()
    for obj in meshes:
        before["objects"] += 1
        before["verts"] += len(obj.data.vertices)
        before["tris"] += sum(1 for poly in obj.data.polygons if len(poly.vertices) == 3) \
            + sum(len(poly.vertices) - 2 for poly in obj.data.polygons if len(poly.vertices) > 3)
        for slot in obj.material_slots:
            if slot.material is not None:
                mats.add(slot.material.name)
    before["materials"] = len(mats)
    if not meshes:
        print("FAIL: no mesh objects after import")
        return 1

    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.remove_doubles(threshold=1e-5)
        bpy.ops.mesh.normals_make_consistent(inside=False)
        bpy.ops.mesh.quads_convert_to_tris(quad_method="BEAUTY", ngon_method="BEAUTY")
        bpy.ops.object.mode_set(mode="OBJECT")

    # place the asset base on the ground: shift the whole scene so min world Z == 0
    world_z = [(obj.matrix_world @ v.co).z for obj in meshes for v in obj.data.vertices]
    if world_z:
        scene_min_z = min(world_z)
        for obj in meshes:
            obj.location.z -= scene_min_z

    after = {"objects": len(meshes), "verts": 0, "tris": 0, "materials": len(mats)}
    for obj in meshes:
        after["verts"] += len(obj.data.vertices)
        after["tris"] += sum(len(poly.vertices) - 2 for poly in obj.data.polygons
                            if len(poly.vertices) >= 3)

    try:
        bpy.ops.export_scene.gltf(
            filepath=args.output,
            export_format="GLB",
            export_apply=True,
            use_selection=False,
            export_materials="EXPORT",
        )
    except Exception as exc:  # noqa: BLE001
        print(f"FAIL: GLB export error: {exc}")
        return 1

    report = {"result": "PASS", "input": args.input, "output": args.output,
              "before": before, "after": after}
    print("BLENDER_SMOKE_REPORT " + json.dumps(report))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
