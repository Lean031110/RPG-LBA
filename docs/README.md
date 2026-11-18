# Documentación de RPG LBA — Las Cenizas de Lythara

Índice general de la documentación del proyecto. Última verificación:
2026-11-16. El estado real del proyecto vive en [STATUS.md](STATUS.md); el
plan canónico de fases en [ROADMAP.md](ROADMAP.md).

## Documentos de navegación (núcleo)

| Documento | Contenido |
|---|---|
| [STATUS.md](STATUS.md) | Situación real: fase, iteración, sistemas, pruebas, CI, PR y próximos objetivos |
| [ROADMAP.md](ROADMAP.md) | Fases oficiales del Production Kit, correspondencia con iteraciones internas y criterios de cierre |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Mapa de la arquitectura REAL del código (autoloads, capas, sistemas, plantilla heredada) |
| [QUALITY_GATES.md](QUALITY_GATES.md) | Puertas de aceptación: qué se exige para declarar terminada una tarea |
| [DECISIONS/](DECISIONS/) | Decisiones arquitectónicas nuevas (ADR-008..013); ADR-001..007 en `13_RIESGOS_Y_DECISIONES.md` |

## Diseño y canon del juego

| Documento | Categoría |
|---|---|
| [00_BRIEF_MAESTRO.md](00_BRIEF_MAESTRO.md) | Visión general |
| [01_GDD.md](01_GDD.md) | GDD |
| [03_CLASES_COMBATE_LOOT.md](03_CLASES_COMBATE_LOOT.md) | Clases, combate y botín (resumen) |
| [diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md](diseno/02_CLASES_ATRIBUTOS_HABILIDADES.md) | Canon completo de las 6 clases, atributos y habilidades |
| [PLAN_MAESTRO_ITERACIONES_RPG_LBA.md](PLAN_MAESTRO_ITERACIONES_RPG_LBA.md) | Plan de iteraciones internas (histórico-operativo) |

## Narrativa

| Documento | Categoría |
|---|---|
| [narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md](narrativa/00_BIBLIA_DEL_MUNDO_Y_HISTORIA.md) | Biblia del mundo e historia |
| [narrativa/01_MISIONES_Y_CADENAS.md](narrativa/01_MISIONES_Y_CADENAS.md) | Misiones y cadenas |
| [02_NARRATIVA_Y_MISIONES.md](02_NARRATIVA_Y_MISIONES.md) | Narrativa (documento raíz) |

## Mundo, arte y dirección técnica

| Documento | Categoría |
|---|---|
| [04_MUNDO_DUNGEONS.md](04_MUNDO_DUNGEONS.md) | Mundo, región de Camagüey, localidad de Verdaluz y mazmorras |
| [DECISIONS/ADR-013_jerarquia_mundo_camaguey_verdaluz.md](DECISIONS/ADR-013_jerarquia_mundo_camaguey_verdaluz.md) | Canon territorial: jerarquía mundo → Camagüey → Verdaluz y reglas de streaming |
| [direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md](direccion-artistica/03_DIRECCION_ARTISTICA_Y_UX.md) | Dirección artística y UX |
| [direccion-artistica/VALDELUZ_WORLD_ART_BIBLE.md](direccion-artistica/VALDELUZ_WORLD_ART_BIBLE.md) | Biblia visual de Valdeluz (rama capital, PR #15) |
| [environment/01_SISTEMA_AMBIENTAL.md](environment/01_SISTEMA_AMBIENTAL.md) | Sistema ambiental (ciclo día/noche, clima) |
| [08_DIRECCION_ARTISTICA_ASSETS.md](08_DIRECCION_ARTISTICA_ASSETS.md) | Assets y dirección artística |

## Plataformas, red y producción

| Documento | Categoría |
|---|---|
| [16_COMPATIBILIDAD_ANDROID.md](16_COMPATIBILIDAD_ANDROID.md) | Matriz de compatibilidad Android |
| [16_ADAPTIVE_GRAPHICS_CAMERA_UX.md](16_ADAPTIVE_GRAPHICS_CAMERA_UX.md) | Gráficos adaptativos, cámara y UX móvil |
| [05_MULTIJUGADOR_Y_SERVIDOR.md](05_MULTIJUGADOR_Y_SERVIDOR.md) | Multijugador y servidor (objetivo) |
| [18_MULTIJUGADOR.md](18_MULTIJUGADOR.md) | Multijugador (estado real) |
| [11_GITHUB_Y_CI_CD.md](11_GITHUB_Y_CI_CD.md) | GitHub y CI/CD |
| [17_CONTENT_PACKS_GITHUB_UPDATES.md](17_CONTENT_PACKS_GITHUB_UPDATES.md) | Content packs y actualizaciones |
| [18_GOOGLE_PLAY_RELEASE_PIPELINE.md](18_GOOGLE_PLAY_RELEASE_PIPELINE.md) | Pipeline de publicación en Google Play |

## Ingeniería y calidad

| Documento | Categoría |
|---|---|
| [06_ARQUITECTURA_GODOT.md](06_ARQUITECTURA_GODOT.md) | Arquitectura Godot (documento base) |
| [07_UX_CONTROLES_MOBILE.md](07_UX_CONTROLES_MOBILE.md) | UX y controles móviles |
| [10_QA_Y_VALIDACION.md](10_QA_Y_VALIDACION.md) | QA y validación |
| [12_CRITERIOS_DE_ACEPTACION.md](12_CRITERIOS_DE_ACEPTACION.md) | Criterios de aceptación |
| [13_RIESGOS_Y_DECISIONES.md](13_RIESGOS_Y_DECISIONES.md) | Riesgos y ADR-001..007 |
| [14_FUENTES_Y_REFERENCIAS.md](14_FUENTES_Y_REFERENCIAS.md) | Fuentes y referencias |
| [15_IMPORTAR_Y_PROBAR_LOCAL.md](15_IMPORTAR_Y_PROBAR_LOCAL.md) | Cómo importar y probar en local |
| [09_ROADMAP_Y_PROMPTS.md](09_ROADMAP_Y_PROMPTS.md) | Roadmap histórico y prompts (superseded por ROADMAP.md) |

## Informes históricos por fase

- [auditoria/](auditoria/) — Fase 0 y Fase 1.
- [reportes/](reportes/) — Fases 2 a 5, 4A/4B/4C y reconciliación integral.
- [kit/](kit/) — Referencia del Production Kit original.

## Convenciones

- Los documentos con prefijo numérico (`00_`..`18_`) son la serie original
  del Production Kit y se conservan con sus rutas: no renombrar sin
  actualizar `AGENTS.md` y los workflows.
- Los informes por fase (`reportes/`, `auditoria/`) son históricos y no se
  editan retrospectivamente; los cambios de estado van en `STATUS.md`.
- Toda decisión arquitectónica nueva se registra como ADR en
  [DECISIONS/](DECISIONS/).
