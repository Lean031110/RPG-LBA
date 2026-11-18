# Plan Maestro de Iteraciones — RPG LBA

> **Numeración canónica (ADR-008):** las fases OFICIALES del proyecto son
> las del Production Kit (0–9) y su referencia única es
> [`ROADMAP.md`](ROADMAP.md), que incluye la tabla de correspondencia con
> estas iteraciones internas. Este documento se conserva como registro
> operativo-histórico de las iteraciones de agentes. Las iteraciones
> internas citadas aquí NO equivalen 1:1 a fases oficiales del mismo
> número (p. ej. la "Fase 5 interna" de sistemas de combate alimenta la
> Fase oficial 2).

Documento vivo: refleja el estado REAL del proyecto y las prioridades de las
próximas entregas. Se actualiza al cierre de cada iteración. La fecha de corte
de esta edición es la **reconciliación integral** (2026-11-15): las PR #3 a
#14 están fusionadas en `main` (fases 1–5 + documentación + departamento de
arte); la PR #15 (capital de Valdeluz) queda como fase futura conservada.
El estado actualizado al día está en [`STATUS.md`](STATUS.md).

## Estado actual (reconciliación integral)

Sistemas completados y verificados por CI (además de todo lo de 4C-visual):

- Motor de combate compartido jugador/enemigos (ArpgCombatant + componentes
  en scripts/arpg/combat): daño centralizado con inmunidad/crítico por
  estadísticas/bloqueo con tope/vulnerabilidad/límites, estados alterados
  (stun, sangrado, rotura de armadura, ralentización, potenciación, prisa),
  recargas por identificador, hitboxes con línea de visión (nada de golpes a
  través de muros) y geometría centrada para arcos de 360°, controlador de
  acciones con ventanas windup/activa/recuperación, buffer de entrada y
  sistema de objetivo.
- Machetero de la Sierra COMPLETO según canon: combo ligero de 3 pasos,
  ataque pesado con perforación de armadura, Tajo de Guásima (sangrado),
  Guardia del Bohío (postura defensiva), Carga del Mambí (embestida
  aturdidora), Corte de la Ceiba (rompe armadura) y definitiva Huracán de
  Machetes (5 golpes + remate) con carga real; pasivas Pulso de monte
  (parada perfecta) y Pies de piedra; regeneración de vigor; crítico por
  estadísticas; desbloqueo por nivel; puntos de atributo (5/nivel, canon).
- Monstruario de 3 especies con IA diferenciada: Sombra de Portal (melee
  telegráfico), Perro de ceniza (rodea al objetivo, aúlla prisa a la
  manada) y Guarapo negro (tanque lento, golpe de área con empuje y trampa
  de resina); FSM común con LOS en detección y golpe, reaparición por datos.
- HUD completo: barra de 4 habilidades + definitiva con recarga radial,
  candado por nivel y coste; marco de objetivo (nombre/nivel/vida/estados);
  números de daño y crítico flotantes; chips de estados; bloqueo mantenido;
  teclado completo (J/L/K/2-4/R/ESP/Q/MAYÚS); combate bloqueado en diálogos.
- Multijugador LAN: causa raíz del error 20 corregida (teardown del peer
  previo + permiso INTERNET en ambos presets de exportación), puertos con
  respaldo 8080..8084, campo IP con puerto, señal de desconexión de jugador
  y smoke de 2 procesos reales con doble sala consecutiva.

Pruebas: 294/294 casos (42 suites) en verde; gdlint + gdformat en verde;
smoke multijugador (2 procesos) en verde.

Sistemas completados y verificados por CI:

- Vertical slice jugable de El Eco de Valdeluz (Fases 1–3): Machetero,
  Sombra de Portal, Cheo, misión VS_P00 con XP, guardado y recuperación.
- Compatibilidad Android: matriz por hardware, perfiles LOW/MEDIUM/HIGH,
  APK ARM64 + Universal firmados con la autofirma del proyecto, CI con
  emuladores API 35/36 (instalación, arranque, capturas).
- Art Pass de Valdeluz (Fase 4B): shaders de viento/humedad/hierro, VFX de
  combate, HUD semitransparente con minimapa funcional.
- Presentación cinematográfica propia (iteración 4C): intro saltable con el
  emblema oficial, boot splash de marca y transición al menú.
- Menú principal rediseñado con lenguaje visual compartido (ArpgUiTheme +
  ArpgBackdrop: cielo, luna, silueta de Valdeluz, palmas, brasas).
- Apartado MULTIJUGADOR visible con lobby LAN real (ENet) y estado honesto
  de lo implementado vs en desarrollo.
