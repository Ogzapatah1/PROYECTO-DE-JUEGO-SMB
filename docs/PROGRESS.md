# PROGRESS.md — Estado del proyecto

---

## ✅ Completado

- Elección de tecnología: Love2D + Lua
- Elección de herramientas: Tiled, bump.lua, anim8, HUMP camera, STI
- Arquitectura modular definida (Input, Animation, Tilemap, Collision, Camera, Entity, Scene)
- Sistema de documentación creado
- **Estructura de carpetas creada** en el proyecto real
- **conf.lua** — ventana 512×288, physics desactivado, vsync activado
- **main.lua** — orquestador con require de Input y Animation, test visual de input
- **src/input.lua** — completo: isDown, isPressed, isReleased, bindings configurables
- **src/animation.lua** — escrito (requiere reescritura en próxima sesión, ver abajo)
- **lua_concepts.md** — documentación de patrones Lua usados en el proyecto
- **Input module probado** — teclas muestran true/false correctamente en pantalla
- **Arte elegido** — Pink Monster (32×32) + cave tileset (32×32, sheet 320×192)
- **Assets copiados** al proyecto en assets/sprites/

---

## 🔄 En progreso

- **src/animation.lua** — necesita reescritura para formato multi-archivo
  - Versión actual asume UN spritesheet con múltiples filas
  - Assets reales usan UN archivo por animación, siempre fila 1
  - Interfaz pública (setState, update, draw) no cambia — solo la implementación interna

---

## ⬜ Pendiente

### Phase 1 — Core (primer hito: el personaje se mueve y salta)
- [ ] Reescribir src/animation.lua para formato multi-archivo (una imagen por estado)
- [ ] Escribir src/entities/player.lua (posición, velocidad, input, cambio de estado de animación)
- [ ] Actualizar main.lua para cargar y dibujar el player
- [ ] Hito visible: Pink Monster aparece en pantalla, idle, camina, salta
- [ ] Física básica (gravedad, velocidad, salto) con dt
- [ ] Colisión con suelo plano

### Phase 2 — World
- [ ] Tilemap module con STI
- [ ] Diseñar primer nivel en Tiled (tileset 32×32, cave tileset)
- [ ] Colisión con tiles via bump.lua
- [ ] Camera module con límites del mundo (HUMP camera)

### Phase 3 — Game Feel
- [ ] Estados de animación completos (idle, walk, run, jump, hurt)
- [ ] Sonido y música
- [ ] Transiciones de escena via Scene Manager

### Phase 4 — Enemies y Gameplay
- [ ] Entity system
- [ ] Movimiento de enemigos y AI básica
- [ ] Coleccionables y obstáculos
- [ ] Vidas, puntaje, game over

---

## 📋 Historial de sesiones

| Fecha | Qué se hizo |
|-------|-------------|
| Mayo 2026 — Sesión 1 | Setup del proyecto, definición de arquitectura, creación del sistema docs/ |
| Mayo 2026 — Sesión 2 | Estructura de carpetas real, conf.lua, main.lua, input.lua, animation.lua, evaluación y elección de arte, assets organizados |

---

_(Actualizar al final de cada sesión)_
