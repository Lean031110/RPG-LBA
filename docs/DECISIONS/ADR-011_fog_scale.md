# ADR-011 — API `fog_scale` en EnvironmentController para vistas de revisión

**Fecha:** 2026-11-16 · **Estado:** Aceptada · **Evidencia:** commit
`25bc199` (rama capital, PR #15), suite 299/299 verde, capturas reales
con medición de color (cielo R201/G112/B74 a las 17:00).

## Contexto

La auditoría del 15/11/2026 detectó que la escena de revisión de la
capital asignaba `allow_dynamic_shadows`, propiedad inexistente en
`EnvironmentController`. Al corregirlo surgió el problema real de fondo:
las vistas cenitales de revisión de ciudad acumulan 70–110 m de
profundidad y la niebla calculada para la cámara en tercera persona del
juego (~8 m del personaje) lava la imagen entera (medido: brillo medio
190/255 con 16–33% de fog gris-azulada; veredicto de dirección de arte
"NECESITA_MEJORA" en dos iteraciones).

## Decisión

1. Se ELIMINA toda asignación a propiedades inexistentes (regla: solo API
   real).
2. `EnvironmentController` gana una API real y documentada:
   `@export_range(0.0, 1.0, 0.05) var fog_scale := 1.0`, aplicada como
   multiplicador del `fog_density` ya calculado en `_apply_visual_state`.
   - Default `1.0` = comportamiento BIT a bit idéntico al anterior (el
     cálculo base no cambia; 299/299 tests en verde lo verifican).
   - La escena de revisión de la capital la fija a `0.25`.
3. Las sombras del sol siguen decidiéndolas exclusivamente
   `GraphicsSettings.shadow_mode()` (perfiles LOW/MEDIUM/HIGH): la
   herramienta de revisión aplica `apply_profile("high")`, que es la API
   existente y no persiste en `user://settings.json`.
4. La hora de revisión usa el keyframe real más cálido del ciclo
   (17:00, sol naranja rasante) en lugar de inventar iluminación nueva.

## Alternativas descartadas

- Modificar `fog_density` desde fuera: se sobrescribe cada frame por
  `_apply_visual_state()` (no funciona).
- Desactivar la niebla en el controlador para todo el juego: cambiaría el
  look real del juego por una herramienta de revisión.
- Crear un Environment paralelo en el preview: duplicaría el sistema
  atmosférico (prohibido: arquitecturas paralelas).

## Consecuencias

- El controlador gana una palanca legítima reutilizable por futuras
  vistas de revisión (mazmorras, regiones).
- La deuda artística restante de la capital (contraste de sombras,
  exposición del atardecer, tiling de suelos) queda registrada en la
  PR #15 como trabajo de artpass futuro, no como defecto de la API.
