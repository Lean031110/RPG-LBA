# Fase 4B — Informe del Art Pass de Valdeluz

**Rama:** `agent/fase4b-artpass-valdeluz` · **PR:** #10 (apilado sobre PR #9, Fase 4A).
Contiene además, por la fusión de la línea: el sistema ambiental de la Fase 1B
(día/noche, clima, faroles) y todas las correcciones de la Fase 4A.

---

## A. Petición del propietario (literal, resumida)

En una rama separada, iniciar el Art Pass profesional de la zona jugable de
Valdeluz con la identidad aprobada: fantasía oscura caribeña, Cuba ficticia de
1953, arquitectura colonial envejecida, tierra roja, piedra caliza y vegetación
tropical; manigua, ceibas, palmas, ruinas y faroles; atmósfera misteriosa y
cinematográfica. Materiales PBR; texturas de tierra/piedra/madera/hierro y
vegetación; shaders de viento, humedad, agua y desgaste; cielo y atmósfera
día/noche; iluminación y sombras optimizadas; modelos y animaciones mejoradas
del Machetero; enemigos mejorados visualmente; VFX de combate; HUD, inventario
y menús profesionales. Mantener el Compatibility Renderer. Assets de
ambientCG, Poly Haven, Kenney o Quaternius con licencia verificada y
manifiesto.

## B. Qué se hizo

1. **`ArpgArtKit`** (`scripts/arpg/art/art_kit.gd`) + tres shaders originales
   (`assets/art/shaders/`), todos Compatibility Renderer seguros (desplazamiento
   de vértices y mezclas en fragment; sin GI dinámica ni volumétricos):
   - `wind_sway.gdshader`: balanceo por altura con fase derivada de la posición
     mundial (una instancia del material sirve para toda la manigua).
   - `wet_surface.gdshader`: humedad por fresnel (albedo oscurecido, roughness
     que cae en ángulos rasantes, filo suave).
   - `worn_iron.gdshader`: óxido procedimental por value-noise que devora el
     metal (metallic/roughness reactivos).
2. **Aplicación en la paleta de Valdeluz** (`TerrainMaterialLibrary`):
   `puddle_wet` (charcas), `wind_tuft/wind_frond/wind_canopy` (hierba alta,
   pencas de palma, copas de ceiba) y `worn_iron` (ruedas de la carreta y poste
   del farol de la entrada).
3. **Machetero mejorado** (solo nodos visuales; la lógica de movimiento, hitbox
   y daño no se toca): mangas arremangadas, cara legible desde la cámara
   isométrica (ojos + bigote), cinta del sombrero, talega al hombro, vaina del
   machete en la cadera, suelas; rebote vertical del ciclo de pasos que vuelve
   a cero en reposo.
4. **Sombra de Portal mejorada** (FSM intacta): capa de filo frío con emisión
   tenue, tres jirones al viento (shader), bruma de suelo translúcida y ascua
   de reposo en los ojos (el pulso carmesí del windup la pisa).
5. **VFX de combate** enganchados a la ventana de golpe ya existente:
   `ArpgArtKit.slash_trail` (estela del tajo en `_open_hitbox_window`),
   `hit_spark` (chispas al impactar, color distinto en crítico) y `dust_burst`
   (polvo rojo al esquivar). CPUParticles3D de un solo uso con
   autodestrucción doble (finished + temporizador).
6. **HUD/menús**: rastreador de misiones con acento lateral dorado, toast con
   entrada animada (ascenso + fundido), radios unificados a 8 px, pie del menú
   actualizado. El HUD móvil semitransparente estilo DI/MLBB y el minimapa ya
   venían de la Fase 3; esta fase los pule sin rehacerlos.
7. **Cielo y atmósfera día/noche**: entregado por la fusión de la Fase 1B
   (`EnvironmentController`: 7 keyframes solares, niebla, lluvia, faroles que
   se encienden de noche). Las sombras por perfil y su alcance llegaron con la
   Fase 4A.

## C. Assets de terceros: intentos y decisión (AGENTS §5)

| Fuente | Resultado del intento | Detalle |
|---|---|---|
| ambientCG | **Inaccesible** | Conexión no establecida desde el entorno (000) |
| Poly Haven | **CDN caído** | API responde; `dl.polyhaven.org` devuelve 521 |
| Kenney | **Sin enlace estático** | La página no expone el `.zip` sin JavaScript/POST en este entorno |
| Quaternius | **SPA sin enlaces** | La web no expone descargas directas al HTML |

