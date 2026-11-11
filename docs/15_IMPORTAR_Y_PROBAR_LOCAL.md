# 15 — Cómo importar y probar el resultado en tu PC

## Antes de descargar

- Mantener Godot Standard 4.7.2.
- Tener espacio para el proyecto, paquetes de assets y caché `.godot`.
- La CPU Pentium B950 y 12 GB RAM pueden limitar la fluidez del editor 3D. Las compilaciones/CI se ejecutan en GitHub; la PC local se usa para revisión y prueba, no para compilar cada build.

## Descargar desde GitHub

1. Esperar que la IA abra PR y que CI quede verde.
2. Revisar el PR y sus logs. No aceptar solo una captura del agente.
3. Una vez integrado, abrir Releases o Actions → Artifacts y descargar el ZIP de proyecto o el APK debug.
4. Si se descarga el código fuente, extraerlo en una carpeta nueva.
5. Abrir Godot Project Manager → Import → seleccionar la carpeta donde está `project.godot`.
6. Esperar la primera importación de recursos.
7. Si la importación se completa sin errores, pulsar F6 para la escena principal configurada o F5 para el proyecto.

## Qué no copiar

No copiar `.godot/`, cachés temporales ni export credentials de otra máquina. No reemplazar `project.godot` a mano sin una copia del proyecto.

## APK

- Descargar el artifact `RPG-LBA-Android-debug` de una ejecución exitosa.
- Instalar solo en dispositivos de prueba.
- El APK debug no es una versión final firmada para distribución pública.
- Registrar modelo del teléfono, variante de RAM, versión Android y renderer al probar.

## Si Godot muestra errores

1. No borrar carpetas al azar.
2. Guardar captura y salida de Output.
3. Abrir el log de CI de la misma commit.
4. Comparar hash/commit local con el artifact.
5. Informar archivo y línea exacta al agente.
6. Crear issue o comentario en el PR; no editar directamente `main`.

## Criterio de prueba humana

Probar menú, creación de personaje, joystick, ataque, habilidades, inventario, diálogo, misión, zona, muerte/respawn, party y reconexión. La simulación headless no reemplaza esta prueba.
