# PRODUCTION_STATUS.md — Estado de producción del departamento de arte

- **Fecha:** 2026-11-15
- **Rama:** `feature/ai-art-department` (base: main @ 26fb66b)
- **Pull Request:** https://github.com/Lean031110/RPG-LBA/pull/12 (abierto, sin merge automático)
- **Motor de la fábrica:** v1.0 (procedural CPU: NumPy/Pillow + trimesh/bpy)

## 1. Estado global

| Métrica | Valor |
|---|---|
| Trabajos en cola | 93/93 validados (0 pending, 0 processing, 0 failed) |
| Catálogo | 93 recursos con estado `validated` (→ `published` al fusionar el PR) |
| Validación global | 0 fallos; manifiesto PASS; duplicados PASS |
| Suite pytest | 41/41 PASS |
| Godot headless | SKIPPED (sin binario en el entorno de desarrollo; preparado en CI) |

## 2. Producción del primer lote (completado)

| Categoría | Recursos | Detalle |
|---|---|---|
| Texturas seamless PBR | 21 | césped, tierra roja, barro, arena, caliza, adoquín, granito, ladrillo viejo, estuco×4 (base + ocre/turquesa/coral), hormigón, asfalto, madera×2, zinc ondulado, tejas, mármol, agua, follaje |
| Materiales Godot | 10 | 3 estucos de fachada, madera, tejas, adoquín, asfalto, mármol, zinc, césped |
| Vegetación | 10 | palma real, cocotero, ceiba, mango, flamboyán, arbusto, hierba, helecho, seto, flores |
| Rocas y natural | 10 | peñasco, redonda, musgosa, arenisca, guijarros, borde de camino, volcánica, coral, mojón, tronco caído |
| Mobiliario urbano | 10 | farol colonial, farola moderna, bancos×2, papelera, parada de guagua, alcantarilla, señal de STOP, bolardo, jardinera |
| Mobiliario interior | 10 | mesa, silla, silla de balanceo, sofá, armario, cama, estantería, lámpara, escritorio, mostrador |
| Arquitectura | 10 | puerta colonial, puerta simple, ventana colonial, ventana moderna, columna, escalera, balcón, arco, verja de hierro, tejado |
| Edificios modulares | 7 | casa colonial ×2 variantes, casa 2 plantas ×2, comercio, edificio de apartamentos, casa en esquina |
| Objetos decorativos | 5 | barril de ron, jaba, maceta, letrero colgante, pila de jabas |

Cada recurso: archivo real en `assets/`, entrada de catálogo completa,
informe de validación PASS y preview en `ART_DEPARTMENT/PREVIEWS/`.

## 3. Backends usados

- Producción local del primer lote: **trimesh** (sandbox Python 3.12 sin bpy).
- CI (workflows): Blender/bpy con Python 3.11 + fallback automático trimesh.
- El backend queda registrado por recurso en `procedencia.backend`.

## 4. Registro de errores corregidos (trazabilidad)

1. `KeyError 'path'` → el campo del manifiesto es `ruta` (corregido en
   preview/validadores/CLI).
2. Semilla no determinista (`hash()` de Python) → `stable_seed()` sha256
   (corregido; los reintentos ahora reproducen y el dedupe funciona).
3. Primitivas trimesh orientadas +Z → pre-rotación a +Y del DSL (corregido;
   se regeneró la geometría completa del lote).
4. Voronoi con semillas envueltas en posición módulo → índices desenrollados
   (costura real del adoquín corregida).
5. Roughness constante en 8 tipos + metallic del zinc constante →
   modulación aditiva fbm propia + máscara metálica efectiva (corregido y
   revalidado).
6. Hiladas pares en ladrillo/tejas rompían el running bond al envolver →
   hiladas impares (corregido).

## 5. Trabajo pendiente (próximos lotes)

- Cola vacía: para ampliar la biblioteca, encolar nuevos trabajos
  (GENERATION_GUIDE.md) y ejecutar Asset Factory en Actions.
- Sugerido (prioridad del canon): `water` ya está; añadir `cement_smooth`,
  variantes de fachada (crema/caliza), vehículos (categoría registrada,
  generadores futuros), más edificios por variación paramétrica.
- Comprobación Godot headless en CI (opcional, con binario).
- Revisión visual humana (canon §10) antes de considerar aprobado el Art Pass.

## 6. Cambios de rutas/IDs

Ninguno tras la publicación inicial. Los IDs del primer lote son definitivos;
cualquier cambio futuro se anotará aquí y en el PR correspondiente.
