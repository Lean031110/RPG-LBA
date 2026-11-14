# gdlint: ignore=max-public-methods
extends Node
## Autoload Network (Fase 5): lobby LAN con ENet de ciclo de vida ROBUSTO.
##
## CAUSA RAIZ del error 20 corregida (docs/18_MULTIJUGADOR.md):
##   ERR_CANT_CREATE (20) al crear sala tenía DOS causas reales:
##   1. EN ESCRITORIO: crear una segunda sala sin cerrar el peer anterior
##      (el puerto 8080 seguía enlazado). start_host/join ahora hacen
##      SIEMPRE teardown del peer previo antes de crear el nuevo.
##   2. EN ANDROID: los presets de exportación no pedían el permiso
##      INTERNET, así que el sandbox bloqueaba el socket UDP. Ambos presets
##      lo incluyen ahora (permissions/internet=true).
##   Además el puerto es configurable con respaldo (8080..8084): si el
##   preferido está ocupado por OTRA aplicación, la sala se abre en el
##   siguiente y se comunica al cliente (el campo IP acepta "ip:puerto").
##
## El resto del contrato público se mantiene (start_host/join_game/
## leave_game/players/server_disconnected) para no romper el menú ni las
## pruebas existentes.

signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal session_started(role: String, bound_port: int)

const SERVER_ADDRESS: String = "127.0.0.1"
const SERVER_PORT: int = 8080
const PORT_ATTEMPTS: int = 5
const MAX_PLAYERS: int = 10
const MAX_NICK_LENGTH := 24
const MAX_ADDRESS_LENGTH := 253

var players := {}
var player_info := {"nick": "host", "skin": Character.SkinColor.BLUE}
var bound_port := SERVER_PORT

var _session_active := false


func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.connected_to_server.connect(_on_connected_ok)


# ---------------------------------------------------------------------------
# Ciclo de vida de sesión (teardown SIEMPRE antes de crear)
# ---------------------------------------------------------------------------


func start_host(nickname: String, skin_color_str: String, preferred_port := SERVER_PORT) -> int:
	## Crea la sala. Devuelve OK o el código de error de ENet/Godot. Antes de
	## crear el peer nuevo, cierra y libera CUALQUIER sesión anterior (la causa
	## del error 20 en escritorio). Prueba hasta PORT_ATTEMPTS puertos.
	_teardown_session("rehost")
	player_info["nick"] = sanitize_nickname(nickname, "Host_" + str(multiplayer.get_unique_id()))
	player_info["skin"] = skin_str_to_e(skin_color_str)
	for attempt: int in PORT_ATTEMPTS:
		var port := preferred_port + attempt
		var peer := ENetMultiplayerPeer.new()
		var error := peer.create_server(port, MAX_PLAYERS)
		if error != OK:
			## Puerto ocupado (u otra causa): liberar este peer y probar el
			## siguiente. El último error se devuelve al final.
			peer.close()
			teardown_peer(peer)
			if attempt == PORT_ATTEMPTS - 1:
				push_warning(
					(
						"Network: no se pudo abrir ningún puerto %d..%d (código %d = ERR_CANT_CREATE si 20). "
						% [preferred_port, port, error]
					)
				)
				return error
			continue
		peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.multiplayer_peer = peer
		_session_active = true
		bound_port = port
		## El anfitrión SIEMPRE ocupa el hueco 1 (también en headless: el
		## lobby es el mismo; el guardado antiguo era un artefacto de la
		## plantilla y dejaba la lista vacía en CI).
		players[1] = player_info.duplicate()
		player_connected.emit(1, players[1])
		session_started.emit("server", bound_port)
		return OK
	return ERR_CANT_CREATE


func join_game(nickname: String, skin_color_str: String, address: String = SERVER_ADDRESS) -> int:
	## Se une a una sala por IP o "ip:puerto". Devuelve OK o el error (la
	## conexión fallida llega además por la señal del multiplayer).
	_teardown_session("rejoin")
	var parsed := _parse_address(address)
	if parsed.is_empty():
		return ERR_INVALID_PARAMETER
	player_info["nick"] = sanitize_nickname(nickname, "Player_" + str(multiplayer.get_unique_id()))
	player_info["skin"] = skin_str_to_e(skin_color_str)
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(parsed["address"], parsed["port"])
	if error != OK:
		teardown_peer(peer)
		return error
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	_session_active = true
	bound_port = parsed["port"]
	session_started.emit("client", bound_port)
	return OK


func leave_game() -> void:
	## Salir de la sala (anfitrión o invitado) liberando el peer YA: la sala
	## puede volver a crearse inmediatamente sin reiniciar la aplicación.
	_teardown_session("leave")


func _teardown_session(_reason: String) -> void:
	## Cierre total y ordenado de cualquier sesión previa: peer cerrado,
	## desasignado del multiplayer y lista de jugadores limpia. Idempotente.
	var peer := multiplayer.multiplayer_peer
	if peer != null:
		teardown_peer(peer)
		multiplayer.multiplayer_peer = null
	var had_session := _session_active or not players.is_empty()
	_session_active = false
	players.clear()
	if had_session:
		## Aviso a la UI para que refresque (la lista queda vacía).
		server_disconnected.emit()


