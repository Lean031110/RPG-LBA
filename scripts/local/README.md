# Scripts locales (se implementan durante el proyecto)

Los scripts para iniciar el servidor headless, crear mundos y lanzar dos clientes deben generarse después de la auditoría de la plantilla. No se incluyen comandos definitivos que asuman nombres de escenas o argumentos aún no creados.

Cuando exista el servidor:
- documentar `--headless`, puerto, `world_id`, `instance_id` y config;
- crear `run_server_local.sh` con comprobación de puertos y shutdown limpio;
- crear `run_two_clients.sh` solo para test/dev;
- no usar valores de producción ni secretos en scripts.
