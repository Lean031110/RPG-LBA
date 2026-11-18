# Kaggle + TripoSR — prototipo GPU reanudable (cero costes)

Implementación del mandato §9 del prompt maestro. Este carril GPU es
**independiente de la fábrica CPU** y no la modifica.

**Estado de integración: NOT TESTED** (no existen secrets `KAGGLE_USERNAME` /
`KAGGLE_KEY` en el repositorio todavía; el workflow `asset-gpu-triposr.yml`
reporta `SKIPPED / KAGGLE_NOT_CONFIGURED` hasta que el propietario los cree y
se registre una corrida real en `gpu_task_queue.json`).

## Flujo

1. `asset-gpu-triposr.yml` (workflow_dispatch, guarda de rama: nunca `main`).
2. `scripts/ci/kaggle_triposr_dispatch.py` lee `gpu_task_queue.json`:
   - sin secrets → `SKIPPED: KAGGLE_NOT_CONFIGURED` (exit 0, sin cuota gastada);
   - selecciona tareas `QUEUED` (lote 1–2) verificando idempotencia
     (tarea con `COMPLETED_RAW` en el historial nunca se re-despacha);
   - comprueba que la imagen de entrada existe y tiene procedencia (si falta
     → `FAILED_INPUT_IMAGE_MISSING`, nunca genera);
   - valida que el asset/ID no exista ya (sin duplicados por hash/ID);
   - monta `kernel_staging/` (git-ignored): kernel + `kernel-metadata.json`
     (privado, `accelerator nvidiaTeslaT4`) + `batch_manifest.json` + imágenes;
   - `kaggle kernels push -p kernel_staging/kernel`;
   - sin GPU/cuota → tarea `DEFERRED_QUOTA` (no FAIL, no bucles de reintento).
3. El kernel (`kernel/triposr_batch_kernel.py`) corre en Kaggle:
   - clona la revisión fijada de TripoSR (MIT código+pesos, upstream
     https://github.com/VAST-AI-Research/TripoSR);
   - exige pesos `model.ckpt` en la revisión fijada (si no están → FAIL
     documentado, nunca fuentes sin verificar);
   - procesa el lote acotado; escribe `job_state.json` con run id, device,
     hash SHA-256 de entradas/salidas; salta tareas ya generadas
     (idempotencia en el kernel también);
   - salida = malla CRUDA (GLB), nunca un asset aprobado.
4. Recuperación: `kaggle kernels output <slug> -p <carpeta>` (método
   documentado por el CLI oficial). El estado queda en `gpu_task_queue.json`.
5. GitHub Actions + Blender headless limpian/deciman/normalizan/exportan GLB
   (carril existente de la fábrica), el validador comprueba malla/escala/pivote/
   texturas/límites móviles, se genera preview+reporte y se publica en rama
   `agent/*` mediante PR **sin auto-merge**.

## Reglas duras

- Lotes pequeños (1–3); nunca decenas sin revisión.
- Tareas idempotentes: jamás regenerar un job terminado.
- `DEFERRED_QUOTA` en lugar de reintentos infinitos.
- Nunca cuentas adicionales para reiniciar cuotas ni aceleradores de pago.
- Imágenes de entrada: solo originales o con licencia apropiada, registradas
  primero en `assets/manifest.csv`.
- Pesos/datasets nunca en este repositorio.
- TripoSR es reconstrucción rugosa de un solo vista para objetos estáticos:
  NO produce personajes completos, rigging, animaciones ni topología de
  producción. Siempre requiere limpieza Blender + revisión humana.

## Pendiente antes de la primera corrida real

1. Propietario: crear `KAGGLE_USERNAME` y `KAGGLE_KEY` en Actions Secrets.
2. Fijar `TRIPOSR_PIN` (commit exacto) en `kernel/triposr_batch_kernel.py`
   tras verificar que esa revisión contiene `model.ckpt`.
3. Añadir la imagen piloto en `kernel/batches/gputask_001/input/reference.png`
   (obra original o CC0) y registrarla en `assets/manifest.csv`.
4. Sustituir `OWNER_KAGGLE_USERNAME` en `kernel/kernel-metadata.json` (lo hace
   el glue automáticamente con el nombre de la cuenta).
5. Comprobar cuota GPU vigente (`kaggle` CLI o web) antes de cada despacho.

Hasta que todo lo anterior ocurra y quede registrado, el estado de este
carril es **NOT TESTED** (criterio de aceptación §17.9: se documenta como tal
en lugar de fingir una corrida).
