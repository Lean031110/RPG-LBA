# RPG LBA — Asset Factory (v1 bootstrap)

> Estado: infraestructura documental inicial. No declara generación automática ni integración productiva completadas.

## Propósito
Mantener una fábrica reproducible para descubrir, evaluar, generar, optimizar, aprobar e integrar recursos visuales de RPG LBA. La fuente de verdad del código sigue siendo este repositorio; el inventario vive en assets/library/catalog.csv y las licencias verificadas en assets/manifest.csv.

La automatización nunca sustituye la revisión visual humana ni incorpora recursos cuya licencia no esté comprobada.

## Canon visual
- Fantasía oscura caribeña, Cuba ficticia de 1953; campaña El Eco de Valdeluz.
- Low-poly estilizado y suavizado, proporciones heroicas, materiales mates y VFX legibles.
- Paletas regionales según docs/08_DIRECCION_ARTISTICA_ASSETS.md.
- No copiar IP, personajes, mapas, UI, música ni assets de otros juegos.
- Godot 4.7.2 Standard, GDScript tipado y Compatibility Renderer; Android ARM64 y dispositivos modestos son prioridad.

## Fuente de verdad y estructura
| Ruta | Contenido |
|---|---|
| assets/library/catalog.csv | Inventario maestro, ID estable por recurso o grupo lógico |
| assets/manifest.csv | Procedencia, licencia, autor, URL y condiciones |
| assets/library/README.md | Taxonomía, naming y reglas |
| docs/art-pipeline/PROVIDERS.md | Fuentes, APIs, límites y evaluación |
| docs/art-pipeline/N8N_BACKUP_AND_MIGRATION.md | Backup/migración n8n |
| n8n/workflows/ | Exportaciones JSON importables, sin credenciales |
| .github/workflows/assets-validation.yml | Validación automatizada |
| scripts/ci/validate_asset_library.py | Validador local/CI |

## Arquitectura objetivo
1. GitHub: repositorio, historial, inventario, manifiestos, workflows exportados, issues, PRs y reportes. Fuente de verdad.
2. n8n: orquestación, programación, colas, reintentos, estados y avisos. Es reemplazable y no almacena el progreso único.
3. GitHub Actions: validación, Blender headless, conversión GLB, optimización, pruebas Godot y publicación de PR/artefactos.
4. Firebase Spark (opcional): panel ligero, metadatos operativos, cola de revisión y notificaciones. No guardar aquí la única copia de workflows, secretos ni modelos fuente.
5. Proveedores externos: Poly Haven, ambientCG, Kenney, KayKit, Smithsonian Open Access y otros, siempre con licencia por recurso.
6. Telegram: notificaciones y enlaces a PR/issue; nunca enviar tokens ni archivos privados.

## Ciclo de vida
DISCOVERED → LICENSE_REVIEW → PLANNED → GENERATING/PROCESSING → QA → REVIEW → APPROVED → INTEGRATED.
Estados adicionales: MISSING, REJECTED, NEEDS_IMPROVEMENT y QUARANTINED.
- APPROVED exige archivo real, hash SHA-256, ruta, licencia aprobada, validación técnica y revisión visual humana.
- INTEGRATED exige PR fusionado y referencia al commit.
- Si falta una prueba, usar NOT TESTED; nunca convertirla en PASS.
- Licencia desconocida = QUARANTINED; no entra en builds distribuibles.

## IDs
Formato recomendado: lba.<domain>.<category>.<slug>.v<major>, por ejemplo lba.character.player.machetero.v1. IDs inmutables; nombres visibles pueden cambiar/localizarse. Nunca derivar el ID de un nombre traducible.

## Flujo Git
- Nunca escribir directamente en main.
- Una tarea por rama agent/assets-<category>-<task>.
- Abrir PR con inventario, manifiesto, capturas, pruebas, hashes y licencias.
- No auto-merge.
- No subir pesos de modelos, datasets masivos, cachés, renders temporales ni credenciales.
- Para binarios grandes, evaluar Git LFS y sus cuotas/costes antes; no asumir que es gratuito.

## QA mínimo
- GLB/glTF 2.0 como intercambio preferente; conservar fuentes editables cuando proceda.
- Revisar escala, pivot, orientación, normales, UV, materiales, texturas, rig, animaciones, colisiones y LOD.
- Registrar triángulos, materiales, draw calls estimadas, resolución y tamaño.
- Generar capturas de inspección y probar en Godot 4.7.2 Compatibility.
- Revisar perfiles LOW/MEDIUM/HIGH; no elevar polígonos/texturas sin medir.
- Revisión humana obligatoria de silueta, legibilidad, coherencia y canon.

## Presupuestos iniciales provisionales
Son límites de revisión, no mediciones ni aceptación final; ajustar con profiling y ADR:
- Personajes/enemigos comunes: preferir 5k–20k triángulos LOD0; jefes 15k–35k; props comunes 500–5k.
- Texturas runtime: 512–1024 px en LOW/MEDIUM; 2K solo si perfil y memoria lo justifican.
- Evitar materiales únicos innecesarios; atlas/reutilización cuando sea útil.
- Colisiones simples; no usar malla de render como colisión por defecto.
- Medir huesos, materiales y draw calls en escena real.

## Seguridad
Credenciales solo en GitHub Actions Secrets/Environments, n8n Credentials o gestor seguro. Nunca en CSV, JSON exportado, .env versionado, issues, prompts públicos, logs ni commits. .env.example solo contiene nombres y valores vacíos/ejemplo.

## Definition of Done
1. Inventario y manifiesto pasan validación.
2. Export/import de workflows probado en n8n real.
3. Backup y restore de workflows, DB y encryption key probado.
4. Telegram envía/recibe prueba con secreto seguro.
5. GitHub Actions procesa asset de prueba y conserva reporte/hash.
6. Godot importa GLB en Compatibility sin errores.
7. PR de prueba y revisión humana.
8. Todo lo no probado queda NOT TESTED.

Consultar AGENTS.md, docs/08_DIRECCION_ARTISTICA_ASSETS.md, docs/11_GITHUB_Y_CI_CD.md y assets/manifest.csv.
