# PROMPT 10 — IMPLEMENTACIÓN DE CLASES, PROGRESIÓN Y CAMPAÑA EXPANSIBLE

Eres el agente principal de desarrollo de RPG LBA — Las Cenizas de Lythara.

## Repositorio y autoridad
Repositorio: https://github.com/Lean031110/RPG-LBA
La documentación revisada está en la rama docs/classes-progression-open-campaign. Verifica si está integrada antes de usarla. No supongas que la rama es main. Si no está integrada, solicita su integración o trabaja desde esa rama solo con autorización explícita.
No uses tokens pegados en chat. Configura la credencial en el gestor seguro del entorno.

## Lectura obligatoria
Lee completos AGENTS.md, README.md, docs/01_GDD.md, docs/AGENT_BRIEFING_VISION_CUBANA.md, docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md, docs/narrativa/01_MISIONES_Y_CADENAS.md, docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md, docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md, docs/09_ROADMAP_Y_PROMPTS.md, docs/13_RIESGOS_Y_DECISIONES.md y prompts/09_ART_PASS_CUBAN_DARK_FANTASY.md.

## Canon creativo
Fantasía oscura gótico-caribeña en Cuba ficticia de 1953. Campaña inicial El Eco de Valdeluz. Se puede perseguir claridad y atmósfera de ARPG oscuro moderno, pero está prohibido copiar Diablo u otra IP: nombres, personajes, monstruos, iconos, UI, mapas, sonidos, animaciones o diseños.

## Clases vigentes: exactamente seis
1. Machetero de la Sierra — guardián/tanque de machete, defensa e interrupción.
2. Bruja de la Manigua — hechicera de raíces, viento, zonas y control.
3. Sepulturero de Guanabacoa — invocador original de ecos y recuerdos; arquetipo de invocador oscuro con identidad cubana propia. No llamarlo Nigromante ni copiar su diseño.
4. Tirador del Malecón — rifle/pistola, precisión y trampas.
5. Cimarrón Sombrío — duelista furtivo, movilidad y ejecución.
6. Bardo del Solar — apoyo rítmico, control y mejora de grupo.

No reintroducir Santero de la Luz. No cambiar nombres, recursos ni kits sin actualizar especificación y obtener aprobación.

## Trabajo 1 — Implementación de clases
- Auditar combate y Player actual.
- Separar definición de clase, estadísticas, habilidades, VFX y UI.
- Externalizar datos en Resources/JSON/CSV validados, según arquitectura existente.
- Cada clase tendrá ataque básico, esquiva, pasivas, cuatro habilidades, definitiva y dos especializaciones.
- Recursos diferenciados: Vigor, Esencia, Ceniza, Concentración y Compás.
- Añadir animaciones, telegráficos y sonidos originales; la animación nunca será fuente de verdad del daño.
- Todas las clases deben poder jugar en solitario y aportar valor en grupo.

## Trabajo 2 — Balance y experiencia
Usa la tabla y curva de docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md.
- Nivel objetivo del primer arco: 1–30, extensible.
- Cinco puntos de atributo por nivel.
- XP por misiones, enemigos, exploración, eventos y jefes.
- Limitar XP repetible; evitar granjas, reconexión abusiva, XP de invocaciones propias y doble concesión.
- Reparto en grupo por participación válida sin penalizar sanación/apoyo.
- Servicio único de cálculo de daño, mitigación, crítico, control y XP.
- Simular DPS, supervivencia, control, movilidad y apoyo con builds equivalentes.
- Documentar escenario, nivel, equipo, duración y semilla de cada benchmark.
- Ajustar recompensas de misiones al ritmo medido; no balancear mirando solo la tabla.

## Trabajo 3 — Misiones y mundo abierto a expansión
- Mantener IDs estables, prerequisitos, flags, recompensas y migraciones.
- No usar texto visible como ID.
- Mantener P00–P27 como primer arco; P26 es victoria parcial, P27 epílogo abierto.
- El Rey de la Ceniza escapa fragmentado; no queda muerto ni destruido definitivamente.
- No cerrar el destino de Maela, Varela ni los aliados.
- Añadir soporte para misiones de NPC, cadenas secundarias, encargos, facciones, regiones y capítulos futuros.
- Diario con Historia, Secundarias, NPC/Encargos, Facciones e Historias por descubrir.
- NPCs con estado, reputación, horario/rutina, diálogos condicionales y banderas.
- Nuevas misiones deben añadirse mediante datos sin reescribir el gestor central.

## Trabajo 4 — Identidad visual y UX
- Mantener el logo RPG LBA sin cambios.
- Usar el nuevo logo LBA Games en README y créditos.
- Mantener dirección artística gótico-caribeña y Art Pass del prompt 09.
- Clases reconocibles por silueta, arma, animación, paleta secundaria y VFX, no solo color.
- UI de selección de clase con rol, dificultad de dominio, fortalezas, debilidades y recurso.
- No saturar pantalla móvil; permitir configurar botones.

## Trabajo 5 — Pruebas obligatorias
- XP y curva monotónica hasta nivel 30 y preparada para ampliación.
- Recompensas de primera victoria, repetición, grupo, exploración y jefes.
- No duplicar XP por reintentos, invocaciones ni reconexión.
- Estadísticas y crecimiento por clase.
- Costes, cooldowns, cancelaciones, alcance, línea de visión y estados.
- Invocaciones con límite de entidades y sin drops/XP propios.
- Encuentros comparativos de clase en solitario y grupo.
- Guardado/carga y migración de personajes.
- Misiones ramificadas, NPC, prerequisitos y flags.
- Regresión de vertical slice y Art Pass.
- Importación Godot doble, lint, GdUnit4, smoke, evidencia visual y CI.

## Orden de implementación
1. Auditar rama, base, sistemas, pruebas y estado GitHub.
2. Construir prototipo de combate de las seis clases con datos mínimos.
3. Implementar XP y crecimiento de personaje.
4. Ejecutar simulaciones, ajustar coeficientes y documentar.
5. Conectar clases con inventario, HUD y selección.
6. Integrar NPC/quests y asegurar arquitectura ampliable.
7. Ejecutar pruebas, corregir regresiones y documentar.
8. Abrir PR; no hacer merge automático.

## Reglas de entrega
- Una rama agent/<fase>-<tarea> por PR.
- No push directo a main.
- No borrar sistemas ni tests existentes.
- No declarar PASS sin ejecución real.
- APK, Android físico y FPS = NOT TESTED si no se probaron.
- No avanzar automáticamente a la fase siguiente.
- Informe con archivos, decisiones, balance, pruebas, logs, capturas y limitaciones.
