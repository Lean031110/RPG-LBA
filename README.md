# RPG LBA — Las Cenizas de Lythara

<p align="center"><img src="assets/branding/rpg-lba-logo.svg" alt="RPG LBA — Las Cenizas de Lythara" width="760"></p>
<p align="center"><strong>Un action RPG isométrico de fantasía oscura con alma cubana.</strong><br>Cuba, 1953. Una isla viva. Un mal antiguo. Siete recuerdos que no deben perderse.</p>
<p align="center"><img src="assets/branding/lba-games-logo.svg" alt="LBA Games" width="360"></p>

## El juego

**Las Cenizas de Lythara** es un action RPG 3D para PC y Android, desarrollado en Godot 4.7.2, con cámara isométrica, combate de acción, seis clases, campaña cinematográfica, misiones, exploración por regiones y criaturas sobrenaturales. La primera campaña se titula **El Eco de Valdeluz** y se desarrolla en una Cuba ficticia de 1953, reinterpretada como fantasía oscura.

> La historia es una ficción alternativa. La cultura cubana es parte central del mundo y se trata con respeto; los sucesos y lugares sobrenaturales inventados no se presentan como hechos históricos reales.

## Dirección creativa

- **Tono:** oscuro, gótico, misterioso y aventurero; esperanza, humor y humanidad entre el horror.
- **Identidad:** gótico caribeño, arquitectura colonial y art déco, vegetación tropical, tierra roja, piedra caliza, faroles, radios, trenes y música original de inspiración cubana.
- **Visual:** materiales de terreno distinguibles, cielo visible, ciclo día/noche y clima dinámico.
- **Referencia de calidad:** claridad de combate y atmósfera de ARPG oscuro moderno, sin copiar interfaces, personajes, mapas, iconos, fuentes o assets de otros juegos.
- **Plataformas objetivo:** Android de gama baja/media y PC. Rendimiento y compatibilidad física solo se publican tras medirlos.

## Seis clases

| Clase | Rol |
|---|---|
| Machetero de la Sierra | Tanque / combate cercano |
| Bruja de la Manigua | Control / magia |
| Santero de la Luz (alternativa de nombre: Guardián de la Luz) | Curación / apoyo |
| Tirador del Malecón | Distancia / precisión |
| Cimarrón Sombrío | Asesino / movilidad |
| Bardo del Solar | Apoyo / control |

Estadísticas, habilidades, pasivas, definitivas y especializaciones: [Clases y habilidades](docs/diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md).

## Historia y producción narrativa

- [Biblia del mundo e historia cinematográfica](docs/narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md)
- [Misiones principales y cadenas secundarias](docs/narrativa/01_MISIONES_Y_CADENAS.md)
- [Dirección artística y rediseño UX](docs/direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md)
- [Brief de implementación para agentes](docs/AGENT_BRIEFING_VISION_CUBANA.md)
- [Índice de visión creativa](docs/CREATIVE_VISION_INDEX.md)

## Estado real del proyecto

**No confundas documentación aprobada con gameplay implementado.** La Fase 1 fue reportada como completada localmente: 48/48 pruebas GdUnit4 y 10 capturas visuales, según el informe entregado el 12-11-2026. Su push/PR todavía debe verificarse en GitHub antes de considerar el código integrado en `main`. APK Android, dispositivo físico y FPS siguen como **NOT TESTED** en ese informe. El nuevo Art Pass, el ciclo día/noche y el rediseño de interfaz están especificados, no implementados todavía.

| Área | Estado |
|---|---|
| Base Godot 4.7.2 y auditoría | Fase 0 reportada completada |
| Vertical slice Fase 1 | Entrega local reportada; verificar PR/CI |
| Historia y dirección creativa | Documentadas |
| Rediseño visual y UX | Especificado; pendiente de implementación |
| Seis clases | Diseño documentado; implementación completa pendiente |
| Multijugador autoritativo | Preparación arquitectónica; validar por fases |
| APK / Android físico / FPS | NOT TESTED según informe de Fase 1 |

## Tecnología

- Godot 4.7.2 Standard + GDScript.
- Compatibility Renderer.
- GdUnit4 y GitHub Actions.
- Objetivo móvil ARM64.

No introducir C#, extensiones nativas ni cambiar renderer sin decisión técnica aprobada y ADR.

## Empezar

### Requisitos
Godot **4.7.2 Standard**, Git y las herramientas indicadas por los scripts de CI.

### Clonar e importar
```bash
git clone https://github.com/Lean031110/RPG-LBA.git
cd RPG-LBA
godot --headless --path . --import
godot --headless --editor --path . --quit
```

Abre el proyecto con Godot y ejecuta F5. Consulta `AGENTS.md`, `scripts/ci/` y `.github/workflows/` para comandos de pruebas. No declares tests aprobados si no los ejecutaste.

## Para agentes de IA

1. Leer `AGENTS.md` antes de tocar archivos.
2. Leer `docs/AGENT_BRIEFING_VISION_CUBANA.md`.
3. Leer la biblia, misiones, clases y dirección artística.
4. Inspeccionar rama, commit, árbol, PR y workflows reales.
5. Crear rama `agent/<fase>-<tarea>`; nunca push directo a `main`.
6. Una fase por PR; incluir tests y evidencias.
7. Reportar PASS / FAIL / SKIPPED / NOT TESTED con comandos, logs y enlaces.
8. No inventar resultados, no borrar sistemas funcionales y no guardar secretos.
9. No continuar más allá del alcance autorizado.

## Organización

- `assets/branding/` — logos vectoriales de RPG LBA y LBA Games.
- `docs/narrativa/` — canon, personajes, historia y misiones.
- `docs/diseno/` — clases, atributos y habilidades.
- `docs/direccion-artistica/` — arte, mundo, UI, iluminación y criterios visuales.
- `docs/` — arquitectura, riesgos, QA y guías de agentes.
- `prompts/` — prompts de producción por fase.
- `config/` — datos y perfiles.
- `scenes/`, `scripts/`, `tests/` — implementación Godot.

## Licencias y propiedad intelectual

La licencia del código propio debe decidirse explícitamente antes de distribuir. La licencia del template upstream no cubre automáticamente assets ni contenido nuevo. Cada recurso externo debe figurar en `assets/manifest.csv` con autor, URL, versión, licencia y atribución. No incorporar recursos sin licencia verificable. Música, textos, personajes, iconos y mapas deben ser originales o contar con permisos explícitos.

## Marca

- **Juego:** RPG LBA — Las Cenizas de Lythara.
- **Campaña:** El Eco de Valdeluz.
- **Estudio/productora:** LBA Games.
- **Lema de estudio:** Creamos mundos · Contamos historias.
- **Lema de campaña:** Cuba, 1953. Una isla viva. Un mal antiguo.

## Contribuir

Lee `AGENTS.md`, trabaja en una rama y abre PR. Toda propuesta visual incluye capturas en 16:9 y 20:9. Toda propuesta técnica incluye pruebas y estado verificable.