Decisión: **contenido 100 % original y procedural** (geometría + shaders +
paleta propios), que ya era la política del repositorio («cero riesgo de
licencia»). No se incorporó ningún archivo externo, así que no hay entradas
nuevas en `assets/manifest.csv` que registrar; los intentos quedan
documentados aquí y en el cuerpo del PR. Si en otro entorno las descargas
funcionan, se aplicará el proceso normal: verificación de licencia por archivo
y fila en el manifiesto.

## D. Pruebas (comandos y resultados)

Local (Godot 4.7.2, OpenJDK 21):

| # | Prueba | Comando | Resultado |
|---|---|---|---|
| 1 | Suite GdUnit4 completa | `GODOT_BIN=… ./addons/gdUnit4/runtest.sh --headless "--audio-driver Dummy" --continue --add res://tests` | **200/200 PASS** (incl. `test_art_kit.gd` nuevo: materiales, paleta y VFX con autodestrucción) |
| 2 | Import + smoke | `GODOT_BIN=… bash scripts/ci/validate_project.sh .` | PASS |
| 3 | Layout del menú/panel | `godot --headless --path . -s scripts/local/measure_menu_layout.gd` | Nueva partida (640,423); Jugar centro+(-152,+44.5) — coordenadas que usa la CI |

## E. Evidencia de CI (identificadores reales)

Corrida final en verde: **43499113001** (android-debug, todos los trabajos).
En los artefactos `RPG-LBA-Android-emulator-api35/36-x86_64-evidence` queda
`playable_capture=valdeluz`: la escena jugable capturada es la Valdeluz real
con el Art Pass aplicado, en el emulador Android, a 1920x1080. Copias
comprometidas en el repo como evidencia:
`screenshots/arpg/fase4_menu_principal_emulador.png` y
`screenshots/arpg/fase4_valdeluz_artpass_emulador.png`. Telemetría PERF en
cada evidencia (fps/escala/memoria del proceso en emulador).

Iteraciones de esta fase (más el historial completo en el informe de la Fase
4A): el flujo de capturas arrastraba tres bugs heredados que se corrigieron
aquí (diálogo inmersivo, taps con doble escala, menú/panel a size=(0,0)).

## F. Pendiente / NOT TESTED

- **Revisión visual humana**: las capturas están publicadas en el PR para la
  revisión del propietario (AGENTS §10: no declarar aceptación visual sin
  revisión humana). No se declara aceptada.
- **Dispositivo físico**: igual que la Fase 4A (protocolo docs/16 §E).
- Variantes de textura por perfil (512/1024 frente a 1K/2K): pendiente de un
  Art Pass con assets externos viables; hoy el objetivo se aproxima con
  escala de render + distancia de vista (documentado en docs/16 §B).

## G. Archivos importantes

`scripts/arpg/art/art_kit.gd`, `assets/art/shaders/*.gdshader`,
`scripts/arpg/environment/terrain_material_library.gd` (paleta ampliada),
`scripts/arpg/level/valdeluz_builder.gd` (aplicación de materiales),
`scripts/arpg/player/arpg_player.gd` y `scripts/arpg/enemies/shadow_of_portal.gd`
(visuales), `scripts/arpg/ui/arpg_hud.gd` y `arpg_main_menu.gd` (pulido),
`tests/unit/test_art_kit.gd`, `screenshots/arpg/fase4_*.png`.

## H. Recomendación para la siguiente fase

1. Revisión humana de las capturas del PR; iterar composición/iluminación
   según el feedback.
2. Reintentar los assets externos (ambientCG/Poly Haven/Kenney/Quaternius)
   desde un entorno con acceso; seguir AGENTS §5 (licencia por archivo,
   manifiesto).
3. Ejecutar el protocolo físico de docs/16 §E en el Redmi 9C y el S22 Ultra.

## I. Instrucciones para el siguiente agente

- El Compatibility Renderer es innegociable: sin GI dinámica, volumétricos ni
  reflejos costosos. Los shaders de `ArpgArtKit` son el patrón a seguir.
- La lógica de juego (FSM, hitbox, daño, balance) no se toca desde el Art
  Pass: los VFX se cuelgan de la ventana de golpe ya existente.
- Ninguna aceptación visual sin revisión humana de capturas reales.
