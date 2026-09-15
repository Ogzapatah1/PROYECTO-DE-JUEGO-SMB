# Referencia Rápida: Lua 5.1 + LÖVE 11.x

> **Objetivo**: Evitar errores de sintaxis comunes. Consultar antes de escribir código nuevo.

---

## Fuentes Oficiales (Bookmark estas)

| Qué | URL | Qué buscar |
|-----|-----|------------|
| **Lua 5.1 Reference Manual** | <https://www.lua.org/manual/5.1/> | Sintaxis completa, librería estándar, metamétodos |
| **Lua 5.1 PIL (Programming in Lua)** | <https://www.lua.org/pil/contents.html> | Tutorial por capítulos, patrones idiomáticos |
| **LÖVE Wiki** | <https://love2d.org/wiki/Main_Page> | API completa: love.graphics, love.filesystem, callbacks |
| **LÖVE Callbacks** | <https://love2d.org/wiki/love> | `love.load`, `love.update(dt)`, `love.draw`, `love.keypressed`, etc. |
| **LÖVE Types** | <https://love2d.org/wiki/Types> | `Image`, `Quad`, `Canvas`, `Font`, `Sound`, `Shader` |
| **LÖVE Tutorials** | <https://love2d.org/wiki/Tutorials> | Paso a paso: "Getting Started", "Tilesets", "Physics" |

---

## Errores Comunes que Hemos Tenido (y cómo evitarlos)

### 1. Metatables / "Clases" Lua
```lua
-- ❌ MAL: tabla simple sin metatable
local Camera = {}
function Camera.new(w, h, s)
    return { x=0, y=0, worldW=w, worldH=h, scale=s }
end
function Camera:update(dt, tx, ty)  -- self es la tabla, PERO no hay herencia
    self.x = tx
end

-- ✅ BIEN: metatable con __index
local Camera = {}
Camera.__index = Camera
function Camera.new(w, h, s)
    return setmetatable({ x=0, y=0, worldW=w, worldH=h, scale=s }, Camera)
end
function Camera:update(dt, tx, ty)
    self.x = tx
end
```
**Regla**: Si usas `:` en la definición O en la llamada, **siempre** `setmetatable(t, Class)` y `Class.__index = Class`.

### 2. `pcall` / `xpcall` — retornos
```lua
-- ❌ MAL: asumir que retorna solo el valor
local code = pcall(fn)  -- code es boolean, NO el retorno de fn

-- ✅ BIEN: capturar ambos
local ok, result = pcall(fn)
if not ok then
    -- result es el error message
else
    -- result es lo que fn retornó
end
```

### 3. `require` cache
```lua
-- ❌ MAL: esperar que require recargue el archivo
package.loaded["src/input"] = nil
local Input = require("src/input")  -- SÍ recarga, pero afecta a TODOS los que ya lo requerían

-- ✅ BIEN: diseñar módulos sin estado global mutable, o usar factory functions
local function createInput()
    local state = {}
    return { load=function()..., update=function()... }
end
```

### 4. `love.filesystem` vs `io.open` rutas
```lua
-- ❌ MAL: rutas relativas en io.open (depende de CWD)
local f = io.open("selftest_result.txt", "w")

-- ✅ BIEN: ruta absoluta conocida
local RESULT_DIR = "C:\\Users\\Admin\\Desktop\\AI and Programing\\Proyects\\LOVE2D\\PROYECTO DE JUEGO SMB"
local f = io.open(RESULT_DIR .. "\\selftest_result.txt", "w")

-- ✅ BIEN: love.filesystem (usa save dir, portable)
love.filesystem.setIdentity("smbgame")
love.filesystem.write("result.txt", "contenido")
```

### 5. STI mapas `.lua` — Formato exacto
```lua
-- ❌ MAL: encoding csv + data suelto
encoding = "csv",
data =
    0, 0, 1, 1,

-- ✅ BIEN: encoding lua + tabla + tileoffset
encoding = "lua",
data = { 0, 0, 1, 1, ... },
tilesets = {
    { name="cave", firstgid=1, tilewidth=32, tileheight=32,
      tileoffset={x=0,y=0},  -- ¡OBLIGATORIO!
      image="../sprites/Tileset.png", imagewidth=320, imageheight=192, ... }
}
```

### 6. `bump.lua` — Coordenadas top-left vs center
```lua
-- Player guarda center (x, y). Bump espera top-left.
local halfW, halfH = w/2, h/2
world:add(player, x - halfW, y - halfH, w, h)

-- world:move devuelve top-left → reconvertir a center
local actualX, actualY = world:move(player, goalX - halfW, goalY - halfH)
player.x = actualX + halfW
player.y = actualY + halfH
```

