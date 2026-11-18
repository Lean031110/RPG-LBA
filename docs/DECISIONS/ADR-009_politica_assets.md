# ADR-009 — Política de assets: manifiesto, fábrica y pendientes de licencia

**Fecha:** 2026-11-16 · **Estado:** Aceptada · **Evidencia:** PR #12
(fusionada), `assets/manifest.csv` (9 entradas externas),
`ART_DEPARTMENT/AI_ASSET_FACTORY/catalog/assets_manifest.json` (93
recursos), `THIRD_PARTY_NOTICES.md`, check `asset-license-audit (manifest)`.

## Estado real verificado (2026-11-16)

1. **Assets externos** (`assets/manifest.csv`, 9 entradas): robot CC0 de
   la plantilla, texturas Kenney CC0, etc. Auditables por CI.
2. **Fábrica de arte propia** (93 recursos: 62 trimesh paramétrico, 21
   NumPy/PIL, 10 factory): licencia MIT del propio proyecto, procedencia
   documentada por recurso, estado `published`, validación en CI
   (`asset-factory` workflows). Son obra original: sin riesgo de licencia
   de terceros.
3. **Pendientes de verificación** (`THIRD_PARTY_NOTICES.md`):
   - `assets/ui/close.svg`: icono de la plantilla SIN atribución
     documentada. En uso SOLO en `scenes/ui/inventory_ui.tscn` (escena
     heredada de la plantilla, no del stack ARPG).
   - Fuente Kurland (`assets/fonts/Kurland.ttf`): SIN archivo de licencia
     junto al archivo. Ya NO se usa en código ni escenas del proyecto
     (verificado por grep: 0 usos en `scripts/` y `scenes/`); su mención
     restante es documental.
   - Cinzel (SIL OFL 1.1) SÍ se usa (ArpgUiTheme) y TIENE su OFL.txt.

## Decisión

1. Todo asset nuevo exige registro completo en el manifiesto
   correspondiente ANTES de fusionar (la check `asset-license-audit` lo
   exige en CI).
2. `close.svg` NO se redistribuye como asset de producción: mientras la
   UI heredada que lo usa siga existiendo, se documenta el riesgo en
   THIRD_PARTY_NOTICES.md y se prohíbe su uso en UI nueva del ARPG.
   Antes de cualquier release distribuible debe sustituirse por un icono
   propio o CC0 verificado (tarea de Fase 9).
3. `Kurland.ttf` no se usa: no se elimina (conservar historial), pero se
   marca como no-distribuible y las referencias documentales deben decir
   que la fuente activa del proyecto es Cinzel (OFL) + Noto.
4. La fábrica de arte solo produce con licencias del propio proyecto y
   queda excluida de adquisición de terceros.
5. Ningún asset comercial puede incorporarse sin autorización expresa
   del propietario.

## Consecuencias

- El riesgo legal queda acotado a `close.svg` y `Kurland.ttf` (ambos
  sin uso en el stack ARPG); se resuelven en Fase 9 antes de RC.
- `PROVENANCE.md` y `THIRD_PARTY_NOTICES.md` son los documentos vivos de
  licencias; esta ADR fija su política.
