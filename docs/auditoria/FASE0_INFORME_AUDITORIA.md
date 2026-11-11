# Informe de auditoría — Fase 0: base reproducible

**Proyecto:** RPG LBA — Las Cenizas de Lythara
**Fase:** 0 — Auditoría y bootstrap (prompt `prompts/00_AUDITORIA_Y_BOOTSTRAP.md`)
**Rama de trabajo:** `agent/fase0-auditoria-y-bootstrap` (base: `main` = upstream `v2.0.0`)
**Commits de la fase:** `2410606`, `2ecca5a`, `96311c1`, `2c328ea`, `fd81964`, `2d35186`, + informe
**Fecha de ejecución:** 2026-11-12
**Ejecutor:** agente de programación (sin acceso a credenciales GitHub del responsable)
**Motor:** Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`), binario oficial Linux x86_64

---

## 1. Objetivo y alcance

Auditar la plantilla base fijada, verificar que funciona con Godot 4.7.2,
documentar qué trae y qué no trae, construir el repositorio RPG-LBA con
procedencia y CI reproducible, y entregar la matriz de decisión
reutilizar/modificar/sustituir/no usar. **No se implementó ningún feature de
juego** (regla del prompt 00 y de AGENTS.md).

## 2. Plantilla base fijada (procedencia)

| Campo | Valor |
| --- | --- |
| Repositorio | https://github.com/devmoreir4/godot-3d-multiplayer-template |
| Tag auditado | `v2.0.0` — **verificado que existe** |
| Objeto tag | `6b58ad830ea3a876528bf6ce934d93cca90c49de` |
| **Commit SHA fijado** | **`51b2614fbd92e4c79a3353832256d41d79a6cf4a`** |
| Licencia del código | MIT (Carlos Moreira, 2026) |
| Assets de terceros | Excluidos del MIT; ATTRIBUTIONS por carpeta |
| Remote en este repo | `upstream` (configurado; no se hace push a upstream) |

Verificación con `git ls-remote --tags` (salida real, 2026-11-12):

```
6b58ad830ea3a876528bf6ce934d93cca90c49de  refs/tags/v2.0.0
51b2614fbd92e4c79a3353832256d41d79a6cf4a  refs/tags/v2.0.0^{}
```

El commit del tag coincide con el HEAD actual de `main`/`develop` upstream
(2026-09-02, «Merge pull request #27 from devmoreir4/fix/issue-templates»).

## 3. Qué trae la plantilla (verificado en código, 167 archivos, 3.184 líneas GDScript)

| Sistema | Estado real verificado |
| --- | --- |
| Sesiones multijugador ENet (UDP 8080) | Host, join, hasta 10 jugadores declarados (`MAX_PLAYERS = 10`), sanitización de nick (24 chars), dirección y skin |
| Servidor dedicado headless | `level.gd` auto-hostea al detectar `DisplayServer "headless"`; `run_headless_server.sh` incluido |
| Registro de jugadores | RPC `_register_player` validado en servidor (`is_server`, deduplicación, sanitización) y sincronización por `_sync_registered_player` (authority) |
| Inventario autoritativo | `PlayerInventory` (dominio puro, `RefCounted`): 16 slots + 4 bonus de mochila, stacks, merge/swap, equipar/desequipar, serialización dict. El servidor es dueño; cliente pide y recibe sync |
| Items | `Item` (Resource: id, tipo, rareza, stack, valor, icono, escena) + `ItemDatabase` con **13 items hardcodeados** |
| Equipamiento visible | Sombreros/armas/mochila anclados al esqueleto con attach points y sync por RPC |
| Chat | Relay por servidor, sanitización 160 chars, `any_peer` validado |
| Lista de jugadores | Tab con refresco por señal |
| Objetos físicos en mundo | Drops con RigidBody3D, push, pickup con validación en servidor (cooldown 1 s, ventana temporal, en suelo, item delante) |
| Movimiento | 3ª persona cámara-relativa, sprint, doble salto, animaciones sincronizadas con rate-limit (10 req/s, ráfaga 6) |
| Cámara | SpringArm con ratón, conmutable 1ª/3ª persona |
| CI upstream | `godot-ci.yml` (gdlint/gdformat + import con Godot **4.7-stable**) y `release.yml` (draft release con ZIP + SHA-256 en tags) |

## 4. Qué NO trae la plantilla (verificado: no existe en el código)

- **Combate real.** El ataque reproduce la animación `Attack1` y nada más.
  Verificación: `grep -rE "health|damage|take_damage|hitbox|hurtbox" **/*.gd`
  → **0 coincidencias**. El README de la plantilla lo declara y el código lo
  confirma: no hay HP, daño, hitbox ni hurtbox en todo el proyecto.
- Enemigos, IA, telegráficos, muerte, drops de enemigos.
- Clases, habilidades, cooldowns, recursos de clase.
- Misiones, NPCs, diálogos, mundo por regiones, streaming, mazmorras.
- Economía (moneda, comerciantes, crafting), rareza con afijos.
- Persistencia (no hay guardado de ningún tipo).
- Controles táctiles/joystick (input 100% teclado/ratón).
- Tests (ni `tests/`, ni `addons/`, ni GdUnit4) y preset de exportación
  Android (no existe `export_presets.cfg`).
- Party, guild, trade, world_id/realm.

## 5. Hallazgos de la auditoría

| # | Severidad | Hallazgo | Acción |
| --- | --- | --- | --- |
| H1 | **CRÍTICO** | `project.godot` declara renderer **Forward Plus** (Vulkan). El objetivo RPG LBA es Compatibility (GLES 3.0) para móviles modestos; Redmi 9C no tiene Vulkan. | Cambiar a `gl_compatibility` en Fase 1 (PR separado, medir impacto). |
| H2 | **CRÍTICO (CI)** | En checkout limpio, la 1ª importación emite 4 errores de la fuente `Kurland.ttf` (el editor intenta cargarla antes de importarla). El `validate.yml` original del kit fallaría por su `grep` de `ERROR:`. | Corregido: `validate.yml` hace import en 2 pasadas (la 1ª genera recursos sin validar, la 2ª valida estricta). Verificado: 2ª pasada sin errores. |
| H3 | MEDIO | CI upstream fija `4.7-stable`, el kit exige **4.7.2 exacto**. | Corregido: `godot-ci.yml` actualizado a `4.7.2-stable` (ADR-001). |
| H4 | MEDIO (licencias) | `assets/fonts/Kurland.ttf` y `assets/ui/close.svg` NO tienen atribución documentada en la plantilla. | Registrados en `assets/manifest.csv` como PENDIENTES DE VERIFICACIÓN; Kurland identificado externamente (GGBotNet, dafont, listada SIL OFL 1.1). Acción: verificar archivo de licencia real o sustituir antes de cualquier release. |
| H5 | MENOR (seguridad) | `apply_force_to_server_object` es `any_peer` sin verificación de propietario: cualquier cliente puede empujar objetos físicos por nombre. | Solo afecta a física cosmética (no inventario). Corregir en Fase 6 (validación de ownership/rate) o al reemplazar el sistema de drops. |
| H6 | MENOR | `request_add_item` solo lo puede invocar el propio servidor/peer 1 (host). En modo listen-server el host-jugador podría auto-darse items. | Aceptable para plantilla; en RPG LBA el servidor dedicado no tendrá jugador peer 1. Documentar y testear en Fase 6. |
| H7 | INFO | Sombreros Poly by Google son **CC BY 3.0 (atribución obligatoria)**, no CC0; además son estéticamente modernos (auriculares, fedora). | Atribución conservada en `assets/items/ATTRIBUTIONS.md`; se sustituirán por assets medievales en fases posteriores. |
| H8 | INFO | `ItemDatabase` hardcodea items en GDScript; el kit exige datos externalizados (CSV/JSON validados). | Migrar a datos en Fase 3. |
| H9 | INFO | Sin `export_presets.cfg`; la exportación Android no está configurada. | `android-debug.yml` queda en SKIPPED automático hasta Fase 1. |
| H10 | INFO | El historial git del template se preserva íntegro (tags v1.0.0–v2.0.0). | Procedencia garantizada; `main` de RPG-LBA = v2.0.0 prístina. |

## 6. Matriz de decisión (reutilizar / modificar / sustituir / no usar)

| Sistema/asset de la plantilla | Veredicto | Justificación y destino |
| --- | --- | --- |
| Autoload `Network` (sesiones, registro, sanitización) | **REUTILIZAR** | Base sólida y validada; extender en Fase 6/7 con world_id, rate-limit global, handshake |
| Servidor dedicado headless + `run_headless_server.sh` | **REUTILIZAR** | Funciona hoy (probado con 2 clientes); evoluciona a servidor autoritativo completo |
| `PlayerInventory` (dominio puro) | **REUTILIZAR** | Limpio, sin dependencia de UI; extender en Fase 3 (rareza, afijos, nivel, slots de equipo ARPG) |
| `Item` (Resource) | **REUTILIZAR + MODIFICAR** | Añadir nivel requerido, clase, slot de equipo ARPG |
| `ItemDatabase` | **MODIFICAR** | Externalizar 13 items de muestra a datos CSV/JSON (regla del kit, H8) |
| Equipamiento visible (attach points + sync) | **REUTILIZAR patrón** | El mecanismo sirve; los modelos concretos se cambian |
| Chat con relay de servidor | **REUTILIZAR** | Añadir rate-limit por jugador (Fase 7) |
| Player list, menús base, pausa | **REUTILIZAR** | Se rediseñan visualmente en fases de UI |
| Sistema de drops/pickup con validación temporal | **REUTILIZAR** | Patrón de ventana/cooldown en servidor útil para loot |
| Rate-limit de animaciones (token bucket) | **REUTILIZAR** | Patrón aplicable a acciones de combate |
| Controlador de jugador 3ª persona + sprint + doble salto | **SUSTITUIR** | ARPG isométrico exige controller nuevo (Fase 1); se conserva el patrón de autoridad/animación |
| Cámara SpringArm 1ª/3ª persona con ratón | **SUSTITUIR** | Cámara elevada/isométrica fija (Fase 1) |
| Ataque solo-animación | **SUSTITUIR** | Combate real con hitbox/ventana activa/daño en autoridad (Fase 1-2) |
| Arena de pruebas (`arena.tscn`) | **NO USAR en release** | Vale como sandbox de desarrollo; el contenido real empieza en Brumaclara (Fase 1) |
| Robot CC0 de AGChow | **NO USAR en release** | Placeholder de desarrollo; KayKit Adventurers lo sustituye (Fase 1) con licencia comprobada |
| Sombreros modernos Poly by Google (CC BY 3.0) | **NO USAR** | Estética no medieval + atribución obligatoria; sustituir |
| Items Quaternius (mochila/armas/misc) | **NO USAR en release** | Placeholders de prueba; sustituir por kit medieval (spada/axe sirven de proxy de dev) |
| Texturas prototype Kenney | **REUTILIZAR (grisbox)** | Suelo de prototipo; región final usa kits de entorno |
| Fuente Kurland | **PENDIENTE** | Verificar OFL 1.1 en fuente oficial o sustituir (H4) |
| `close.svg` | **SUSTITUIR** | Sin licencia documentada (H4) |
| Renderer Forward Plus | **MODIFICAR** | A `gl_compatibility` en Fase 1 (H1) |
| Workflows upstream (`godot-ci.yml`, `release.yml`) | **REUTILIZAR (adaptados)** | Versión alineada a 4.7.2; release solo draft |
| `icon.png` | **SUSTITUIR** | Icono original de RPG LBA (Fase 1) |

## 7. Pruebas ejecutadas (comandos reales y resultados)

Niveles de validación diferenciados según `docs/10_QA_Y_VALIDACION.md`:

### 7.1 Validación estática (A)

| Prueba | Comando | Resultado |
| --- | --- | --- |
| Verificación de tag upstream | `git ls-remote --tags https://github.com/devmoreir4/godot-3d-multiplayer-template` | **PASS** — v2.0.0 existe; SHA fijado `51b2614` |
| Confirmación de ataque sin daño | `grep -rE "health\|damage\|take_damage\|hitbox\|hurtbox" scripts/` | **PASS** — 0 coincidencias; afirmación del README verificada en código |
| Lint GDScript | `gdlint scripts tests` | **PASS** — sin problemas (gdtoolkit 4.5.0) |
| Formato GDScript | `gdformat --check scripts tests` | **PASS** — 17 archivos sin cambios |
| Manifiesto de assets | `python3 scripts/ci/check_asset_manifest.py assets/manifest.csv` | **PASS** — 7 filas completas (2 pendientes de verificación humana de licencia) |

### 7.2 Importación headless (A)

Sobre checkout limpio de la plantilla y sobre la rama final de RPG-LBA,
con `Godot_v4.7.2-stable_linux.x86_64`:

| Prueba | Comando | Resultado |
| --- | --- | --- |
| Import 1ª pasada | `godot --headless --path . --import` | **PASS** (exit 0; 4 líneas benignas de `Kurland.ttf`, conocidas y documentadas — H2) |
| Import 2ª pasada (estricta) | `godot --headless --editor --path . --quit --verbose` + grep de `SCRIPT ERROR:\|Parse Error:\|Failed loading resource\|ERROR:` | **PASS** — sin errores críticos |

### 7.3 Smoke de escena principal (E)

| Prueba | Comando | Resultado |
| --- | --- | --- |
| Arranque de `level.tscn` headless | `timeout 90s godot --headless --audio-driver Dummy --path . --quit-after 180` + grep estricto | **PASS** — exit 0, sin errores críticos |

### 7.4 Multijugador simulado headless (D)

Arnés reproducible (incluido en el repo y en CI): `tests/multiplayer/run_multiplayer_smoke.sh`
levanta **1 servidor dedicado headless + 2 clientes headless independientes**
en 127.0.0.1:8080 usando la escena real sin modificarla.

| Prueba | Comando | Resultado |
| --- | --- | --- |
| Servidor dedicado + 2 clientes (plantilla original) | `GODOT_BIN=… bash tests/multiplayer/run_multiplayer_smoke.sh .` (en copia de la plantilla) | **PASS** — `distinct_registered=2` en servidor; `peak_registered=2 peak_spawned=2` en ambos clientes; exit 0 en los 3 procesos |
| Repetibilidad | misma prueba 3 ejecuciones consecutivas | **PASS** — 3/3 estables |
| Servidor + 2 clientes (rama RPG-LBA final) | mismo comando en `agent/fase0-auditoria-y-bootstrap` | **PASS** — mismo resultado |

Salida real (una de las ejecuciones):

```
LBA_MP_RESULT role=server distinct_registered=2 peak_registered=2 ... status=PASS
LBA_MP_RESULT role=client distinct_registered=0 peak_registered=2 peak_spawned=2 ... status=PASS
LBA_MP_RESULT role=client distinct_registered=0 peak_registered=2 peak_spawned=2 ... status=PASS
```

Nota: los logs de cliente contienen una línea esperada y benigna
`ERROR: Couldn't create an ENet host.` — es el intento de auto-host headless
de la plantilla que falla porque el puerto ya lo ocupa el servidor dedicado.
Está documentada en el driver y permitida explícitamente en el paso de CI.

### 7.5 No ejecutables en este entorno

| Prueba | Estado | Motivo |
| --- | --- | --- |
| Interacción visual con GPU (menús con ratón, gameplay visual) | **NOT TESTED** | El sandbox no tiene GPU/display; solo headless. Requiere PC del responsable (ver `docs/15_IMPORTAR_Y_PROBAR_LOCAL.md`). |
| Exportación APK debug | **NOT TESTED** | No existe `export_presets.cfg` (H9); el workflow queda SKIPPED por diseño. |
| Instalación/prueba en Android físico (Redmi 9C u otro) | **NOT TESTED** | No hay dispositivo ni conexión ADB en este entorno. Obligatorio antes de declarar cualquier compatibilidad/FPS. |
| GdUnit4 unit tests | **SKIPPED** | `addons/gdUnit4` y tests de unidad no existen aún (se integran cuando haya lógica de dominio que probar, Fase 1+). |
| GitHub Actions real | **NOT TESTED** | Requiere repositorio GitHub destino y credenciales del responsable (ver §9). |

## 8. Repositorio RPG-LBA construido

- `main` = plantilla v2.0.0 **prístina** (sin push directo, protegida al desplegar).
- Rama `agent/fase0-auditoria-y-bootstrap` con 7 commits lógicos:
  1. `2410606` kit de producción (AGENTS.md, docs, prompts, config)
  2. `2ecca5a` manifiesto de assets + THIRD_PARTY_NOTICES
  3. `96311c1` arnés multijugador headless + scripts locales
  4. `2c328ea` CI (validate.yml 2 pasadas + mp + manifiesto; android-debug; godot-ci 4.7.2)
  5. `fd81964` README propio + PROVENANCE.md
  6. `2d35186` scripts de CI del kit
  7. (este informe)
- Remote `upstream` apunta a devmoreir4; el `origin` (OWNER/REPO) lo añade el
  responsable al publicar.
- Tags upstream heredados (v1.0.0–v2.0.0) para trazabilidad.
- Sin secretos, sin `.godot/`, sin APKs, sin credentials.
- Pipeline local completo ejecutado sobre la rama final: **6/6 PASS**
  (lint, import 1, import 2 estricto, smoke, multijugador, manifiesto).

## 9. Bloqueos y pendientes que requieren el responsable

1. **OWNER/REPO real**: el prompt maestro usa un placeholder. No se pudo
   crear/pushear el repositorio GitHub. Entregado: ZIP del repo con historial
   `.git` completo + `git bundle`. Para publicar: crear repo vacío
   `RPG-LBA`, descomprimir/clonar el bundle, `git remote add origin …`,
   push de `main` y de la rama `agent/fase0…`, abrir PR y dejar que Actions
   corra (el flujo completo se ejecutará por primera vez ahí).
2. **Credenciales GitHub**: sin token de escritura no hay push/PR/Actions.
   Los workflows están listos; su primera ejecución real será la evidencia
   definitiva (URLs de runs quedarán en el PR).
3. **Licencias pendientes (H4)**: decisión humana sobre Kurland.ttf y
   close.svg (verificar/sustituir).
4. **Prueba visual y en dispositivo**: en la PC del responsable con Godot
   4.7.2 (pasos en README) y, más adelante, Redmi 9C físico.
5. **Decisión de licencia del código propio** (pendiente registrada en ADR).

## 10. Próximo paso

**Esperando autorización humana para Fase 1 — Vertical slice** según
`prompts/01_VERTICAL_SLICE.md`: cambio a Compatibility renderer, cámara
isométrica, personaje de prueba, movimiento omnidireccional, bosque pequeño,
un enemigo con telegráfico y daño real, HUD móvil, misión tutorial y perfil
Low. PR independiente, mismo flujo de evidencia.

Hasta esa autorización no se modifica ningún sistema de juego.
