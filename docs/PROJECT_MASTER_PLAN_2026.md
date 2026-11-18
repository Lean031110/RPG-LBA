# Plan maestro de producción — RPG LBA
**Revisión:** 2026-11-18 · **Base auditada:** `main` @ `e1d415b8a2fd1439736a4c899b309a76085fae29`
**Estado:** guía operativa; no sustituye al GDD ni certifica funcionalidades.

## 1. Propósito y reglas de lectura
Este documento ordena la producción del juego, la documentación, los agentes y los criterios de aceptación. La fuente de verdad se divide por dominio:
- Visión y alcance: `docs/01_GDD.md`.
- Canon narrativo: `docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md` y `docs/narrativa/01_MISIONES_Y_CADENAS.md`.
- Clases y números de diseño: `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`.
- Mundo macro: `docs/04_MUNDO_DUNGEONS.md`.
- Dirección visual y UX: `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`.
- Arquitectura existente: `docs/ARCHITECTURE.md` + código real.
- Estado de ejecución: `docs/STATUS.md`, ROADMAP y Actions; no los informes históricos.
- Reglas de agentes: `AGENTS.md`, `docs/QUALITY_GATES.md` y ADRs.

Si dos documentos se contradicen, no elegir silenciosamente. Abrir una nota de discrepancia, identificar propietario del dato y proponer actualización/ADR.