- HUD: botón táctil de pausa, recargas radiales en habilidad/esquiva,
  realce táctil, acento dorado de paneles.
- Cámara ARPG con oclusión reversible (muros que tapan al jugador se vuelven
  semitransparentes; nada se elimina).
- Icono Android adaptativo y heredado con el emblema oficial (antes: icono
  genérico de Godot).

Pruebas: 225/225 casos (34 suites) en verde; gdlint + gdformat en verde.

APK de referencia de seguridad: `RPG-LBA-Android-Universal-debug.apk`
(v0.1.0, 102 MB) instalado con éxito en el Samsung Galaxy S22 Ultra del
propietario. El ARM64 de v0.1.0 falló en el mismo teléfono; el análisis
forense (ver "Diagnóstico APK ARM64" abajo) demostró que el archivo publicado
era válido y que la variante ARM64 es un subconjunto estructural de la
Universal, por lo que la causa del fallo estuvo en la copia local del
teléfono (descarga truncada/corrupta es la hipótesis más probable, imposible
de verificar en remoto). La v0.1.1 añade verificación de integridad
prominente (SHA-256 + tamaño exacto en la release) y `versionCode 2` para
distinguir la instalación nueva.

## Diagnóstico APK ARM64 (resumen; detalle en la release v0.1.0)

1. Los bytes publicados en GitHub son idénticos a los verificados en CI
   (SHA-256 coincidente).
2. Verificación forense independiente (androguard + apksigtool + recorrido
   EOCD/zipalign propio): ambas variantes correctas en firma v2+v3,
   manifiesto (com.lbagames.rpglba, minSdk 24, targetSdk 36, versionCode 1),
   resources.arsc Stored+alineado, CRC y bloques de firma consistentes.
3. Las librerías arm64-v8a son byte-idénticas en ambas variantes.
4. La CI instaló y ARRANCÓ el ARM64 en emulador API 35 (traducción ARM):
   `Success / installed_and_launched`, con captura del menú.
5. Conclusión: el APK publicado es válido e instalable; el fallo en el S22
   Ultra solo puede venir de la copia local (descarga truncada) o del estado
   del teléfono en ese momento. Protocolo de verificación en la release.

## Iteraciones

### Iteración actual — Fase 5: sistemas, combate y personaje (COMPLETADA)

Sistemas lógicos y jugables terminados (informe completo en
docs/reportes/FASE_05_SISTEMAS.md). El visual sigue aplazado a propósito:
sin nuevas texturas, modelos, audio ni efectos de arte en esta fase.

### Iteración siguiente — mundo y texturas (prioridad principal)

- Mapa y terrenos: ampliar Valdeluz (caminos, plazas, entradas).
- Edificios y muros altos (interiores visibles con la oclusión existente).
- Vegetación (manigua) con LOD y materiales de viento.
- Texturas y materiales procedurales (NoiseTexture2D, GradientTexture2D,
  SurfaceTool): piedra caliza, madera envejecida, tejas criollas.
- Iluminación y sombras por perfil; agua (río/costa) y efectos ambientales.
- Optimización por perfil (Redmi 9C LOW 30 FPS / S22 Ultra HIGH 60 FPS).

### Iteraciones posteriores (orden tentativo)

1. Pulido visual del Machetero de la Sierra: el kit LÓGICO ya está completo y
   probado (Fase 5: combo de 3, pesado, Tajo de Guásima, Guardia del Bohío,
   Carga del Mambí, Corte de la Ceiba, Huracán de Machetes, pasivas Pulso de
   monte y Pies de piedra). Falta la capa visual/audio por habilidad (VFX,
   poses pulidas, ventana visual de la parada) — nombres canónicos según
   docs/diseno/02, sin volver a implementar la lógica.
2. Ampliar enemigos y combate (IA, tipos, respuesta de golpe).
3. Completar inventario y progresión (equipo, atributos, economía).
4. Nuevas misiones de la campaña (capítulos siguientes de Valdeluz).
5. Multijugador real: servidor dedicado + sincronización de partida
   (arquitectura en docs/18_MULTIJUGADOR.md; el lobby LAN ya funciona).
6. Nuevas clases (Bruja, Sepulturero…) con el estándar del Machetero.
7. Ampliar mundos (regiones nuevas tras el primer arco).

## Reglas del proyecto (se mantienen)

- No simular: ni multijugador online, ni FPS en hardware no medido, ni
  funciones que no existan (AGENTS.md §7).
- El emulador NO sustituye la prueba en dispositivo físico (protocolo en
  docs/16_COMPATIBILIDAD_ANDROID.md).
- Cada APK nuevo debe ser una mejora real sobre el anterior.
- Sin push directo a main; PRs apiladas por fase (ver docs/11).
