# Capturas reales del juego — Entrega 2026-11-18

Renders del motor real (Godot 4.7.2 Standard, Compatibility Renderer, GL por
software llvmpipe bajo Xvfb, igual que el workflow `visual-captures.yml`).
Generadas desde el árbol de `main` tras la reconciliación (merge PR #18,
`4a020fb`; los archivos de juego no difieren del renderizado). Resoluciones
16:9 (1280x720) y 20:9 (1600x720).

| Archivo | Contenido | Resolución |
|---|---|---|
| `01-menu-principal.png` | Menú principal (logo oficial, botones Continuar/Nueva partida/Multijugador/Ajustes) | 16:9 |
| `02-personaje.png` | Personaje (Machetero) en el mundo con HUD y misión VS_P00 | 16:9 |
| `03-gameplay.png` | HUD de gameplay completo (vida, misión, minimapa, controles táctiles) | 20:9 |
| `04-combate.png` | **Combate real**: Sombra de Portal a 1,9 m del jugador, enfrentamiento en curso (HP del jugador 95 tras recibir golpe) | 16:9 |
| `05-inventario.png` | Inventario «Mochila» con arma e instrucciones de equipo | 16:9 |
| `06-mundo.png` | Entorno de Valdeluz (afueras integradas) a mediodía forzado | 16:9 |
| `07-presentacion.png` | Presentación/intro splash | 16:9 |
| `08-menu-principal-209.png` | Menú principal — comprobación de aspecto 20:9 | 20:9 |
| `09-ajustes.png` | Menú de ajustes | 16:9 |
| `10-creditos.png` | Créditos | 16:9 |
| `11-multijugador.png` | Menú multijugador (lobby LAN) | 16:9 |
| `12-combate-sepulturero.png` | Kit del Sepulturero de Guanabacoa con invocación activa | 16:9 |

## Verificación

- Ninguna captura es negra ni vacía: `verify_visual_captures.py` PASS (12/12),
  media 51–149, varianza 93–4793.
- Verificación visual adicional por modelo de visión (QA): menús legibles,
  botones presentes, HUD completo, personaje y enemigo distinguibles. El
  entorno se renderiza con el perfil gráfico LOW (auto-detección por
  llvmpipe/sin GPU); en un teléfono real el motor selecciona el perfil del
  dispositivo.
- Ausencias documentadas (mandato §10): la **capital de Valdeluz** (PR #15,
  fase futura, no integrada en `main`) no tiene captura porque no forma parte
  del build; no se sustituye por imágenes ficticias. No hay mazmorras
  integradas todavía (roadmap Fase 5).

## Regenerar

```bash
bash scripts/ci/capture_visual_suite.sh <dir_salida>
godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --script res://scripts/local/capture_combate.gd -- <dir>/04-combate.png
godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --script res://scripts/local/capture_mundo_mediodia.gd -- <dir>/06-mundo.png
```

(requiere servidor X o Xvfb; los tres scripts viven en `scripts/local/`).
