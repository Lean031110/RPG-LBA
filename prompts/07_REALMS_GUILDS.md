# Prompt 07 — Mundos, guilds y social

Implementa `world_id`, selector de realm, instancias de dungeon, party de cuatro, guild inicial, chat protegido y trade bilateral solo cuando los fundamentos multijugador estén estables. Una instancia o proceso de servidor puede atender un realm de desarrollo. La separación de realms debe estar reflejada en cada clave persistente. No desplegar microservicios ni marketplace global sin medir necesidad. Crear tests de aislamiento por world_id, permisos guild, invitaciones, trade atómico, doble confirmación y desconexión en medio de trade.
