# Procedencia del repositorio (Provenance)

Documento obligatorio de trazabilidad. Cualquier auditoría futura debe poder
reconstruir de dónde salió cada byte de este proyecto.

## Plantilla base fijada

| Campo | Valor |
| --- | --- |
| Repositorio upstream | https://github.com/devmoreir4/godot-3d-multiplayer-template |
| Tag auditado | `v2.0.0` (tag anotado `6b58ad830ea3a876528bf6ce934d93cca90c49de`) |
| **Commit SHA fijado** | **`51b2614fbd92e4c79a3353832256d41d79a6cf4a`** |
| Autor del commit | Carlos Moreira <carlosmoreira.bji@gmail.com> |
| Fecha del commit upstream | 2026-09-02T05:21:35-03:00 |
| Asunto | Merge pull request #27 from devmoreir4/fix/issue-templates |
| Licencia del código | MIT (Carlos Moreira, 2026) — `LICENSE` |
| Assets de terceros | Excluidos del MIT; regidos por sus `ATTRIBUTIONS.md` |
| Remote configurado | `upstream` → https://github.com/devmoreir4/godot-3d-multiplayer-template.git |
| Tags heredados | `v1.0.0`, `v1.1.0`, `v1.2.0`, `v2.0.0` (historial git completo preservado) |

## Verificación del pin (comandos ejecutados)

```bash
git ls-remote --tags https://github.com/devmoreir4/godot-3d-multiplayer-template
# 6b58ad830ea3a876528bf6ce934d93cca90c49de  refs/tags/v2.0.0
# 51b2614fbd92e4c79a3353832256d41d79a6cf4a  refs/tags/v2.0.0^{}   <- commit

git clone https://github.com/devmoreir4/godot-3d-multiplayer-template.git
cd godot-3d-multiplayer-template && git checkout v2.0.0
git rev-parse HEAD   # 51b2614fbd92e4c79a3353832256d41d79a6cf4a
```

## Motor fijado

| Campo | Valor |
| --- | --- |
| Godot | 4.7.2 Standard (no .NET) |
| Binario verificado | `Godot_v4.7.2-stable_linux.x86_64` |
| Versión reportada | `4.7.2.stable.official.ed1daf0bf` |
| Descarga oficial | https://github.com/godotengine/godot/releases/tag/4.7.2-stable |
| Renderer actual del proyecto | Forward Plus (heredado de la plantilla) — **cambio a Compatibility planificado para Fase 1, pendiente de autorización** |

## Qué se verificó de la plantilla (2026-11-12)

- Lectura completa de scripts (3.184 líneas GDScript), escenas, workflows y atribuciones.
- Importación headless con Godot 4.7.2: primera pasada con mensajes benignos de
  fuente (conocidos, documentados), segunda pasada sin errores.
- Smoke test headless de la escena principal: PASS.
- Servidor dedicado headless + 2 clientes independientes: PASS (arnés
  reproducible en `tests/multiplayer/`).
- Confirmado en código: el ataque de ejemplo reproduce la animación `Attack1`
  y NO implementa daño, vida, hitbox ni hurtbox (cero coincidencias de
  `health|damage|take_damage|hitbox|hurtbox` en todo el código).
- Confirmado: sin enemigos, sin clases, sin misiones, sin guardado, sin tests,
  sin preset Android, sin controles táctiles, cámara de tercera/primera persona
  con ratón (no isométrica).

Informe completo: `docs/auditoria/FASE0_INFORME_AUDITORIA.md`.

## Cambios aplicados sobre la plantilla en la rama `agent/fase0-auditoria-y-bootstrap`

Solo bootstrap; **ningún cambio de gameplay** (regla del prompt 00):

1. Kit de producción añadido: `AGENTS.md`, `docs/`, `prompts/`, `config/`.
2. `assets/manifest.csv` creado con los 7 assets de terceros heredados.
3. `THIRD_PARTY_NOTICES.md` con el estado de licencias y 2 pendientes de verificación.
4. Arnés de pruebas multijugador headless en `tests/multiplayer/` (no modifica
   el juego; instancia la escena real).
5. CI: `validate.yml` (import 2 pasadas + smoke + multijugador + manifiesto),
   `android-debug.yml` (SKIPPED hasta preset), `godot-ci.yml` actualizado a
   Godot 4.7.2 y con lint en `tests/`. `release.yml` upstream conservado.
6. Plantillas de issues/PR del kit; las del template fueron sustituidas
   (histórico accesible en git y upstream).
7. `README.md` propio; `scripts/local/` con envoltorio de pruebas.
8. `.gitignore`: añadido `artifacts/` (logs de CI/pruebas no se versionan).

## Relación futura con upstream

- `upstream` queda configurado para poder comparar/coger mejoras.
- NO se hará push a upstream desde este repositorio.
- Antes de mergear cambios de upstream en el futuro: auditar diff, licencias,
  ejecutar CI completo y abrir PR (mismo flujo que cualquier cambio).
