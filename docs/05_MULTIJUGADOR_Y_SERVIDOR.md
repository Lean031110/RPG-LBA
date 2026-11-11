# 05 — Arquitectura multijugador y persistencia

## Decisión

**Servidor dedicado autoritativo**. No usar peer-host para mundos online. El servidor decide estado verdadero; los clientes solo envían acciones e inputs.

## Topología

- Cliente Godot Android/desktop.
- Servidor Godot headless con la misma base de código y un modo/feature `dedicated_server`.
- Transporte inicial: ENet/UDP del High-Level Multiplayer API de Godot.
- Puerto configurable; valor de desarrollo inicial documentado en `server/config`.
- Para LAN, el cliente conecta a IP local y puerto del servidor PC.
- Para online, servidor público y servicio de login/realm directory serán tareas posteriores. GitHub Actions no aloja partidas en vivo.

## Mundos y zonas

Identificadores:
- `account_id`: cuenta abstracta si login está implementado.
- `character_id`: personaje persistente.
- `world_id`: realm/mundo elegido.
- `zone_id`: región actual.
- `instance_id`: instancia de mazmorra/evento.

Primera versión: un proceso servidor, un `world_id`, zonas cargables y una instancia activa de mazmorra por grupo. Después, el manager de mundo puede lanzar procesos/containers separados para realms o zonas con alta demanda. No dividir en microservicios antes de tener mediciones.

## Capacidad

- Prueba inicial: 2 clientes.
- MVP: 4 jugadores por party y zona.
- Objetivo de diseño posterior: hasta 10 por instancia de zona si benchmark lo permite, alineado con la plantilla base que anuncia hasta 10.
- No prometer 50/100/1000 jugadores ni un MMO a escala comercial sin pruebas de carga y servidor adecuado.

## Autoridad y seguridad

El servidor valida:
- identidad y peer_id;
- rate limits y tamaño de paquetes;
- ownership de personaje/objetos;
- zona, distancia y línea de visión si la mecánica lo necesita;
- cooldown, coste de recurso y estado vivo;
- equipo permitido y requisitos;
- inventario y slots libres;
- nivel/estado de quest;
- daño, crítico, estado alterado y muerte;
- roll de loot y moneda;
- operación de trade como transacción atómica.

Cliente nunca envía `damage=9999`, `item_count=100`, `gold=...` como verdad. Cliente envía `attack_request(ability_id, target_or_direction, input_sequence)`. Servidor recalcula.

## Sincronización

- Inputs/acciones discretas validadas por servidor.
- Movimiento: snapshot periódico; interpolación de entidades remotas; predicción local limitada y reconciliación para el propio jugador.
- Inventario, quest, moneda y trade: mensajes fiables y estado versionado.
- Efectos cosméticos pueden ser no fiables y reconstruibles.
- Usar IDs estables y secuencias para deduplicar requests.
- No sincronizar cada hueso de animación; replicar estado/acción y reproducir animaciones localmente.

## Tick y rendimiento de red

Comenzar probando 15–20 ticks/s de simulación y snapshots de movimiento alrededor de 10–15 Hz, ajustables por perfil/latencia. Son valores iniciales de ingeniería, no garantías. Medir CPU, tráfico, jitter, pérdida y sensación de control. No mandar transform completo con reliable cada frame.

## Party, guild y social

- Party cap 4, invitación, aceptar/rechazar, líder, expulsión, abandonar.
- Objetivos de misión compartibles cuando el jugador está en zona y grupo válido.
- Revivir a aliado con canalización, interrupción y cooldown.
- Guild cap 20 en fase inicial si se implementa; roles líder/oficial/miembro.
- Chat texto de grupo y zona con rate limit, longitud limitada, bloqueo/reportes; desactivar chat global hasta tener moderación básica.
- Trade bilateral: ambos ven oferta final, confirman, servidor bloquea items, valida de nuevo y hace commit atómico.

## Persistencia

Desarrollo:
- SQLite en servidor para una instancia local y datos pequeños.
- Escrituras por transacciones, backups periódicos, schema version y migraciones.
- No escribir una DB compartida en NFS/Dropbox ni guardar datos online dentro del repo.

Producción/múltiples procesos:
- PostgreSQL recomendado.
- `world_id` en datos persistentes.
- Guardado de personaje, inventario, progreso, quest, guild y economía.
- Cache de sesión en memoria; checkpoint/flush por evento y desconexión segura.

## Desconexión y recuperación

- Si cae cliente, mantener estado por periodo corto y luego logout.
- Si cae servidor, el último commit persistente debe preservar inventario/quest/economía; no prometer recuperación de combate instantáneo.
- El servidor registra transacciones críticas con identificadores idempotentes.
- No guardar cada frame en DB.

## Modos

- Offline: `OfflineMultiplayerPeer` o una capa de autoridad local, usando mismos servicios.
- LAN/Online: `ENetMultiplayerPeer` cliente a servidor dedicado.
- No hacer que el primer jugador conectado sea automáticamente dueño de las reglas del mundo.

## Operación

El servidor escucha solo en interfaces previstas. En LAN no exponer a Internet. Online requiere firewall, TLS/HTTPS para login, protección DDoS del proveedor, logs sin secretos, actualizaciones y gestión de datos. ENet usa UDP; documentar los puertos que realmente configure la aplicación.
