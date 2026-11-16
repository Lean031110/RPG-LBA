# ADR-012 — Keystore de depuración: alcance y prohibición de uso en producción

**Fecha:** 2026-11-16 · **Estado:** Aceptada · **Evidencia:** Fase 3B
(`reportes/FASE_03B_APK_DEBUG_FIRMA_VERIFICACION.md`), `export_presets.cfg`
(líneas 47–53 y 101+), `build/android/README.md`.

## Contexto

El repositorio versiona `build/android/rpglba-debug.keystore` (alias
`rpglba-debug`, credenciales de depuración estándar visibles en
`export_presets.cfg`). Es un keystore de DEPURACIÓN generado con keytool
de OpenJDK durante la Fase 3B para poder distribuir APK de prueba con
autofirma reproducible.

## Decisión

1. `rpglba-debug.keystore` es EXCLUSIVAMENTE de depuración: sirve para
   APK debug verificables en CI (instalación en emuladores) y pruebas
   internas. Android trata los debug keystores con credenciales públicas
   por convención; su presencia en un repo open source no es un secreto
   comprometido.
2. PROHIBIDO reutilizarlo como clave de producción/release: toda release
   distribuible en Google Play requiere un keystore de release distinto,
   generado por el propietario, NUNCA commiteado al repositorio, y
   gestionado como secreto.
3. La firma de producción es tarea de la Fase 9 (RC) con aprobación
   humana explícita; `18_GOOGLE_PLAY_RELEASE_PIPELINE.md` documenta el
   pipeline objetivo.
4. Ningún otro credencial (tokens, claves privadas, secrets de
   publicación) puede versionarse. La CI usa exclusivamente secretos de
   GitHub configurados por el propietario (hoy: ninguno necesario; los
   workflows actuales no requieren secretos).

## Consecuencias

- La política de firma queda explícita y auditables en este ADR.
- Si en el futuro se filtra el debug keystore, el daño se limita a las
  instalaciones de prueba (no afecta releases).
