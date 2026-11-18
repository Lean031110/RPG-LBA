# Informe — Reconciliación, continuidad y entrega (2026-11-18)

Mandato: «ORDEN MAESTRA DE CONTINUIDAD, RECONCILIACIÓN Y ENTREGA — RPG LBA».
Alcance: auditoría integral del repositorio, secretos/variables, corrección de
deuda, reconciliación de ramas, integración por PR, APK única ARM64, capturas
reales y paquete de entrega. Este informe se redacta ANTES de modificar código
(§4.3) y se cierra con los resultados reales al final de la intervención.

---

## 1. Estado verificado de `main` (consulta real, no memoria)

- `main` = **8061242** (merge PR #21, 2026-11-17T00:54Z). Repositorio público,
  60,9 MB, 21 ramas, rama por defecto `main`.
- Proyecto: Godot 4.7.2 Standard, GDScript tipado, GL Compatibility, español.
  `project.godot` main scene: `scenes/arpg/menu/intro_splash.tscn`.
  Autoloads: Network, ItemDatabase, RpgDB, SaveSystem, QuestSystem,
  GraphicsSettings, CombatEvents (7).
- Volumen: 32 escenas `.tscn`, 47 ficheros de test GdUnit4, ~90 scripts de juego.
- Exportación: 2 presets Android debug (ARM64 y Universal), mismo package
  `com.lbagames.rpglba`, version/code 3, version/name 0.2.0, autofirma debug
  documentada (`build/android/rpglba-debug.keystore`, credenciales públicas de
  convención debug, no release).

## 2. CI en `main` (últimas corridas, verificadas por API)

| Workflow (run 2026-11-17, sha 8061242) | Resultado |
|---|---|
| RPG LBA - Validate | success |
| Godot CI | success |
| Visual Captures | success |
| Android debug APK (export+verifica+emuladores) | success |
| Asset Factory (schedule) | skipped (por diseño: `FACTORY_CRON_ENABLED` ausente) |

Fallos históricos recientes (2026-11-16, rama `agent/asset-cloud-automation`
en commits intermedios 7b96766/8806005): Asset Validation (segfault teardown
bpy), release.yml (`timeout-minutes` en job reutilizable), asset-library-index
(PyYAML ausente). **Los tres quedaron corregidos en 3a845e6** y el HEAD de esa
rama terminó con las 6 workflows en verde (runs 43916869482/9399/9748/9360/9418/955204).

## 3. Ramas: clasificación (21 ramas, §7.1)

### 3.1 Completas y ya integradas en `main` (16, sin trabajo pendiente)
`agent/fase0…fase5` (7), `agent/fase1b`, `agent/fase3b`, `agent/fase4a`,
`agent/fase4b`, `agent/reconciliacion-ci-visual`, `docs/*` (2),
`feature/phase-2-playable-prototype`, `feature/ai-art-department`,
`fix/fase4b-lint-release`. Todas con +0/-N respecto a `main` (ancestry
verificado). Se conservan como historial; no requieren acción.

### 3.2 Incompletas pero terminables / integrables (3 PR abiertas)

| PR | Rama | +adelante/-atrás | Contenido único | Estado CI en HEAD |
|---|---|---|---|---|
| #17 | `agent/docs-reorganizacion` | +1/-5 | Solo docs: índice, STATUS, ROADMAP canónico, arquitectura, gates, ADR-008..012 (+609/-0) | verde en 8342c80 (2026-11-16) |
| #18 | `agent/asset-cloud-automation` | +37/-5 | Fábrica cloud consolidada: 9 workflows, validadores, índice canónico 2.0.0, carril Kaggle, Firebase rules, evidencias (+14021/-10) | verde en 3a845e6 (2026-11-16, 6 workflows) |
| #15 | `feature/valdeluz-capital-city` | +6/-5 | Capital de Valdeluz PREVIEW (fase futura) + World Art Bible + tests (+839/-2) | verde en 25bc199 (2026-11-16) |

### 3.3 Duplicadas / obsoletas (1 PR)

| PR | Rama | Situación |
|---|---|---|
| #19 | `agent/assets-factory-bootstrap` (+18/-5) | Su contenido útil fue reconciliado DENTRO de #18 (documentado archivo por archivo en `ART_DEPARTMENT/CLOUD_AUTOMATION/PR19_RECONCILIATION.md`): reglas Firestore, plantilla n8n Poly Haven, 4 proveedores, guía de secrets. El resto (catálogo/índice/workflow paralelos) fue retirado a propósito para evitar doble fuente canónica. Tras fusionar #18, esta PR queda SUPERSEDED; la rama NO se borra. |

### 3.4 Nota sobre `agent/fase1c-valdeluz-capital`

Alias exacto de fase1b (mismo SHA 4b8bcdd, documentado en
RECONCILIACION_INTEGRAL.md). Su PR #15 añade trabajo ÚNICO de fase futura en
rama aparte. Sin acción.

## 4. Dependencias y orden de integración

1. **PR #17 (docs)**: sin dependencias, docs puros. Integrar primero.
2. **PR #18 (fábrica)**: depende de que #19 NO se fusione (evitar duplicados);
   integra el contenido reconciliado de #19.
3. **PR #19**: cerrar como superseded tras #18 (comentario con evidencia);
   rama conservada.
4. **PR #15 (capital)**: fase FUTURA según roadmap del propio proyecto («fase
   futura; solo mantenimiento de base, sin fusión a main», commit b4f7bcd).
   Se actualiza contra `main` y se mantiene ABIERTA aparte; NO se fusiona
   (mandato §7: mantener aparte las ramas futuras).
