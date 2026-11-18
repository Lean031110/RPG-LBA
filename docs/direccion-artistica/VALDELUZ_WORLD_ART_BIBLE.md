# Valdeluz — World Art Bible y especificación de producción

**Estado:** primera entrega estructural procedural; pendiente de revisión visual humana.
**Rama:** `feature/valdeluz-capital-city`
**Motor:** Godot 4.7.2 Standard · GDScript tipado · Compatibility Renderer.
**Objetivo de calidad:** estilo A, fantasía estilizada premium; perfil BALANCED con escalado Low/Medium/High.
**Canon:** gótico caribeño ficticio de 1953, según `03_DIRECCION_ARTISTICA_Y_UX.md`.

## 1. Objetivo y límites

Construir la primera capital jugable de la campaña como espacio legible, coherente y ampliable. Esta entrega añade un mapa de revisión 3D procedural independiente; no reemplaza `valdeluz_slice.tscn`, no altera la misión VS_P00 y no afirma que interiores, NPC, navegación o economía estén implementados.

La escena se encuentra en `scenes/arpg/valdeluz/valdeluz_capital_preview.tscn`. Su generador determinista es `scripts/arpg/level/valdeluz_capital_builder.gd`.

## 2. Plano lógico

Huella aproximada: 108 × 88 metros, con una plaza de 23 × 23 metros y ejes viales principales de 7 metros.

| Sector | Contenido previsto/representado |
|---|---|
| Plaza Mayor | Fuente central, bancos, pavimento de caliza y faroles |
| Barrio del Sol | Viviendas coloniales de estuco y teja |
| Barrio del Sur | Viviendas, patios y conexiones de calle |
| Casa de Cabildo | Hito administrativo con torre |
| Mercado del Puerto | Dos puestos y edificio comercial |
| Santuario de las Campanas | Hito espiritual con torre |
| Red vial | Ejes norte-sur/este-oeste, calles de conexión y aceras |
| Perímetro | Muros bajos, portales visuales y arbolado tropical |

Los nombres y edificios son diseño ficticio del juego; no representan edificios históricos concretos.

## 3. Lenguaje visual — estilo A

- Siluetas estilizadas y redondeadas; proporciones arquitectónicas legibles desde cámara isométrica.
- Volúmenes grandes y limpios, con detalles secundarios repetidos con moderación.
- Paleta unificada: carbón, azul petróleo, verde manigua, tierra roja, caliza, ámbar, carmesí y oro viejo.
- Fachadas con variación controlada: crema, ocre, rosa envejecido y verde azulado; evitar saturación alta.
- Tejados de teja oscura, cornisas de caliza, carpintería de madera y hierro forjado.
- Luz cálida local en faroles y luz regional del sistema `EnvironmentController`.
- Vegetación tropical en grupos y bordes; mantener despejados los ejes de lectura y la plaza.

## 4. Materiales y texturas

La escena utiliza materiales compartidos de `VisualKit.noise_material` y `VisualKit.flat_material`, además de la paleta ambiental regional. El ruido procedural genera variación tonal sin descargar texturas externas ni repetir planos de color totalmente lisos.

| Superficie | Respuesta material | Uso |
|---|---|---|
| Estuco | Ruido fino, rugosidad alta | Fachadas |
| Teja | Ruido medio, tonos terracota | Cubiertas |
| Caliza | Ruido medio, tono cálido | Zócalos, bordillos, fuente |
| Tierra | Ruido de baja frecuencia | Base y calles |
| Adoquín | Variación de tono | Plaza y ejes peatonales |
| Madera | Rugosidad alta, tono nogal | Puertas, balcones, bancos y puestos |
| Hierro | Tono carbón, metalness discreto | Barandas y faroles |
| Vidrio | Azul petróleo oscuro | Ventanas |
| Agua | Azul verdoso con emisión muy baja | Fuente decorativa |
| Follaje | Dos tonos verdes compartidos | Árboles y copas |

**Importante:** el ruido procedural no equivale a un set PBR completo de albedo/normal/roughness/AO. Los mapas PBR externos se integrarán cuando la fábrica de assets de la PR #12 esté aprobada e incorporada a la rama base. No se inventan rutas de archivos aún ausentes.

## 5. Geometría, colisión y rendimiento

