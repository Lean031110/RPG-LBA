# INITIAL_AUDIT.md — Auditoría inicial del Departamento de Arte (AI Asset Factory)

- **Fecha:** 2026-11-15
- **Rama de trabajo:** `feature/ai-art-department` (creada desde `main` @ `26fb66b`)
- **Autor:** Agente de Producción 3D (AI Art Department), según mandato del responsable.
- **Ámbito:** solo recursos visuales y su fábrica. No se toca gameplay, escenas, scripts,
  inventario, NPCs, misiones ni configuración del motor.

## 1. Motor y versión

- `project.godot`: `config/features=PackedStringArray("4.7", "Forward Plus")`.
- Canon técnico (AGENTS.md §4): **Godot 4.7.2 Standard + GDScript**. El prompt de Art Pass
  exige que los materiales funcionen en **Compatibility Renderer** y perfil Low.
- Resolución base: 1280×720, stretch `canvas_items`/`expand` (deben existir variantes 16:9 y 20:9).

## 2. Estructura de carpetas existente (no se duplica)

```
assets/
  branding/           (SVG de logotipos)
  characters/player/  (3DGodotRobot.glb + paletas PNG + meshes/*.tres ArrayMesh)
  environment/textures/  (prototype_dark.png, prototype_orange.png, ATTRIBUTIONS.md)
  items/{backpacks,hats,misc,weapons}/{icons,models}/  (GLB + PNG BaseColor)
  ui/ fonts/
config/ docs/ prompts/ scenes/ scripts/ tests/ screenshots/
.github/workflows/  (android-debug.yml, godot-ci.yml, release.yml, validate.yml — NO se modifican)
```

**Convenciones detectadas:**
- Rutas: `assets/<dominio>/<categoría>/models|icons/`, en inglés, `snake_case`.
- Modelos: **GLB** con texturas PNG adyacentes (`<modelo>_<Textura>_BaseColor.png`) o embebidas.
- Materiales: `StandardMaterial3D` (embebidos en `.tres` ArrayMesh o generados por el importador glTF).
- `.png.import` se comitean junto a las texturas (los genera el editor; la fábrica NO los fabrica).
- Atribución de terceros: `assets/environment/ATTRIBUTIONS.md` + regla de `assets/manifest.csv` (AGENTS.md §5).

**Decisión de integración (nuevas carpetas, sin duplicar existentes):**
- Texturas del mundo → `assets/environment/textures/<material>/` (convención ya existente).
- Modelos 3D → `assets/models/<categoría>/` (nueva, alineada con el mandato del responsable).
- Definiciones de materiales → `assets/materials/` (nueva; JSON + guía, sin `.tres` inventados a mano
  porque requieren UID generados por Godot — ver §7).
- `assets/environments/` (nueva) para composiciones/entornos futuros.
- `ART_DEPARTMENT/` contiene la fábrica, previews, documentación y catálogo.
  `ART_DEPARTMENT/TEXTURES|MODELS_3D|MATERIALS|ENVIRONMENTS` apuntan (README) a la ubicación
  canónica en `assets/` para **no duplicar binarios** en Git.

## 3. Recursos visuales existentes y carencias

| Grupo | Existente | Carencia detectada |
|---|---|---|
| Terreno/entorno | 2 texturas prototype (dark/orange) | Césped, tierra roja, caliza, barro: **ninguno real** |
| Personaje | 3DGodotRobot.glb + 5 paletas | placeholder (no es contenido final) |
| Objetos | ~7 GLB de items + iconos PNG | suficientes para inventario básico |
| Vegetación | 0 | **total** (árboles, palmas, ceibas, sotobosque) |
| Edificios/arquitectura | 0 | **total** (casas coloniales, fachadas, portales) |
| Mobiliario urbano | 0 | **total** (faroles, bancos, papeleras) |
| Muebles interiores | 0 | **total** |
| Vehículos | 0 | total (fuera del primer lote) |

Conclusión: el proyecto está en Fase 1 / Art Pass pendiente; la fábrica cubre exactamente
el hueco de mundo-entorno-materiales que exige `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`.

## 4. Canon artístico vigente (fuente de verdad) y contradicción resuelta

