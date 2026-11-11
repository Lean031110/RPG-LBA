# 12 — Criterios de aceptación por fase

## Fase 0

- Repo propio inicializado y branch principal limpia.
- Base template v2.0.0 fijada por tag + commit SHA registrado.
- README/licencias/atribuciones revisados.
- Godot 4.7.2 headless importa la plantilla sin errores críticos nuevos.
- Servidor base y dos clientes probados o estado real documentado.
- CI ejecuta import y smoke; no hay secretos.

## Fase 1

- El personaje puede moverse en 8 direcciones, detenerse, chocar con obstáculos y permanecer dentro del mapa.
- Cámara sigue al personaje sin jitter y no atraviesa paredes principales.
- Joystick táctil funciona en Android; input teclado solo para dev.
- Un enemigo tiene telegráfico, ataque, HP, muerte y drop.
- El jugador completa la misión tutorial y recibe recompensa una sola vez.
- UI no se corta en resoluciones objetivo.
- APK debug abre en al menos un Android; Redmi 9C prueba separada obligatoria para declarar soporte.

## Fase 2

- Seis clases creadas, cada una con identidad funcional.
- Habilidades con costes/cooldowns/rangos y feedback.
- Tests de daño y cooldown pasan.
- Sin habilidades que solo reproduzcan animación sin efecto documentado.

## Fase 3

- Inventario/slots/stack/equipamiento persistentes.
- Compra/venta/crafting no genera duplicación.
- Datos migrables por versión.

## Fase 4

- 5 principales y 8 secundarias jugables.
- Quest no puede dar recompensa más de una vez.
- Todos los objetivos tienen feedback y tracking.

## Fase 5

- Ciudad + 5 regiones + 3 dungeons conectadas como contenido inicial.
- Seeds reproducibles.
- Bosses con mecánicas diferentes.
- Ruta completa siempre posible en generación procedural.

## Fase 6

- 2 clientes mínimos y 4 jugadores objetivo en LAN.
- Estado importante validado en servidor.
- Inventario, vida, daño y quest consistentes.
- Cliente malicioso de test no puede inventar daño o items.

## Fase 7

- Varias worlds aisladas por world_id.
- Party/guild/trade pasan tests de permisos/atomicidad.

## Fase 8

- Matriz Low/Medium/High funcional.
- Benchmark real Redmi 9C y otro dispositivo.
- Publicar mediciones sin ocultar caídas.

## Fase 9

- Checklist release, licencias, privacy, seguridad, migraciones, backups, build firmada y pruebas smoke físicas.
