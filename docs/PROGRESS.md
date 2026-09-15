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
- **src/tilemap.lua** — STI loader, getSpawn, getBounds
- **src/camera.lua** — tracking al centro del jugador, clamping a límites del mapa (640×352), zoom pixel-art 3x
- **Colisión con tiles via bump.lua** — alineación top-left corregida, colisión con suelo y plataformas
- **Assets elegidos** — Pink Monster (32×32) + cave tileset (32×32, sheet 320×192)
- **Mapa de prueba creado** — assets/maps/level_1_1.lua (20×11, tileset cave incrustado, capa ground collidable + capa spawn)
- **Hot-Reload en vivo** — presionar `R` recarga el nivel desde el archivo `.lua` de Tiled en caliente
- **Suite de Selftests Automatizada** — `src/selftest/` con 157 checks en 7 módulos (`input`, `animation`, `player`, `tilemap`, `bump`, `camera`, `full`) funcionando a **100% PASS**

---

## 🔄 En progreso

- **Transición a Fase 3 — Game Feel & Level Design** — el motor mínimo del nivel está 100% probado y funcionando.

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
- [ ] Diseñar niveles completos en Tiled usando `level_1_1.lua` como plantilla

### Phase 3 — Game Feel
- [ ] Estados de animación adicionales (hurt, climb, attack)
- [ ] Efectos de sonido (salto, aterizaje) y música de fondo
- [ ] Transiciones de escena via Scene Manager

### Phase 4 — Enemies y Gameplay
- [ ] Entity system para enemigos
- [ ] Movimiento de enemigos y AI básica (patrullaje Pink Monster / Goomba)
- [ ] Coleccionables y obstáculos
- [ ] Vidas, puntaje, game over

---

## 📋 Historial de sesiones

| Fecha | Qué se hizo |
|-------|-------------|
| Mayo 2026 — Sesión 1 | Setup del proyecto, definición de arquitectura, creación del sistema docs/ |
| Mayo 2026 — Sesión 2 | Estructura de carpetas real, conf.lua, main.lua, input.lua, animation.lua, evaluación y elección de arte, assets organizados |
| Septiembre 2026 — Sesión 3 | animation.lua reescrito a multi-archivo, player.lua MVP (movimiento, gravedad, salto variable, animación), HUD de debug — Fase 1 completa |
| Septiembre 2026 — Sesión 4 | Tiled instalado, libs descargadas (bump, STI, HUMP camera), mapa de prueba 20×11 creado como .lua, STI + bump plugin + cámara integrados, player usa bump para colisión con tiles — Fase 2 funcional |
| Septiembre 2026 — Sesión 5 | Solución de desalineación de coordenadas Player-Bump (Top-Left), fix de desempacado de dimensiones de cámara `Tilemap.getBounds`, adición de hot-reload con tecla `R`, activación de `t.console = true` en `conf.lua`, suite de selftests corregida y validada con **157/157 PASS (100%)** — Fase 2 100% Probada y Operativa |

---

_(Actualizar al final de cada sesión)_
