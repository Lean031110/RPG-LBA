# GITHUB_ACTIONS.md — Workflows y cuotas

## Los tres workflows (todos NUEVOS; no se toca ninguno existente)

| Workflow | Trigger | Qué hace |
|---|---|---|
| `asset-factory.yml` | `workflow_dispatch` (+ schedule **desactivado**) | Lee la cola, produce `limit` recursos (1-5), valida, previews, tests, guarda el progreso en la rama |
| `asset-validation.yml` | `workflow_dispatch` + `pull_request` (paths ART_DEPARTMENT/, assets/) | pytest + validación de todo el catálogo + artifact de informes (14 días) |
| `asset-publication.yml` | `workflow_dispatch` | Higiene del repo, marca `published`, guarda estado y crea/actualiza el PR |

**Cómo lanzar la fábrica:** pestaña *Actions* → *Asset Factory (produccion)* →
*Run workflow* → rama `feature/ai-art-department` → limit (3 por defecto) →
perfil → Run. Cada ejecución produce en lotes pequeños y consigna con
`[skip ci]` (no dispara otros workflows → **sin recursión**, mandato §9).

## Diseño anti-recursos infinitos

- Concurrencia `asset-factory` con `cancel-in-progress: false`: una
  ejecución a la vez, nunca dos fábricas solapadas.
- `timeout-minutes: 25` por job.
- Reintentos limitados: 3 por trabajo (`max_attempts` en factory_config.json);
  tras 3 fallos queda `failed` con el error registrado en la cola.
- Reanudación: `reset_stale()` devuelve a `pending` los `processing` con más
  de 45 min (config `stale_processing_minutes`); nunca se repite un
  recurso completado (estados en el JSON persistido).
- Ciclo nocturno: desactivado por defecto. Para activarlo crear la variable
  de repositorio `FACTORY_CRON_ENABLED=true` (02:30 UTC).

## Cuotas de GitHub Free (verificadas en INITIAL_AUDIT.md §5)

- 2.000 min/mes de Actions → con ~6-8 min por lote de 3 recursos hay margen
  para ~250-300 recursos/mes; producir solo lo que se integra.
- Job máx 6 h (usamos 25 min).
- Artifacts: 90 días máx. → NO son almacenamiento permanente (mandato §14);
  los recursos viven en la rama.
- Repo ≤ 1 GB recomendado: el lote actual pesa ~21 MB; sin Git LFS
  (no configurado en el repo; si un GLB supera ~45 MB, usar Releases y
  dejar referencia en el catálogo).

## Blender en CI

`asset-factory.yml` instala Python 3.11 + intenta `pip install bpy==4.2.0`
con `continue-on-error: true`: si bpy falla, la fábrica sigue con el backend
trimesh (misma API, misma salida GLB). El backend usado queda registrado por
recurso en el catálogo (`procedencia.backend`).

## PR de publicación

`asset-publication.yml` abre/actualiza el PR `feature/ai-art-department` →
`main` con el cuerpo de `templates/PR_BODY.md` (estructura de evidencia de
AGENTS.md §3: objetivo, archivos, decisiones, comandos, resultados reales
PASS/FAIL/SKIPPED y limitaciones). **Sin merge automático.**

## Seguridad

- `GITHUB_TOKEN` efímero con `permissions` mínimas por workflow
  (`contents: write` solo donde hace falta; `pull-requests: write` solo en
  publication).
- Ningún PAT/secret en el repo, workflows, URL o artifacts (AGENTS.md §11).
- No se suben: `.venv`, cachés, pesos de modelos de IA, binarios temporales.
