# 13 — Riesgos, límites y decisiones registradas

## Riesgos

1. **Scope demasiado grande:** un MMO completo supera el alcance de una sola generación de IA. Mitigación: fases, vertical slice, entregas pequeñas.
2. **PC modesta:** la compilación y el trabajo pesado ocurren en Actions; Godot local se usa para importar/inspeccionar/jugar. La CPU Pentium no garantiza editor 3D fluido.
3. **Red móvil:** latencia, pérdida, CGNAT y disponibilidad afectan online. Mitigación: LAN primero; online solo con alojamiento y pruebas reales.
4. **Recursos mezclados:** packs low-poly no siempre comparten estilo. Mitigación: escena de comparación, paleta y atlas compartido.
5. **Licencias:** un repo MIT puede incorporar assets con licencias distintas. Mitigación: manifest por asset y revisión legal.
6. **Renderer Compatibility:** compatible con hardware OpenGL ES 3.0, pero no soporta todas las funciones avanzadas; la estética se diseña con esas limitaciones.
7. **Procedural generation:** un mapa aleatorio puede bloquear rutas o crear encuentros injustos. Mitigación: módulos fijos, grafo validado y seeds.
8. **Seguridad de economía:** duplicación/exploits. Mitigación: server authoritative, transacciones idempotentes y tests de manipulación.
9. **GitHub Actions:** minutos, cache, artifacts y runners tienen límites. Mitigación: workflow ligero en PR, builds pesadas manuales/tags.
10. **IA inventa resultados:** mitigación: pedir logs de ejecución y enlaces a Actions, y marcar NOT TESTED si no puede probar.

## ADR-001 — Motor y lenguaje

Godot 4.7.2 Standard + GDScript. Motivo: el usuario ya instaló Godot 4.7.2, GDScript evita .NET y mantiene el flujo ligero.

## ADR-002 — Renderer

Compatibility primero. Motivo: ampliar soporte a móviles low-end que tienen GLES 3.0. Dispositivo debe probarse. Perfil High no cambia renderer en runtime. Una edición Mobile separada solo tras prueba.

## ADR-003 — Multiplayer

Servidor dedicado autoritativo. Motivo: sincronización, persistencia, seguridad y multi-world. No P2P/player-host en producción.

## ADR-004 — Persistencia

SQLite para prototipo de un servidor; PostgreSQL para múltiples procesos/producción. No desplegar DB compleja antes de que exista necesidad.

## ADR-005 — Mundo

Zonas separadas con carga/transición, streaming interno por sectores si es necesario. No un mapa único infinito.

## ADR-006 — Repo base

Auditar `devmoreir4/godot-3d-multiplayer-template` release v2.0.0. Reutilizar solo tras confirmar build y licencias. Es un starter de multiplayer, no un ARPG. Tiene movimiento/cámara de primera/tercera persona, sesiones, inventario/equipo/chat, server headless; la animación de ataque de muestra no hace daño.

## ADR-007 — Pruebas

GdUnit4 para unit/integration tests de GDScript, además de scripts de import/smoke y test real Android. La versión master 7.0.0 declara compatibilidad con Godot 4.7; fijar release exacta y action version en el bootstrap.


## ADR-F2-INV — Sistema de invocaciones del Sepulturero (Fase 2)

Numeración con prefijo de fase: la reorganización documental abierta (PR #17)
ya reserva ADR-008..012 en su rama; este bloque evita colisiones al fusionar.

- **ADR-F2-INV-01 — Los ecos son combatientes, no adornos.** `ArpgEcho` hereda
  de `ArpgCombatant`: los enemigos lo golpean por el pipeline común y los
  estados le aplican igual. Motivo: canon de Fase 2 ("entidades funcionales del
  sistema de combate"). La hitbox del eco se monta INERTE (capa/máscara 0)
  porque su golpe es un duelo directo resuelto por el dueño — pero el contrato
  de la base (muerte → `hitbox.close()`) se cumple.
- **ADR-F2-INV-02 — Capa PLAYER para el cuerpo del eco.** Sus golpes enemigos
  usan máscara PLAYER; poner al eco en esa capa hace que lo ataquen sin tocar
  el motor. Los golpes del propio jugador (máscara ENEMY) nunca lo dañan, y
  los recogibles lo ignoran (exigen `add_potion`, API exclusiva del jugador).
- **ADR-F2-INV-03 — El daño del eco sale del dueño.** Toda ofensiva del eco
  (golpe, carga de la Procesión) se resuelve con `resolve_strike` del
  Sepulturero: escala con intelecto del jugador y respeta la regla canon de
  que las invocaciones no generan XP/botín por sí mismas (el crédito es del
  dueño). El eco nunca consulta la capa PLAYER al elegir objetivos: no puede
  dañar al dueño ni a otros ecos.
- **ADR-F2-INV-04 — Contención de amenazas tras bandera de datos.**
  `ArpgEnemy` reparte su atención entre el jugador (hogar) y los ecos vivos
  SOLO si `enemy_data.engage_summons` está activa. Sin ecos en escena el
  comportamiento es bit a bit el anterior (regla del motor común). Al perder
  al eco, el enemigo vuelve al hogar: nunca se queda sin meta.
- **ADR-F2-INV-05 — La onda de Último encargo es una zona del dueño.**
  Reutiliza `ArpgAreaEffect` (un tick: daño + slow). Una onda no es un eco: no
  engendra cadenas (regla anti-cadena del canon). Solo la expiración natural
  por duración la produce; morir en combate o la Vela no la provocan.
- **ADR-F2-INV-06 — Balance provisional en JSON, no en código.** El canon da
  nombres y efectos cualitativos pero ninguna cifra. Costes, cooldowns, vida
  de ecos, duraciones y fragmentos viven en `game/data/classes.json` (nota del
  propio archivo: "hipótesis de diseño sin validar"). El `fragment_gain` de
  Nombre prestado (25) se fijó neto-positivo frente al coste de la Marca (20);
  el resto de cifras sigue las magnitudes de Bruja/Machetero. Ajustar con
  telemetría, no a mano en los kits.
- **ADR-F2-INV-07 — La "revelación" de la Marca queda tendida, no activa.**
  El canon pide "debilita y revela": lo mecánico vigente es `vulnerable` (+30%
  daño entrante) + registro para la pasiva. La revelación completa (marcados
  visibles en sigilosos/detección) se activa cuando existan enemigos con
  sigilo (fases futuras); el estado y el registro ya existen.

## Decisión pendiente del responsable

- Propietario/nombre exacto del repo GitHub.
- Si el repo será privado mientras se integran assets.
- Alojamiento futuro del servidor online.
- Identidad final del estudio/empresa que aparece en créditos.
- Licencia del código propio del juego (MIT/GPL/propietaria) antes de publicar. No asumir que el repo completo queda bajo MIT por la plantilla.
