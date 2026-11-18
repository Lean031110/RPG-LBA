# Reconciliación de PR #18 y PR #19 — qué se migró, qué se retiró y por qué

**Fecha:** 16–17 de noviembre de 2026
**Base elegida:** PR #18 (`agent/asset-cloud-automation`) — parte de la fábrica
existente y propone el sistema más completo, tal como decidió el prompt maestro.
**PR secundaria:** #19 (`agent/assets-factory-bootstrap`).
**Estado de PR #19:** abierta; su contenido útil ya está migrado aquí. La
decisión de cerrarla como superseded corresponde al propietario. No se borra
nada de su rama.

## 1. Por qué PR #18 es la base

- PR #19 crea un catálogo maestro paralelo (`assets/library/catalog.csv`) y
  otra ubicación de workflows (`n8n/`) y documentación (`docs/art-pipeline/`),
  duplicando las funciones canónicas que el prompt maestro §4 exige consolidar
  en una única fuente.
- Su workflow `assets-validation.yml` tiene un error de sintaxis YAML
  (`branches: ain]`), por lo que su CI está rojo (mergeable_state `unstable`).
- PR #18 parte del manifiesto real de la fábrica (93 entradas), genera índices
  con hashes y enlaces, y define la jerarquía de fuentes única.

## 2. Destino de cada archivo de PR #19

| Archivo en PR #19 | Decisión | Destino canónico |
|---|---|---|
| `firebase/firestore.rules` | **MIGRADO íntegro** | `firebase/firestore.rules` (reglas deny-by-default; sin cambios) |
| `firebase/README.md` | **MIGRADO íntegro** | `firebase/README.md` (cuotas Spark, modelo de datos, estado NOT CONFIGURED) |
| `n8n/workflows/01_polyhaven_catalog_discovery.json` | **MIGRADO** | `automation/n8n/workflows/01_polyhaven_catalog_discovery.json` + doc compañero `.md` (única ubicación de plantillas) |
| `n8n/WORKFLOW_INDEX.csv` | **ABSORBIDO** | Tabla de índice en `automation/n8n/workflows/README.md` (roadmap PLANNED conservado; el CSV como fuente paralela se retira) |
| `n8n/workflows/README.md` | SUPERSEDED | Reglas ya cubiertas por `automation/n8n/README.md` y su propio README de plantillas |
| `docs/art-pipeline/PROVIDERS.md` (OpenGameArt, Sketchfab, Poly Pizza, BlendKit) | **MIGRADO parcial** | 4 proveedores nuevos en `PROVIDER_REGISTRY.json`; política de selección y tabla de credenciales ya cubiertas por `SECRETS_SETUP.md` |
| `docs/art-pipeline/README.md` (taxonomía, IDs, presupuestos, ciclo de vida) | **MIGRADO parcial** | Consolidado en `ASSET_CONVENTIONS.md` (IDs, taxonomía, presupuestos móviles, estados); arquitectura y seguridad ya cubiertas por `CLOUD_AUTOMATION/README.md` |
| `scripts/ci/validate_asset_library.py` | **MIGRADO parcial** | Sus comprobaciones (sha256 real, gating de estados, escape de rutas) se portan al validador consolidado `scripts/ci/validate_asset_factory.py`; su dependencia de `assets/library/catalog.csv` se retira porque ese catálogo no es canónico |
| `docs/art-pipeline/SECRETS_AND_SETUP.md` | ABSORBIDO | Checklist del propietario y guía de PAT fine-grained añadidas a `SECRETS_SETUP.md`; el resto ya estaba cubierto |
| `docs/art-pipeline/N8N_BACKUP_AND_MIGRATION.md` | SUPERSEDED | Todo el contenido (licencia CE/Sustainable Use, trial Cloud, Data Tables por tabla, restauración) ya está en `N8N_PORTABILITY.md` |
| `.github/workflows/assets-validation.yml` | SUPERSEDED | El CI de activos vive en `asset-library-index.yml` (con validador consolidado + chequeo estricto del índice) y en `asset-validation.yml` (pytest de fábrica); además su YAML estaba roto |
| `assets/library/catalog.csv` | RETIRADO (no migrado) | Inventario maestro = `ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`; navegación = `ASSET_LIBRARY_INDEX.json`; procedencia = `assets/manifest.csv`. Sus 3 filas de prueba no referencian archivos reales del repo y quedan cubiertas por el índice |
| `assets/library/README.md` | RETIRADO (no migrado) | Taxonomía/naming consolidados en `ASSET_CONVENTIONS.md` con rutas reales |
| `README.md` (raíz, +18 líneas) | SUPERSEDED | La sección de activos de la raíz ya enlaza el sistema completo; se amplió en este PR |

## 3. Nada se pierde

- La rama `agent/assets-factory-bootstrap` permanece intacta en GitHub con sus
  18 commits; este documento es el mapa de dónde vive ahora cada pieza útil.
- Los elementos PLANNED del índice de workflows (source-scan, license-audit,
  job-dispatch, blender-process, godot-validation, telegram-review,
  backup-export) se conservan como roadmap en `automation/n8n/workflows/README.md`.
- Las comprobaciones del validador se conservan (portadas) en
  `scripts/ci/validate_asset_factory.py`.

## 4. Verificación de la migración

| Comprobación | Resultado |
|---|---|
| Reglas Firestore deny-by-default presentes y referenciadas | PASS |
| Plantilla Poly Haven importada con doc compañero e índice | PASS |
| 4 proveedores nuevos registrados con licencia/coste verificados | PASS |
| Convenciones (IDs/taxonomía/presupuestos) consolidadas | PASS |
| Validador consolidado ejecutado en CI | PASS (ver run en el PR) |
| Ningún archivo de PR #19 eliminado de su rama | PASS |
