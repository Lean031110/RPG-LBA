# Auditoría de Secretos y Variables — GitHub Actions (2026-11-18)

Mandato §5. Alcance: inventario REAL de Repository Secrets y Variables de
`Lean031110/RPG-LBA`, cruce contra todas las referencias de workflows y
scripts en TODAS las ramas, correcciones compatibles y pruebas controladas.

**Reglas aplicadas:** nunca se consultaron valores de secrets (la API no los
expone y no se intentó); los valores de VARIABLES se usaron solo en memoria
para las pruebas de autenticación y no se registran en este documento ni en
ningún artefacto. Cuenta personal (sin secrets de organización) y
**0 environments** (verificado por API): todo es nivel repositorio.

---

## 1. Inventario de Secrets (nombres, fechas — API `actions/secrets`)

| Secret | Creado | Actualizado | Referenciado por |
|---|---|---|---|
| `ASSET_WORK_BRANCH` | 2026-11-18 | 2026-11-18 | Ningún workflow (documentado como variable en `SECRETS_SETUP.md`) |
| `HF_TOKEN` | 2026-11-18 | 2026-11-18 | Ningún workflow (futuro proveedor HF; guía `SECRETS_SETUP.md`) |
| `KAGGLE_KEY` | 2026-11-17 | 2026-11-17 | `asset-gpu-triposr.yml` (rama #18) |
| `KAGGLE_USERNAME` | 2026-11-17 | 2026-11-17 | `asset-gpu-triposr.yml` (rama #18) |
| `SMITHSONIAN_API_KEY` | 2026-11-18 | 2026-11-18 | Ningún workflow (proveedor futuro) |
| `TELEGRAM_ADMIN_CHAT_ID` | 2026-11-17 | 2026-11-17 | Ninguno (nombre distinto al que usa el workflow) |
| `TELEGRAM_BOT_TOKEN` | 2026-11-17 | 2026-11-17 | `asset-review-telegram.yml` (rama #18) |
| `_3DVALLEY_API_KEY` | 2026-11-18 | 2026-11-18 | Ningún workflow (guía `SECRETS_SETUP.md`; el guion bajo existe porque GitHub no admite nombres que empiezan por dígito) |

## 2. Variables ANTES de la intervención (API `actions/variables`)

Siete de las ocho entradas eran **credenciales reales en texto claro**
(iguales o parecidas a secrets homónimos): `HF_TOKEN`, `KAGGLE_KEY`,
`KAGGLE_USERNAME`, `SMITHSONIAN_API_KEY`, `TELEGRAM_BOT_TOKEN`,
`TELEGRAM_CHAT_ID`, `_3DVALLEY_API_KEY`.

**Riesgo (CRÍTICO):** las Variables de Actions se muestran en claro en
Settings → Secrets and variables → Actions y pueden quedar expuestas en logs
de workflows si algún paso las imprime. Estaban en un repositorio público
(aunque solo visibles para quien tenga acceso de administración, cualquier
ejecución futura que las referenciara mal podía filtrarlas). **Ningún
workflow en ninguna rama las referenciaba** (verificado con `git grep` sobre
las 21 ramas). Acción tomada: **eliminadas**; solo permanecen los secrets.
Valores probados ANTES de eliminarlas (ver §5).

## 3. Variables DESPUÉS de la intervención (estado final)

| Variable | Valor | Justificación (inequívoca de la configuración real) |
|---|---|---|
| `ASSET_WORK_BRANCH` | `agent/asset-cloud-automation` | Fallback por defecto de `asset-factory-scheduler.yml` (línea TARGET_REF). Rama de trabajo de la fábrica; nunca `main`. |
| `ASSET_BATCH_LIMIT` | `3` | Default de `inputs.limit` del scheduler; guía `SECRETS_SETUP.md` recomienda 1–3. |

`FACTORY_CRON_ENABLED` **se deja ausente a propósito**: activaría la
producción cron automática de assets, desactivada hasta la prueba e2e
aprobada por el propietario (decisión documentada en PR #18). No se crea
ninguna variable sensible.

## 4. Matriz de requisitos (mandato §5.2)

| Nombre | Tipo | Uso (workflow/script) | Obligatorio | Ubicación | Existencia | Prueba de validación | Estado |
|---|---|---|---|---|---|---|---|
| `GITHUB_TOKEN` | Secret automático | Todos los workflows (`gh`, release, publication) | Sí | Automático de GitHub | Presente (automático) | Identidad/permisos verificados en cada corrida | PASS |
| `TELEGRAM_BOT_TOKEN` | Secret | `asset-review-telegram.yml` | Sí (avisos) | Repository | Presente | `getMe` HTTP 200 con el valor de la variable homónima (antes de borrarla); el secret se ejercita tras la fusión vía `workflow_run` | PASS (valor de variable); secret: ver §6 |
| `TELEGRAM_CHAT_ID` | Secret | `asset-review-telegram.yml` | Sí (avisos) | Repository | **Ausente** con ese nombre; existe `TELEGRAM_ADMIN_CHAT_ID` (secret) | `sendMessage` HTTP 400 «chat not found» con el valor de la VARIABLE `TELEGRAM_CHAT_ID` (fallido); secret `TELEGRAM_ADMIN_CHAT_ID` por probar en Actions | **CORREGIDO**: fallback `TELEGRAM_CHAT_ID ‖ TELEGRAM_ADMIN_CHAT_ID ‖ vars.TELEGRAM_CHAT_ID`; resultado pendiente de la corrida post-fusión |
| `KAGGLE_USERNAME` | Secret | `asset-gpu-triposr.yml`, `kaggle_triposr_dispatch.py` | Sí (carril GPU) | Repository | Presente | `datasets/list?user=` HTTP 200 autenticado (sin GPU) | PASS (valor de variable); secret por ejercitar |
| `KAGGLE_KEY` | Secret | `asset-gpu-triposr.yml`, `kaggle_triposr_dispatch.py` | Sí (carril GPU) | Repository | Presente | ídem (autenticación básica 200) | PASS (valor de variable); secret por ejercitar |
| `HF_TOKEN` | Secret | Ninguno aún (proveedor futuro) | No | Repository | Presente | `whoami-v2` HTTP **401** con el valor de la variable homónima | **FAIL** el valor probado; el secret debe rotarse/verificar el propietario si se quiere usar |
| `SMITHSONIAN_API_KEY` | Secret | Ninguno aún (proveedor futuro) | No | Repository | Presente | Endpoint documentado `api.si.edu/openaccess/api/v1/search` devuelve 404 con y sin clave | NOT TESTED (API reubicada/deprecada; credencial no evaluable) |
| `_3DVALLEY_API_KEY` | Secret | Guía `SECRETS_SETUP.md` (n8n/futuro) | No | Repository | Presente | `GET /api/v1/account` HTTP 200 (Bearer) | PASS (valor de variable); secret por ejercitar |
| `ASSET_WORK_BRANCH` | Variable (docs) / Secret (existe como secret) | Scheduler (#18) | Condicional | Repository | Presente como SECRET; creada como VARIABLE con valor inequívoco | El scheduler usa `inputs.target_ref ‖ vars.ASSET_WORK_BRANCH ‖ default` | PASS (configurada) |
| `FACTORY_CRON_ENABLED` | Variable | `asset-factory.yml` (main) | Condicional (cron) | Repository | **Ausente por diseño** | El job schedule se auto-saltea («skipped») | SKIPPED (intencional; requiere aprobación e2e del propietario) |
| `ASSET_BATCH_LIMIT` | Variable | Guía `SECRETS_SETUP.md` | No | Repository | Creada (=3) | N/A (documental) | PASS |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Secret | Doc `SECRETS_SETUP.md` (opcional) | No | Repository | **Ausente** | N/A | SKIPPED (integración opcional no activada) |
| `N8N_API_KEY` / `N8N_ENCRYPTION_KEY` | Secret | Doc n8n (self-hosted del propietario) | No | Repository | **Ausente** | N/A | SKIPPED (n8n no conectado; plantillas saneadas listas) |
| `JANCTION_API_KEY` | Secret | Doc proveedor | No | Repository | **Ausente** | N/A | SKIPPED (sin uso verificado) |

## 5. Pruebas de autenticación controladas (mandato §5.5)

Ejecutadas 2026-11-18 desde la auditoría, contra los valores de las VARIABLES
(los únicos accesibles fuera de Actions; eliminadas después de probarlas).
Nunca se imprimieron valores ni cuerpos de respuesta con datos privados.

| Servicio | Verificación | Código HTTP | Resultado |
|---|---|---|---|
| Telegram | `getMe` | 200 (bot `@RpgLbaBot`) | PASS (token válido) |
| Telegram | `sendMessage` (1 único mensaje diagnóstico) | 400 «chat not found» | FAIL del valor probado: el bot no conoce ese chat (el propietario no envió `/start` al bot, o el chat id es incorrecto) |
| Kaggle | `datasets/list?user=` (llamada ligera, 0 GPU) | 200 autenticado | PASS |
| Hugging Face | `whoami-v2` | 401 | FAIL (token inválido/expirado) |
| Smithsonian | `openaccess/api/v1/search` | 404 con y sin clave | NOT TESTED (endpoint caído; no evaluable) |
| 3DValley | `GET /api/v1/account` (gratuito, Bearer) | 200 | PASS |
| GitHub (PAT auditoría) | identidad + permisos + repo | 200 | PASS (Lean031110, admin del repo) |

**Criterio del mandato aplicado:** «secreto presente no equivale a
autenticación PASS». Dos credenciales presentes fallaron su prueba real.

## 6. Corrección de nomenclatura aplicada (mandato §5.4B)

`asset-review-telegram.yml` (entra vía PR #18) pasa de:

```yaml
TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID }}
```

a la cadena compatible (respeta el nombre documentado en `SECRETS_SETUP.md`,
el secret real existente y la variable si el propietario la volviera a crear):

```yaml
TELEGRAM_CHAT_ID: ${{ secrets.TELEGRAM_CHAT_ID || secrets.TELEGRAM_ADMIN_CHAT_ID || vars.TELEGRAM_CHAT_ID }}
```

No se duplican secrets; no se inventan valores; el workflow sigue
terminando `SKIPPED` limpio si nada existe.

**Resultado de la prueba end-to-end dentro de Actions (2026-11-18, tras la
PR #22):** la cadena de fallback FUNCIONA — `TELEGRAM_BOT_TOKEN` y el chat id
del secret se inyectaron correctamente (enmascarados `***` en el log). Dos
hallazgos reales:

1. Bug preexistente corregido en la PR #23: con disparo `workflow_run`,
   `github.event_path` llega VACÍO y el script hacía `open('')` → crash
   (run 44306896445). Tras el fix (campos vía `${{ github.event.workflow_run.* }}`
   + lectura protegida), la regresión del run 44308521370 llegó hasta la llamada
   real a la API de Telegram: **el workflow ya funciona; el fallo restante es
   de CREDENCIAL, no de código**.
2. El valor del secret `TELEGRAM_ADMIN_CHAT_ID` da **HTTP 400 Bad Request**
   de la API de Telegram al enviar (mismo error que el valor de la variable
   probada localmente: «chat not found»). El token del bot es VÁLIDO (getMe
   200, @RpgLbaBot). Acción del propietario: abrir chat con @RpgLbaBot, enviar
   `/start`, obtener el chat id real y actualizar el secret. Hasta entonces,
   cada corrida de Asset Validation/Factory/Publication terminará con este
   workflow en rojo y el error exacto visible (comportamiento deseado).

## 7. Acciones requeridas del propietario (no automatizables)

1. **Rotar/regenerar `HF_TOKEN`** (el valor probado dio 401) si se desea usar
   Hugging Face; guardar el nuevo solo como Secret.
2. **Arreglar el destino de Telegram**: abrir chat con `@RpgLbaBot`, enviar
   `/start`, obtener el chat id real (getUpdates) y actualizar el secret
   `TELEGRAM_ADMIN_CHAT_ID` (o crear `TELEGRAM_CHAT_ID`). Hasta entonces los
   avisos de Telegram no llegarán (el workflow lo reporta explícitamente).
3. **Smithsonian**: si se retoma, identificar el endpoint vigente antes de
   dar por válida la clave.
4. **Revocar el PAT de esta auditoría** al terminar (buenas prácticas del
   mandato §3).
