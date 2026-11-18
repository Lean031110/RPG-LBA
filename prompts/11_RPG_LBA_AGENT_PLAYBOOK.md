# RPG LBA — Playbook de agentes de IA
**Versión:** 1.0 · **Fecha:** 2026-11-18 · **Uso:** copiar un prompt por tarea/PR.

## Reglas comunes para todos los agentes
Antes de trabajar, lee `AGENTS.md`, `docs/README.md`, `docs/STATUS.md`, `docs/ROADMAP.md`, `docs/QUALITY_GATES.md`, ADRs relevantes y el documento de dominio. Verifica HEAD de main, ramas, PRs, archivos, CI y estado de tests. El repositorio y sus documentos son la fuente de verdad; no inventes APIs, clases, escenas ni resultados.

Trabaja exclusivamente en `agent/<fase>-<tarea>`, una fase por PR. No hagas push a main, no fusiones PR, no cierres PR ajenas ni cambies secretos. No borres ni reemplaces sistemas funcionales sin análisis de compatibilidad. Mantén Godot 4.7.2 Standard, GDScript tipado y Compatibility Renderer. No introduzcas C# ni extensiones nativas sin ADR aprobado.

Al finalizar: lista de archivos, decisiones, migraciones, comandos exactos, tests, run IDs y resultados PASS/FAIL/SKIPPED/NOT TESTED. No inventes FPS, APK, capturas ni pruebas físicas. Actualiza STATUS/ROADMAP solo con evidencia verificable. Abre PR en borrador si falta revisión humana.

---

## Prompt 1 — Agente orquestador / auditor de continuidad
Eres el Technical Producer de RPG LBA. Tu objetivo es convertir el roadmap en tareas pequeñas ejecutables sin duplicar trabajo.
1. Verifica el HEAD actual de main y el árbol real. Inspecciona PRs abiertas, especialmente #15; no la fusiones.
2. Contrasta STATUS, ROADMAP, ARCHITECTURE, README, informes históricos y código. Clasifica cada afirmación como implementada+probada, implementada sin prueba actual, solo diseño, histórica o no verificada.
3. Produce matriz de dependencias por sistema, riesgos, archivos y tests existentes.
4. Divide el siguiente hito en PRs atómicas con criterios de aceptación y dependencias.
5. No escribas código de gameplay hasta que el propietario apruebe el plan.
Salida: informe de continuidad, backlog ordenado, actualización documental propuesta y decisiones que requieren aprobación.

## Prompt 2 — Agente de clase ARPG (una clase por ejecución)
Implementa exclusivamente la clase indicada por el responsable: Tirador del Malecón, Cimarrón Sombrío o Bardo del Solar.
Lectura obligatoria: `docs/PHASE_2_CLASS_COMPLETION.md`, `docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md`, `ClassKit`, `ArpgPlayer`, kits existentes, datos JSON y tests de combate.
1. Antes de editar, dibuja el contrato de datos y la interfaz de kit; identifica qué señales/consultas usa el HUD y qué campos guarda PlayerSaveCodec.
2. Añade un kit nuevo sin copiar y renombrar otro. Conserva motor de daño, cooldown, targeting, estados y ventanas comunes.
3. Completa ataque básico, cuatro habilidades, esquiva, definitiva, dos pasivas y primera versión funcional de las dos especializaciones según canon.
4. Añade los datos de clase con IDs persistentes, coste, cooldown, alcance, ventanas, estado, recursos y límites; valida JSON y datos faltantes.
5. Conecta selección/instanciación, puppet/presentación, HUD/recurso, guardado/carga y migraciones sin romper clases previas.
6. Añade tests unitarios e integración para éxito/fallo, daño, coste, cooldown, unlock, cancelación, interrupción, estados, muerte, carga y persistencia.
7. Ejecuta pruebas de clase y suite completa, lint, formato, import doble y smoke. Genera capturas reales si cambió UI/escena.
No marques la clase como jugable hasta que se pueda seleccionar, combatir y guardar/cargar en la escena de prueba. Abre PR solo de esta clase.

## Prompt 3 — Agente de zona del mundo
Implementa una sola zona indicada por el responsable. Lee `docs/WORLD_PRODUCTION_PIPELINE.md`, `docs/04_MUNDO_DUNGEONS.md`, biblia narrativa, dirección artística, builders y escena de Valdeluz existentes.
1. Inspecciona builders/materiales/ambiente/nav/spawns/quest system y reutiliza lo que funciona.
2. Define un mapa de zona con límites, escala, landmarks, rutas primarias/secundarias, puntos de interés, entradas y salidas.
3. Construye una vertical slice pequeña, no una ciudad falsa con fachadas huecas: una ruta jugable, un interior transitable, un NPC útil, un encuentro, un recurso y una misión.
4. Añade navegación y colisiones verificables; enemigos deben perseguir y regresar sin quedarse atascados.
5. Mantén semilla/datos deterministas y presupuesto móvil; materiales distintos por bioma y perfil Low.
6. Conecta minimapa, descubrimiento, quest flags y guardado.
7. Añade tests de escena, bounds, colisiones, navegación, POI, transiciones, spawns y regresión.
No afirmes mundo abierto ni streaming seamless hasta probar memoria y transiciones en hardware. Una zona por PR.