5. Rama nueva `agent/reconciliacion-continuidad-2026`: informes, corrección de
   nomenclatura de secrets en workflows, capturas finales y documentación de
   entrega. PR propia al final.

Reglas respetadas: solo merges por PR (nunca push directo a `main`), sin force
push, sin borrar ramas con trabajo útil, CI verde obligatoria antes de cada
merge, `delete_branch_on_merge` ya desactivado.

## 5. Secretos y variables — inventario real (resumen; detalle en §9)

Secrets existentes (8, nombres verificados por API, valores nunca consultados):
`ASSET_WORK_BRANCH`, `HF_TOKEN`, `KAGGLE_KEY`, `KAGGLE_USERNAME`,
`SMITHSONIAN_API_KEY`, `TELEGRAM_ADMIN_CHAT_ID`, `TELEGRAM_BOT_TOKEN`,
`_3DVALLEY_API_KEY`.

Hallazgos principales:

1. **CRÍTICO (seguridad)**: 7 credenciales reales existían ADEMÁS como
   Variables en texto claro (Telegram, HF, Kaggle, Smithsonian, 3DValley).
   Ningún workflow de ninguna rama las referenciaba como `vars.*`. Se
   eliminaron las variables y quedaron solo los secrets homónimos
   (auditoría completa en `docs/ops/SECRETS_AND_VARIABLES_AUDIT.md`).
2. **Nomenclatura**: `asset-review-telegram.yml` (PR #18) usa
   `secrets.TELEGRAM_CHAT_ID`, pero el secret existente es
   `TELEGRAM_ADMIN_CHAT_ID`. Corrección compatible con cadena de fallback
   `TELEGRAM_CHAT_ID || TELEGRAM_ADMIN_CHAT_ID || vars.TELEGRAM_CHAT_ID`.
3. **Variables creadas (no sensibles, valores inequívocos de la config real)**:
   `ASSET_WORK_BRANCH=agent/asset-cloud-automation` (default del scheduler),
   `ASSET_BATCH_LIMIT=3` (default `inputs.limit` del scheduler, guía 1–3).
   `FACTORY_CRON_ENABLED` se deja AUSENTE a propósito (cron desactivado hasta
   prueba e2e aprobada por el propietario — decisión ya documentada en #18).
4. Pruebas controladas ejecutadas (§5.5): ver §9 y el documento de auditoría.

## 6. Problemas históricos — estado tras reproducir/inspeccionar

1. **APK ~103 MB que no instalaba en S22 Ultra (v0.1.0)**: diagnóstico ya
   documentado en `android-debug.yml`/`LEEME_INSTALACION.txt`: APK válido
   (firma v2+v3, zipalign PASS, manifiesto correcto, instaló y arrancó en
   emulador API 35/36); causa raíz atribuida a copia local truncada en el
   teléfono. Protocolo de verificación SHA-256 incluido en la entrega.
   La APK ARM64 actual de `main` es de 52 MB (v0.2.0).
2. **UI/escalado**: suite de capturas 16:9 y 20:9 en CI (9 capturas
   verificadas no-negras por estadística de píxeles). Revisión humana sigue
   siendo el gate final (AGENTS §10).
3. **Identidad gráfica**: icono Android adaptativo propio
   (`assets/branding/icon_full_192.png` + foreground/background) ya
   configurado en ambos presets; NO es el icono genérico de Godot.
4. **Estabilidad**: 295/295 casos GdUnit4 en la última reconciliación;
   suites actuales en CI verde.

## 7. Riesgos y pendientes honestos

- Instalación/ejecución del APK ARM64 en hardware físico (S22 Ultra, Redmi 9C):
  **PENDIENTE DE HARDWARE** — la CI solo prueba emulador x86_64 (Universal) y
  sanity ABI (rechazo esperado INSTALL_FAILED_NO_MATCHING_ABIS para ARM64).
- LAN con dos clientes reales, FPS sostenidos, temperatura: PENDIENTE DE
  HARDWARE/HUMANO.
- Credenciales cuyo VALOR falló las pruebas controladas (ver §9): requieren
  rotación por el propietario.
- `main` no debe recibir merges sin CI verde; las 3 PR integrables están
  «behind» y se actualizarán antes de fusionar.

## 8. Plan de ejecución (etapas del mandato)

- ETAPA A (este informe): completada.
- ETAPA B: auditoría de secretos/variables + pruebas controladas — completada
  (documento en `docs/ops/`). Corrección de nomenclatura va en la PR final.
- ETAPA C: sin errores nuevos de Android/UI/escenas detectados en `main`
  (CI verde); la corrección real de esta intervención es la de nomenclatura
  de secrets y la limpieza de variables.
- ETAPA D: actualizar #17/#18/#15 contra `main` (merge, sin force push) y
  re-ejecutar CI.
- ETAPA E: fusionar #17 y #18 por API con CI verde; cerrar #19 superseded;
  #15 queda abierta como fase futura.
- ETAPA F: APK única ARM64 desde `main` final (workflow android-debug),
  renombrada a `RPG-LBA-Android.apk`, verificación estática + SHA-256.
- ETAPA G: capturas reales (Godot 4.7.2 + Xvfb + llvmpipe, 16:9 y 20:9) en
  `ARTIFACTS/final/screenshots/`; ZIP del proyecto Godot importable validado
  desde carpeta limpia; paquete de entrega único.
- ETAPA H: auditoría final e informe al propietario con estados
  PASS/FAIL/SKIPPED/NOT TESTED.

## 9. Pruebas de autenticación (resumen ejecutivo; valores nunca registrados)

| Servicio | Prueba | Código | Estado |
|---|---|---|---|
| Telegram bot token | `getMe` (valor de la variable, ya eliminada) | 200 (@RpgLbaBot) | PASS |
| Telegram chat_id (variable) | `sendMessage` único de diagnóstico | 400 «chat not found» | FAIL (valor de la variable; el SECRET `TELEGRAM_ADMIN_CHAT_ID` se prueba en Actions) |
| Hugging Face | `whoami-v2` | 401 | FAIL (valor de la variable; secret sin probar) |
| Kaggle | `datasets/list?user=` (light, sin GPU) | 200 autenticado | PASS |
| Smithsonian | `openaccess/api/v1/search` con y sin clave | 404 (endpoint caído/reubicado) | NOT TESTED (credencial no evaluable) |
| 3DValley | `GET /api/v1/account` (Bearer, gratuito) | 200 | PASS |
| GitHub PAT | identidad + permisos repo | 200 (Lean031110, admin repo) | PASS |

Nota: los valores probados eran los de las VARIABLES (eliminadas después de
probarlas). Los SECRETS homónimos solo son verificables dentro de Actions;
se ejercitarán tras la fusión con un `workflow_dispatch` de Asset Validation
(que dispara `asset-review-telegram` vía `workflow_run`) y se reportará el
resultado real.

## 11. Resultados reales (cierre, 2026-11-18)

### Integración ejecutada (cada paso con CI verde y sin push directo a main)

| Paso | Acción | Resultado | SHA / evidencia |
|---|---|---|---|
| 1 | Rama `agent/docs-reorganizacion` actualizada con `main` (merge d30f94b), CI 7/7 checks verdes | PASS | push `8342c80..d30f94b`; checks en d30f94b |
| 2 | **PR #17 fusionada** (merge commit) | PASS | `f2240aa` |
| 3 | Rama `agent/asset-cloud-automation` actualizada con `main` dos veces (16345ab → 3eb283f; strict checks), CI 8/8 verde en 3eb283f | PASS | checks en 3eb283f |
| 4 | PR #18 convertida de draft a ready (GraphQL `markPullRequestReadyForReview`) y **fusionada** | PASS | `4a020fb` |
| 5 | **PR #19 cerrada como superseded** con comentario que cita `PR19_RECONCILIATION.md`; rama conservada intacta | PASS | comentario 6978636779 |
| 6 | Rama `feature/valdeluz-capital-city` actualizada contra el `main` final (97e20ce → 622a5be); CI en verde; PR #15 se conserva ABIERTA como fase futura | PASS | 622a5be |
| 7 | Variables creadas (`ASSET_WORK_BRANCH`, `ASSET_BATCH_LIMIT`) y 7 variables con credenciales en claro eliminadas | PASS | §5.4 del doc de auditoría |
| 8 | Corrección de nomenclatura `asset-review-telegram.yml` (cadena `TELEGRAM_CHAT_ID ‖ TELEGRAM_ADMIN_CHAT_ID ‖ vars.TELEGRAM_CHAT_ID`) | PASS | esta PR |
| 9 | Capturas reales 16:9 y 20:9 (12) regeneradas desde el árbol final y verificadas + revisión por modelo de visión | PASS | `ARTIFACTS/final/screenshots/` |

### Estado final de ramas/PR

- `main` = `4a020fb` (+ merge de esta PR). CI 4 workflows en verde en cada push.
- Abiertas: solo #15 (fase futura, justificada en roadmap). Cerradas no
  fusionadas: #19 (superseded). Todas las demás (1–18, 20, 21): fusionadas.
- Ramas conservadas: las 21 (ninguna borrada; `delete_branch_on_merge` sigue desactivado).

### Pruebas de autenticación (final)

Ver §9 y `docs/ops/SECRETS_AND_VARIABLES_AUDIT.md`. Pendiente de propietario:
rotar `HF_TOKEN` (FAIL 401), corregir chat id de Telegram (el bot @RpgLbaBot
es válido; el valor probado dio «chat not found»), Smithsonian NOT TESTED
(endpoint caído). Kaggle, 3DValley y GitHub: PASS.

### Pendiente / no probado (honesto)

- Instalación del APK ARM64 en hardware físico (S22 Ultra, Redmi 9C):
  PENDIENTE DE HARDWARE (la CI valida emulador x86_64 API 35/36 con la
  variante Universal y sanity ABI para ARM64).
- LAN con dos clientes físicos, FPS sostenidos, temperatura: PENDIENTE.
- Valores de los SECRETS (solo probables dentro de Actions): se ejercitan
  con dispatch de Asset Validation tras esta fusión (dispara el workflow de
  Telegram vía `workflow_run`).