func teardown_peer(peer: MultiplayerPeer) -> void:
	## Cierra y libera un peer ENet (close + desreferencia para que el socket
	## suelte el puerto de inmediato).
	if peer == null:
		return
	if peer is ENetMultiplayerPeer:
		(peer as ENetMultiplayerPeer).close()
	peer.close()


func _parse_address(address: String) -> Dictionary:
	## Acepta "192.168.1.42", "192.168.1.42:8081" y valida el formato.
	var clean := sanitize_address(address)
	if clean.is_empty():
		return {}
	if ":" in clean:
		var parts := clean.split(":")
		if parts.size() != 2 or not parts[1].is_valid_int():
			return {}
		var port := int(parts[1])
		if port < 1 or port > 65535:
			return {}
		return {"address": parts[0], "port": port}
	return {"address": clean, "port": SERVER_PORT}


# ---------------------------------------------------------------------------
# Señales del multiplayer
# ---------------------------------------------------------------------------


func _on_connected_ok() -> void:
	var peer_id := multiplayer.get_unique_id()
	players[peer_id] = player_info.duplicate()
	player_connected.emit(peer_id, players[peer_id])
	_register_player.rpc_id(1, player_info.duplicate())


func _on_player_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
	for peer_id: int in players:
		_sync_registered_player.rpc_id(id, peer_id, players[peer_id])


@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	if not (new_player_info is Dictionary):
		return
	var new_player_id := multiplayer.get_remote_sender_id()
	if new_player_id == 0:
		return
	if players.has(new_player_id):
		return
	var sanitized := sanitize_player_info(new_player_info, "Player_" + str(new_player_id))
	players[new_player_id] = sanitized
	player_connected.emit(new_player_id, sanitized)
	_sync_registered_player.rpc(new_player_id, sanitized)


func _on_player_disconnected(id: int) -> void:
	## Un jugador se fue: la lista se actualiza y la UI se entera (señal nueva
	## de la Fase 5; antes la lista se quedaba con el fantasma).
	if players.erase(id):
		player_disconnected.emit(id)


func _on_connection_failed() -> void:
	_teardown_session("connection_failed")


func _on_server_disconnected() -> void:
	_teardown_session("server_disconnected")


@rpc("authority", "reliable")
func _sync_registered_player(peer_id: int, registered_player_info: Dictionary) -> void:
	if multiplayer.is_server():
		return
	if players.has(peer_id):
		return
	var sanitized := sanitize_player_info(registered_player_info, "Player_" + str(peer_id))
	players[peer_id] = sanitized
	player_connected.emit(peer_id, sanitized)


# ---------------------------------------------------------------------------
# Validación (contrato público intacto)
# ---------------------------------------------------------------------------


func skin_str_to_e(s: Variant) -> Character.SkinColor:
	match str(s).strip_edges().to_lower():
		"blue":
			return Character.SkinColor.BLUE
		"yellow":
			return Character.SkinColor.YELLOW
		"green":
			return Character.SkinColor.GREEN
		"red":
			return Character.SkinColor.RED
		_:
			return Character.SkinColor.BLUE


func sanitize_player_info(info: Dictionary, fallback_nick: String) -> Dictionary:
	return {
		"nick": sanitize_nickname(str(info.get("nick", "")), fallback_nick),
		"skin": sanitize_skin_value(info.get("skin", Character.SkinColor.BLUE)),
	}


func sanitize_nickname(nickname: String, fallback: String) -> String:
	var clean := ""
	var last_was_space := false
	for i: int in range(nickname.length()):
		var codepoint := nickname.unicode_at(i)
		if codepoint <= 31 or codepoint == 127:
			if not last_was_space:
				clean += " "
				last_was_space = true
			continue
		var character := nickname.substr(i, 1)
		if character == " ":
			if last_was_space:
				continue
			last_was_space = true
		else:
			last_was_space = false
		clean += character
	clean = clean.strip_edges()
	if clean.is_empty():
		clean = fallback.strip_edges()
	if clean.length() > MAX_NICK_LENGTH:
		clean = clean.substr(0, MAX_NICK_LENGTH).strip_edges()
	if clean.is_empty():
		clean = "Player"
	return clean


func sanitize_address(address: String) -> String:
	var clean := address.strip_edges()
	if clean.is_empty():
		return SERVER_ADDRESS
	if clean.length() > MAX_ADDRESS_LENGTH:
		return ""
	if clean.contains("://") or clean.contains("/") or clean.contains("\\"):
		return ""
	return clean


func sanitize_skin_value(value: Variant) -> Character.SkinColor:
	if value is int:
		var as_int := int(value)
		if (
			as_int
			in [
				Character.SkinColor.BLUE, Character.SkinColor.YELLOW, Character.SkinColor.GREEN, Character.SkinColor.RED
			]
		):
			return value
		return Character.SkinColor.BLUE
	return skin_str_to_e(str(value))