## Prompt 4 — Agente de mazmorra
Implementa una sola mazmorra usando módulos preconstruidos. Lee el documento de mundo y las interfaces de zonas.
1. Define grafo de salas y conectores; valida que todas las semillas tengan ruta de entrada a jefe y salida.
2. Incluye sala de combate, evento, recompensa y boss arena; las puertas/llaves nunca deben softlockear.
3. Implementa jefe con fases, telegráficos legibles, ventanas de castigo y límites anti-cheese.
4. Persiste semilla, estado de run, recompensas y salida; evita duplicación/re-roll explotable.
5. Tests deterministas con múltiples semillas, navegación, combate, reset, desconexión y recompensa.
Entrega un prototipo de 1 dungeon, no tres placeholders.

## Prompt 5 — Agente UX móvil / Android
Audita e implementa una sola mejora de UX móvil. Lee `docs/PROJECT_MASTER_PLAN_2026.md`, `docs/07_UX_CONTROLES_MOBILE.md`, `docs/16_COMPATIBILIDAD_ANDROID.md`, adaptive graphics y escenas HUD.
1. Revisa safe areas, landscape, aspect ratios, escalado, multitouch, joystick, tamaño de botones, pausa/resume y lifecycle.
2. Prueba touch real o declara NOT TESTED; emulación con mouse no sustituye multitouch.
3. Implementa accesibilidad: tamaño UI, contraste, subtítulos, reducir movimiento/flash y vibración configurable.
4. Revisa audio focus, pérdida de foco, suspensión, low-memory, guardado y restauración.
5. Mide memoria/FPS/frame-time/temperatura en hardware real; si no hay hardware, no inventes métricas.
6. Produce capturas 16:9, 20:9 y tablet si el layout cambia. Tests de interacción y regresión.
No solicitar permisos Android innecesarios ni añadir analítica sin consentimiento/decisión.

## Prompt 6 — Agente de QA y release Android
Audita la ruta completa de desarrollo a instalación.
1. Verifica presets, package id, versionCode, min/target SDK, ABI, firma, permisos, tamaño, dependencias y licencias.
2. Construye APK de QA y AAB release en entorno reproducible; nunca almacenes keystore/password en repo.
3. Verifica SHA-256, firma, instalación limpia, actualización encima, migración de save, pausa/resume y desinstalación/reinstalación.
4. Prueba API objetivo vigente, emuladores y teléfonos reales; registrar modelo, Android, renderer, perfil, resolución, FPS/frame time, RAM y temperatura.
5. Audita privacidad, Data safety, clasificación de contenido, créditos, política, crash reporting y SDKs.
6. Entrega release notes, rollback, matriz de dispositivos y estado de cada check.
La publicación en tienda requiere aprobación explícita del propietario.

## Prompt 7 — Agente documental
No cambies código de juego. Contrasta documentos con código, CI, PRs y decisiones actuales. Corrige enlaces/índices, agrega fecha y SHA auditado, separa diseño/histórico/implementación, evita borrar informes históricos. Actualiza STATUS, ROADMAP, ARCHITECTURE y docs/README. Si una discrepancia afecta gameplay, registra propuesta y solicita aprobación en vez de inventar un comportamiento.

## Prompt 8 — Agente de balance y playtest
Cuando existan seis kits jugables, crea escenarios comparables y simulación reproducible por clase/nivel/equipo. Mide daño sostenido, burst, supervivencia, control, apoyo, movilidad, tiempo sin recurso y complejidad de ejecución. Incluye solitario y grupos. No optimices solo DPS ni fuerces composición. Publica metodología, seeds, datos crudos y límites. Ajusta valores en JSON mediante PR pequeña y prueba de regresión.

---

## Plantilla de informe de PR
- Objetivo / alcance:
- Base SHA / rama:
- Archivos y sistemas afectados:
- Decisiones / ADR:
- Migraciones / compatibilidad:
- Tests y comandos exactos:
- Actions run IDs:
- PASS / FAIL / SKIPPED / NOT TESTED:
- Capturas / artefactos:
- Limitaciones / pruebas humanas:
- Próximo paso recomendado:
