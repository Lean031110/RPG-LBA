#!/usr/bin/env python3
"""TripoSR batch kernel — runs INSIDE Kaggle (GPU), pinned and idempotent.

Design constraints (master prompt §9):
- pinned TripoSR revision + pinned weights; small controlled batch;
- checkpoints and a run id are written before/after each task;
- idempotent: a task whose output already exists is skipped, never regenerated;
- no account cycling, no paid accelerators, nothing downloaded from sources
  whose license is unknown;
- output is a RAW mesh: GitHub Actions + Blender headless must clean/export/
  validate it before any catalog registration. This kernel never declares an
  asset approved.

Provenance of the TripoSR integration itself: NOT TESTED until a real Kaggle
run of this kernel is recorded in gpu_task_queue.json (history) — see
automation/kaggle/README.md.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import traceback
from pathlib import Path

WORK = Path(os.environ.get("KAGGLE_WORKING_DIR", "/kaggle/working"))
INPUT = Path(os.environ.get("KAGGLE_INPUT_DIR", "/kaggle/input"))

TRIPOSR_REPO = "https://github.com/VAST-AI-Research/TripoSR.git"
TRIPOSR_PIN = os.environ.get("TRIPOSR_PIN", "main")  # replace with an exact commit hash before first production run
RENDER_RESOLUTION = 160  # moderate; raise only with headroom
MESH_RESOLUTION = 192    # marching-cubes grid

BATCH = json.loads((WORK / "batch_manifest.json").read_text()) if (WORK / "batch_manifest.json").exists() else json.loads(Path("batch_manifest.json").read_text())


def log(msg: str) -> None:
    print(f"[triposr-kernel] {msg}", flush=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    log(f"$ {' '.join(cmd)} (cwd={cwd or '.'})")
    return subprocess.run(cmd, cwd=cwd, check=False, text=True, capture_output=True)


def main() -> int:
    repo_dir = WORK / "TripoSR"
    state_path = WORK / "job_state.json"

    state: dict = {"run_id": os.environ.get("KAGGLE_KERNEL_RUN_ID") or os.environ.get("KAGGLE_RUN_ID") or "unknown",
                   "tripoSR_pin": TRIPOSR_PIN,
                   "repo": TRIPOSR_REPO,
                   "gpu_requested": True,
                   "tasks": {},
                   "notes": []}
    state_path.write_text(json.dumps(state, indent=2))

    # 1) Clone pinned revision (weights expected in-repo; MIT for code+weights
    #    per upstream README; if the checkout changes, re-verify).
    if not repo_dir.exists():
        result = run(["git", "clone", "--depth", "1", TRIPOSR_REPO, str(repo_dir)])
        if result.returncode != 0:
            state["notes"].append(f"clone failed: {result.stderr[-400:]}")
            state_path.write_text(json.dumps(state, indent=2))
            log("FAIL: cannot clone TripoSR")
            return 1
        if TRIPOSR_PIN != "main":
            run(["git", "-C", str(repo_dir), "fetch", "--depth", "1", "origin", TRIPOSR_PIN])
            run(["git", "-C", str(repo_dir), "checkout", TRIPOSR_PIN])

    weights = repo_dir / "model.ckpt"
    if not weights.exists():
        state["notes"].append("model.ckpt not found in the pinned checkout; verify weights location before next run")
        state_path.write_text(json.dumps(state, indent=2))
        log("FAIL: pinned weights missing — do NOT proceed with unverified sources")
        return 1

    # 2) Python deps for inference
    req = repo_dir / "requirements.txt"
    if req.exists():
        run([sys.executable, "-m", "pip", "install", "-q", "-r", str(req)])
    run([sys.executable, "-m", "pip", "install", "-q", "rembg", "huggingface-hub"])

    sys.path.insert(0, str(repo_dir))

    # 3) Load model
    try:
        import torch  # noqa: WPS433 (kernel scope)
        from tsr.system import TSR  # type: ignore

        device = "cuda" if torch.cuda.is_available() else "cpu"
        state["device"] = device
        state["cuda_available"] = torch.cuda.is_available()
        state_path.write_text(json.dumps(state, indent=2))
        if device != "cuda":
            state["notes"].append("no CUDA visible on Kaggle: mark DEFERRED_QUOTA and stop")
            state_path.write_text(json.dumps(state, indent=2))
            log("SKIPPED/DEFERRED_QUOTA: no CUDA device visible")
            return 0

        model = TSR.from_pretrained(str(repo_dir), config_name="config.yaml", weight_name="model.ckpt")
        model.renderer.set_chunk_size(8192)
    except Exception:
        state["notes"].append("model load failed:\n" + traceback.format_exc()[-800:])
        state_path.write_text(json.dumps(state, indent=2))
        log("FAIL: model load")
        return 1

    # 4) Process the bounded batch, idempotently
    from PIL import Image  # noqa: WPS433

    for task in BATCH.get("tasks", []):
        task_id = task["task_id"]
        out_dir = WORK / "outputs" / task_id
        out_dir.mkdir(parents=True, exist_ok=True)
        mesh_path = out_dir / f"{task_id}_raw.glb"
        if mesh_path.exists():
            state["tasks"][task_id] = {"status": "SKIPPED_ALREADY_DONE", "output": str(mesh_path)}
            state_path.write_text(json.dumps(state, indent=2))
            log(f"{task_id}: output exists — skip (idempotency)")
            continue

        image_path = Path(task.get("input_image", ""))
        if not image_path.exists():
            # the dispatch glue copies batch inputs next to this script
            alt = Path(image_path.name)
            image_path = alt if alt.exists() else image_path
        if not image_path.exists():
            state["tasks"][task_id] = {"status": "FAIL_MISSING_INPUT", "expected": str(task.get("input_image"))}
            state_path.write_text(json.dumps(state, indent=2))
            log(f"{task_id}: input image missing — FAIL (never fabricate an output)")
            continue

        try:
            image = Image.open(image_path).convert("RGBA")
            code = model([image], device)
            mesh = model.extract_mesh(code, resolution=MESH_RESOLUTION, discretization=0.8)[0]
            mesh.export(str(mesh_path), include_normals=True)

            state["tasks"][task_id] = {
                "status": "GENERATED_RAW",
                "output": str(mesh_path),
                "sha256": sha256(mesh_path),
                "input_sha256": sha256(image_path),
                "render_resolution": RENDER_RESOLUTION,
                "mesh_resolution": MESH_RESOLUTION,
                "device": device,
            }
            state_path.write_text(json.dumps(state, indent=2))
            log(f"{task_id}: raw mesh written to {mesh_path}")
        except Exception:
            state["tasks"][task_id] = {"status": "FAIL", "error": traceback.format_exc()[-800:]}
            state_path.write_text(json.dumps(state, indent=2))
            log(f"{task_id}: generation failed")

    # 5) Copy job_state.json next to outputs for easy retrieval
    shutil.copy(state_path, WORK / "outputs" / "job_state.json")
    log("done — outputs are RAW: Blender headless cleanup in GitHub Actions follows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
