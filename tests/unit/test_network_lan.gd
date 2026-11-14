class_name TestNetworkLanLifecycle
extends GdUnitTestSuite
## Ciclo de vida del lobby LAN (Fase 5) — reproduce y verifica la corrección
## del error 20 (ERR_CANT_CREATE): crear sala → salir → crear OTRA sala
## inmediatamente, sin reiniciar. Además: puertos con respaldo, ip:puerto y
## señal de desconexión de jugador.


func _settle() -> void:
	## Da tiempo al poll de ENet para que las señales crucen.
	for index: int in 10:
		await get_tree().create_timer(0.05).timeout


func test_create_room_and_recreate_immediately() -> void:
	## EL caso del error 20: sala → abandono → sala otra vez, seguido.
	Network.leave_game()
	var error := Network.start_host("HostPrueba", "blue")
	assert_int(error).is_equal(OK)
	assert_bool(Network.players.has(1)).is_true()
	var port_first := Network.bound_port
	Network.leave_game()
	assert_int(Network.players.size()).is_equal(0)
	## La segunda sala se crea en el MISMO puerto (el anterior se liberó ya).
	var error2 := Network.start_host("HostPrueba", "blue")
	assert_int(error2).is_equal(OK)
	assert_int(Network.bound_port).is_equal(port_first)
	Network.leave_game()


func test_host_falls_back_when_port_busy() -> void:
	## Un servidor externo ocupa el 8080: la sala abre en el 8081 (respaldo).
	var blocker := ENetMultiplayerPeer.new()
	assert_int(blocker.create_server(Network.SERVER_PORT, 4)).is_equal(OK)
	Network.leave_game()
	var error := Network.start_host("HostPrueba", "blue")
	assert_int(error).is_equal(OK)
	assert_int(Network.bound_port).is_equal(Network.SERVER_PORT + 1)
	Network.leave_game()
	blocker.close()


func test_join_parses_ip_with_port() -> void:
	Network.leave_game()
	## Dirección válida con puerto custom: el cliente se CREA (OK). La
	## sincronización completa de 2 procesos reales vive en el smoke test
	## (tests/multiplayer), que levanta servidor + cliente de verdad.
	var error := Network.join_game("Cliente", "blue", "127.0.0.1:18099")
	assert_int(error).is_equal(OK)
	Network.leave_game()


func test_join_rejects_malformed_address() -> void:
	Network.leave_game()
	var error := Network.join_game("Cliente", "blue", "http://maquina")
	assert_int(error).is_equal(ERR_INVALID_PARAMETER)
	Network.leave_game()


func test_leave_clears_everything() -> void:
	Network.leave_game()
	assert_int(Network.start_host("Host", "blue")).is_equal(OK)
	Network.leave_game()
	assert_int(Network.players.size()).is_equal(0)
	(
		assert_bool(
			(
				Network.multiplayer.multiplayer_peer == null
				or (Network.multiplayer.multiplayer_peer is OfflineMultiplayerPeer)
			)
		)
		. is_true()
	)


func test_rejoin_after_connection_failure() -> void:
	## Conexión fallida (nadie escucha) → limpieza → host funciona después.
	Network.leave_game()
	var error := Network.join_game("Cliente", "blue", "127.0.0.1:18199")
	assert_int(error).is_equal(OK)
	await get_tree().create_timer(1.2).timeout
	## Tras el fallo la sesión quedó limpia (señal server_disconnected).
	assert_int(Network.players.size()).is_equal(0)
	## Y montar sala después de un fallo de conexión funciona.
	assert_int(Network.start_host("Host", "blue")).is_equal(OK)
	Network.leave_game()


func test_double_teardown_is_safe() -> void:
	Network.leave_game()
	Network.leave_game()
	assert_int(Network.start_host("Host", "blue")).is_equal(OK)
	Network.leave_game()
	Network.leave_game()
	assert_int(Network.players.size()).is_equal(0)
