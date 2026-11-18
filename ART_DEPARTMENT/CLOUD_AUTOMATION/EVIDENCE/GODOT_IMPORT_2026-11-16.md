# Evidencia: Godot 4.7.2 importa el proyecto completo (headless) sin errores críticos

**Fecha:** 2026-11-16 (UTC)
**Criterio de aceptación §17.11:** Godot 4.7.2 importa el recurso de prueba sin errores críticos.
**Resultado:** **PASS** — import completo del proyecto real (no un subconjunto), 0 líneas `ERROR` y 0 `SCRIPT ERROR` en el log, código de salida 0.

## Entorno y binarios

| Componente | Valor |
|---|---|
| Godot | 4.7.2.stable.official.ed1daf0bf (Standard), `Godot_v4.7.2-stable_linux.x86_64.zip` desde https://github.com/godotengine/godot/releases/download/4.7.2-stable/ (misma URL que usa el CI `godot-ci.yml`) |
| SHA-256 del zip | `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` |
| Repositorio | checkout limpio de `agent/asset-cloud-automation` (árbol idéntico al de main en `assets/`) |
| Comando | idéntico al del job `godot-headless-check` del CI |

## Comando exacto

```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --import
```

## Resultados

| Métrica | Valor |
|---|---|
| Código de salida | 0 |
| Pasos de import (assets del proyecto) | 349 pasos; `DONE` en import y reimport |
| Líneas `ERROR` en el log completo | 0 |
| Líneas `SCRIPT ERROR` | 0 |
| GLB en caché `.godot/imported` | 148 entradas (`*.scn`+`*.md5`, ≈74 GLB únicos) incluyendo los 62 modelos de la fábrica y los heredados |
| Tamaño de caché generada | 44 MB (`.godot/` está en `.gitignore`; nunca se commitea) |

El log muestra la reimportación explícita de modelos de la fábrica (p. ej.
`mdl_buildings_shop_facade_001.glb`, `mdl_buildings_house_colonial_02_002_lod1.glb`) con
`DONE` en cada uno.

## Alcance y limitaciones honestas

- PASS de importación **no** equivale a `GODOT_IMPORT_PASS` de catálogo por asset, a integración en escena ni a prueba Android; esos estados siguen `NOT TESTED` en `ASSET_LIBRARY_INDEX.json` hasta que se ejecuten los validadores por asset y la prueba en dispositivo.
- Renderer Compatibility y perfil Android: este humo corrió el importador estándar del binario oficial 4.7.2 Standard, igual que el CI; las pruebas de render en emulador/device físico siguen siendo gates separados (ver README §2).
- No se ejecutó la suite GdUnit4 en esta pasada (eso pertenece al CI `godot-ci.yml`, ya en verde en el repositorio).
