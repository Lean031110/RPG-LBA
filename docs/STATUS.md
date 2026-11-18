# STATUS — Situación real del proyecto

| Campo | Valor |
|---|---|
| Fecha de actualización | 2026-11-18 (UTC+8) — reconciliación y entrega |
| Rama principal | `main` @ `4a020fb` (merge PR #18) |
| Último commit auditado en main | `4a020fb` — CI completa verde (4 workflows) |
| PR abiertas | #15 (fase futura, capital de Valdeluz): actualizada contra main, CI verde, sin fusión por decisión de roadmap |
| Fase oficial vigente | Fase 2 — Combate ARPG y seis clases (en curso; 3/6 implementadas) |
| Iteración interna actual | Post-Fase 5 interna (sistemas de combate) — correspondencia en ROADMAP.md |
| Version del proyecto | 0.2.0 (`project.godot`/presets) |

## Fases completadas (fase oficial del Production Kit)

- **Fase 0 — Auditoría y bootstrap:** PR #1 (fusionada). Repo base auditado,
  Godot 4.7.2 + GDScript + Compatibility fijados.
- **Fase 1 — Vertical slice:** PR #2..#5 (fusionadas). El Eco de Valdeluz
  jugable: Machetero, Sombra de Portal, Cheo, misión VS_P00 con XP,
  guardado y recuperación, escenarios, iluminación y ciclo día/noche.

## Sistemas funcionales y probados (implementado + probado)

- Motor de combate compartido (ArpgCombatant + `scripts/arpg/combat/*`):
  daño centralizado, estados alterados, cooldowns por identificador,
  hitboxes con línea de visión, buffer de entrada, targeting.
- Machetero COMPLETO (kit de 4 habilidades + definitiva + 2 pasivas +
  progresión + persistencia). Canon en `docs/diseno/02`.
- **Bruja de la Manigua jugable** (PR #20): 2/6 — motor común de proyectiles
  y zonas persistentes + kit completo con pruebas.
- **Sepulturero de Guanabacoa jugable** (PR #21): 3/6 — sistema de
  invocaciones + kit completo con pruebas.
- Monstruario de 3 especies con IA diferenciada y FSM común.
- HUD móvil completo con recargas radiales, minimapa y bloqueo en diálogos.
- Menú principal, presentación, intro splash y tema visual propio.
- Multijugador LAN (lobby ENet, 2 procesos, smoke en CI). NO autoritativo.
- Perfiles de calidad LOW/MEDIUM/HIGH + adaptativo con matriz Android.
- APK ARM64 + Universal autofirmadas desde CI, con verificación de
  instalación en emuladores API 35/36.
- Presentación visual verificada en 16:9 y 20:9 (workflow Visual Captures).
- GdUnit4: **295/295 casos, 43/43 suites en `main`** (4 más en la rama de la
  capital: 299/299). gdlint y gdformat limpios en 124 archivos.
- Departamento de arte con fábrica de assets (93 recursos con licencia en
  manifiesto, PR #12 fusionada tras validar).

## Sistemas parciales

- **Fase 2 (combate):** 3 de 6 clases implementadas y probadas (Machetero,
  Bruja, Sepulturero). Tirador, Cimarrón y Bardo están definidas en
  datos/documentación, sin kit jugable. Es el siguiente bloque de trabajo.
- **Fase 4 (misiones):** QuestSystem operativo con VS_P00; falta la campaña
  completa (28 principales + 12 cadenas según canon).
- **Fase 5 (mundo):** slice de Valdeluz jugable; capital procedural en PR #15
  (borrador, fase futura); faltan 5 regiones, POIs, 3 mazmorras y 5 jefes.
- **Fase 6 (multijugador):** lobby funcional; falta servidor autoritativo
  (intenciones en cliente, validación, reintento, hasta 4 jugadores).
- **Fase 8 (calidad):** perfiles gráficos hechos; falta audio completo,
  batería/memoria y validación física (S22 Ultra, Redmi 9C: NOT TESTED).

## Solo definido en datos / solo documentado

- Inventario ARPG, economía, mercaderes, crafting, mejoras (Fase 3): diseño
  en `docs/03`; no hay sistema ARPG de inventario propio (el existente en
  `scripts/inventory/` es herencia de la plantilla multiplayer).
- Mundos/guilds/chat/comercio bilateral (Fase 7): solo especificación.
- Pipeline Google Play (Fase 9): solo documento.

## Bloqueos

- Ninguno técnico activo. Restricciones conocidas: sin hardware Android
  físico en el entorno (validación de dispositivo = NOT TESTED), el
  propietario debe aprobar fusiones (protección de `main` con checks).

## Estado de CI (verificado 2026-11-18)

- `main` @ `4a020fb` tras fusionar PR #17 (docs canónicos) y PR #18 (fábrica
  cloud consolidada); ambas con las 6 checks requeridas en verde en sus
  HEAD reales tras actualizarlas contra `main` (modo strict).
- PR #19 cerrada como superseded: su contenido útil vive en #18 (ver
  `ART_DEPARTMENT/CLOUD_AUTOMATION/PR19_RECONCILIATION.md`); rama conservada.
- PR #15 @ `622a5be`: actualizada contra el `main` final; CI en verde; se
  conserva ABIERTA como fase futura (decisión de roadmap: la capital no se
  fusiona antes de tiempo).
- Checks requeridas para fusionar: project-import + game-smoke-test,
  multiplayer-smoke, asset-license-audit, gdunit-tests, GDScript lint and
  format, Godot headless check (todas en verde en `main`).

## Próximos objetivos (orden)

1. Fase 2: implementar las 3 clases restantes (Tirador, Cimarrón, Bardo;
   una por entrega, con pruebas de daño/coste/cooldown/estados/cancelación).
2. Fase 3: inventario/equipo/economía ARPG con instancias estables y
   transacciones seguras.
3. Fase 4: campaña inicial de misiones sobre QuestSystem.
4. Fase 5: integrar capital (PR #15) cuando el gameplay lo exija.
5. Proveedor/secretos pendientes del propietario: rotar `HF_TOKEN` (401 en
   prueba real) y arreglar el chat id de Telegram (ver
   `docs/ops/SECRETS_AND_VARIABLES_AUDIT.md` §7).

## Evidencias

- Capturas reales del motor (16:9 y 20:9) por workflow Visual Captures.
- Evidencia local de la capital (4 vistas): métricas en el comentario de la
  PR #15 (https://github.com/Lean031110/RPG-LBA/pull/15#issuecomment-6904581797).
