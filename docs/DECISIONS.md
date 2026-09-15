# DECISIONS.md — Log de decisiones técnicas

Cada vez que aparece una bifurcación técnica importante, se documenta aquí
antes de decidir. El objetivo es no elegir basado en lo primero que encontramos,
sino evaluar opciones con criterio claro.

---

## #001 — Sprites y compatibilidad con anim8

**Fecha:** Mayo 2026
**Estado:** ✅ Resuelta

**Situación:**
Los primeros sprites evaluados (Kenney aliens) usaban archivos XML para describir
frames en posiciones arbitrarias dentro del sheet. anim8 espera una grilla uniforme.

**Opciones evaluadas:**

| Opción | Pros | Contras |
|--------|------|---------|
| A) Buscar sprites en formato de tiras horizontales | Zero fricción con anim8, más simple | Requiere encontrar assets con el estilo correcto |
| B) Escribir un atlas loader custom (src/atlas.lua) | Compatible con cualquier XML atlas | Más complejidad, más código que aprender en Phase 1 |
| C) Reorganizar sheets manualmente en Aseprite | Control total | Requiere dominar Aseprite antes de tener el juego funcionando |

**Decisión:** Opción A — Se evaluaron los assets Kenney (XML atlas, 128×128px) y se
descartaron. Se adoptaron los sprites Pink Monster que usan tiras horizontales
(un archivo por animación, todos los frames en fila 1), directamente compatibles
con anim8. No se necesita atlas loader.

**Resultado:** anim8 se mantiene. Cada estado de animación es un archivo PNG separado.
La grilla anim8 siempre es fila 1, N columnas según el número de frames del archivo.

---

## #002 — Dirección de arte del juego

**Fecha:** Mayo 2026
**Estado:** ✅ Resuelta

**Situación:**
Se evaluaron dos sets de assets con estilos y formatos completamente distintos.
Había que elegir uno antes de escribir el sistema de animación.

**Opciones evaluadas:**

| Opción | Estilo | Tamaño | Formato | Problema |
|--------|--------|--------|---------|----------|
| A) Kenney Alien Characters + Ground tiles | Cartoon suave, colorido | 128×256px personaje, 128×128 tiles | XML atlas | Escala enorme, requiere atlas loader, atlas no compatible con anim8 |
| B) Pink Monster + Cave Tileset | Pixel art oscuro, cohesivo | 32×32 ambos | Tiras horizontales | Ninguno relevante |

**Criterio de decisión:**
- Consistencia visual entre personaje y mundo
- Compatibilidad directa con anim8 sin código extra
- Escala apropiada para ventana 512×288

**Decisión:** Opción B — Pink Monster + Cave Tileset.

**Resultado:**
- Personaje: 32×32px, 13 archivos de animación (ver PROGRESS.md para inventario)
- Tiles: 32×32px, sheet 320×192 (grilla 10×6 = 60 tiles)
- Ventana 512×288: 16 tiles ancho × 9 tiles alto (proporciones exactas del NES Mario)
- anim8 compatible directamente, sin atlas loader

---

## #003 — Arquitectura de animation.lua: un sheet vs múltiples archivos

**Fecha:** Mayo 2026
**Estado:** ✅ Resuelta

**Situación:**
animation.lua fue escrito asumiendo un único spritesheet con un estado por fila.
Los assets reales del Pink Monster usan un archivo PNG separado por cada estado
de animación. Hay que decidir cómo adaptar el módulo.

**Opciones evaluadas:**

| Opción | Pros | Contras |
|--------|------|---------|
| A) Mantener diseño actual (un sheet, múltiples filas) | Sin cambios en el código existente | Requeriría combinar todos los PNGs en un sheet manualmente |
| B) Reescribir para múltiples archivos (una imagen por estado) | Usa los assets tal como vienen, más simple de extender | Requiere reescribir animation.lua |

**Decisión:** Opción B — Reescribir animation.lua.
La interfaz pública (setState, update, draw) no cambia.
Solo cambia la implementación interna y la forma en que se definen los estados.

