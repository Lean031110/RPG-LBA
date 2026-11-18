# STATUS — Situación real del proyecto
**Actualizado:** 2026-11-18 · **Base de auditoría:** `main` @ `e1d415b8a2fd1439736a4c899b309a76085fae29`.

> Este archivo describe el estado verificable del repositorio. Un diseño, un nombre en JSON, una escena preview o un APK generado no equivalen a una función de juego aceptada.

## Estado ejecutivo
| Campo | Estado |
|---|---|
| Rama principal | `main` @ `e1d415b` |
| Protección | Activa; seis checks requeridas |
| CI del HEAD auditado | Las seis checks requeridas PASS; APK/emuladores y capturas también reportan PASS en check-runs del SHA |
| Fase oficial más avanzada | Fase 2: 3/6 clases |
| Próximo objetivo | Completar Tirador, Cimarrón y Bardo, una clase por PR |
| Mundo | Slice de Valdeluz; capital procedural en PR #15 abierta/draft; resto mayormente diseño |
| Release | v0.2.0 documentada; no equivale a release candidate de tienda |
| Hardware físico | S22 Ultra y Redmi 9C: NOT TESTED según la documentación disponible |

## Fases oficiales
| Fase | Estado | Evidencia / límite |
|---|---|---|
| 0. Auditoría y bootstrap | COMPLETA | PR #1 fusionada; base Godot 4.7.2/GDScript/Compatibility |
| 1. Vertical slice | COMPLETA según historial integrado | Valdeluz slice, VS_P00, jugador, enemigo, NPC, XP/guardado y ambiente |
| 2. Combate ARPG y seis clases | **EN CURSO — 3/6** | Machetero, Bruja y Sepulturero tienen kits; Tirador, Cimarrón y Bardo aún no |
| 3. Inventario, equipo y economía | NO INICIADA como sistema ARPG | Inventario heredado no cuenta como inventario ARPG propio |
| 4. Misiones y narrativa | PARCIAL | QuestSystem/VS_P00; campaña completa pendiente |
| 5. Mundo y mazmorras | PARCIAL | Slice de Valdeluz; PR #15 es preview de capital; cinco regiones, dungeons y jefes requieren implementación y validación |
| 6. Multijugador autoritativo | PARCIAL | Lobby y smoke LAN; no hay servidor autoritativo completo |
| 7. Mundos, grupos y guilds | NO INICIADA | Diseño |
| 8. Calidad, rendimiento y audio | PARCIAL | Perfiles, CI y capturas; audio y mediciones en hardware físico pendientes |
| 9. Release candidate | NO INICIADA | Pipeline documentado y APK de debug; faltan gates de release pública/tienda |

## Sistemas implementados en el árbol de main
- Motor compartido de combate, daño, estados, cooldowns, hitboxes/LOS, targeting y ventanas de acción.
- Machetero, Bruja y Sepulturero: kits diferenciados; revisar tests por clase antes de extender.
- Tres especies de enemigos con IA diferenciada.
- Movimiento, cámara isométrica, joystick virtual, HUD, minimapa, menús y pausa.
- Ciclo día/noche, clima y materiales/entorno de Valdeluz.
- Guardado local y servicio de progresión.
- Lobby LAN ENet y smoke automatizado; no autoritativo.
- Perfiles gráficos LOW/MEDIUM/HIGH y adaptativo.
- Export Android ARM64 + Universal en CI y capturas 16:9/20:9.

## Estado de GitHub verificado
- HEAD de main: `e1d415b8a2fd1439736a4c899b309a76085fae29`, merge PR #24.
- PR #23 corrigió el caso `EVENT_PATH` vacío en workflow_run.
- PR #24 documentó la prueba real de Telegram: bot token válido, envío falla HTTP 400 por chat ID incorrecto. No registrar ni copiar secretos; requiere acción del propietario.
- PR #15 sigue ABIERTA y en BORRADOR, rama `feature/valdeluz-capital-city`, HEAD `622a5be`. No fusionada. La descripción declara interiores no transitables y validación humana/Android pendiente.
- Se consultaron los check-runs del SHA de main: las seis checks obligatorias aparecen con conclusión success. El workflow Android también muestra export/verificación e instalación en emulador success; los pasos de release por tag aparecen skipped/cancelled según ejecución.
- El registro GdUnit histórico más reciente en STATUS/QUALITY_GATES es 295/295; la ejecución del HEAD auditado reporta `gdunit-tests` success. No convertir el conteo histórico en un conteo nuevo si el XML de esa ejecución no se ha leído.

## Pendientes prioritarios
1. Fase 2: implementar Tirador, Cimarrón y Bardo con kit, datos, HUD, guardado, pruebas y balance.
2. Fase 3: inventario ARPG real, instancias estables, equipo, rarezas, loot, crafting y economía transaccional.
3. Fase 4: implementar prólogo P00–P03 y campaña persistente.
4. Fase 5: vertical slice urbana de Valdeluz, primera región exterior completa y una mazmorra piloto.
5. Fase 6: servidor autoritativo, validación de inputs y transacciones.
6. UX móvil: safe areas, multitouch físico, accesibilidad, lifecycle Android y audio.
7. Rendimiento: FPS sostenidos, frame time, memoria, temperatura y batería en dispositivos físicos.
8. Release: AAB, firma protegida, migraciones, privacidad, Data safety, legal, soporte y beta.

## Reglas de honestidad
- El informe de Fase 2 de movimiento es histórico y no cierra la Fase oficial 2 de seis clases.
- Los números de balance son hipótesis hasta simulación y playtest.
- La capital de PR #15 no es una ciudad completa ni forma parte de main.
- El lobby LAN no es multijugador autoritativo.
- Un APK instalado en emulador no demuestra compatibilidad física ni rendimiento sostenido.
- Los informes históricos se conservan; actualizar este STATUS y añadir adendas fechadas.

## Siguiente entrega recomendada
Una PR por clase pendiente, en orden Tirador → Cimarrón → Bardo; después una PR de integración/selección y otra de balance. Para el mundo: auditar #15 sin fusionarla, crear un slice urbano vertical y luego Brumaclara + Galerías de Ghar.