- Geometría generada una vez en `_ready`; no se reconstruye cada frame.
- Materiales compartidos por categoría para reducir cambios de estado.
- Colisión estática simplificada: una caja por edificio y una base plana para el suelo.
- Sin GI dinámica, reflejos de pantalla, volumétricos ni sombras locales.
- Densidad de vegetación configurable y acotada entre 0.25 y 1.0.
- Las fachadas son decorativas; los interiores no son transitables en esta entrega.
- La escena es un preview de mundo, no un mapa de navegación final ni una zona con streaming.

Presupuesto objetivo BALANCED (pendiente de medición): 16–25 edificios/hitos, 20–40 árboles, faroles sin sombras y materiales compartidos. No se declara FPS, memoria ni compatibilidad física Android hasta medir en dispositivo.

## 6. Integración de assets y referencias

### Recursos internos

- `scripts/arpg/level/visual_kit.gd`: helpers procedurales y ruido 128 × 128.
- `scripts/arpg/environment/terrain_material_library.gd`: paleta ambiental de Valdeluz.
- `scripts/arpg/environment/environment_controller.gd`: cielo, ciclo, clima y faroles.
- `docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md`: canon visual obligatorio.
- `docs/AGENT_BRIEFING_VISION_CUBANA.md`: puerta de Art Pass y criterios de aceptación.

### Dependencia visual pendiente

PR #12 — [AI Art Department: fábrica de recursos 3D + primer lote (93 recursos)](https://github.com/Lean031110/RPG-LBA/pull/12).

Su documentación describe modelos GLB y conjuntos PBR de césped, tierra roja, barro, caliza, adoquín, estuco, madera, teja, follaje y otros. Esa PR es una rama separada y no se presupone fusionada. Tras su revisión:
1. comprobar IDs, rutas, licencias y estado `validated/published` del catálogo;
2. seleccionar recursos BALANCED adecuados para ciudad;
3. integrarlos mediante un PR específico de assets;
4. generar los `.import` desde Godot 4.7.2;
5. comparar materiales bajo cámara real y perfil Low.

### Referencias de dirección

- Godot 4.7 — StandardMaterial3D: https://docs.godotengine.org/en/4.7/classes/class_standardmaterial3d.html
- Godot 4.7 — NoiseTexture2D: https://docs.godotengine.org/en/4.7/classes/class_noisetexture2d.html
- Godot 4.7 — Compatibility renderer: https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html
- glTF 2.0: https://www.khronos.org/gltf/
- OpenGL ES 3.0: https://www.khronos.org/opengles/

Las referencias técnicas no sustituyen la revisión de licencias de cada asset. Esta entrega no incorpora recursos externos de terceros; la geometría y los materiales se generan con código del proyecto.

## 7. Validación y aceptación

| Criterio | Estado en esta PR |
|---|---|
| Escena 3D independiente y cargable | Pendiente de Godot CI |
| Distribución de ciudad, plaza, calles y distritos | Implementada por código; inspección visual pendiente |
| Materiales compartidos con variación procedural | Implementados |
| Colisiones estáticas simplificadas | Implementadas por código; smoke pendiente |
| Reproducibilidad con semilla fija | Implementada por código; test pendiente |
| Importación Godot 4.7.2 | NOT TESTED localmente |
| Suite GdUnit4 | NOT TESTED localmente |
| Capturas 16:9 y 20:9 / revisión humana | NOT TESTED |
| Android físico y FPS | NOT TESTED |

Comandos previstos en entorno con Godot 4.7.2:

```bash
godot --headless --path . --import
godot --headless --editor --path . --quit --verbose
godot --headless --path . res://scenes/arpg/valdeluz/valdeluz_capital_preview.tscn --quit-after 120
./addons/gdUnit4/runtest.sh --headless --add res://tests/integration/test_valdeluz_capital_builder.gd
gdlint scripts/arpg/level/valdeluz_capital_builder.gd scripts/arpg/level/valdeluz_capital_preview.gd tests/integration/test_valdeluz_capital_builder.gd
gdformat --check scripts/arpg/level/valdeluz_capital_builder.gd scripts/arpg/level/valdeluz_capital_preview.gd tests/integration/test_valdeluz_capital_builder.gd
```

No marcar como visualmente aprobado ni listo para producción hasta revisar capturas reales y probar el dispositivo objetivo.
