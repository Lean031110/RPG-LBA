# Instrucciones de agente — Nueva visión cubana de RPG LBA

**Estado:** propuesta creativa aprobada por el responsable para convertirse en dirección del proyecto.  
**Rama de documentación:** `docs/vision-cubana-dark-fantasy`  
**Proyecto:** Godot 4.7.2 Standard, GDScript, renderer Compatibility.  
**No introducir secretos ni tokens en archivos, prompts, logs, commits o capturas.**

## Lectura obligatoria

Antes de modificar gameplay, leer:
1. `AGENTS.md`
2. `README.md`
3. `docs/01_GDD.md`
4. `docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md`
5. `docs/narrativa/01_MISIONES_Y_CADENAS.md`
6. `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`
7. `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`
8. `docs/13_RIESGOS_Y_DECISIONES.md`
9. Informe de entrega de Fase 1 y `prompts/01_VERTICAL_SLICE.md`.

Los documentos de narrativa y arte pasan a ser la fuente de verdad creativa. Si chocan con una regla técnica, conservar la regla técnica y proponer un ADR; no improvisar.

## Estado de partida

La Fase 1 local reporta 48/48 tests, 10 capturas, 11 criterios declarados PASS; no hay prueba real de APK, dispositivo Android ni FPS. La rama de Fase 1 no se debe considerar integrada en `main` hasta verificar el PR y su CI. El README debe describir la rama real y no fingir que el contenido está en main.

## Objetivo inmediato: Art Pass + UX Pass

El responsable no aprueba la presentación actual. No continuar añadiendo contenido sobre el bosque y la interfaz actuales sin resolver la dirección artística.

### Entregables visuales

- Nuevo bosque de Valdeluz con césped texturizado, tierra roja, caminos con huellas, piedra caliza, raíces, vegetación tropical variada y materiales distinguibles.
- Cielo/horizonte visible.
- Ciclo de día y noche continuo, con amanecer, día, atardecer y noche.
- Clima básico: despejado, nublado, lluvia y niebla; tormenta después.
- Iluminación y niebla adaptadas a perfiles Low/Medium/High.
- HUD y menús rediseñados con jerarquía de ARPG oscuro, legibles en móvil.
- Capturas comparativas y prueba en 16:9 y 20:9.
- Mantener el renderer Compatibility y Godot 4.7.2.
- No copiar assets, UI, tipografías, personajes o efectos de Diablo III. La referencia es la claridad y atmósfera, no la propiedad intelectual.

### Criterios de aceptación

- En capturas se distingue visualmente césped, tierra, roca, madera y metal.
- Se ve cielo real y horizonte, no fondo vacío.
- El mismo lugar se reconoce en cuatro franjas horarias, con luz y ambiente coherentes.
- El personaje, enemigos y telegráficos son legibles.
- El HUD no tapa la acción y funciona con safe areas y relación 20:9.
- Los perfiles Low conservan lectura y atmósfera sin efectos caros.
- No se declara compatibilidad/fps Android hasta probar hardware real.

## Orden de trabajo

1. Auditar rama, commits, árbol, CI y PR real; no asumir que el branch local ya está en GitHub.
2. Comparar el estado de `main` con la rama de Fase 1 y evitar perder cambios.
3. Integrar la documentación creativa por PR separado si aún no está integrada.
4. Crear rama `agent/art-pass-cuban-dark-fantasy` desde el commit aprobado.
5. Entregar un plan de 3–5 tareas pequeñas y estimar riesgos.
6. Producir escena de benchmark con 4 materiales y cielo antes de rehacer toda la zona.
7. Implementar ciclo día/noche y capturar 4 horarios.
8. Rediseñar HUD y menú.
9. Rehacer el bosque de Valdeluz con assets licenciados.
10. Ejecutar import×2, lint, GdUnit, smoke, visual evidence y CI.
11. Abrir PR; no hacer push directo a main.
12. Esperar revisión humana de capturas antes de ampliar el contenido.

## Después del Art Pass

La producción narrativa y mecánica se divide así:
- **Siguiente:** estabilizar Art Pass/UX y luego implementar clases en datos y habilidades testeables.
- **Después:** sistema de misiones/diálogos y prólogo P00–P03.
- **Después:** primera región jugable y cadenas secundarias.
- **Después:** inventario/economía, mazmorras, jefes, multiplayer LAN y optimización.
- El online público queda fuera hasta tener servidor autoritativo desplegado, autenticación, seguridad y pruebas de carga.

## Reglas de seguridad GitHub

- El token que el responsable entregue al agente se introduce únicamente en el gestor seguro/secret del entorno autorizado.
- No pedir que lo pegue en el chat ni imprimirlo en consola.
- No incluir PAT en URL, archivo, variable de workflow, screenshot, commit o artefacto.
- Si el token ya fue publicado en un chat o log, revocarlo y crear uno nuevo con mínimo alcance.
- Verificar permisos mínimos: contents write y pull requests write para el repositorio; no pedir scopes globales innecesarios.
- No borrar ramas ni forzar push.

## Definition of Done

Un PR de Art Pass solo se considera completo con:
- Capturas antes/después y cuatro horas del día.
- Lista de assets y licencias.
- Pruebas automatizadas ejecutadas y enlazadas.
- Logs sin errores críticos.
- Comparación de resolución y relación de aspecto.
- Estado Android físico como NOT TESTED si no hubo dispositivo.
- Aprobación visual del responsable.
