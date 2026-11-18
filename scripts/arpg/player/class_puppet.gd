# gdlint: ignore=max-public-methods
class_name ClassPuppet
extends Node3D
## Base comun de las marionetas visuales de clase (Fase 2): el jugador y el
## HUD dependen SOLO de esta interfaz (mismos metodos que usaba la marioneta
## del Machetero), de modo que cada clase aporta su presentacion sin tocar la
## logica. Preparada para sustituir el montaje por AnimationPlayer futuro.


func animate_walk(_phase: float, _run_blend: float) -> void:
	pass


func animate_idle(_delta: float) -> void:
	pass


func animate_combat_state(_delta: float, _state: Dictionary) -> void:
	## _state: {blocking, action_kind, phase, progress, dodging, busy}
	pass


func play_death() -> void:
	pass


func reset_pose() -> void:
	pass


func set_blade_glow(_active: bool) -> void:
	## Resplandor del arma/foco arcano cuando el equipo otorga potencia.
	pass
