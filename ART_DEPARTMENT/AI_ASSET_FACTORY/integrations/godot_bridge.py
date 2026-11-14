"""Puente Godot: comprobación headless OPCIONAL de importación.

La fábrica NO depende de Godot para producir/validar. Si el entorno
dispone de un binario Godot 4, `godot_import_check` abre el proyecto en
modo headless dos pasadas (requisito del prompt 09) y devuelve el log;
si no, se reporta SKIPPED de forma explícita (AGENTS.md §3: nunca
convertir un NOT TESTED en PASS).
"""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


def find_godot() -> str | None:
    for name in ("godot", "godot4", "godot-headless", "godot_server"):
        path = shutil.which(name)
        if path:
            return path
    return None


def godot_import_check(repo_root: Path, godot_bin: str | None = None,
                       timeout_s: int = 600) -> dict:
    """Ejecuta `godot --headless --import` dos veces; devuelve dict con estado."""
    godot = godot_bin or find_godot()
    if godot is None:
        return {"estado": "SKIPPED",
                "detalle": "Sin binario Godot en PATH. Requiere verificación con editor."}
    logs = []
    for pasada in (1, 2):
        try:
            proc = subprocess.run(
                [godot, "--headless", "--path", str(repo_root), "--import"],
                capture_output=True, text=True, timeout=timeout_s, cwd=str(repo_root),
            )
            logs.append({"pasada": pasada, "returncode": proc.returncode,
                         "tail": (proc.stdout + proc.stderr)[-2000:]})
        except subprocess.TimeoutExpired:
            return {"estado": "FAIL", "detalle": f"Timeout en pasada {pasada}", "logs": logs}
    ok = all(l["returncode"] == 0 for l in logs)
    errores = [l for l in logs if "ERROR" in l["tail"] and "SCRIPT ERROR" in l["tail"]]
    return {
        "estado": "PASS" if ok and not errores else "FAIL",
        "detalle": f"{len(logs)} pasadas ejecutadas",
        "logs": logs,
    }
