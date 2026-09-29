# PROGRESS.md — Estado del proyecto

---

## ✅ Completado

- Elección de tecnología: Love2D + Lua
- Elección de herramientas: Tiled, bump.lua, anim8, HUMP camera, STI
- Arquitectura modular definida (Input, Animation, Tilemap, Collision, Camera, Entity, Scene)
- Sistema de documentación creado
- **Estructura de carpetas creada** en el proyecto real
- **conf.lua** — ventana 512×288, physics desactivado, vsync activado, `t.console = true` (log terminal en Windows)
- **main.lua** — orquestador con Input, Animation, Player, Tilemap, Camera, dispatcher `--test`, y hot-reload (`R` key)
- **src/input.lua** — completo: isDown, isPressed, isReleased, bindings configurables, testMode
- **src/animation.lua** — animación por estados con tiras PNG horizontales
- **src/entities/player.lua** — estandarizado a coordenadas top-left, movimiento, gravedad, salto variable, bump collision, anim state sync
- **src/tilemap.lua** — STI loader, `getSpawn`, `getSpawns` y `getBounds`
- **src/camera.lua** — tracking al centro del jugador y clamping a límites del mapa; `main.lua` usa actualmente `CAMERA_SCALE = 1`
- **Colisión con tiles via bump.lua** — alineación top-left corregida, colisión con suelo y plataformas
- **Assets elegidos** — Pink Monster (32×32) + cave tileset (32×32, sheet 320×192)
- **Mapa editable en Tiled** — `assets/maps/level_1_1.tmx` y exportación `.lua`; la versión actual mide 80×11 tiles (2560×352 px), con suelo colisionable, `player_spawn` y cuatro puntos `dude_monster_spawn`
- **Hot-Reload en vivo** — presionar `R` recarga el nivel desde el archivo `.lua` de Tiled en caliente
- **Suite de Selftests Automatizada** — 10 módulos (`input`, `animation`, `player`, `tilemap`, `bump`, `camera`, `full`, `enemy`, `gameplay`, `contact`); ejecución del 29 de septiembre de 2026: **277/277 PASS**, incluyendo patrulla/ataque ante huecos, posiciones seguras de aparición, contacto, vidas, respawn, game over y prioridad de fin de etapa.

- **Documentation & GitHub**: README.md exhaustivo creado y repositorio sincronizado en GitHub.
- **Workflow de Niveles con Tiled**: Creación del archivo de proyecto `assets/maps/level_1_1.tmx` y configuración de auto-exportación a `.lua`.
- **Ajustes de Cámara & Viewport**: La escala evolucionó de 3x a 2x y la versión actual de `main.lua` usa `CAMERA_SCALE = 1` para ver más del mapa.
- **Tuning de Física de Salto**: `JUMP_SPEED = -340` en `player.lua` permite superar obstáculos de 2 tiles (64 px) de altura.
- **Sistema de Vidas y Muerte por Foso**: Empieza con 3 vidas. Caer hasta `player.y >= 350` resta una vida; aparece "YOU DIED!" durante 5 segundos y luego se reaparece en el punto de inicio. Al llegar a 0 vidas, "GAME OVER!" dura 6 segundos antes de reiniciar con 3 vidas.
- **Sistema de Finalización de Etapa (Stage Finish)**: Al llegar a `player.x >= mapW - 64`, el juego se pausa en un mensaje de felicitación y espera `C` o `F`. `C` muestra "Sorry, no more Stages available!" y `F` muestra "Ending..."; cada mensaje permanece 5 segundos antes de cerrar el juego. No hay una segunda etapa todavía.
- **Dude Monster y contacto**: Cada punto `dude_monster_spawn` del layer `spawn` crea un enemigo; el nivel 1.1 contiene cuatro. Sus puntos se ajustaron para que la caja inicial de 32×32 no se solape con el suelo ni sobresalga de plataformas. `src/ai/dude_monster.lua` decide el estado individual: patrulla inicialmente hacia la izquierda a 30 px/s, gira antes de huecos y ante paredes; si el jugador se acerca, ataca a 45 px/s. Durante el ataque espera ante un hueco, aunque el jugador esté cerca al otro lado, y vuelve a perseguirlo cuando hay terreno seguro en su dirección. `src/entities/enemy.lua` aplica movimiento, gravedad, colisión y animaciones. La caja de contacto mide 20×24. El contacto activa la muerte salvo que la meta se alcance en el mismo frame. Aún no se puede derrotar al enemigo.

---

## 🔄 En progreso

- **Transición a Fase 3 — Game Feel & Level Design** — motor de nivel y cámara ajustados; listo para diseñar niveles completos y agregar FX.
- **Fase 4 — Gameplay** — sistemas de vidas, fin de etapa y contacto con Dude Monster implementados y cubiertos por selftests; los cuatro enemigos ya se confirmaron en juego. Queda seguir evaluando el ritmo de los encuentros y las pantallas de muerte/respawn en partidas completas.

---

## ⬜ Pendiente

### Phase 1 — Core
- [x] Reescribir src/animation.lua para formato multi-archivo (una imagen por estado)
- [x] Escribir src/entities/player.lua (posición, velocidad, input, cambio de estado de animación)
- [x] Actualizar main.lua para cargar y dibujar el player
- [x] Hito visible: Pink Monster aparece en pantalla, idle, camina, salta
- [x] Física básica (gravedad, velocidad, salto) con dt
- [x] Colisión con suelo plano

