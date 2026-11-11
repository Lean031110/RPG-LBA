# 10 — QA, pruebas y definición de validación

## Niveles de validación

### A. Validación estática/importación

- Godot exacto 4.7.2 Standard.
- Abrir/importar proyecto en headless.
- Revisar logs por `SCRIPT ERROR`, `Parse Error`, `Failed loading resource` y errores críticos.
- Validar recursos, UID/paths, escenas y autoloads.
- Comprobar que no quedan referencias a assets inexistentes.

### B. Unit tests

Usar GdUnit4 para reglas puras: daño, cooldown, recursos, inventario, rareza, tablas de loot, progreso de quest, permisos de guild y cálculo de estadísticas.

### C. Integration tests

- Main menu -> character select -> world.
- Entrar/salir de zona.
- Aceptar misión, contar evento y reclamar recompensa.
- Comprar/vender/craft/equipar/guardar/cargar.
- Iniciar dungeon, completar boss y reclamar drop.

### D. Multiplayer tests

- Iniciar headless server local.
- Iniciar dos clientes independientes.
- Conectar/desconectar.
- Mover, atacar, recibir daño, morir/revivir.
- Inventario y quest consistentes.
- Rechazar RPC inválido, spoof, spam, item inexistente y cooldown falsificado.
- Simular caída en trade y comprobar atomicidad.

### E. Visual/smoke tests

- Usar Xvfb + renderizador software para capturas automáticas cuando la escena lo permita.
- Comparación visual no sustituye revisión humana: tolerancia por versión de driver, fonts y antialiasing.
- Guardar capturas de menú, HUD, personaje, combate, ciudad y dungeon como artifacts.
- Ejecutar smoke test con Dummy audio y sin hardware GPU.

### F. Android real

Se requiere instalar el APK en Redmi 9C y al menos un teléfono de gama media/alta. Registrar:
- modelo exacto y RAM;
- versión Android;
- GPU/driver si se conoce;
- resolución y perfil;
- FPS mediano y 1% low si se mide;
- memoria RAM pico;
- temperatura/thermal throttling;
- consumo de batería aproximado;
- fallos/ANR/crashes;
- carga y tiempos de transición.

## Criterios para el perfil Low

Objetivo inicial: 30 FPS, no promesa. Test mínimo sugerido: 20 minutos con combate, enemigos, UI y transición de zona; informar promedio y caídas. Si no se alcanza, reducir efectos/visibilidad/entidades y volver a medir. No ocultar resultados fuera de objetivo.

## Test cases mínimos

1. Proyecto importa limpio.
2. Main scene arranca.
3. Todos los autoloads inicializan.
4. Cada clase puede moverse/atacar/equipar.
5. Habilidad no se lanza sin recurso/cooldown listo.
6. Telegráfico se muestra antes del daño.
7. Muerte y reaparición respetan regla de zona.
8. Items no se duplican al desconectar.
9. Quest recompensa se recibe una sola vez.
10. Dungeon seed genera mismo grafo.
11. Grafo tiene ruta de entrada a boss/salida.
12. Dos clientes observan estado de jugador/monstruo coherente.
13. Servidor rechaza request inválido.
14. Trade atómico: todos los objetos se intercambian o ninguno.
15. World IDs no filtran datos entre mundos.
16. APK debug se instala/abre en dispositivos de prueba.
17. Ajustes low cambian realmente sombras, distancia y efectos.

## Semáforo de calidad

- PASS: comando/test terminó con éxito y artefacto/evidencia existe.
- FAIL: test se ejecutó y falló.
- SKIPPED: test no se ejecutó por condición documentada.
- NOT TESTED: falta equipo, acceso, credencial o implementación.

No llamar a un proyecto “100% libre de errores”. El objetivo es reducir regresiones y descubrir fallos repetibles.
