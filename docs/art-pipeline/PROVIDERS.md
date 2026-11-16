# Proveedores y recursos gratuitos

Última revisión documental: 2026-11-15. Precios, cuotas y licencias pueden cambiar; verificar la página y licencia exacta en cada descarga.

## Assets descargables

| Proveedor | Recurso/API | Coste | Licencia/precaución | Uso |
|---|---|---|---|---|
| Poly Haven | https://polyhaven.com · https://api.polyhaven.com · https://github.com/Poly-Haven/Public-API | API pública gratuita; sin key para endpoints públicos | Assets CC0. API viva exige User-Agent único y crédito Powered by Poly Haven | HDRI, PBR, modelos selectos |
| ambientCG | https://ambientcg.com · https://docs.ambientcg.com/api/v3/ | API GET pública; token solo para beneficios Patreon | CC0 según política; verificar paquete | Terreno, piedra, madera, metal |
| Kenney | https://kenney.nl/assets | Packs individuales gratuitos | CC0 según sus términos; revisar LICENSE; no asumir que cada bundle es gratis | Props, UI auxiliar, prototipos |
| KayKit | https://kaylousberg.com/game-assets | Packs gratuitos y de pago | Revisar licencia del pack y archivo incluido | Personajes, dungeons, props |
| Quaternius | https://quaternius.com/packs.html | Selección gratuita | Licencia QAL actual y páginas antiguas CC0 pueden diferir; revisar pack exacto y redistribución | Personajes, monstruos, armas, entornos |
| Smithsonian Open Access | https://www.si.edu/openaccess · https://api.si.edu/ | API requiere registro de key | Descargar solo objetos marcados CC0; algunos registros no ofrecen media | Referencias, objetos y props selectos |
| OpenGameArt | https://opengameart.org/ | Descargas gratuitas | Licencia por asset: CC0, CC-BY, GPL, etc.; leer licencia completa | Audio, texturas y modelos puntuales |
| Sketchfab | https://sketchfab.com/features/free-3d-models | Catálogo gratuito y mixto | Licencia por modelo; CC-BY exige atribución. Download API requiere OAuth y autenticación | Recursos puntuales |
| Poly Pizza | https://poly.pizza/ | Muchos modelos gratuitos | Licencia por modelo, no por sitio ni autor | Modelos low-poly puntuales |
| BlendKit (antes BlenderKit) | https://www.blendkit.com/plans/pricing/ | Plan Free limitado | Royalty Free permite uso comercial pero no reventa del modelo como modelo/paquete; distinguir de CC0 | Materiales y assets selectos |

## Generación y GPU cloud

| Servicio | Acceso gratis documentado | Límite/riesgo | Decisión |
|---|---|---|---|
| Hugging Face ZeroGPU | Spaces ZeroGPU existentes accesibles a cuentas Free | 5 minutos GPU/día para Free; cola compartida; uso propio alojado tiene requisitos | Pruebas breves, no producción continua |
| Kaggle Notebooks | GPU P100 gratuita si está disponible | Cuota semanal dinámica; documentación menciona hasta 30 h/semana o más según demanda, con colas/sesiones | Lotes con checkpoint |
| Google Colab Free | GPU variable | No garantiza GPU ni sesiones; desconexiones y límites dinámicos | Trabajo oportunista |
| GitHub Actions público | Runner estándar Linux 4 CPU/16 GB RAM gratis e ilimitado en repos públicos | Sin GPU dedicada; disco/RAM limitados; artifacts con cuota/retención | Blender headless, conversión, lint, QA, Godot import |
| SheepIt | Render distribuido comunitario gratuito | Render, no modelado; requiere contribuir recursos; API automatizable no confirmada | Opcional para renders |
| JANCTION Render MCP | Beta gratuita reportada con cuota pequeña | Experimental, límites cambian; no subir material sensible | Adaptador experimental apagado por defecto |
| ComfyUI + TRELLIS / TripoSR / Hunyuan3D | Modelos/código abiertos y Spaces comunitarios | Open source no significa cómputo gratis; VRAM alta, colas y licencias específicas | Z.ai prepara jobs; ejecutar solo con GPU gratuita disponible |

## GitHub Actions + Blender

Blender soporta modo background y scripts Python: blender --background --python script.py. Los runners estándar de GitHub son CPU, no una GPU generativa. Úsalos para importar/exportar GLB, modificadores, decimación, revisión de mallas, thumbnails, hashes, validación de Godot y reportes. No descargar pesos de varios GB en cada PR. Usar workflow_dispatch, caché y concurrency para evitar ejecuciones duplicadas.

## APIs/credenciales que se podrán necesitar

| Variable/credencial | Cómo obtenerla | Necesaria |
|---|---|---|
| GITHUB_TOKEN | Automática en Actions | Sí para acciones GitHub; permisos mínimos |
| HF_TOKEN | https://huggingface.co/settings/tokens | No para Spaces públicos; sí gated/privados |
| KAGGLE_USERNAME + KAGGLE_KEY | https://www.kaggle.com/settings → API → Create New Token | Solo si se automatizan notebooks/datasets autenticados |
| SMITHSONIAN_API_KEY | https://api.data.gov/signup/ | Sí para Smithsonian API |
| TELEGRAM_BOT_TOKEN | BotFather en Telegram | Sí para notificaciones |
| TELEGRAM_CHAT_ID | Iniciar conversación con el bot y obtenerlo por flujo seguro/getUpdates | Sí para destino privado |
| FIREBASE_SERVICE_ACCOUNT_JSON | Firebase Console → Project settings → Service accounts | Solo backend si se activa Firebase |
| FIREBASE_PROJECT_ID | Firebase Console → Project settings → General | Si Firebase se activa |
| N8N_ENCRYPTION_KEY | Generar aleatoriamente para la instancia | Obligatoria para conservar credenciales cifradas |
| JANCTION_API_KEY | Solo si beta actual emite clave | Opcional/experimental |

Poly Haven y ambientCG no necesitan API keys para sus endpoints públicos. No generar claves para servicios que no las requieren.

## Política de selección
1. Priorizar CC0; aceptar CC-BY solo si la atribución puede viajar con el juego.
2. No aprobar NC, ND, editorial-only, GPL, “personal use” o licencias inciertas sin revisión y autorización.
3. Guardar URL exacta del asset individual, no solo homepage.
4. Registrar fecha de revisión y copia/enlace de licencia.
5. La licencia del agregador no sustituye la de la fuente original.
