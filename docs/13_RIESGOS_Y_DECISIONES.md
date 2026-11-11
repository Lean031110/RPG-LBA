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

## Decisión pendiente del responsable

- Propietario/nombre exacto del repo GitHub.
- Si el repo será privado mientras se integran assets.
- Alojamiento futuro del servidor online.
- Identidad final del estudio/empresa que aparece en créditos.
- Licencia del código propio del juego (MIT/GPL/propietaria) antes de publicar. No asumir que el repo completo queda bajo MIT por la plantilla.
