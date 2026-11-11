extends Node
## Headless multiplayer smoke driver (CI reproducible).
## Selected via environment variable:
##   LBA_MP_ROLE=server -> runs the real level, counts distinct player registrations
##                         via the Network.player_connected signal (no polling race),
##                         waits for clients to finish, then reports.
##   LBA_MP_ROLE=client -> runs the real level, joins 127.0.0.1 after LBA_MP_JOIN_DELAY
##                         seconds, confirms 2 registered + 2 spawned, lingers briefly,
##                         then reports.
## The real level scene is instantiated unchanged; this driver only observes.
## Not part of gameplay code.
##
## Known expected noise on clients: the template auto-hosts when headless, so a client
## whose port 8080 is already taken logs one benign "Couldn't create an ENet host" error.

const LEVEL_SCENE := "res://scenes/level/level.tscn"
const SERVER_ADDRESS := "127.0.0.1"
const POLL_TIMEOUT_SEC := 30.0
const EXPECTED_PLAYERS := 2
const CLIENT_LINGER_SEC := 4.0
const SERVER_GRACE_SEC := 15.0

var _role := ""
var _join_delay := 1.0
var _level: Node = null
var _distinct_registered := {}
var _peak_registered := 0
var _peak_spawned := 0


func _ready() -> void:
	_role = OS.get_environment("LBA_MP_ROLE").to_lower()
	var delay_str := OS.get_environment("LBA_MP_JOIN_DELAY")
	if delay_str.is_valid_float():
		_join_delay = maxf(0.0, delay_str.to_float())
	_level = load(LEVEL_SCENE).instantiate()
	add_child(_level)

	if _role == "server":
		Network.player_connected.connect(_on_player_connected)
		await _run_server_scenario()
	elif _role == "client":
		await get_tree().create_timer(_join_delay).timeout
		var error = Network.join_game("CI_Client", "blue", SERVER_ADDRESS)
		if error != null and error != OK:
			print("LBA_MP_RESULT role=client status=FAIL reason=join_error_%s" % str(error))
			get_tree().quit(1)
			return
		await _run_client_scenario()
	else:
		print("LBA_MP_RESULT role=unknown status=FAIL reason=LBA_MP_ROLE_not_set")
		get_tree().quit(1)


func _on_player_connected(peer_id, _player_info) -> void:
	_distinct_registered[int(peer_id)] = true


func _run_server_scenario() -> void:
	var timeout_msec := Time.get_ticks_msec() + int(POLL_TIMEOUT_SEC * 1000.0)
	# 1. Wait (event-driven) until EXPECTED_PLAYERS distinct clients have registered.
	while _distinct_registered.size() < EXPECTED_PLAYERS and Time.get_ticks_msec() < timeout_msec:
		await get_tree().create_timer(0.2).timeout

		# 2. Give clients time to confirm their own state and exit.
	var latched := _distinct_registered.size() >= EXPECTED_PLAYERS
	# 2. Give clients time to confirm their own state and exit.
	var grace_deadline := Time.get_ticks_msec() + int(SERVER_GRACE_SEC * 1000.0)
	while Time.get_ticks_msec() < grace_deadline and Network.players.size() > 0:
		await get_tree().create_timer(0.25).timeout
	_finish(latched)


func _run_client_scenario() -> void:
	var timeout_msec := Time.get_ticks_msec() + int(POLL_TIMEOUT_SEC * 1000.0)
	var latched := false
	while Time.get_ticks_msec() < timeout_msec:
		await get_tree().create_timer(0.2).timeout
		_peak_registered = maxi(_peak_registered, Network.players.size())
		_peak_spawned = maxi(_peak_spawned, _spawned_players())
		if Network.players.size() >= EXPECTED_PLAYERS and _spawned_players() >= EXPECTED_PLAYERS:
			latched = true
			break
	if latched:
		await get_tree().create_timer(CLIENT_LINGER_SEC).timeout
	_finish(latched)


func _spawned_players() -> int:
	if _level == null:
		return 0
	var container: Node = _level.get_node_or_null("PlayersContainer")
	if container == null:
		return 0
	return container.get_child_count()


func _finish(passed: bool) -> void:
	var spawned := _spawned_players()
	var status := "PASS" if passed else "FAIL"
	print(
		(
			(
				"LBA_MP_RESULT role=%s distinct_registered=%d peak_registered=%d peak_spawned=%d"
				+ " registered_now=%d spawned_now=%d status=%s"
			)
			% [
				_role,
				_distinct_registered.size(),
				maxi(_peak_registered, _distinct_registered.size()),
				maxi(_peak_spawned, spawned),
				Network.players.size(),
				spawned,
				status,
			]
		)
	)
	get_tree().quit(0 if passed else 1)
