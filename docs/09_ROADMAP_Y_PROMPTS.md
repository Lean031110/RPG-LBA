# 09 — Roadmap de producción y prompts por fase

## Regla de ejecución

El agente no debe desarrollar el juego completo en una sola operación. Cada fase termina con un PR pequeño, un informe y pruebas verdes. Cuando una fase falle, corregirla antes de avanzar.

## Fase 0 — Auditoría y base reproducible

- Clonar el repositorio base Godot 3D Multiplayer Template en tag `v2.0.0`.
- Revisar cada script, escena, licencia, workflow y asset.
- Ejecutar el proyecto original en Godot 4.7.2 y probar servidor con 2 clientes.
- Confirmar el estado real de inventario/equipamiento/chat/sesiones.
- Identificar sistemas que no son ARPG: cámara tercera persona, movimiento, ataque solo visual, arena de prueba.
- Crear fork/copia en repo `RPG-LBA` (nombre sugerido; comprobar disponibilidad).
- Conservar upstream remoto y tag/commit de origen.
- Añadir este kit, `AGENTS.md`, branch protection, CI básico.

**Salida:** repo importable y plantilla original validada, informe de activos/licencias y deuda técnica.

## Fase 1 — Vertical slice single player

- Cámara elevada/isométrica.
- Personaje de una clase.
- Movimiento con joystick y teclado de pruebas.
- Una escena de bosque pequeña.
- Un enemigo, ataque básico, HP, muerte y drop.
- HUD móvil, menú pausa y ajuste de calidad.
- Una misión corta tutorial.

**Salida:** APK de debug, gameplay de 5 minutos, pruebas de movimiento, combate, loot y scene startup.

## Fase 2 — Combate ARPG y seis clases

- Datos de clase, recurso, habilidades y cooldown.
- 6 clases con 1 básico, 4 habilidades, esquiva y definitiva inicial.
- Enemigos por arquetipo y élites.
- Telegráficos, VFX y audio.
- Balance inicial a nivel 1–10.

**Salida:** test de habilidad por clase, daño validado, cooldown/coste y UI legible.

## Fase 3 — Inventario, equipo y economía

- Slots, rareza, afijos, consumibles, materiales.
- Comerciantes, herrero, alquimista, almacén y desguace.
- Fabricación y upgrade acotado.
- Guardado local offline y servicio de inventario servidor.

**Salida:** transacciones idempotentes, no duplicar/dupear objetos, pruebas de save/load, compra/venta y equipar.

## Fase 4 — Misiones y narrativa

- Cinco principales y ocho secundarias.
- NPC, diálogos, objetivos, tracking y recompensas.
- Estado de quest persistente.
- Localización española y estructura inglés.

**Salida:** campaña inicial completada desde prólogo hasta cierre, misiones no repetibles indebidamente.

## Fase 5 — Mundo y dungeons

- Ciudad Valdeluz y regiones iniciales.
- Streaming por zonas.
- 3 dungeon graphs deterministas y seed de servidor.
- 5 jefes con fases y mecánicas.
- Eventos y puntos de interés.

**Salida:** entradas/salidas no bloqueadas, semilla reproduce dungeon, navmesh valida conectividad y boss puede completarse.

## Fase 6 — Multijugador LAN autoritativo

- Cliente/servidor y selección de modo.
- Prueba 2 clientes y party 4.
- Servidor headless.
- Sincronización de posición/acción/vida/animación.
- Validación de combate, drops, inventario y misiones.
- Reconexión y salida segura.

**Salida:** dos a cuatro clientes terminan misión y jefe sin divergencia de estado.

## Fase 7 — Mundos, grupos y guild

- World selector/realm ID.
- Instance manager.
- Party, guild inicial, chat protegido y trade bilateral.
- SQLite single realm; migración PostgreSQL cuando corresponda.

**Salida:** personajes aislados por world_id, no duplicación de trades, guild permissions tests.

## Fase 8 — Calidad, rendimiento y audio

- Perfil bajo/medio/alto.
- LOD, visibilidad, densidad de enemigos, resolución interna y efectos.
- Música/sfx por región/clase.
- Pruebas de memoria, calentamiento y batería.
- Pruebas físicas Redmi 9C y un dispositivo más potente.

**Salida:** matriz de dispositivos con mediciones reales y límites conocidos.

## Fase 9 — Release candidate

- Seguridad y revisión de RPC.
- Migraciones y backups.
- Prueba de carga con clientes simulados.
- Export Android firmado fuera de PR, release notes, credits y legal.
- Bug bash y pruebas manuales.

**Salida:** release candidate, no producción pública hasta configurar alojamiento y soporte.

## Prompts

### Prompt general para cada fase

“Lee `AGENTS.md` y todos los documentos de diseño referenciados. Trabaja solo en la fase autorizada. Primero inspecciona el estado actual y presenta un plan pequeño. No sobrescribas ni borres sistemas. Implementa pruebas antes o junto al código. Ejecuta el pipeline local y GitHub Actions. Abre PR. Informa PASS/FAIL/SKIPPED/NOT TESTED con evidencia real. No avances a la siguiente fase.”

### Secuencia recomendada

- `prompts/00_AUDITORIA_Y_BOOTSTRAP.md`
- `prompts/01_VERTICAL_SLICE.md`
- `prompts/02_COMBATE_Y_CLASES.md`
- `prompts/03_INVENTARIO_ECONOMIA.md`
- `prompts/04_MISIONES.md`
- `prompts/05_MUNDO_DUNGEONS.md`
- `prompts/06_MULTIJUGADOR_LAN.md`
- `prompts/07_REALMS_GUILDS.md`
- `prompts/08_OPTIMIZACION_RELEASE.md`
