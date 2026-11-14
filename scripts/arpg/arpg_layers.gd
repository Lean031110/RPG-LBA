class_name ArpgLayers
## Capas físicas del modo ARPG (definidas en project.godot [layer_names]).
## Valor de capa N = 2^(N-1). Una sola fuente de verdad para evitar máscaras invertidas.

const PLAYER := 4  # layer_3 arpg_player
const WORLD := 8  # layer_4 arpg_world
const ENEMY := 16  # layer_5 arpg_enemy
const PICKUP := 32  # layer_6 arpg_pickup
const HITBOX_PLAYER := 64  # layer_7 arpg_hitbox_player
const HITBOX_ENEMY := 128  # layer_8 arpg_hitbox_enemy
