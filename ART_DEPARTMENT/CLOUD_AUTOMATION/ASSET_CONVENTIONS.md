# Asset conventions — IDs, taxonomía, naming, presupuestos y estados

Consolidated from: `CLOUD_AUTOMATION/README.md` §3, the bootstrap conventions
proposed in PR #19 (`docs/art-pipeline/README.md`) and AGENTS.md. This is the
single reference for *where every kind of asset lives* and *how it is named*.
PR #19's parallel conventions doc is retired (see
[PR19_RECONCILIATION.md](PR19_RECONCILIATION.md)).

## 1. Taxonomía y rutas reales por tipo de contenido

Respect existing folders first; `assets/` already contains `characters/`,
`enemies/`, `items/`, `models/`, `environment/`, `materials/`, `ui/`, `art/`,
`branding/`. New content goes into this layout (English, `snake_case`):

| Contenido | Ruta canónica | Ejemplo de archivo |
|---|---|---|
| Personaje jugador por clase | `assets/characters/player/<class_id>/` | `chr_player_machetero_001.glb` |
| NPC por región | `assets/characters/npcs/<region_id>/<npc_id>/` | `chr_npc_valdeluz_cheo_001.glb` |
| Enemigo común | `assets/enemies/common/<enemy_id>/` | `chr_enemy_sombra_portal_001.glb` |
| Jefe | `assets/enemies/bosses/<boss_id>/` | `chr_boss_guajiro_sin_rostro_001.glb` |
| Armas por clase | `assets/items/weapons/<class_id>/` | `itm_weapon_machete_siera_001.glb` |
| Armadura/casco por hueco | `items/armor/<slot>/<class_id>/`, `items/helmets/...` | `itm_armor_chest_machetero_001.glb` |
| Accesorios | `assets/items/accessories/` | `itm_acc_anillo_ceniza_001.glb` |
| Props/mobiliario | `assets/models/furniture/`, `assets/models/objects/` | ya en uso por la fábrica |
| Arquitectura exterior | `assets/models/architecture/`, `assets/models/buildings/` | ya en uso |
| Urbano modular | `assets/models/urban/` | ya en uso |
| Kit de región | `assets/environment/regions/<region_id>/` | kit_valdeluz_* |
| Kit de mazmorra | `assets/environment/dungeons/<dungeon_id>/` | kit_mazmorra_* (confirmar nombres con la biblia antes de crear) |
| Vegetación / rocas | `assets/models/vegetation/`, `assets/models/rocks/` | ya en uso |
| Texturas PBR | `assets/environment/textures/<material_family>/` | `tex_ground_grass_tropical_001_*` |
| Materiales Godot | `assets/materials/` | `mat_*.tres` |
| Animaciones/rigs | `assets/animations/humanoid|quadruped|flying|spectral|amorphous|boss/` | `anm_humanoid_idle_001.glb` |
| VFX | `assets/effects/combat|magic|environment/` | `vfx_machete_slash_001.tscn` |
| Iconos UI | `assets/ui/icons/` | ya en uso |
| Audio | `assets/audio/ambience|music|sfx/` | `snd_*.ogg` |

Class IDs estables (no traducibles): `machetero`, `bruja_manigua`,
`sepulturero`, `tirador_malecon`, `cimarron`, `bardo_solar`. Region IDs:
`valdeluz`, `la_habana_campanas`, y los que fije la biblia (verificar antes de
crear kits; no confundir hubs con regiones exteriores).

## 2. Formato de IDs

- Existentes (inmutables, ya publicados en el manifiesto): prefijo por tipo +
  familia + slug + versión: `mdl_vegetation_palm_royal_001`, `tex_ground_grass_tropical_001`,
  `mat_caliza_001`.
- Nuevos assets: mismo estilo `snake_case` con prefijo por dominio
  (`chr_`, `itm_`, `mdl_`, `tex_`, `mat_`, `anm_`, `vfx_`, `snd_`, `icn_`) + `_NNN`
  (número de versión, no año). Nunca derivar el ID de un nombre traducible.
