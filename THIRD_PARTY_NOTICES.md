# Third-Party Notices — RPG LBA

Este archivo resume las licencias de todo el material de terceros presente en el
repositorio. El detalle por asset vive en `assets/manifest.csv`. Los archivos
`ATTRIBUTIONS.md` originales de la plantilla se conservan sin modificar.

## Estructura de licencias del repositorio

| Ámbito | Licencia | Notas |
| --- | --- | --- |
| Código GDScript de la plantilla base | MIT (Carlos Moreira, 2026) | `LICENSE` en la raíz |
| Documentación del kit RPG LBA (`docs/`, `prompts/`, `config/`) | Uso/adaptación libre para este proyecto | ver `docs/kit/LICENSE_KIT.txt`; no concede licencias sobre assets externos |
| Código nuevo de RPG LBA (tests, scripts, CI) | Por decidir por el responsable | decisión pendiente registrada en `docs/13_RIESGOS_Y_DECISIONES.md` |

## Assets de terceros incluidos (heredados de la plantilla v2.0.0)

### 1. 3D Godot Robot Platformer Character — CC0 1.0 Universal
- Autor: AGChow (https://github.com/AGChow)
- Fuente: https://github.com/AGChow/3D-Godot-Robot-Platformer-Character
- Uso: personaje de prueba y paletas. Atribución no obligatoria (se acredita por
  cortesía). Detalle en `assets/characters/player/ATTRIBUTIONS.md`.

### 2. Prototype Textures — Kenney — CC0 1.0 Universal
- Fuente: https://kenney.nl/ (Prototype Textures 1.0, 2020-04-08)
- Uso: texturas de suelo del área de pruebas. Detalle en
  `assets/environment/ATTRIBUTIONS.md`.

### 3. Items (mochila, armas, misc) — Quaternius — CC0 1.0 Universal
- Autor: Quaternius (https://www.patreon.com/quaternius)
- Uso: modelos e iconos de inventario. Detalle en `assets/items/ATTRIBUTIONS.md`.

### 4. Sombreros — Poly by Google (vía Poly Pizza) — CC BY 3.0 (ATRIBUCIÓN OBLIGATORIA)
- Fuente: https://poly.pizza (enlaces por modelo en `assets/items/ATTRIBUTIONS.md`)
- Atribución requerida por la licencia: «Hats by Poly by Google» con enlace a
  poly.pizza. Esta atribución DEBE conservarse mientras se usen estos modelos.
- Estado: estos sombreros modernos (fedora, auriculares, etc.) no encajan con la
  dirección artística medieval de RPG LBA; se prevé sustituirlos en fases
  posteriores. Mientras existan en el repo, la atribución es obligatoria.

### 5. Fuente Kurland — GGBotNet — PENDIENTE DE VERIFICACIÓN
- Fuente: https://www.dafont.com/kurland.font (listada como SIL Open Font
  License 1.1 / uso comercial gratuito según dafont y fontspace).
- RIESGO: la plantilla NO incluye archivo de licencia junto a `assets/fonts/Kurland.ttf`.
- Acción requerida: verificar los términos en la fuente oficial y conservar una
  copia de la licencia junto al archivo, o sustituir la fuente antes de
  cualquier build distribuible.

### 6. `assets/ui/close.svg` — PENDIENTE DE VERIFICACIÓN
- Icono incluido en la plantilla sin atribución documentada.
- Acción requerida: reemplazar por un icono propio o CC0 verificado antes de
  cualquier release pública.

### 7. `icon.png` — MIT (contenido de la plantilla)
- Render del robot CC0 creado para la plantilla. Se reemplazará por el icono
  original de RPG LBA en la Fase 1.

## Assets previstos y NO incluidos aún

KayKit (Adventurers, Dungeon Remastered), Quaternius (RPG Characters, Medieval
Village), Poly Haven y Kenney (paquetes adicionales) están catalogados en
`docs/08_DIRECCION_ARTISTICA_ASSETS.md` pero NO forman parte de este
repositorio todavía. Se incorporarán únicamente desde sus fuentes oficiales,
con licencia comprobada por paquete y entrada en `assets/manifest.csv`, sin
redistribuir los paquetes fuente cuando sus términos no lo permitan.

## Política

- Ningún asset sin licencia verificable se incorpora al juego (regla 5 de `AGENTS.md`).
- Cada asset nuevo exige fila completa en `assets/manifest.csv`.
- El CI ejecuta `scripts/ci/check_asset_manifest.py` en cada cambio.
- No extraer música, modelos, textos, iconos ni código de IP protegidas
  (Diablo, World of Warcraft, Albion Online, etc.).
