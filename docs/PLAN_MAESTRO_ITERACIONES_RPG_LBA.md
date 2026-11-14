# Plan Maestro de Iteraciones — RPG LBA

Documento vivo: refleja el estado REAL del proyecto y las prioridades de las
próximas entregas. Se actualiza al cierre de cada iteración. La fecha de corte
de esta edición es la iteración 4C-visual (v0.1.1).

## Estado actual (v0.1.1, iteración 4C-visual)

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

### Iteración actual — 4C-visual (COMPLETADA en esta entrega)

1. [x] Diagnosticar el APK ARM64 (forense + evidencia CI; causa no estructural).
2. [x] Mantener la Universal funcional (misma estructura; versionCode 2).
3. [x] Presentación cinematográfica con emblema oficial, salto y transición.
4. [x] Icono Android adaptativo + heredado + boot splash de marca.
5. [x] Rediseño del menú principal (composición, jerarquía, animación).
6. [x] Apartado MULTIJUGADOR visible con pantalla propia y honesta.
7. [x] Unificación visual de todas las pantallas (ajustes, créditos, pausa,
       derrota, panel de clase) bajo ArpgUiTheme.
8. [x] HUD: pausa táctil, recargas radiales, realce de pulsación.
9. [x] Cámara: oclusión reversible con histéresis; muros visibles.
10. [x] APK v0.1.1 (ARM64 + Universal), verificación estática y de emulador.

### Iteración siguiente — mundo y texturas (prioridad principal)

- Mapa y terrenos: ampliar Valdeluz (caminos, plazas, entradas).
- Edificios y muros altos (interiores visibles con la oclusión existente).
- Vegetación (manigua) con LOD y materiales de viento.
- Texturas y materiales procedurales (NoiseTexture2D, GradientTexture2D,
  SurfaceTool): piedra caliza, madera envejecida, tejas criollas.
- Iluminación y sombras por perfil; agua (río/costa) y efectos ambientales.
- Optimización por perfil (Redmi 9C LOW 30 FPS / S22 Ultra HIGH 60 FPS).

### Iteraciones posteriores (orden tentativo)

1. Terminar el Machetero de la Sierra: 5 habilidades con efectos reales
   (Corte de Sierra, Barrido del Machete, Guardia de Acero, Embestida del
   Cimarrón, Furia de la Sierra), definitiva, animaciones y estadísticas.
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
