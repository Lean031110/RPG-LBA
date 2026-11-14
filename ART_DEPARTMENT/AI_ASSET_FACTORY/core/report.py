"""Informes de validación por recurso (mandato §13).

Cada recurso terminado obtiene un informe JSON en
ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/validation_reports/<id>.json
con el resultado de cada comprobación (PASS / FAIL / SKIPPED).
"""
from __future__ import annotations

import json
from datetime import datetime, timezone

from core import paths


class ValidationReport:
    def __init__(self, asset_id: str) -> None:
        self.asset_id = asset_id
        self.checks: list[dict] = []

    def check(self, name: str, ok: bool, detail: str = "") -> bool:
        self.checks.append(
            {
                "comprobacion": name,
                "resultado": "PASS" if ok else "FAIL",
                "detalle": detail,
            }
        )
        return ok

    def skipped(self, name: str, detail: str = "") -> None:
        self.checks.append({"comprobacion": name, "resultado": "SKIPPED", "detalle": detail})

    @property
    def ok(self) -> bool:
        return all(c["resultado"] != "FAIL" for c in self.checks)

    def summary(self) -> str:
        if self.ok:
            fails = [c for c in self.checks if c["resultado"] == "FAIL"]
            return "PASS" if not fails else "FAIL"
        return "FAIL"

    def to_dict(self) -> dict:
        passed = sum(1 for c in self.checks if c["resultado"] == "PASS")
        failed = sum(1 for c in self.checks if c["resultado"] == "FAIL")
        skipped = sum(1 for c in self.checks if c["resultado"] == "SKIPPED")
        return {
            "asset_id": self.asset_id,
            "fecha": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "resultado": self.summary(),
            "pasadas": passed,
            "fallidas": failed,
            "omitidas": skipped,
            "comprobaciones": self.checks,
        }

    def save(self) -> str:
        p = paths.REPORTS_DIR / f"{self.asset_id}.json"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(self.to_dict(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        return p
