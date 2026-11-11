# Prompt 02 — Combate y seis clases

Implementa los seis arquetipos definidos en `docs/03_CLASES_COMBATE_LOOT.md` como datos configurables, no seis sistemas duplicados. Para cada clase crear recursos de clase, recurso, habilidades, VFX, animaciones y sonidos. Primero implementar 2 clases completas y probarlas; después completar las otras cuatro reutilizando componentes.

Cada habilidad debe tener ID estable, coste, cooldown, alcance, forma de área, ventana activa, reglas de cancelación y validación. El servidor/modo autoridad calcula hit/damage. Añade telegráficos que se lean en móvil y opciones para reducir VFX.

Tests: coste insuficiente, cooldown, rango, línea de visión si aplica, hit duplicado, muerte, interrupción, daño amigable/hostil, invulnerabilidad y balance de datos. No crear habilidad sin animación/feedback y tooltip.
