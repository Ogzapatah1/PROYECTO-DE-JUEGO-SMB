# CONCEPTS.md — Conceptos acumulados

Cada concepto está escrito en palabras simples + un ejemplo del juego específicamente.
Cuando un concepto se entiende mejor con el tiempo, se expande o corrige la entrada.

---

## Lua

### Variables y tablas
**Qué es:** Una variable guarda un dato. Una tabla guarda muchos datos en una sola variable.
**En nuestro juego:** `player` es una tabla que guarda x, y, speed, sprite, animación — todo junto en un lugar.

### Funciones
**Qué es:** Un bloque de código con nombre que puedes ejecutar desde cualquier parte del programa.
**En nuestro juego:** `Input.isDown("jump")` es una función que pregunta si el botón de salto está presionado.

### Local vs Global
**Qué es:** `local` significa que la variable solo existe dentro del archivo o función donde fue creada. Sin `local`, existe en todo el programa (global).
**Por qué importa:** Con muchos archivos, las variables globales se pueden pisar entre sí sin querer. Usamos `local` casi siempre.

### Dot `.` vs Colon `:`
**Qué es:** Dos formas de llamar funciones.
- Punto `.` → función normal, no sabe quién la llama
- Dos puntos `:` → método, Lua pasa automáticamente `self` (el objeto que llama)
**En nuestro juego:**
- `Input.isDown("jump")` — punto, porque Input es único, no hay varias instancias
- `playerAnim:setState("walk")` — dos puntos, porque hay múltiples animaciones y cada una necesita saber que es ella misma

### Metatables y el patrón de clase
**Qué es:** Una manera de crear múltiples objetos independientes que comparten los mismos métodos pero tienen su propia data.
**En nuestro juego:** `playerAnim` y `enemyAnim` usan el mismo código de `Animation`, pero cada uno tiene su propio `currentState`. Si el jugador cambia a "walk", el enemigo no cambia.
**Cuándo se usa:** Cada vez que necesitamos más de una "instancia" de algo.

### `require()`
**Qué es:** Importa el código de otro archivo `.lua` y lo devuelve como una tabla (módulo).
**En nuestro juego:** `local Input = require("src/input")` carga todo el módulo Input.
**Importante:** Lua guarda el resultado en caché — si dos archivos hacen `require("src/input")`, el archivo solo se ejecuta una vez. Los dos reciben la misma tabla.

### Guard clauses (retorno temprano)
**Qué es:** Verificar condiciones de fallo al inicio de una función y hacer `return` inmediato. El código principal solo corre si todo está bien.
**En nuestro juego:** En `Animation:setState(name)`, si ya estamos en ese estado hacemos `return` de inmediato. Sin esto, la animación se reiniciaría al frame 1 cada frame y se vería congelada.
```lua
function Animation:setState(name)
    if self.currentState == name then return end  -- guard clause
    -- lógica real aquí
end
```

### Two-frame input (snapshot de dos frames)
**Qué es:** Guardar el estado del teclado de este frame Y del frame anterior. Comparándolos podemos detectar el momento exacto en que una tecla se presiona o se suelta.
**En nuestro juego:**
- `isDown` → tecla sostenida (caminar)
- `isPressed` → tecla recién presionada, solo un frame (saltar)
- `isReleased` → tecla recién soltada (cortar velocidad de salto)
**Por qué importa:** Sin esto, mantener Z presionado haría saltar al personaje infinitamente cada frame.

---

## Love2D

### El game loop
**Qué es:** Love2D llama automáticamente tres funciones en orden, constantemente:
1. `love.load()` — se ejecuta una sola vez al inicio
2. `love.update(dt)` — se ejecuta cada frame, aquí va la lógica
3. `love.draw()` — se ejecuta cada frame después de update, aquí se dibuja
**En nuestro juego:** La física del jugador se calcula en `update`, el sprite se dibuja en `draw`.

### dt (delta time)
**Qué es:** El tiempo en segundos que pasó desde el último frame. Varía según qué tan rápido corre el juego.
**Por qué importa:** Si movemos al jugador `speed` píxeles por frame, va más rápido en computadoras rápidas. Si multiplicamos por `dt`, va igual de rápido en todas.
**En nuestro juego:** `player.x = player.x + player.speed * dt`

### conf.lua
**Qué es:** Archivo especial que Love2D lee ANTES que main.lua. Configura la ventana, resolución, título, y qué módulos cargar.
**En nuestro juego:** Define la ventana en 512×288 (16 tiles × 9 tiles a 32px por tile) y desactiva el módulo de physics ya que usamos bump.lua.

### love.graphics.setDefaultFilter
**Qué es:** Controla cómo Love2D escala las imágenes. "nearest" mantiene cada píxel como un cuadrado nítido. Sin esto, el pixel art se ve borroso al escalarlo.
**En nuestro juego:** Se llama en love.load() con "nearest", "nearest" antes de cargar cualquier imagen.

---

## Librerías externas

### anim8
**Qué es:** Librería para manejar animaciones desde sprite sheets.
**Cómo funciona:** Le dices el tamaño de cada frame (ancho × alto) y cuántos frames tiene la animación. Avanza los frames automáticamente con el tiempo.
**En nuestro juego:** Cada animación del Pink Monster es un archivo PNG separado con todos los frames en una fila horizontal. anim8 recibe el tamaño del frame (32×32) y el número de columnas.
```lua
local grid = anim8.newGrid(32, 32, image:getWidth(), image:getHeight())
local anim = anim8.newAnimation(grid("1-6", 1), 0.1)  -- 6 frames, fila 1
```

### bump.lua
**Qué es:** Librería para detección de colisiones AABB (rectángulos). Maneja los casos borde difíciles como esquinas y tunneling.
**En nuestro juego:** Se usará para que el jugador colisione con los tiles del mapa. Pregunta "quiero moverme de A a B, ¿qué obstáculos encuentro?" y devuelve resultados precisos.

### STI (Simple Tiled Implementation)
**Qué es:** Librería para cargar mapas exportados desde el editor Tiled.
**En nuestro juego:** Carga el archivo `.lua` que exporta Tiled y dibuja los tiles en pantalla.

---

## Arte y assets

### Sprite strip (tira horizontal)
**Qué es:** Formato de spritesheet donde todos los frames de UNA animación están en una sola fila, de izquierda a derecha. Cada frame tiene exactamente el mismo tamaño.
**En nuestro juego:** Pink_Monster_Walk_6.png tiene 6 frames de 32×32 en una fila = imagen de 192×32px total.
**Por qué importa:** anim8 funciona perfectamente con este formato.

### Texture atlas (atlas de texturas)
**Qué es:** Formato alternativo donde muchos sprites de distintos tamaños están empaquetados en una imagen grande, con un archivo XML que describe la posición exacta de cada uno.
**En nuestro juego:** Los assets Kenney usaban este formato. Lo descartamos porque requería un loader custom y agregaba complejidad innecesaria en Phase 1.

### Quad (Love2D)
**Qué es:** La forma nativa de Love2D para recortar un rectángulo de una imagen más grande. Le dices: "de esta imagen, dame el rectángulo en x=64, y=0, ancho=32, alto=32".
**En nuestro juego:** anim8 crea Quads internamente. No necesitamos crearlos a mano con nuestros assets actuales.

---

_(Los nuevos conceptos se agregan a medida que aparecen en las sesiones)_
