class_name WeatherController
extends RefCounted
## Estado climático desacoplado del render. Las transiciones se mezclan por pesos,
## por lo que cambiar de clima a mitad de una transición no produce un salto brusco.

signal weather_changed(weather: int)

enum Weather { CLEAR, OVERCAST, FOG, RAIN }

const WEATHER_NAMES := ["Despejado", "Nublado", "Niebla", "Lluvia"]

var transition_seconds := 18.0
var _weights: Array[float] = [1.0, 0.0, 0.0, 0.0]
var _targets: Array[float] = [1.0, 0.0, 0.0, 0.0]
var _target_weather: int = Weather.CLEAR


func set_weather(weather: int, instant: bool = false) -> bool:
	if weather < Weather.CLEAR or weather > Weather.RAIN:
		return false

	_target_weather = weather
	for index in range(_targets.size()):
		_targets[index] = 1.0 if index == weather else 0.0

	if instant or transition_seconds <= 0.0:
		_weights = _targets.duplicate()
		weather_changed.emit(_target_weather)
	return true


func advance(delta: float) -> void:
	if delta <= 0.0 or not is_transitioning():
		return

	var step := delta / maxf(transition_seconds, 0.001)
	for index in range(_weights.size()):
		_weights[index] = move_toward(_weights[index], _targets[index], step)

	_normalize_weights()
	if not is_transitioning():
		weather_changed.emit(_target_weather)


func get_weight(weather: int) -> float:
	if weather < Weather.CLEAR or weather > Weather.RAIN:
		return 0.0
	return _weights[weather]


func get_dominant_weather() -> int:
	var dominant := Weather.CLEAR
	var highest := -1.0
	for index in range(_weights.size()):
		if _weights[index] > highest:
			highest = _weights[index]
			dominant = index
	return dominant


func get_weather_name() -> String:
	return WEATHER_NAMES[get_dominant_weather()]


func is_transitioning() -> bool:
	for index in range(_weights.size()):
		if absf(_weights[index] - _targets[index]) > 0.0001:
			return true
	return false


func get_weights() -> Array[float]:
	return _weights.duplicate()


func _normalize_weights() -> void:
	var total := 0.0
	for value in _weights:
		total += value
	if total <= 0.0:
		_weights = [1.0, 0.0, 0.0, 0.0]
		return
	for index in range(_weights.size()):
		_weights[index] /= total