### Phase 2 — World
- [x] Tilemap module con STI
- [x] Colisión con tiles via bump.lua
- [x] Camera module con límites del mundo
- [x] Estandarización de coordenadas Top-Left y resolución de bugs de desalineación
- [x] Unpacking de dimensiones de cámara (`mapW`, `mapH`)
- [x] Recarga de mapa en caliente (`R` key)
- [x] Suite de selftest progresiva (157 checks, 100% PASS)
- [x] Integración editable en Tiled (.tmx) + documentación completa README.md
- [x] Ampliación del mapa actual a 80×11 tiles
- [ ] Diseñar niveles completos en Tiled usando `level_1_1.tmx` / `level_1_1.lua`

### Phase 3 — Game Feel
- [ ] Estados de animación adicionales (hurt, climb, attack)
- [ ] Efectos de sonido (salto, aterizaje) y música de fondo
- [ ] Transiciones de escena via Scene Manager

### Phase 4 — Enemies y Gameplay
- [x] Entidad inicial Dude Monster: animación, gravedad, colisión con terreno y seguimiento horizontal del jugador
- [x] Velocidad de seguimiento reducida a 45 px/s; contacto causa muerte, salvo si se alcanza el fin de etapa en el mismo frame
- [x] Tres vidas, caída en foso, respawn y game over
- [x] Mensaje de fin de etapa con opciones `C` y `F`
- [x] Pruebas automáticas de contacto, pérdida única de vida, respawn, game over y prioridad de fin de etapa
- [x] Posicionar varios Dude Monsters desde puntos en Tiled y restaurarlos al reaparecer
- [x] IA modular del Dude Monster: patrulla, persecución cercana y espera segura ante huecos
- [x] Corregir los cuatro puntos para que la caja inicial quede libre y apoyada sobre plataformas; verificarlo con selftest
- [x] Confirmar en juego que los cuatro Dude Monsters aparecen y funcionan con las posiciones corregidas
- [ ] Prueba manual del ritmo, contacto y pantallas de muerte/respawn
- [ ] Sistema base de entidades, si lo requieren varios tipos de enemigos
- [ ] Movimiento de enemigos y AI básica (patrullaje Pink Monster / Goomba)
- [ ] Coleccionables y obstáculos
- [ ] Puntaje y HUD de juego final (las vidas están en el HUD de depuración)

---

## 📋 Historial de sesiones

| Fecha | Qué se hizo |
|-------|-------------|
| Mayo 2026 — Sesión 1 | Setup del proyecto, definición de arquitectura, creación del sistema docs/ |
| Mayo 2026 — Sesión 2 | Estructura de carpetas real, conf.lua, main.lua, input.lua, animation.lua, evaluación y elección de arte, assets organizados |
| Septiembre 2026 — Sesión 3 | animation.lua reescrito a multi-archivo, player.lua MVP (movimiento, gravedad, salto variable, animación), HUD de debug — Fase 1 completa |
| Septiembre 2026 — Sesión 4 | Tiled instalado, libs descargadas (bump, STI, HUMP camera), mapa de prueba 20×11 creado como .lua, STI + bump plugin + cámara integrados, player usa bump para colisión con tiles — Fase 2 funcional |
| Septiembre 2026 — Sesión 5 | Solución de desalineación de coordenadas Player-Bump (Top-Left), fix de desempacado de dimensiones de cámara `Tilemap.getBounds`, adición de hot-reload con tecla `R`, activación de `t.console = true` en `conf.lua`, suite de selftests corregida y validada con **157/157 PASS (100%)** — Fase 2 100% Probada y Operativa |
| Septiembre 2026 — Sesión 6 | Creación de README.md, .gitignore y sincronización en GitHub; creación de `level_1_1.tmx` para edición visual en Tiled; ajuste de viewport (`CAMERA_SCALE = 2`) y tuning de física de salto (`JUMP_SPEED = -340` para superar 2 tiles). |
| Septiembre 2026 — Sesión 7 | Implementación de sistema de fin de etapa (Stage Finish) con felicitaciones, selección mediante teclas 'C' / 'F', mensajes contextuales ("Sorry, no more Stages available!" y "Ending...") y temporizadores de 5 segundos. |
| Septiembre 2026 — Mapa y enemigo inicial | Mapa ampliado a 80×11, cámara a escala 1x, tres vidas con muerte por foso/respawn/game over y Dude Monster con colisión de terreno; este hito se subió a GitHub. |
| Septiembre 2026 — Contacto enemigo | Dude Monster reducido a 45 px/s; solapamiento con jugador causa muerte y resta una vida. La meta gana ante contacto simultáneo. Añadidos `gameplay` y `contact` selftests; 202/202 checks pasan. |
| 29 septiembre 2026 — Encuentros e IA | Caja de contacto enemiga reducida a 20×24 sin alterar su colisión con terreno; múltiples apariciones precisas desde Tiled; patrulla y ataque modular con detección de huecos; corregidos los puntos que hacían caer a los dos enemigos intermedios. 277/277 checks pasan y el usuario confirmó jugando que los cuatro aparecen y funcionan. |

---

_(Actualizar al final de cada sesión)_
