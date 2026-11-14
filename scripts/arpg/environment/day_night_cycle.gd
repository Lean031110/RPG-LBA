class_name DayNightCycle
extends RefCounted
## Reloj local de mundo. No conoce escenas, personajes ni servicios de gameplay.
## El servidor podrá sincronizar una hora autoritativa llamando set_time_hours().

signal time_changed(hour: float)
signal period_changed(period: int)

enum Period { DAWN, MORNING, MIDDAY, DUSK, EVENING, NIGHT }

const DEFAULT_DAY_LENGTH_SECONDS := 1440.0

var day_length_seconds := DEFAULT_DAY_LENGTH_SECONDS
var time_hours := 6.5
var _current_period: int = Period.DAWN


func _init(initial_time_hours: float = 6.5) -> void:
	time_hours = fposmod(initial_time_hours, 24.0)
	_current_period = get_period()


func configure(duration_seconds: float, initial_time_hours: float) -> void:
	day_length_seconds = maxf(duration_seconds, 1.0)
	set_time_hours(initial_time_hours)


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	var safe_duration := maxf(day_length_seconds, 1.0)
	set_time_hours(time_hours + (delta * 24.0 / safe_duration))


func set_time_hours(value: float) -> void:
	time_hours = fposmod(value, 24.0)
	var next_period := get_period()
	if next_period != _current_period:
		_current_period = next_period
		period_changed.emit(_current_period)
	time_changed.emit(time_hours)


func get_period() -> int:
	if time_hours >= 5.5 and time_hours < 7.0:
		return Period.DAWN
	if time_hours >= 7.0 and time_hours < 11.0:
		return Period.MORNING
	if time_hours >= 11.0 and time_hours < 16.0:
		return Period.MIDDAY
	if time_hours >= 16.0 and time_hours < 18.0:
		return Period.DUSK
	if time_hours >= 18.0 and time_hours < 19.0:
		return Period.EVENING
	return Period.NIGHT


func get_period_name() -> String:
	match get_period():
		Period.DAWN:
			return "Amanecer"
		Period.MORNING:
			return "Mañana"
		Period.MIDDAY:
			return "Mediodía"
		Period.DUSK:
			return "Atardecer"
		Period.EVENING:
			return "Anochecer"
		_:
			return "Noche"


func get_time_label() -> String:
	var hour_value := int(floor(time_hours))
	var minute_value := int(floor((time_hours - float(hour_value)) * 60.0))
	return "%02d:%02d" % [hour_value, minute_value]


func get_normalized_time() -> float:
	return time_hours / 24.0