**Resultado:** ✅ Implementado en Sesión 3. `Animation.new(states)` recibe ahora una
tabla con `path`, `frames`, `duration` y carga un PNG por estado. Detalle técnico
importante descubierto al implementar: la llamada a la grilla de anim8 es
`grid("1-N", 1)` — primero van las COLUMNAS y después la FILA. Escribir
`grid(1, N)` selecciona la fila N y rompe la animación.

---

## #004 — Quién define los estados de animación y cómo anclar la física

**Fecha:** Septiembre 2026
**Estado:** ✅ Resuelta

**Situación:**
Al crear el player MVP aparecieron dos pequeñas bifurcaciones:
1. La tabla de estados de animación (idle/walk/run/jump) podía vivir en main.lua
   (como en el test harness) o dentro de player.lua.
2. El sprite se dibuja a escala 3× desde su CENTRO, pero la física usa lógica
   sin escala. El chequeo de suelo usaba medio-alto lógico (16px), lo que hacía
   que los pies del sprite quedaran hundidos en el piso 96×3−96 = 32px.

**Opciones evaluadas (estados):**

| Opción | Pros | Contras |
|--------|------|---------|
| A) Definir los estados en main.lua y pasarlos al player | main controla todo | main sabe detalles del player, se rompe el encapsulamiento |
| B) Que player.lua defina y construya su propia animación | El player es autosuficiente; los enemigos copiarán el molde | Nada importante |

**Opciones evaluadas (ancla de física):**

| Opción | Pros | Contras |
|--------|------|---------|
| A) Física en píxeles lógicos (32×32), dibujar compensando | Separa mundo real de visual | Compensación frágil, confusa |
| B) Física y chequeos usando la altura VISUAL escalada | Los pies tocan exactamente el suelo | Las velocidades se expresan en píxeles escalados |

**Decisión:** Opción B en ambos casos.
- `player.lua` define `animStates` y construye su propia `Animation` en `new()`.
- El ground check usa `halfH = (height/2) * scale` (altura visual). La escala es
  una constante `SCALE` dentro de player.lua.

**Resultado:** El MVP se ve correcto (pies pegados al suelo) y el player es
autosuficiente. Al introducir bump.lua (Fase 2) se revisará: la física de bump
debería usar una caja lógica y la escala deberá volver a evaluarse.

---

## #005 — Coordenadas del mundo, ancla bump y reformat de cámara

**Fecha:** Septiembre 2026
**Estado:** ✅ Resuelta

**Situación:**
Al integrar Phase 2 (STI + bump + cámara) aparecieron tres bifurcaciones técnicas:

1. **Coordenadas del mundo**: el player MVP usaba unidades escaladas (SCALE=3)
   con la física mezclada con la escala visual. Al introducir un tilemap real,
   hay que decidir si el mundo usa píxeles-de-tile (1 tile = 32px) o píxeles escalados.

2. **Ancla de la caja de colisión en bump**: bump workIn los rectángulos con
   esquina superior izquierda (x, y, w, h), pero nosotros guardamos la posición
   del player como CENTRO del sprite. Hay que traducir entre ambos.

3. **Cámara**: HUMP camera fue elegida en Phase 1, pero STI's `map:draw(tx,ty,sx)`
   aplica su PROPIA transformación de cámara (translate + scale sobre un canvas).
   Usar HUMP camera `attach()` y también `map:draw()` causa doble transformación.

**Opciones evaluadas:**

| Opción | Pros | Contras |
|--------|------|---------|
| (1A) Mundo en píxeles-de-tile (32px), zoom solo visual | Consistente con STI/bump, mapa y player comparten espacio | Requiere mover zoom a la cámara |
| (1B) Mantener unidades escaladas del MVP | Sin cambios | Inconsistente: bumps/tiles en 32px vs player en 96px |
| (2A) Convertir centro→top-left al llamar bump, guardar como centro | APIs públicas (`player.x/y`) siguen siendo centro | Traducción en cada llamada |
| (2B) Guardar top-left directamente | Sin conversión | Rompe draw (que espera centro) y HUD |
| (3A) HUMP camera + map:draw dentro de attach | "A la lettre" del plan | Doble transformación, mapa mal dibujado |
| (3B) Cámara simple OWN (x,y,scale) + map:draw(tx,ty,sx) | Consistente con STI | HUMP queda sin usar |

