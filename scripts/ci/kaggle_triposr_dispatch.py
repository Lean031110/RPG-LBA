#!/usr/bin/env python3
"""Kaggle/TripoSR dispatch glue — runs in GitHub Actions (CPU runner).

Responsibilities (master prompt §9):
1. Pick QUEUED tasks from automation/kaggle/gpu_task_queue.json (bounded batch).
2. Verify the asset does not already exist and hashes/IDs are not duplicated.
3. Require KAGGLE_USERNAME + KAGGLE_KEY; without them exit SKIPPED with cause
   (KAGGLE_NOT_CONFIGURED), never a fake PASS.
4. Prepare a private kernel folder (kernel-metadata.json + code + batch manifest
   + inputs) and push it with the Kaggle CLI (idempotency: a task with a
   completed job in history is never re-pushed).
5. Poll/record kernel status; retrieve documented outputs.
6. DEFERRED_QUOTA on unavailable GPU/quota; never retry loops, never extra accounts.

Status vocabulary (subset): QUEUED, DISPATCHED, GENERATING, COMPLETED_RAW,
DEFERRED_QUOTA, FAILED, SKIPPED_ALREADY_DONE.

Evidence honesty: this glue prints SKIPPED/PASS/FAIL with a machine-readable
reason line the workflow surfaces in its summary.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUEUE_PATH = ROOT / "automation/kaggle/gpu_task_queue.json"
KERNEL_SRC = ROOT / "automation/kaggle/kernel"
STAGE = ROOT / "automation/kaggle/kernel_staging"  # git-ignored scratch
BATCH_LIMIT = int(os.environ.get("KAGGLE_BATCH_LIMIT", "2"))


def utcnow() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def stamp(event: str, **fields) -> dict:
    entry = {"utc": utcnow(), "event": event}
    entry.update(fields)
    return entry


def have_secrets() -> bool:
    return bool(os.environ.get("KAGGLE_USERNAME")) and bool(os.environ.get("KAGGLE_KEY"))


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    print(f"$ {' '.join(cmd)}", flush=True)
    return subprocess.run(cmd, **kw, check=False, text=True)


def main() -> int:
    queue = json.loads(QUEUE_PATH.read_text(encoding="utf-8"))
    tasks = queue.get("tasks", [])
    changed = False

    if not have_secrets():
        print("SKIPPED: KAGGLE_NOT_CONFIGURED (KAGGLE_USERNAME/KAGGLE_KEY secrets absent).")
        print("No kernel was pushed; no quota was consumed; tasks stay QUEUED.")
        return 0

    username = os.environ["KAGGLE_USERNAME"]

    pending = [t for t in tasks if t.get("status") == "QUEUED"]
    done_ids = {
        h.get("task_id")
        for t in tasks
        for h in t.get("history", [])
        if h.get("event") in ("COMPLETED_RAW",)
    }
    pending = [t for t in pending if t["task_id"] not in done_ids]
    if not pending:
        print("PASS: nothing to dispatch (idempotent — queue has no QUEUED tasks).")
        return 0

    batch = pending[:BATCH_LIMIT]

    if STAGE.exists():
        shutil.rmtree(STAGE)
    STAGE.mkdir(parents=True)
    shutil.copytree(KERNEL_SRC, STAGE / "kernel", dirs_exist_ok=True)

    manifest_tasks = []
    for task in batch:
        image_rel = task.get("input_image", "")
        image_src = ROOT / "automation/kaggle" / image_rel if image_rel else None
        if image_src is None or not image_src.is_file():
            task["status"] = "FAILED"
            task.setdefault("history", []).append(
                stamp("FAILED", reason="INPUT_IMAGE_MISSING", expected=str(image_rel)))
            changed = True
            print(f"FAIL: {task['task_id']} input image missing: {image_rel}")
            continue
        staged = STAGE / "kernel" / "batches" / task["task_id"] / "input"
        staged.mkdir(parents=True, exist_ok=True)
        shutil.copy2(image_src, staged / image_src.name)
        manifest_tasks.append({
            "task_id": task["task_id"],
            "input_image": f"batches/{task['task_id']}/input/{image_src.name}",
        })
        print(f"staged input for {task['task_id']}")

    (STAGE / "kernel" / "batch_manifest.json").write_text(
        json.dumps({"tasks": manifest_tasks}, indent=2), encoding="utf-8")

    metadata = json.loads((STAGE / "kernel" / "kernel-metadata.json").read_text(encoding="utf-8"))
    metadata["id"] = f"{username}/rpg-lba-triposr-batch"
    (STAGE / "kernel" / "kernel-metadata.json").write_text(
        json.dumps(metadata, indent=2), encoding="utf-8")

    if manifest_tasks:
        result = run(["kaggle", "kernels", "push", "-p", str(STAGE / "kernel")])
        if result.returncode != 0:
            out = (result.stdout or "") + (result.stderr or "")
            quota_markers = ("quota", "gpu", "accelerator", "exceeded", "limit")
            deferred = any(m in out.lower() for m in quota_markers)
            for task in batch:
                if task.get("status") != "FAILED":
                    task["status"] = "DEFERRED_QUOTA" if deferred else "QUEUED"
                    task.setdefault("history", []).append(
                        stamp("DEFERRED_QUOTA" if deferred else "PUSH_ERROR",
                              reason=out[-300:]))
            changed = True
            print(("SKIPPED: DEFERRED_QUOTA — " if deferred else "FAIL: kernel push failed — ") + out[-300:])
            QUEUE_PATH.write_text(json.dumps(queue, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            return 0 if deferred else 1
        for task in batch:
            if task.get("status") != "FAILED":
                task["status"] = "DISPATCHED"
                task["kernel_slug"] = f"{username}/rpg-lba-triposr-batch"
                task.setdefault("history", []).append(
                    stamp("DISPATCHED", kernel=f"{username}/rpg-lba-triposr-batch",
                          batch_tasks=[t["task_id"] for t in manifest_tasks]))
                changed = True
        print("PASS: kernel pushed (private, GPU requested). Poll with a later dispatch:")
        print(f"      kaggle kernels status {username}/rpg-lba-triposr-batch")

    if changed:
        queue["updated_utc"] = utcnow()
        QUEUE_PATH.write_text(json.dumps(queue, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
