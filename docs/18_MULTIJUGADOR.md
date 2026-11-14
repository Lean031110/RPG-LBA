# 18 — Multijugador: estado real y camino al online

Estado a v0.1.1 (iteración 4C). Este documento es el registro honesto de qué
existe, qué no, y qué hace falta. Diseño de fondo: [05_MULTIJUGADOR_Y_SERVIDOR](05_MULTIJUGADOR_Y_SERVIDOR.md).

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
