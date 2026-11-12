# 09 — Roadmap de producción y prompts por fase

## Puerta creativa nueva — antes de ampliar el juego

La vertical slice funcional no obtuvo aprobación visual final. Antes de desarrollar más regiones, enemigos o contenido, ejecutar el **Art Pass + UX Pass** definido en `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md` y autorizado por `docs/AGENT_BRIEFING_VISION_CUBANA.md`.

Orden obligatorio inmediato:
1. Verificar estado real de main, rama Fase 1, commits, árbol, PR y CI; no asumir que una entrega local ya está en GitHub.
2. Integrar la documentación creativa aprobada mediante PR independiente.
3. Crear rama `agent/art-pass-cuban-dark-fantasy` desde el commit aprobado.
4. Construir benchmark de césped, tierra roja, piedra, vegetación y cielo.
5. Implementar ciclo día/noche y clima básico con cuatro capturas horarias.
6. Rediseñar HUD/menús para 16:9 y 20:9.
7. Rehacer bosque de Valdeluz, medir y capturar antes/después.
8. Obtener revisión visual humana antes de pasar a contenido adicional.

## Regla de ejecución

El agente no debe desarrollar el juego completo en una sola operación. Cada fase termina con un PR, un informe y pruebas verdes. Cuando una fase falle, corregirla antes de avanzar.

## Fase 0 — Auditoría y base reproducible

- Auditar la plantilla, código, escenas, licencias, workflows y assets.
- Probar servidor y clientes; conservar trazabilidad y CI.

**Salida:** repo importable, informe de activos/licencias y deuda técnica.

## Fase 1 — Vertical slice single player (reportada como entrega local)

- Cámara isométrica, personaje, bosque, enemigo, combate, HUD, misión tutorial y menús.
- El informe de entrega reporta 48/48 tests y 10 capturas. Push/PR/CI deben verificarse antes de marcar la fase integrada.
- APK, dispositivo físico y FPS deben conservar estado NOT TESTED hasta prueba real.

## Fase 1B — Art Pass + UX Pass (prioridad inmediata)

- Terreno con materiales distinguibles: césped, tierra roja, piedra, madera y metal.
- Cielo/horizonte, sol/luna, amanecer/día/atardecer/noche.
- Clima básico: despejado, nublado, lluvia y niebla.
- HUD/menús con jerarquía ARPG oscura, legibles y adaptables.
- Capturas 16:9 y 20:9; pruebas de perfil Low.

**Salida:** aprobación visual humana antes de contenido amplio.

## Fase 2 — Combate ARPG y seis clases

- Implementar estadísticas desde `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`.
- Ataque básico, cuatro habilidades, esquiva, definitiva y pasivas por clase.
- Enemigos por arquetipo y élites; telegráficos, VFX y audio.
- Balance inicial niveles 1–10, tests de coste, cooldown, alcance y daño.

## Fase 3 — Inventario, equipo y economía

- Slots, rareza, afijos, consumibles, materiales.
- Comerciantes, herrero, médico/alquimista, almacén y fabricación.
- Guardado local y servicio futuro de inventario servidor.

## Fase 4 — Misiones y narrativa

- Implementar prólogo P00–P03 y cadena principal en orden.
- Diálogos, objetivos, tracking, decisiones y persistencia.
- Añadir cadenas secundarias en lotes, con IDs estables y localización.

## Fase 5 — Mundo y dungeons

- Valdeluz y regiones iniciales; streaming por sectores.
- Mazmorras deterministas, jefes con fases y eventos.

## Fase 6 — Multijugador LAN autoritativo

- Cliente/servidor, party, sincronización y servidor headless.
- Validar combate, drops, inventario y misiones; reconexión.

## Fase 7 — Mundos, grupos y guild

- World selector, instancias, party, guild y trade seguro.

## Fase 8 — Calidad, rendimiento y audio

- Perfiles Low/Medium/High, LOD, visibilidad, densidad, audio original.
- Medición real de memoria, temperatura, batería y FPS en hardware objetivo.

## Fase 9 — Release candidate

- Seguridad RPC, migraciones, backups, pruebas de carga y export Android firmado.
- Release notes, créditos, legal, bug bash y pruebas manuales.

## Prompts

### Prompt general

“Lee `AGENTS.md` y los documentos de diseño. Trabaja solo en la fase autorizada. Inspecciona el estado actual antes de editar. No sobrescribas ni borres sistemas funcionales. Añade pruebas y evidencia. Ejecuta el pipeline local y GitHub Actions. Abre PR. Informa PASS/FAIL/SKIPPED/NOT TESTED con comandos y logs reales. No avances a la siguiente fase.”

### Secuencia original de prompts

- `prompts/00_AUDITORIA_Y_BOOTSTRAP.md`
- `prompts/01_VERTICAL_SLICE.md`
- `prompts/02_COMBATE_Y_CLASES.md`
- `prompts/03_INVENTARIO_ECONOMIA.md`
- `prompts/04_MISIONES.md`
- `prompts/05_MUNDO_DUNGEONS.md`
- `prompts/06_MULTIJUGADOR_LAN.md`
- `prompts/07_REALMS_GUILDS.md`
- `prompts/08_OPTIMIZACION_RELEASE.md`

Los prompts existentes deben adaptarse a la visión cubana y a la puerta Art Pass sin cambiar silenciosamente su alcance.
