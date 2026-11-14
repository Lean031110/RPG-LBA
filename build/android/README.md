# Autofirma debug de RPG LBA (`rpglba-debug.keystore`)

## Qué es

Clave **autofirmada** (self-signed) de desarrollo que firma el APK debug del
proyecto con herramientas 100 % de código abierto, tal como pidió el
responsable para esta fase:

- **Generador:** `keytool` de OpenJDK (licencia GPL-2.0-with-classpath-exception,
  https://openjdk.org — código abierto).
- **Formato:** PKCS#12, RSA 2048, validez 9999 días.
- **Sujeto del certificado:** `CN=RPG LBA Debug, O=LBA Games, C=CU`.
- **Huella SHA-256 del certificado:**
  `ED:F1:06:6F:37:A3:D1:32:1B:E8:A1:58:42:66:FE:AE:64:D9:5D:9F:A9:E8:6E:A1:A0:FE:EF:A3:57:0B:BB:AB`

## Credenciales (públicas a propósito)

| Campo | Valor |
|---|---|
| Alias | `rpglba-debug` |
| Contraseña del keystore y de la clave | `android` |

Estas credenciales son **públicas por diseño**, igual que el keystore debug
universal de Android (`android`/`android` de AOSP) o el que el editor de Godot
trae embebido. Una clave de desarrollo no protege nada: su única función es
que Android acepte instalar el APK y que **todas las ejecuciones de CI firmen
con la misma identidad**, de modo que un APK nuevo se pueda instalar encima
del anterior sin desinstalar (Android compara firmas al actualizar).

## Por qué se versiona en el repo si `*.keystore` estaba ignorado

Regla del repositorio (AGENTS.md §4): “no guardar tokens, passwords ni
secretos en el repo”. Esto **no** es un secreto: es una clave de desarrollo
con credenciales publicadas en este mismo archivo, verificable por cualquiera.
La ignorancia de `*.keystore` se mantiene para TODA otra clave (en particular
cualquier keystore de release, que SÍ es un secreto real y debe vivir fuera
del repo o en secretos de CI); este archivo es la única excepción, con
justificación, y el preset de export la referencia explícitamente.

## Cómo se usa

`export_presets.cfg` → preset `Android Debug`:

```
keystore/debug="build/android/rpglba-debug.keystore"
keystore/debug_user="rpglba-debug"
keystore/debug_password="android"
```

Godot resuelve la ruta relativa al proyecto y firma el APK con `apksigner`
(build-tools del SDK de Android) durante `--export-debug`.

## Cómo regenerarla / rotarla (si algún día hace falta)

```bash
keytool -genkeypair \
  -keystore build/android/rpglba-debug.keystore \
  -storetype PKCS12 -storepass android -keypass android \
  -alias rpglba-debug -keyalg RSA -keysize 2048 -validity 9999 \
  -dname "CN=RPG LBA Debug, O=LBA Games, C=CU"
```

Ojo: rotar la clave cambia la firma y Android exigirá desinstalar el APK
anterior. No rotar sin necesidad.

## Advertencia

**Nunca firmar una build pública/release con esta clave.** Cualquiera puede
regenerar una clave equivalente con credenciales idénticas; para producción se
usará un keystore privado real (guardado fuera del repo) cuando el proyecto
llegue a distribución pública.
