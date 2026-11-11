# 08 — Dirección artística, recursos 3D, música y licencias

## Dirección de arte

**Estilo:** low-poly estilizado, formas suavizadas, personajes proporciones heroicas, materiales mates, paleta medieval fantástica, color por facción y VFX limpios. Debe recordar a un ARPG de vista elevada moderno sin imitar modelos ni interfaz de juegos existentes.

### Paleta

- Valdeluz: piedra marfil, madera nogal, telas azul profundo y oro viejo.
- Brumaclara: verde musgo, esmeralda suave, luz cálida y niebla ligera.
- Ghar: hierro oscuro, cobre, naranja de forja.
- Marjal: verde petróleo, violeta apagado y bioluminiscencia controlada.
- Costa: azul gris, arena y coral rojo.
- Sierra: gris frío, turquesa mineral y luz blanca.
- Bastión: obsidiana, carmesí, ceniza.

## Política para assets

No descargar indiscriminadamente. El artista/IA debe elegir packs que compartan estilo y probarlos en una escena de comparación antes de añadirlos al repo. Mantener un `assets/manifest.csv` con `asset_id, asset_name, author, source_url, source_version, license, license_url, checked_date, files_used, attribution, commercial_use, redistribution_notes, local_path`.

No incluir en el ZIP de diseño paquetes binarios de terceros. La IA deberá obtenerlos desde las páginas oficiales y colocar solo los archivos que los términos permitan incorporar al juego.

## Catálogo inicial revisado (11-11-2026)

### 1. KayKit Character Pack: Adventurers

- Fuente: https://godotengine.org/asset-library/asset/2129
- También: https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
- Contenido documentado: 4 personajes low-poly riggeados/animados, 75 animaciones, más de 25 armas/accesorios; atlas de textura 1024×1024 que puede evaluarse para downsample.
- Licencia que indica la página de Godot Asset Library: CC0, uso comercial permitido, atribución no obligatoria.
- Uso propuesto: prototipos de personajes base y animaciones. El equipo debe revisar el paquete descargado y conservar LICENSE/README.

### 2. KayKit Dungeon Remastered / Dungeon Pack

- Fuente: https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0
- Contenido: más de 200 módulos/props de mazmorra: paredes, suelo, escaleras, puertas, cofres, barriles, muebles, trampas y estandartes.
- Modelos low-poly, formatos GLTF/FBX/OBJ. El README declara aptitud para móviles y atlas 1024×1024 reducible a 128×128.
- Licencia: CC0 1.0 Universal, según README/LICENSE del repositorio.
- Uso propuesto: kit principal de interiores de mazmorras.

### 3. Quaternius RPG Character Pack

- Fuente: https://quaternius.com/packs/rpgcharacters.html
- La página de este paquete declara 6 personajes de fantasía riggeados, animados y texturizados y muestra CC0.
- Precaución: la licencia general de Quaternius fue actualizada y ahora existe Quaternius Asset License (QAL); cada pack puede tener condiciones particulares. Verificar la licencia incluida y la página de ese pack el día de descarga. No asumir que todo Quaternius es CC0.
- Uso propuesto: alternativas de NPC/clases si estilo y términos coinciden.

### 4. Quaternius Medieval Village Pack

- Fuente: https://quaternius.com/packs/medievalvillage.html
- La página del paquete muestra 44 modelos y CC0.
- Precaución: verificar el texto y archivo de licencia incluido; el sitio publica una QAL general actualizada en 2026. Si el paquete descargado incluye QAL, respetar la restricción de no redistribuir el asset suelto; uso integrado en el juego solo conforme a sus términos.
- Uso propuesto: edificios/props de ciudad, si coincide visualmente con KayKit.

### 5. Poly Haven

- Fuente de licencias: https://polyhaven.com/license
- La organización declara que todos sus HDRI, texturas y modelos son CC0 y permite uso comercial sin atribución obligatoria.
- Uso propuesto: texturas de terreno o assets puntuales. No llenar el juego de modelos realistas si rompen la coherencia low-poly.

### 6. Kenney

- Licencia general: https://kenney.nl/support
- Kenney indica que los assets publicados en sus páginas son public domain/CC0 y pueden usarse en proyectos comerciales sin atribución obligatoria. Revisar cada asset page y su LICENSE.
- No asumir que todos los bundles son gratis: el paquete All-in-1 puede ser de pago. Seleccionar paquetes individuales gratuitos compatibles con el estilo.

## Reglas de coherencia

1. Elige un pack de personajes principal, un pack de entorno principal y un pack de dungeon principal.
2. No combinar más de dos fuentes de personajes en el MVP.
3. Normaliza escala, pivots, orientación, skeleton y naming dentro de Godot; no modificar source files de terceros de forma que se pierda la licencia.
4. Mantener las texturas en atlas y reducir resolución si el aspecto aguanta.
5. Materiales sin superficies hiperrealistas mezcladas con low-poly cartoon.
6. No cambiar el estilo por región; cambiar la paleta/props, manteniendo proporciones.

## Música y audio

- Preferir música original encargada o CC0/CC-BY documentada.
- Fuentes candidatas de audio: Freesound (revisar licencia por archivo), OpenGameArt (revisar cada licencia), Kenney Audio (CC0 según página del asset).
- No extraer audio de YouTube, juegos comerciales o streams.
- Registrar compositores, licencias, atribuciones y fuente de cada archivo.

## Créditos

Créditos finales deben incluir los autores y licencias que requieren atribución, plugins, fuentes, música y contribuyentes reales. No inventar colaboradores. Los assets CC0 pueden acreditarse por cortesía aunque no sea obligatorio.
