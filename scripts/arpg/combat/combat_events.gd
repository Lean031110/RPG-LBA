extends Node
## Autoload CombatEvents (Fase 5): bus de señales de combate para la UI.
## El HUD y los indicadores de daño escuchan aquí sin acoplarse al jugador ni
## a los enemigos; los sistemas de juego emiten. Regla del repo: la UI nunca
## consulta datos cada frame cuando hay un evento que la avisa.
##
## Uso: CombatEvents.damage_dealt.emit(...) desde el que resuelve el golpe.

## Un atacante (jugador o enemigo) conectó un golpe.
signal damage_dealt(target: Node, amount: float, is_crit: bool, world_position: Vector3)
## Un combatiente recibió daño (el HUD del jugador parpadea la barra si es él).
signal damage_taken(victim: Node, amount: float)
## Un golpe fue esquivado o bloqueado por completo (parada perfecta).
signal attack_evaded(victim: Node)
signal attack_parried(victim: Node)
## Un enemigo murió (el HUD de objetivo se limpia; XP y drops los gestionan
## los sistemas de juego, no este bus).
signal enemy_killed(enemy: Node)
## Estados alterados de un combatiente cambiaron (chips del HUD).
signal status_changed(who: Node, status_id: String, active: bool)
