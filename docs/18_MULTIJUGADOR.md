# 18 — Multijugador: estado real y camino al online

Estado a Fase 5. Este documento es el registro honesto de qué existe, qué no,
y qué hace falta. Diseño de fondo: [05_MULTIJUGADOR_Y_SERVIDOR](05_MULTIJUGADOR_Y_SERVIDOR.md).

## Fase 5: causa raíz del error 20 y corrección

El error reportado en pantalla era:

> «No se pudo abrir el puerto 8080 (¿otra sala activa?). Código: 20»

`20` es `ERR_CANT_CREATE`, el código que devuelve
`ENetMultiplayerPeer.create_server()` cuando no puede enlazar el socket.
Había DOS causas reales, ambas corregidas:

1. **EN ESCRITORIO/REENTRADA: peer anterior sin liberar.** Al crear una sala,
   cambiar de pantalla sin pulsar "Abandonar sala" y volver a crear otra, el
   peer ENet anterior seguía vivo con el puerto 8080 enlazado; el nuevo
   `create_server(8080)` fallaba con 20. Corrección: `start_host()` y
   `join_game()` hacen SIEMPRE teardown completo del peer previo (close +
   desasignación del multiplayer + limpieza de la lista) antes de crear el
   nuevo; `leave_game()` libera el puerto de inmediato.
2. **EN ANDROID: falta del permiso INTERNET.** Los presets de exportación no
   pedían `permissions/internet`, así que el sandbox de Android bloqueaba la
   creación del socket UDP con el mismo código 20. Corrección: ambos presets
   (ARM64 y Universal) incluyen `permissions/internet=true`.

Además, como defensa en profundidad:

- **Puertos con respaldo**: si el 8080 está ocupado por OTRA aplicación, la
  sala abre en el 8081 (hasta 8084) y la pantalla muestra `IP:puerto` real.
- **Campo IP con puerto**: al unirse se acepta `192.168.1.42` y
  `192.168.1.42:8081`.
- **Señal `player_disconnected`**: la lista de jugadores se actualiza cuando
  alguien se marcha (antes se quedaba el fantasma).
- **El anfitrión se registra también en headless** (el guardado antiguo era
  un artefacto de la plantilla heredada).

Verificación automatizada (todo local, sin dispositivos):

- `tests/unit/test_network_lan.gd`: crear → salir → crear otra sala en el
  mismo puerto sin reiniciar; respaldo de puerto con el 8080 ocupado;
  parseo de `ip:puerto`; rechazo de direcciones malformadas; limpieza tras
  fallo de conexión; doble teardown seguro.
- `tests/multiplayer` (smoke de 2 procesos headless): servidor + 2 clientes
  reales → 3 jugadores listados → un cliente sale (lista actualizada por
  señal) → el servidor cierra y crea OTRA sala inmediatamente → el cliente
  reentra. Es exactamente el escenario "crear → unirse → salir → volver a
  crear sin reiniciar la aplicación".

Prueba física pendiente (documentada): dos teléfonos Android reales en la
misma red WiFi con los APK de esta fase; el flujo es idéntico al del smoke.

## Qué existe HOY y funciona

Pantalla MULTIJUGADOR accesible desde el menú principal (`scenes/arpg/menu/multiplayer_menu.tscn`)
con:

- **Crear partida (LAN)**: abre un servidor ENet real (UDP 8080) en el
  teléfono/PC del anfitrión usando el autoload `Network`
  (`scripts/autoload/network.gd`). Muestra la IP local para que otro
  dispositivo se una.
- **Unirse por IP (LAN)**: cliente ENet real; ambos dispositivos deben estar
  en la misma red WiFi.
- **Lista de jugadores sincronizada**: registro de jugadores por RPC
  (`_register_player` / `_sync_registered_player`) con sanitización de
  nombres. Funciona entre dos instancias reales.
- **Abandonar sala**, estado de conexión, nombre de sala y contador de
  jugadores.

Qué NO existe (marcado así en la propia pantalla, sin botones que aparenten
funcionar):

- Servidor de listas / matchmaking por internet.
- Sincronización de la partida ARPG (jugadores, enemigos, daño, misiones).
- Salas persistentes, cuentas, reconexión.

## Qué falta para el multijugador online completo

1. **Servidor dedicado autoritativo** (decisión ya tomada en docs/05):
   Godot headless con feature `dedicated_server`, desplegado en un host
   público. GitHub Actions NO puede alojar partidas en vivo.
2. **Registro de salas**: servicio ligero (HTTP) que liste partidas abiertas
   con nombre, jugadores y estado; el cliente lo consulta en la pantalla de
   lista.
3. **Sincronización de gameplay**:
   - Serialización del estado del jugador (posición/acción/salud) a ~10–20 Hz
     con interpolación en el cliente.
   - Enemigos y daño autoritativos en el servidor (el cliente nunca decide
     daño propio).
   - Spawns de pickups y progreso de misión replicados.
4. **Salas y ciclo de vida**: crear/unirse/abandonar con límite de jugadores,
   migración de anfitrión NO requerida (servidor dedicado).
5. **Conexión/desconexión limpias**: timeouts, reconexión con re-join de sala,
   limpieza de entidades del jugador caído.
6. **Persistencia**: cuentas simples + personajes guardados en el servidor
   (ver docs/05 §Mundos y zonas).
7. **Infraestructura**: dominio/hosts, TLS para el login/listas, monitoreo y
   backups. Coste de operación a decidir por el propietario.

## Próximo incremento recomendado

1. Dos instancias locales (PC + teléfono en la misma WiFi) crean y unen una
   sala desde la pantalla actual: validar el flujo real de lobby.
2. Sincronizar SOLO posición y animación de dos Macheteros en el prototipo
   (sin combate): prueba de concepto de replicación.
3. Después, decidir hosting del servidor dedicado y continuar por la lista.