- GAP IDs: `GAP_*` (ver `ASSET_GAP_BACKLOG.json`); nunca reutilizar un GAP ID
  como ID de asset producido, y viceversa.
- IDs heredados: `LEGACY_<hash>` derivados de ruta (ver `LEGACY_ASSET_INDEX.json`);
  mover un archivo heredado exige migración documentada.

## 3. Naming de archivos

- `snake_case` en ASCII, sin espacios ni acentos en nombres de archivo/directorio.
- Mapas PBR como archivos sueltos: `*_base_color`, `*_normal`, `*_roughness`,
  `*_metallic`, `*_ao`, `*_height` (height solo si se justifica).
- GLB/glTF 2.0 preferente; FBX solo como fuente de entrada documentada.
- Unidades en metros, +Y arriba, origen en la base/pies; el forward de
  personajes se documenta y se mantiene consistente.
- No generar `.import` ni UIDs a mano: los crea Godot al importar.

## 4. Presupuestos móviles (límites de revisión, no aceptación)

Godot 4.7.2 Standard, Compatibility Renderer, objetivo ARM64 (Redmi 9C es el
suelo). Son umbrales para marcar revisiones, no garantías de rendimiento:
medir en dispositivo antes de declarar PASS.

| Tipo | LOD0 triángulos | Texturas | Notas |
|---|---|---|---|
| Personaje/enemigo común | 5k–20k | 512–1024 px | atlas por personaje cuando aporte |
| Jefe | 15k–35k | 1024 px | fases pueden compartir atlas |
| Props comunes | 500–5k | 256–512 px | reutilizar material compartido |
| Vegetación/rocas | ≤2k por pieza | atlas 1024–2048 | LOD1 ≈ 50%, LOD2 ≈ 25% |
| Kits modulares | ≤1k por bloque | atlas por kit | un material por kit cuando sea posible |
| VFX | — | ≤512 px | partículas simples en perfil bajo |

Colisiones simples (cajas/cápsulas/concave solo donde se justifique); nunca la
malla de render como colisión por defecto. Medir huesos, materiales y draw
calls en escena real antes de escalar contenido.

## 5. Ciclo de vida y estados

Estados técnicos (automatizables) vs aprobación humana (siempre manual):

```
MISSING → PLANNED → DISCOVERED → LICENSE_REVIEW → QUEUED → GENERATING →
PROCESSING → QA → REVIEW → APPROVED → INTEGRATED
             ↘ QUARANTINED   ↘ NEEDS_IMPROVEMENT → (rework) ↗
             ↘ REJECTED      ↘ DEFERRED_QUOTA (sin cuota GPU) ↗
             ↘ NOT_TESTED (cualquier estado que no tenga prueba real)
```

- `APPROVED` exige: archivo real + SHA-256 + licencia verificada + validación
  técnica + revisión visual humana. Un validador PASS nunca implica
  `APPROVED`.
- `INTEGRATED` exige PR fusionado + referencia al commit.
- Licencia desconocida = `QUARANTINED`: no entra en builds distribuibles.
- Sin prueba real = `NOT TESTED`, nunca PASS.

Las puertas separadas (CATALOGED / LICENSE_VERIFIED / TECH_VALIDATED /
VISUAL_REVIEW_PENDING / VISUAL_APPROVED / GODOT_IMPORT_PASS /
SCENE_INTEGRATION_PASS / ANDROID_DEVICE_PASS) están definidas en
[README.md](README.md) §2 y se registran por asset en
`ASSET_LIBRARY_INDEX.json`.

## 6. Antes de producir cualquier recurso

1. Consultar `ASSET_LIBRARY_INDEX.json` (por hash y por ruta) y
   `ASSET_GAP_BACKLOG.json` (por GAP relacionado).
2. Confirmar que el GAP aún no está cubierto; si lo está, mejorar el asset
   existente en lugar de duplicar con otro nombre.
3. Registrar procedencia y licencia exactas en `assets/manifest.csv` ANTES de
   descargar (ver [SECRETS_SETUP.md](SECRETS_SETUP.md) y AGENTS.md §5).
4. Lotes pequeños (1–3 assets) y PR revisable; nunca decenas sin revisión.
