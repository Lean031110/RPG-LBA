extends Node
## Headless multiplayer smoke driver (CI reproducible; Fase 5).
## Escenario REAL del lobby LAN ejecutado con procesos independientes:
##
##   server: crea sala → espera 2 jugadores → uno se va → la lista se
##           actualiza → cierra sala → crea OTRA sala inmediatamente (el caso
##           del error 20) → espera al cliente de nuevo → PASS.
##   client: se une → confirma que se ve a sí mismo y al anfitrión → sale de
##           la sala → se vuelve a unir a la SEGUNDA sala → PASS.
##
## Usa el autoload Network real (mismo código que el menú MULTIJUGADOR), no
## una simulación. Seleccionado por variable de entorno:
##   LBA_MP_ROLE=server|client  ·  LBA_MP_JOIN_DELAY (s)

const POLL_TIMEOUT_SEC := 30.0
const CLIENT_LINGER_SEC := 3.0
const SERVER_ROOM2_WAIT_SEC := 18.0

var _role := ""
var _join_delay := 1.0
var _players_seen := {}
var _disconnections_seen := 0


func _ready() -> void:
	_role = OS.get_environment("LBA_MP_ROLE").to_lower()
	var delay_str := OS.get_environment("LBA_MP_JOIN_DELAY")
	if delay_str.is_valid_float():
		_join_delay = maxf(0.0, delay_str.to_float())
	Network.player_connected.connect(_on_player_connected)
	Network.player_disconnected.connect(_on_player_disconnected)
	if _role == "server":
		await _run_server_scenario()
	elif _role == "client":
		await get_tree().create_timer(_join_delay).timeout
		await _run_client_scenario()
	else:
		push_error("LBA_MP_ROLE no reconocido: " + _role)
		get_tree().quit(2)


func _on_player_connected(peer_id: int, _info: Dictionary) -> void:
	_players_seen[peer_id] = true


func _on_player_disconnected(_peer_id: int) -> void:
	_disconnections_seen += 1


# ---------------------------------------------------------------------------
# Servidor: sala → 2 jugadores → salida → sala NUEVA sin reiniciar
# ---------------------------------------------------------------------------


func _run_server_scenario() -> void:
	# 1) Crear la sala.
	var error := Network.start_host("ServidorCI", "blue")
	if error != OK:
		_report("server", "FAIL", "host_error_%d" % error)
		return
	print("LBA_MP_INFO role=server room=1 port=%d" % Network.bound_port)

	# 2) Esperar a los 2 jugadores (el anfitrión ya ocupa el hueco 1).
	var timeout := POLL_TIMEOUT_SEC
	while Network.players.size() < 3 and timeout > 0.0:
		await get_tree().create_timer(0.25).timeout
		timeout -= 0.25
	if Network.players.size() < 3:
		_report("server", "FAIL", "players_%d_of_3" % Network.players.size())
		return
	print("LBA_MP_INFO role=server players=%d" % Network.players.size())

	# 3) El cliente A anuncia su salida (canal de humo: ver su log); esperar
	#    la desconexión real con la lista actualizada (señal nueva Fase 5).
	timeout = 8.0
	while _disconnections_seen < 1 and timeout > 0.0:
		await get_tree().create_timer(0.25).timeout
		timeout -= 0.25
	if _disconnections_seen < 1:
		_report("server", "FAIL", "no_disconnection_signal")
		return
	if Network.players.size() != 2:
		_report("server", "FAIL", "list_stale_%d" % Network.players.size())
		return
	print("LBA_MP_INFO role=server player_left players=%d" % Network.players.size())

	# 4) Cerrar la sala y crear OTRA inmediatamente (el caso del error 20).
	Network.leave_game()
	error = Network.start_host("ServidorCI", "blue")
	if error != OK:
		_report("server", "FAIL", "rehost_error_%d" % error)
		return
	print("LBA_MP_INFO role=server room=2 port=%d" % Network.bound_port)

	# 5) El cliente vuelve a entrar en la sala 2.
	timeout = SERVER_ROOM2_WAIT_SEC
	var rejoined := false
	while timeout > 0.0:
		await get_tree().create_timer(0.25).timeout
		timeout -= 0.25
		if Network.players.size() >= 2:
			rejoined = true
			break
	if not rejoined:
		_report("server", "FAIL", "no_rejoin_room2")
		return
	_report("server", "PASS", "rooms_2_players_%d" % Network.players.size())


# ---------------------------------------------------------------------------
# Cliente: unirse → verse con el anfitrión → salir → reentrar a la sala 2
# ---------------------------------------------------------------------------


func _run_client_scenario() -> void:
	# 1) Unirse a la sala 1.
	var error := Network.join_game("ClienteCI", "blue", "127.0.0.1")
	if error != OK:
		_report("client", "FAIL", "join_error_%d" % error)
		return
	var timeout := POLL_TIMEOUT_SEC
	while not _players_seen.has(1) and timeout > 0.0:
		await get_tree().create_timer(0.25).timeout
		timeout -= 0.25
	if not _players_seen.has(1):
		_report("client", "FAIL", "host_not_listed")
		return
	print("LBA_MP_INFO role=client joined_room=1 players=%d" % Network.players.size())

	# 2) Pausa para que el servidor complete su comprobación de 3 jugadores.
	await get_tree().create_timer(CLIENT_LINGER_SEC).timeout

	# 3) Salir de la sala (la lista del anfitrión debe refrescarse sola).
	Network.leave_game()
	if not Network.players.is_empty():
		_report("client", "FAIL", "leave_did_not_clear")
		return
	print("LBA_MP_INFO role=client left_room=1")

	# 4) El servidor crea la sala 2; reentrar sin reiniciar la app.
	await get_tree().create_timer(3.0).timeout
	error = Network.join_game("ClienteCI", "blue", "127.0.0.1")
	if error != OK:
		_report("client", "FAIL", "rejoin_error_%d" % error)
		return
	timeout = POLL_TIMEOUT_SEC
	while not _players_seen.has(1) and timeout > 0.0:
		await get_tree().create_timer(0.25).timeout
		timeout -= 0.25
	if not _players_seen.has(1):
		_report("client", "FAIL", "rejoin_host_not_listed")
		return
	print("LBA_MP_INFO role=client rejoined_room=2 players=%d" % Network.players.size())
	await get_tree().create_timer(2.0).timeout
	_report("client", "PASS", "two_rooms")


func _report(role: String, status: String, reason: String) -> void:
	print("LBA_MP_RESULT role=%s status=%s reason=%s" % [role, status, reason])
	get_tree().quit(0 if status == "PASS" else 1)