### 7. `Input.force` — Edge detection correcto
```lua
-- Para que isPressed/isReleased disparen en EL frame correcto:
function Input.force(action, value)
    current[action]  = value
    previous[action] = not value  -- fuerza transición up→down o down→up
end
```

### 8. `love.graphics` transform stack
```lua
-- ❌ MAL: no hacer pop()
love.graphics.translate(...)
love.graphics.scale(...)
player:draw()

-- ✅ BIEN: push/pop balanceado
love.graphics.push()
love.graphics.translate(...)
love.graphics.scale(...)
player:draw()
love.graphics.pop()
```

### 9. Tablas como arrays vs diccionarios
```lua
-- #t solo cuenta desde 1 hasta primer nil
local t = { 1, 2, nil, 4 }  -- #t == 2, NO 4

-- Para arrays con huecos, usar t.n o ipairs (se detiene en nil)
for i=1, t.n or #t do ... end
```

### 10. `love.update(dt)` — `dt` variable
```lua
-- ❌ MAL: mover sin dt
player.x = player.x + speed

-- ✅ BIEN: frame-rate independent
player.x = player.x + speed * dt
```

---

## Patrones Seguros del Proyecto

### Módulo estándar (factory + estado encapsulado)
```lua
-- src/mi_modulo.lua
local MiModulo = {}

function MiModulo.new(param)
    local self = {
        param = param,
        interno = 0,
    }
    -- métodos como closures capturan self
    function self:metodo(arg)
        self.interno = self.interno + arg
        return self.interno
    end
    return self
end

return MiModulo
```

### Módulo con "clase" (metatable) — para múltiples instancias
```lua
-- src/entidad.lua
local Entidad = {}
Entidad.__index = Entidad

function Entidad.new(x, y)
    return setmetatable({ x=x, y=y, vx=0, vy=0 }, Entidad)
end

function Entidad:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

return Entidad
```

### Callback `love.load` con test mode
```lua
function love.load(args)
    if args and args[1] == "--test" then
        -- modo test: no init gráfico, solo lógica
        return runTests()
    end
    -- modo normal
    love.graphics.setDefaultFilter("nearest", "nearest")
    ...
end
```

---

## Quick Reference: LÖVE Callbacks Order

```
love.conf(t)           -- ANTES de todo (conf.lua)
love.load()            -- 1 vez al inicio
love.update(dt)        -- cada frame (lógica)
love.draw()            -- cada frame (dibujo)
love.keypressed(k)     -- tecla presionada
love.keyreleased(k)    -- tecla soltada
love.mousepressed(x,y,b)
love.mousereleased(x,y,b)
love.resize(w,h)       -- ventana redimensionada
love.quit()            -- al cerrar
love.focus(f)          -- gana/pierde foco
love.visible(v)        -- visible/oculto
```

---

## Debugging Tips

| Problema | Comando rápido |
|----------|----------------|
| Ver tabla completa | `for k,v in pairs(t) do print(k,v) end` |
| Traceback en error | `debug.traceback("", 2)` |
| Medir tiempo | `local t = love.timer.getTime(); ...; print(love.timer.getTime()-t)` |
| Inspeccionar metatable | `getmetatable(obj)` |
| Ver upvalues de closure | `debug.getupvalue(fn, 1)` |

---

## Links de Referencia Rápida (copia en navegador)

- **Lua 5.1 Manual**: https://www.lua.org/manual/5.1/manual.html
- **PIL Cap 16 (Metatables)**: https://www.lua.org/pil/13.html
- **LÖVE love.graphics**: https://love2d.org/wiki/love.graphics
- **LÖVE love.filesystem**: https://love2d.org/wiki/love.filesystem
- **LÖVE love.keyboard**: https://love2d.org/wiki/love.keyboard
- **bump.lua API**: https://github.com/kikito/bump.lua#readme
- **STI (Simple Tiled Implementation)**: https://github.com/karai17/Simple-Tiled-Implementation
- **anim8**: https://github.com/kikito/anim8
- **HUMP Camera**: https://hump.readthedocs.io/en/latest/camera.html

---

## Checklist Antes de Commit

- [ ] ¿Metatables en "clases" con `setmetatable` + `__index`?
- [ ] ¿`pcall` captura `ok, result` correctamente?
- [ ] ¿Rutas absolutas para `io.open`?
- [ ] ¿Mapa STI con `encoding="lua"` + `data={...}` + `tileoffset`?
- [ ] ¿Bump: center ↔ top-left convertido en add/move?
- [ ] ¿`Input.force` setea `previous = not value`?
- [ ] ¿`love.graphics.push()` / `pop()` balanceados?
- [ ] ¿Movimiento usa `dt`?
- [ ] ¿`require` no se espera que recargue?

---

*Actualizar este archivo cuando aparezca un nuevo patrón de error.*