"""Configuración de pruebas: raíz de repo aislada en tmp (no contamina el repo real)."""
import os
import sys
from pathlib import Path

FACTORY_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FACTORY_DIR))

import tempfile

_TMP = tempfile.mkdtemp(prefix="rpg_lba_factory_test_")
os.environ["RPG_LBA_ROOT"] = _TMP

# inicializar directorios del "repo" temporal
from core import paths  # noqa: E402  (lee RPG_LBA_ROOT del entorno)

paths.ensure_dirs()
