# Credenciales y APIs — guía de alta segura

**Regla:** crea las credenciales en cada servicio y guárdalas en GitHub Actions Secrets. No pegues valores aquí en el chat, no los pongas en el prompt de Z.ai y no edites un archivo `.env` que vaya a Git. El repositorio es público.

En GitHub: abre el repositorio → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

| Nombre exacto del secret | Dónde conseguirlo | Uso |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Telegram, abre `@BotFather`, ejecuta `/newbot`, completa nombre y username y copia el token | Enviar avisos |
| `TELEGRAM_CHAT_ID` | Escribe `/start` al bot; consulta `https://api.telegram.org/bot<TOKEN>/getUpdates` en privado, o usa un grupo controlado y añade el bot | Destino de avisos |
| `3DVALLEY_API_KEY` | https://3dvalley.com/account/api | Catálogo CC0 y ejecuciones de IA que el API indique explícitamente como cero créditos |
| `HF_TOKEN` | https://huggingface.co/settings/tokens | Opcional: solo Spaces privados/autenticados; para Spaces públicos no crearlo si no hace falta |
| `KAGGLE_USERNAME` | Usuario de tu cuenta Kaggle | Acceso a Kaggle API |
| `KAGGLE_KEY` | https://www.kaggle.com/settings → API → Create New Token | Acceso a Kaggle API |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase Console → Project settings → Service accounts | Opcional, solo integración servidor-side con Firestore. Restringir permisos y nunca subir el JSON de cuenta de servicio |
| `JANCTION_API_KEY` | Solo si JANCTION emite una clave con uso verificable sin coste | No usar en la primera versión |
| `N8N_ENCRYPTION_KEY` | Generada y controlada por el propietario al desplegar n8n self-hosted | Clave privada de la instancia; almacenar en gestor privado, no en GitHub si no es estrictamente necesario |
| `N8N_API_KEY` | Solo si la instancia n8n y su plan/version exponen la API y el conector lo confirma | No requerida para el pipeline cloud inicial |

## APIs que no requieren claves

- Poly Haven: https://api.polyhaven.com — API pública para catálogo y recursos CC0. Añadir un User-Agent identificable y conservar la atribución/crédito que soliciten sus términos de API.
- ambientCG v3: https://ambientCG.com/api/v3 — recursos CC0; documentar ID/version/hash de cada recurso.
- Blender: https://www.blender.org/ — no requiere cuenta ni API key.
- GitHub Actions: usa el token temporal `GITHUB_TOKEN` que GitHub entrega a cada workflow. No crear un PAT para la primera versión.

## GitHub Actions: variables frente a secretos

Secrets:
- tokens, API keys, chat IDs privados, credenciales JSON y valores privados.

Variables (Settings → Secrets and variables → Actions → Variables):
- `ASSET_BATCH_LIMIT`: cantidad máxima por lote, mantener 1–3 al principio.
- `ASSET_WORK_BRANCH`: rama de trabajo que recibirá la fábrica; nunca `main`.
- `ASSET_CRON_ENABLED`: solo cuando el workflow tenga un dispatcher seguro que envíe el trabajo a `ASSET_WORK_BRANCH`. No activar el cron antiguo antes de corregirlo.

El workflow debe rechazar proveedores con precio desconocido, >0 créditos, pago requerido, tarjeta requerida o términos no verificados. Para 3D Valley, consultar herramientas/cuenta y comprobar precio en vivo; enviar `max_credits=0`, `publish=false`, una clave de idempotencia estable y guardar el job ID antes de esperar.

## Crear el bot de Telegram sin exponer el token

1. Abre Telegram y busca el bot oficial `@BotFather`.
2. Envía `/newbot`, completa los dos nombres y copia el token.
3. Abre el bot que acabas de crear y envíale `/start`.
4. En un navegador privado, consulta `https://api.telegram.org/bot<TOKEN>/getUpdates`. Busca `message.chat.id`. Sustituye `<TOKEN>` localmente; nunca pegues la URL con el token en chat, issue o commit.
5. Guarda el token como `TELEGRAM_BOT_TOKEN` y el chat ID como `TELEGRAM_CHAT_ID` en GitHub Actions Secrets.
6. Ejecuta una prueba manual del workflow de Telegram y confirma que llega un aviso. No actives avisos masivos sin revisar el primer mensaje.

## Firebase: no activar billing para este proyecto

Firebase no es necesario para producir assets. El plan Spark permite usar Firestore para metadatos dentro de los límites publicados, pero Cloud Storage y Cloud Functions no forman parte del camino sin facturación actual. La primera versión se debe mantener con GitHub como catálogo central. No activar Blaze, tarjetas ni overage. Firebase puede añadirse más tarde solo como panel espejo, nunca como almacén canónico de modelos o texturas.

## Qué nunca se debe guardar en el repositorio

- `.env`, secretos, tokens o API keys.
- Claves privadas, service-account JSON, backups de credenciales n8n o credenciales descifradas.
- `.n8n`, SQLite, dump PostgreSQL, backups binarios o execution data.
- Model weights/datasets grandes sin una revisión de almacenamiento/licencia.


## Fuentes adicionales de recursos

| Variable | Cómo obtenerla | Para qué sirve |
|---|---|---|
| `SMITHSONIAN_API_KEY` | Solicitar clave gratuita en https://api.data.gov/signup/ | Consultar API de Smithsonian Open Access. Descargar solo objetos y medios que estén marcados CC0 en el registro individual. |
| `3DVALLEY_API_KEY` | https://3dvalley.com/account/api | Opcional: búsquedas autenticadas de la biblioteca CC0. No usar para generación por API bajo el presupuesto cero: las herramientas API consumen créditos. |

Meshy Free no ofrece API; no existe una clave que debamos colocar para automatizarlo. Su uso gratuito es manual desde https://www.meshy.ai/ y sus outputs exigen atribución CC BY 4.0. Tripo no está aprobado para producción hasta revisar la titularidad/licencia exacta de cada resultado. No poner claves de estos servicios dentro del prompt de Z.ai.

## Regla para agentes

Z.ai y los agentes de código solo deben crear referencias a nombres de secrets (por ejemplo `${{ secrets.TELEGRAM_BOT_TOKEN }}`), nunca pedir su valor en el chat, mostrarlo en logs ni guardarlo en un archivo. El propietario introduce los valores directamente en GitHub Settings > Secrets and variables > Actions.