## 2. Auditoría de continuidad (18-11-2026)
### Hechos confirmados
- Repositorio público `Lean031110/RPG-LBA`; rama principal protegida.
- HEAD de `main` consultado: `e1d415b8a2fd1439736a4c899b309a76085fae29` (merge PR #24). La protección exige seis checks: import+smoke, multiplayer smoke, auditoría de licencias, GdUnit, lint/formato y Godot headless.
- La PR #15 sigue abierta y en borrador. Añade una preview procedural de la capital Valdeluz y su biblia visual; declara explícitamente interiores no transitables y pruebas humanas/Android pendientes. No está integrada en `main`.
- `docs/STATUS.md` indicaba `main @ 4a020fb`, lo cual ya no coincide con HEAD. También afirmaba PR #17/#18 como últimas fusiones, antes de PR #23/#24. Este dato requiere corrección.
- La documentación de fase 2 oficial significa **seis clases ARPG**, no el prototipo de movimiento descrito por el informe histórico `FASE_02_INFORME_DE_IMPLEMENTACION.md`. ADR-008 y ROADMAP ya explican la diferencia.
- `game/data/classes.json` declara seis IDs, pero solo hay kits reales para Machetero, Bruja y Sepulturero. Tirador, Cimarrón y Bardo no tienen aún habilidades en sus registros ni kits implementados. Por tanto Fase 2 = 3/6, no terminada.
- Hay 140 scripts bajo `scripts/arpg/`, 96 archivos bajo `tests/` (incluidos UID/arneses), y 10 escenas bajo `scenes/arpg/` en el árbol inspeccionado. Esos conteos describen el árbol, no calidad ni cobertura.
- El stack ARPG usa `scripts/arpg/*`; el stack `scripts/inventory`, `scripts/ui`, `scripts/multiplayer` es herencia de la plantilla y no debe confundirse con inventario ARPG ni multijugador autoritativo.
- El informe de secretos de PR #24 concluye: token del bot Telegram válido, pero envío falla HTTP 400 por chat ID incorrecto; la integración end-to-end es FAIL hasta que el propietario corrija el secret. No copiar secretos al repositorio.

### Registros históricos que no deben presentarse como estado actual
`RECONCILIACION_INTEGRAL.md`, `RECONCILIACION_CONTINUIDAD_2026.md`, informes de Fase 2/5 y matriz Android contienen evidencias valiosas, pero tienen fechas, SHAs y contexto anteriores. Conservarlos como histórico; añadir adendas fechadas cuando cambie el estado. No reescribir retrospectivamente resultados pasados.

## 3. Organización recomendada de producción
| Departamento | Responsabilidad | Entregables |
|---|---|---|
| Dirección / Product Owner | alcance, prioridades, aprobaciones, decisiones | GDD, roadmap, ADR, aceptación de PR |
| Diseño de juego | combate, clases, progresión, economía, misiones | especificaciones, tablas de balance, casos de uso |
| Ingeniería gameplay | entidades, habilidades, IA, guardado, servicios | GDScript, datos validados, tests |
| Mundo / Level Design | mapa macro, zonas, navegación, POI, mazmorras | escenas, módulos, mapas de navegación, pruebas |
| Arte técnico | materiales, props, personajes, VFX, optimización | assets licenciados, manifest, LOD, presupuesto |
| UX móvil | HUD, controles, safe areas, accesibilidad, onboarding | escenas UI, pruebas táctiles, capturas |
| Online / backend | autoridad, sesiones, identidad, persistencia remota | servidor, protocolo, seguridad, carga |
| QA / release | import, pruebas, dispositivos, firma, tienda | CI, matriz de dispositivos, builds, checklist |
| Documentación | índices, estado, decisiones, runbooks y prompts | docs coherentes y trazables |

Una persona/agente puede cubrir más de un rol, pero cada PR tiene un único objetivo verificable y un responsable de integración.

## 4. Orden de dependencias propuesto
1. **Estabilización de base:** reconciliar docs y verificar el estado real de CI en HEAD.
2. **Fase 2:** terminar las tres clases pendientes una por PR, luego balance comparativo de las seis.
3. **Fase 3:** inventario ARPG, equipo, loot, crafting, comercio y economía con IDs persistentes.
4. **Fase 4:** prólogo P00–P03 y luego campaña por lotes de misiones.
5. **Fase 5:** pipeline de zonas; vertical slice completa de Valdeluz antes de abrir regiones; después primera región exterior y mazmorra.
6. **Fase 6:** servidor autoritativo y validación de economía/combate; el lobby LAN actual no satisface esta fase.
7. **Fase 8 en paralelo controlado:** UX móvil, audio, profiling y pruebas físicas; no esperar al final para descubrir problemas de batería/temperatura.
8. **Fase 7/9:** mundos/guilds y release pública solo cuando sus dependencias estén cerradas.

No desarrollar las seis regiones, tres dungeons, seis clases y online a la vez. La unidad de entrega es un vertical slice pequeño, completo y medible.

## 5. Definición de "juego Android listo"
Un APK que instala no equivale a un juego móvil terminado. El producto necesita:

### Experiencia y controles
- Orientación elegida y bloqueada o soportada de forma intencional; para el ARPG actual, landscape como objetivo primario.
- HUD adaptable a relaciones 16:9, 18:9, 19.5:9, 20:9, tablet y ventanas recortadas.
- Safe areas/insets para notch, cámara, barras del sistema y navegación gestual.
- Joystick multi-touch, botones grandes, separación entre acciones, prevención de toques fantasma, vibración configurable y reasignación básica.
- Accesibilidad: escalado de UI, contraste, subtítulos, tamaño de texto, opción de reducir flashes/cámara, alternativas a color como única señal.
- Tutorial jugable, pausa, reanudación y explicación de controles; no depender de teclado/ratón.

### Ciclo de vida y persistencia
- Manejar pausa/resume, cambio de app, llamada, pérdida de foco, rotación accidental, cierre forzado y falta de memoria.
- Guardado atómico/versionado, recuperación tras interrupción, copias de seguridad locales y migraciones de esquema.
- Configuración persistente: audio, gráficos, controles, idioma, accesibilidad y privacidad.
- Confirmar salida y proteger acciones destructivas; nunca perder progreso por una suspensión del sistema.

### Rendimiento y térmicas
- Perfiles Low/Medium/High medibles; resolución dinámica opcional y límite FPS seleccionable.
- Presupuestos de CPU/GPU, draw calls, memoria, texturas, partículas, luces, sombras y entidades activas.
- LOD/culling/occlusion, pooling, cargas asíncronas y límites por zona.
- Medir FPS sostenidos, frame-time, RAM, almacenamiento, batería y temperatura en teléfonos reales; controlar thermal throttling.
- Probar arranque en frío, sesiones largas, batería baja y dispositivos con poca RAM. No prometer cifras sin medición.

### Audio y contenido
- Mezcla de música, ambiente, UI, combate y voz; controles independientes, mute y audio focus.
- Compresión/streaming de audio, descargas y almacenamiento bajo límites.
- Música y voces originales o con licencia documentada; subtítulos para diálogos y señales importantes.
- Localización externa a código; al menos español completo y arquitectura preparada para más idiomas.

### Red, privacidad y seguridad
- Definir explícitamente qué funciona offline, LAN y online. El juego single-player debe explicar claramente qué funciones requieren conexión.
- Recuperación ante desconexión, reintentos con backoff, colas idempotentes y protección de progreso.
- No guardar credenciales de backend en cliente; autoridad del servidor para moneda, inventario, drops y progreso online.
- Permisos Android mínimos, política de privacidad, retención de datos, consentimiento para analítica y borrado/exportación cuando aplique.
- No solicitar permisos de contactos, ubicación o micrófono si no existe una función aprobada que los necesite.

### Distribución y mantenimiento
- Identidad de paquete, versionado semántico, versionCode creciente, firma de release protegida y custodia externa del keystore.
- AAB para Google Play, APK de QA/sideload, símbolos y mapping archivados, checksums y notas de versión.
- Compatibilidad con API objetivo vigente al publicar; pruebas de instalación, actualización encima, migración, desinstalación/reinstalación y rollback de contenido.
- Política de soporte, canal de reportes, crash logs saneados, métricas sin PII y proceso de hotfix.
- Cumplir políticas vigentes de Google Play: privacidad, Data safety, contenido, permisos, SDKs, clasificación por edades y pruebas previas a producción.

## 6. Lo que falta hoy para ser un producto móvil completo
Según el árbol y la documentación revisados, los gaps prioritarios son:
1. Completar 3 clases y balancear seis (Fase 2).
2. Inventario/equipo/economía ARPG real (Fase 3); el inventario heredado no es sustituto.
3. Campaña implementada más allá de VS_P00 (Fase 4).
4. Zonas conectadas con navegación, interiores, puntos de interés, streaming y contenido real; la PR #15 es una preview de capital, no una ciudad completa (Fase 5).
5. Servidor autoritativo; el lobby LAN actual es un prototipo de sesión (Fase 6).
6. UX pass táctil completo, safe areas, pinch/gestos si se aprueban, accesibilidad y ciclo de vida Android.
7. Audio original y pruebas físicas sostenidas, incluyendo gama baja (S22 Ultra y Redmi 9C como dispositivos objetivo históricos; actualizar la matriz si cambian).
8. Guardado/migraciones auditados para todos los sistemas y recovery ante interrupción.
9. Seguridad, privacidad, localización, crash reporting, legal y release pipeline de producción.
10. QA manual y beta cerrada con telemetría/feedback consentidos.

## 7. Indicadores de producción
No usar porcentajes subjetivos de avance. Medir por entregables aceptados:
- clase: kit + datos + presentación + tests + balance;
- zona: escena importable + nav + colisiones + spawns + POIs + misión + rendimiento;
- dungeon: grafo conectado + semilla + run reproducible + jefe + recompensas + persistencia;
- release: build firmada + instalación/actualización + pruebas de dispositivos + revisión legal/tienda.

Cada elemento debe tener estado `NOT STARTED / IN PROGRESS / PASS / FAIL / NOT TESTED`, evidencia y fecha.

## 8. Decisiones que requieren aprobación humana
No decidir por agente: monetización, gacha/loot boxes, anuncios, PVP, cross-play, servidores públicos, compras, cuentas obligatorias, permisos sensibles, telemetría no esencial, cambios de motor/renderer, y publicar en tiendas. Mantener el MVP sin monetización hasta que exista una decisión explícita.
