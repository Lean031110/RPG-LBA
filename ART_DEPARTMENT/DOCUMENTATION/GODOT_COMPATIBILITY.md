# GODOT_COMPATIBILITY.md — Convenciones para Godot 4.7

## Canon técnico verificado

- `project.godot`: `config/features=PackedStringArray("4.7", "Forward Plus")`.
- AGENTS.md §4: Godot **4.7.2 Standard + GDScript**, sin C# ni extensiones
  nativas; el prompt 09 exige que los materiales funcionen en
  **Compatibility Renderer** y perfil Low.

## Qué garantiza la fábrica

| Aspecto | Garantía |
|---|---|
| Formato | GLB (glTF 2.0 binario), importador nativo de Godot |
| Ejes | Y-up, frente −Z (idéntico a la convención Godot) |
| Escala | 1 unidad GLB = 1 metro |
| Pivote | base del objeto en el origen (y=0) → snap a suelo |
| Materiales | `pbrMetallicRoughness` estándar → StandardMaterial3D automático |
| Normales | presentes y finitas (planas en cajas, suaves en cilindros/esferas) |
| UV | proyección plana por normal dominante (válidas y en [0,1]) |
| Draw calls | geometría fusionada por material dentro de cada GLB |
| Triángulos | MOBILE ≤ 900 por prop, ≤ 3500 por edificio |
| Texturas | seamless; 512 (MOBILE) / 1024 (BALANCED) / 2048 (HIGH) |
| Sin dependencias | ningún addon, shader custom ni extensión nativa nueva |

## Notas por renderer

- **Forward Plus (desktop)**: todo funciona tal cual.
- **Compatibility/mobile**: los mapas `normal/roughness/metallic` funcionan;
  el mapa `height` (desplacement) NO se usa por coste — está para flujos
  externos (baking, detalle futuro). `ao` opcional con `ao_light_affect`.
- Perfil Low del canon (AGENTS.md §7): la textura de 512 del perfil MOBILE
  y las geometrías de 8 segmentos son la referencia de diseño.

## Comprobación de importación

Requisito del prompt 09: dos pasadas headless. Ejecutar en el repo con un
Godot 4.7 en PATH:

```bash
godot --headless --path . --import   # pasada 1
godot --headless --path . --import   # pasada 2
```

La fábrica incluye `integrations/godot_bridge.py` (la usa el workflow
`asset-validation.yml` de forma opcional; reporta SKIPPED si no hay binario,
jamás PASS sin prueba — AGENTS.md §3).

## Los `.import`

La fábrica NO fabrica `.import` a mano: los UID/escaneo los genera el editor
del agente principal al abrir/importar (igual que el resto de assets del
repo). Tras el primer escaneo, tu `.godot/` queda fuera de Git como siempre.

## Sugerencia de verificación rápida en el editor

1. Arrastra `assets/models/vegetation/mdl_vegetation_palm_royal_001.glb`
   a una escena: debe quedar apoyado en el suelo con la corona arriba.
2. Crea un plano con
   `assets/environment/textures/ground/tex_ground_grass_tropical_001_albedo.png`,
   UV 4×4: debe repetirse sin costuras.
3. El minimapa de triángulos del monitor de depuración debe reflejar el
   campo `poligonos` del catálogo (±2 por redondeo de índices).
