"""Cola de trabajos de la fábrica (asset_queue.json) — mandato §9.

Estados: pending → processing → completed → validated → published / failed.
Reanudación: los trabajos 'processing' más antiguos que
stale_processing_minutes vuelven automáticamente a 'pending'.
Reintentos limitados: tras max_attempts fallos el trabajo queda 'failed'.
"""
from __future__ import annotations

import json
import time
from datetime import datetime, timezone
from typing import Any, Callable

from core import paths
from core.config import FactoryConfig

STATES = ("pending", "processing", "completed", "failed", "validated", "published")


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class QueueManager:
    def __init__(self, path=None, config: FactoryConfig | None = None) -> None:
        self.path = path or paths.QUEUE_PATH
        self.cfg = config or FactoryConfig.load()
        self._data = self._load()

    def _load(self) -> dict:
        if self.path.exists():
            try:
                return json.loads(self.path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                pass
        return {"version": 1, "jobs": []}

    def save(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".json.tmp")
        tmp.write_text(
            json.dumps(self._data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        tmp.replace(self.path)

    # ---------------------------------------------------------------- altas
    def add_job(
        self,
        job_id: str,
        category: str,
        name: str,
        generator: str,
        description: str = "",
        params: dict | None = None,
        resolution: int | None = None,
        priority: int = 5,
        profile: str | None = None,
        seed: int | None = None,
    ) -> dict:
        if any(j["id"] == job_id for j in self._data["jobs"]):
            raise ValueError(f"Trabajo duplicado en la cola: {job_id}")
        job = {
            "id": job_id,
            "categoria": category,
            "nombre": name,
            "generador": generator,
            "descripcion": description or f"{name} ({category})",
            "parametros": params or {},
            "resolucion": resolution,
            "prioridad": priority,           # 1 = máxima
            "estado": "pending",
            "semilla": seed if seed is not None else abs(hash((job_id, "seed"))) % (2**31),
            "fecha_creacion": now_iso(),
            "fecha_actualizacion": now_iso(),
            "intentos": 0,
            "ultimo_error": None,
            "perfil": profile or self.cfg.default_profile,
            "asset_id": None,
        }
        self._data["jobs"].append(job)
        self.save()
        return job

    # ------------------------------------------------------------- consultas
    def jobs(self, state: str | None = None) -> list[dict]:
        js = self._data["jobs"]
        if state:
            js = [j for j in js if j["estado"] == state]
        return sorted(js, key=lambda j: (j.get("prioridad", 5), j.get("fecha_creacion", "")))

    def counts(self) -> dict[str, int]:
        out = {s: 0 for s in STATES}
        for j in self._data["jobs"]:
            out[j["estado"]] = out.get(j["estado"], 0) + 1
        out["total"] = len(self._data["jobs"])
        return out

    # ------------------------------------------------------- ciclo de vida
    def reset_stale(self) -> int:
        """Reanudación tras interrupción: 'processing' antiguos → pending."""
        limit = time.time() - self.cfg.stale_processing_minutes * 60
        n = 0
        for j in self._data["jobs"]:
            if j["estado"] != "processing":
                continue
            ts = j.get("fecha_actualizacion", "")
            try:
                t = datetime.fromisoformat(ts).timestamp() if ts else time.time()
            except ValueError:
                t = time.time()
            if t < limit or ts == "":
                j["estado"] = "pending"
                j["fecha_actualizacion"] = now_iso()
                n += 1
        if n:
            self.save()
        return n

    def take_next(self, exclude_generators: set[str] | None = None) -> dict | None:
        """Selecciona y marca 'processing' el siguiente trabajo pendiente."""
        for j in self.jobs("pending"):
            if exclude_generators and j["generador"] in exclude_generators:
                continue
            j["estado"] = "processing"
            j["fecha_actualizacion"] = now_iso()
            self.save()
            return j
        return None

    def complete(self, job: dict, asset_id: str) -> None:
        job["estado"] = "completed"
        job["asset_id"] = asset_id
        job["fecha_actualizacion"] = now_iso()
        job["ultimo_error"] = None
        self.save()

    def fail(self, job: dict, error: str) -> str:
        """Registra fallo; reintenta si quedan intentos. Devuelve estado final."""
        job["intentos"] = int(job.get("intentos", 0)) + 1
        job["ultimo_error"] = str(error)[:500]
        job["fecha_actualizacion"] = now_iso()
        if job["intentos"] >= self.cfg.max_attempts:
            job["estado"] = "failed"
            final = "failed"
        else:
            job["estado"] = "pending"
            final = "retry-scheduled"
        self.save()
        return final

    def mark_validated(self, job_id: str) -> None:
        for j in self._data["jobs"]:
            if j["id"] == job_id and j["estado"] == "completed":
                j["estado"] = "validated"
                j["fecha_actualizacion"] = now_iso()
        self.save()

    def mark_published(self, job_id: str) -> None:
        for j in self._data["jobs"]:
            if j["id"] == job_id and j["estado"] in ("validated", "completed"):
                j["estado"] = "published"
                j["fecha_actualizacion"] = now_iso()
        self.save()

    def mark_all_published(self) -> int:
        """Al fusionar/publicar la rama: los 'validated' pasan a 'published'."""
        n = 0
        for j in self._data["jobs"]:
            if j["estado"] == "validated":
                j["estado"] = "published"
                j["fecha_actualizacion"] = now_iso()
                n += 1
        if n:
            self.save()
        return n

    def iter_pending(self, limit: int, guard: Callable[[dict], bool] | None = None):
        yielded = 0
        while yielded < limit:
            job = self.take_next()
            if job is None:
                return
            if guard and not guard(job):
                # devolverlo a pending sin contar intento
                job["estado"] = "pending"
                job["fecha_actualizacion"] = now_iso()
                self.save()
                others_pending = [x for x in self._data["jobs"] if x["estado"] == "pending"]
                if all(self._is_before(job, x) for x in others_pending if x is not job):
                    return  # no hay nada más elegible
                continue
            yielded += 1
            yield job

    @staticmethod
    def _is_before(a: dict, b: dict) -> bool:
        return (a.get("prioridad", 5), a.get("fecha_creacion", "")) <= (
            b.get("prioridad", 5), b.get("fecha_creacion", "")
        )