Canon aprobado (AGENTS.md §9 + docs/direccion-artistica/03): **RPG LBA — Las Cenizas de Lythara**,
Cuba ficticia de 1953, **gótico caribeño**. Paleta obligatoria: negro carbón, azul petróleo,
verde manigua, tierra roja, piedra caliza, ámbar de farol, rojo carmesí, oro viejo.

**Contradicción detectada:** el mandato de este departamento pide un estilo "estilizado, colorido y
ligeramente caricaturesco"; el canon del repositorio pide fantasía oscura caribeña con paleta
restringida y materiales envejecidos. AGENTS.md §1 prohíbe improvisar una tercera vía sin documentar.

**Resolución adoptada (documentada, no una tercera arquitectura):**
1. **Geometría:** estilizada low-poly, siluetas claras, proporciones coherentes (ambos documentos
   coinciden en esto).
2. **Materiales/paleta:** se usa la paleta del canon como base; los colores coloniales "coloridos"
   se interpretan como **colores desgastados/envejecidos** (ocre apagado, turquesa empolvado, coral
   desvaído, crema sucio) con manchas de humedad, musgo y desgaste. Ningún material plano sin textura
   (prohibido por el canon).
3. La contradicción y esta resolución quedan registradas aquí y en el PR para revisión del responsable.

## 5. Límites de plataforma (GitHub Free) verificados antes de diseñar

- Almacenamiento recomendado del repo ≤ 1 GB (límite duro ~5 GB): el primer lote (~60-80 MB) cabe
  en Git plano; **Git LFS no está configurado** en este repo (`.gitattributes` trata PNG/GLB como
  binarios normales) — no se introduce LFS ahora (1 GB ancho de banda en Free).
- Minutes: 2.000 min/mes en Free; runners estándar, concurrencia limitada → **lotes de 1-5 recursos
  por ejecución**, `workflow_dispatch` manual + schedule **desactivado por defecto** (variable de
  repo `FACTORY_CRON_ENABLED` para activarlo), `timeout-minutes: 25` por job.
- Artifacts de Actions: caducan (90 días) → **no** son almacenamiento permanente; todo recurso
  definitivo vive en ramas del repo.
- Anti-recursión: los workflows de la fábrica solo se disparan por `workflow_dispatch`/schedule
  guardado; el commit de publicación usa `[skip ci]` para no disparar los workflows con trigger
  `push` existentes.

## 6. Entorno de desarrollo local verificado (sin suposiciones)

| Comprobación | Resultado |
|---|---|
| Python | 3.12.16 (venv) — `bpy` oficial requiere 3.11 → **no instalable aquí** |
| Blender binario | **no disponible** localmente |
| numpy / Pillow / trimesh / pygltflib / cv2 / matplotlib / pytest | ✔ instalados (4.11.1 / 11.3.0 / 1.16.5 / 4.13.0 / 3.9.2 / 9.0.2) |
| Disco libre | 6,7 GB |
| Red | GitHub API + PyPI accesibles |

**Decisión de backend geométrico:** la fábrica implementa **dos backends** con la misma API:
- `BlenderBackend` (bpy): motor principal en **GitHub Actions** (Python 3.11 + `pip install bpy`).
- `TrimeshBackend`: motor de producción local y fallback automático en CI.
Ambos producen GLB reales idénticos en estructura. El backend activo queda registrado en el
catálogo por recurso (campo `procedencia.backend`).

## 7. Cómo se importarán los modelos (Godot 4)

- Formato: **GLB** (glTF 2.0 binario, Y-up, metros) → importador glTF de Godot 4 crea
  `StandardMaterial3D` desde `pbrMetallicRoughness` automáticamente.
- Pivote: base del objeto en el origen (y=0), frente hacia −Z (convención Godot).
- Los `.import` los genera el editor del agente principal; la fábrica **no** los fabrica.
- Materiales adicionales en `assets/materials/*.json` (parámetros + texturas relativas) con guía
  de creación manual en Godot; no se generan `.tres` a mano (UID no reproducible sin Godot).

## 8. Plan de publicación

Rama `feature/ai-art-department` → commits descriptivos por bloques → PR a `main`
(sin merge automático, según AGENTS.md §2 y prompt 09). El catálogo
(`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json`) es el índice estable para el
agente principal; IDs y rutas son definitivos desde el primer lote.
