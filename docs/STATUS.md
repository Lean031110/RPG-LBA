# STATUS — Situación real del proyecto

| Campo | Valor |
|---|---|
| Fecha de actualización | 2026-11-16 (UTC+8) |
| Rama principal | `main` @ `83c1194` (merge PR #16) |
| Último commit auditado en main | `83c1194` — CI completa verde (4 workflows, 2026-11-14) |
| PR abierta | #15 (borrador): capital de Valdeluz, head `25bc199`, base `main` |
| Fase oficial vigente | Fase 2 — Combate ARPG y seis clases (en curso; ver ROADMAP.md) |
| Iteración interna actual | Post-Fase 5 interna (sistemas de combate) — correspondencia en ROADMAP.md |
| Version del proyecto | 0.2.0 (`project.godot`) |

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

- **Fase 2 (combate):** solo 1 de 6 clases implementada. Bruja, Sepulturero,
  Tirador, Cimarrón y Bardo están definidas en datos/documentación, sin kit
  jugable. Es el siguiente bloque de trabajo.
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

## Estado de CI (verificado 2026-11-14/16)

- `main` @ `83c1194`: Godot CI, Validate, Visual Captures y Android debug
  APK en verde.
- PR #15 @ `b4f7bcd` (14/11): Godot CI y Validate en ROJO por los 35
  problemas de lint y el error de `allow_dynamic_shadows` — corregidos el
  16/11 en `25bc199`; los 4 workflows re-disparados sobre ese commit.
- Checks requeridas para fusionar: project-import + game-smoke-test,
  multiplayer-smoke, asset-license-audit, gdunit-tests, GDScript lint and
  format, Godot headless check.

## Próximos objetivos (orden)

1. Esperar CI verde de PR #15 y conservarla como borrador (fase futura).
2. Fase 2: implementar las 5 clases restantes (una por entrega, con pruebas
   de daño/coste/cooldown/estados/cancelación), empezando por la Bruja.
3. Fase 3: inventario/equipo/economía ARPG con instancias estables y
   transacciones seguras.
4. Fase 4: campaña inicial de misiones sobre QuestSystem.
5. Fase 5: integrar capital (PR #15) cuando el gameplay lo exija.

## Evidencias

- Capturas reales del motor (16:9 y 20:9) por workflow Visual Captures.
- Evidencia local de la capital (4 vistas): métricas en el comentario de la
  PR #15 (https://github.com/Lean031110/RPG-LBA/pull/15#issuecomment-6904581797).