**Decisión:**
- **(1) A** — Mundo en píxeles-de-tile: player.width/height = 32, gravedad/velocidad
  en px (lógicos). El zoom (3) vive SOLO en la cámara.
- **(2) A** — El player guarda `x, y` como centro; al meter al world de bump se
  convierte a top-left (`x - w/2`). `world:move` devuelve top-left, se reconvierte
  a centro.
- **(3) B** — Se descarta HUMP camera a favor de una `src/camera.lua` propia que
  calcula `x, y, scale`. STI's `map:draw(tx, ty, scale)` maneja el transform del
  mundo; el player se dibuja con el mismo transform manual (translate al centro de
  la pantalla, scale, translate -camera).

**Resultado:** MUY IMPORTANTE — STI cargaba con `encoding = "csv"` pero en mapas
`.lua` espera `data = { ... }` (tabla Lua). Eso causó el error fatal
`attempt to index field 'data' (a number value)`. Fix: `encoding = "lua"` + `data` como tabla.
El juego ahora carga: mapa + player + colisión + cámara funcionando.

---

## #006 — Estandarización de Coordenadas Top-Left en Entidades y Bump

**Fecha:** Septiembre 2026
**Estado:** ✅ Resuelta

**Situación:**
En la Sesión 4, `Player.new` registraba la caja de colisión en bump restando `x - 16, y - 16`, pero `Player:update` llamaba a `world:move(self, goalX, goalY)` pasando las coordenadas del CENTRO. bump.lua interprete `goalX, goalY` como la esquina superior izquierda (top-left). Esto causaba un desplazamiento progresivo de 16px por fotograma que corrompía la física y la detección de suelo.

**Opciones evaluadas:**

| Opción | Pros | Contras |
|--------|------|---------|
| A) Convertir explícitamente entre centro y top-left en cada llamada a `world:move` | Mantiene `self.x, self.y` como centro del sprite | Frágil, propuesto a errores de duplicación u omisión en nuevas entidades |
| B) Estandarizar `self.x, self.y` como Top-Left en toda la entidad | Consistente con bump, STI y LÖVE2D por defecto; simplifica las matemáticas | Requiere dibujar el sprite desplazado `+ width/2, + height/2` |

**Decisión:** Opción B — Estandarizar `self.x, self.y` como Top-Left en la clase `Player` y futuras entidades.
- `world:add(self, self.x, self.y, self.width, self.height)`
- `world:move(self, goalX, goalY)` usa directamente `self.x + self.vx * dt`
- `Player:draw()` pasa `self.x + self.width/2, self.y + self.height/2` a `Animation:draw`
- `camera:update()` sigue al centro `player.x + player.width/2, player.y + player.height/2`

**Resultado:** Se elimina por completo el descalce de colisión. La gravedad, caídas, aterrizajes y deslizamiento por paredes funcionan de forma determinista.

---

## #007 — Suite de Selftests Progresivos y Hot-Reload de Mapa

**Fecha:** Septiembre 2026
**Estado:** ✅ Resuelta

**Situación:**
Para verificar rápidamente la física, el mapa, la cámara y el cargador de mapas sin depender de pruebas manuales exhaustivas cada vez, se necesitaba un arnés de pruebas automatizado y una forma rápida de iterar diseños en Tiled.

**Decisión:**
1. **Dispatcher de Selftests `--test`**: Permite ejecutar tests modulares aislados (`input`, `animation`, `player`, `tilemap`, `bump`, `camera`, `full`) o combinados separando por comas.
2. **Hot-Reload (`R` key)**: En `main.lua`, presionar `R` ejecuta `loadGame()`, releyendo la exportación `.lua` de Tiled al instante sin cerrar el juego.
3. **`t.console = true`**: Habilitado en `conf.lua` para que la salida de pruebas imprima directamente en la consola de Windows (`lovec.exe`).

**Resultado:** 157 checks probados al 100% PASS (0 fallos). Iteración ultra-rápida de niveles al editar en Tiled y presionar `R`.

---

_(Las nuevas decisiones se agregan abajo en orden cronológico)_
