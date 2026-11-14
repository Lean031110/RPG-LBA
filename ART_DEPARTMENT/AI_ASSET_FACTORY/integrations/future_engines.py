"""Integraciones futuras (DESPLEGADAS pero DESACTIVADAS).

Mandato §4: la primera versión NO depende de ComfyUI, Stable Diffusion ni
Hunyuan3D (requieren GPU). Estas pasarelas quedan preparadas y desactivadas;
se activan solo cuando exista hardware compatible, añadiéndolas al registro
de generadores (generators/registry.py) tras validar su salida con los
mismos validadores de validators/validators.py.
"""
from __future__ import annotations


class DisabledEngineStub:
    disponible = False
    razon = "Requiere GPU NVIDIA; desactivado por diseño hasta verificar hardware (mandato §4)."

    def __init__(self, nombre: str):
        self.nombre = nombre

    def generar(self, *args, **kwargs):
        raise NotImplementedError(
            f"Motor '{self.nombre}' desactivado. {self.razon}"
        )


class ComfyUIStub(DisabledEngineStub):
    """Pasarela futura a ComfyUI + SDXL para texturas fotorrealistas."""

    def __init__(self):
        super().__init__("ComfyUI/SDXL")
        self.workflow_base = "ART_DEPARTMENT/AI_ASSET_FACTORY/templates/comfyui_workflow.json"


class Hunyuan3DStub(DisabledEngineStub):
    """Pasarela futura a Hunyuan3D-2 para escaneo-like meshes."""

    def __init__(self):
        super().__init__("Hunyuan3D-2")


# Registro de integraciones futuras (todas desactivadas)
FUTURE_ENGINES = {
    "comfyui": ComfyUIStub(),
    "hunyuan3d": Hunyuan3DStub(),
}
