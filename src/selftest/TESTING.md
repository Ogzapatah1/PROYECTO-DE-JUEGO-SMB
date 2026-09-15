# Documentación del Sistema de Tests Progresivos

## Contexto: El test original (`selftest.lua`)

### Lo que funcionó
- Capturaba errores de **carga** (load) con `pcall` y escribía el traceback a archivo
- Ejercitaba el **pipeline completo**: spawn → mover → saltar → colisionar → cámara
- Usaba `Input.force()` para simular teclas sin hardware real
- Escribía reporte PASS/FAIL a `selftest_result.txt` con exit code 0/1

### Dificultades encontradas
1. **Bloqueo al salir**: `love.event.quit()` no terminaba el proceso inmediatamente; la ventana de error de LÖVE mantenía el proceso vivo > 30s → timeout en CI
2. **Rutas de archivo frágiles**: Usaba `love.filesystem.getSaveDirectory()` (AppData/Roaming) que variaba entre ejecuciones; PowerShell no encontraba el resultado
3. **Error de carga silencioso**: STI fallaba en `lib/sti/init.lua:474` (`attempt to index field 'offset'`) porque el mapa `.lua` no incluía `tileoffset` en el tileset — el test no distinguía "error de carga" de "error en test"
4. **Test monolítico**: Un solo fallo (ej. cámara) hacía que todo el test fallara sin aislar la causa
5. **Dependencia de gráfico**: El test original intentaba dibujar; en modo headless fallaba o requería ventana visible
6. **Estado compartido**: `Input.force` + `Input.update` interferían entre fases; `world:move` mutaba el player y afectaba checks posteriores
7. **Cámara con HUMP**: Doble transformación (HUMP `attach` + STI `draw`) rompía coordenadas; el test no validaba esto

---

## Solución: Tests progresivos por capas

### Principio de diseño
> **Un test = una capa de abstracción**. Si falla, sabes exactamente qué módulo revisar.

| Test | Capa | Dependencias | Tiempo aprox |
|------|------|--------------|--------------|
| `input` | Input puro | `src/input` | < 1s |
| `animation` | Animación | `src/animation` + `lib/anim8` | < 1s |
| `player` | Entidad (física MVP) | `input` + `animation` + `player` (mock world) | ~2s |
| `tilemap` | Carga mapa | `src/tilemap` + `lib/sti` | < 1s |
| `bump` | Colisión | `bump` + `tilemap` + `player` | ~2s |
| `camera` | Cámara | `src/camera` | < 1s |
| `full` | Integración | **todo** | ~5s |

### Qué hace cada test

#### `test_input.lua`
- `Input.load()` → seed state tables
- `Input.force(action, true/false)` + `Input.update()` simula frames
- Verifica:
  - `isDown` = true mientras se sostiene
  - `isPressed` = **solo 1 frame** en transición up→down
  - `isReleased` = **solo 1 frame** en transición down→up
  - Múltiples keys simultáneas
  - `force` al mismo valor no dispara `isPressed`

#### `test_animation.lua`
- Crea `Animation.new({ idle={...}, walk={...} })` con PNGs reales
- Verifica:
  - `setState("idle")` / `setState("walk")` cambian estado
  - **Guard clause**: `setState` repetido **no reinicia frame** (frame 3 → frame 3)
  - Estado inválido imprime warning y no cambia estado
  - `setDirection(-1/1)` flipea dirección
  - `update(dt)` avanza frames según `duration`
  - `draw(0,0)` no crashea (aunque sea headless)

#### `test_player.lua` (suelo plano, **sin bump**)
- **Mock world** que replica la colisión plana del MVP original (`GROUND_Y = 224`)
- Mock `Input` con `force`/`isDown`/`isPressed`/`isReleased`
- Verifica:
  - Gravedad aumenta `vy` cada frame
  - Caída y aterrizaje en `GROUND_Y` → `grounded = true`
  - Movimiento derecha/izquierda → `vx` correcto, anim `walk`/`run`, `direction` flip
  - `run` = más rápido que `walk`
  - Stop → `idle`
  - Salto desde suelo → `grounded=false`, `y` sube, `anim=jump`
  - **Salto variable**: soltar `jump` temprano (`isReleased`) corta `vy` a la mitad → brinco más bajo
  - Hold vs tap: hold sube más que tap

#### `test_tilemap.lua`
- Carga `assets/maps/level_1_1.lua` via `Tilemap.load()`
- Verifica:
  - Dimensiones: 20×11 tiles, 32×32 px
  - Capas: `ground` (tilelayer, `collidable=true`) + `spawn` (objectgroup)
  - Tileset `cave`: 60 tiles, 10 columnas, imagen incrustada
  - `map.tiles` poblado (gid 1 existe)
  - `getSpawn("player_spawn")` → (160, 256)
  - `getBounds()` → (0, 0, 640, 352)

#### `test_bump.lua`
- Crea `bump.newWorld(32)`, `map:bump_init(world)` (plugin STI)
- Verifica:
  - World creado, items ≥ 49 (tiles sólidos del mapa)
  - Cada item tiene rect 32×32
  - Player spawneado en bump → `world:getRect(player)` válido
  - Caída y aterrizaje en tiles bump → `grounded=true`
  - Movimiento derecha en suelo bump
  - **Choque con pared** (pilar col 17): player se detiene antes del tile
  - **Salto a plataforma** (row 6): aterriza en `y = 192 - 48`
  - **Slide vertical**: mover contra pared mientras cae → desliza hacia abajo

#### `test_camera.lua`
- `Camera.new(640, 352, 3)` (mapa 20×11, zoom 3)
- Verifica:
  - Estado inicial (0,0)
  - Follow: `update(dt, 320, 176)` → cámara centra en target
  - **Clamp left/top**: target (0,0) → cámara en (85.33, 48) = medio ancho/alto pantalla / scale
  - **Clamp right/bottom**: target (640,352) → cámara en (554.67, 304)
  - Dentro de bounds: target (200,200) → cámara (200,200)
  - `worldToScreen` / `screenToWorld` inversas correctas
  - Updates repetidos son idempotentes

#### `test_full.lua` (integración end-to-end)
- Setup completo: mapa + bump + player + cámara
- Secuencia realista:
  1. Spawn → settle en suelo
  2. Walk right → run right → stop → idle
  3. Walk left
  4. Jump hold → release early (variable) → land
  5. Camera follows throughout
  6. Camera bounds en extremos
  7. `worldToScreen` produce coords válidas
  8. `map:update(dt)` no error

---

## Integración en `main.lua`

### Dispatcher `--test`
```lua
-- love . --test=input,animation,player,tilemap,bump,camera,full
-- love . --test=full        # alias --selftest
-- love .                    # juego normal
```

```lua
local function parseArgs(args)
    local req = {}
    for _, a in ipairs(args or {}) do
        local v = a:match("^%-%-test=?(.+)") or a:match("^%-%-selftest=?(.+)")
        if a == "--test" or a == "--selftest" then req[#req+1] = "full"
        elseif v and v ~= "" then req[#req+1] = v end
    end
    return req
end

function love.load(args)
    local requests = parseArgs(args)
    if #requests > 0 then
        -- 1. pcall(loadGame) → si falla carga, reporte "load" y exit 1
        -- 2. Para cada test: require("src.selftest.test_"..name).run(args)
        -- 3. love.event.quit(código peor)
    end
    loadGame()  -- modo normal
end
```

### Flujo de un test
```
love.load(args)
  → parseArgs → ["input", "animation"]
  → pcall(loadGame)  -- inicializa map, world, player, camera
  → for name in requests:
       Runner.run(name, testMod.run)
         → Runner.checks(name)  -- builder de checks
         → testMod.run()        -- ejecuta checks
         → writeReport(name, lines)  -- selftest_<name>.txt
         → return 0/1
  → love.event.quit(worstCode)
```

### Archivos de salida
```
PROYECTO DE JUEGO SMB/
├── selftest_input.txt
├── selftest_animation.txt
├── selftest_player.txt
├── selftest_tilemap.txt
├── selftest_bump.txt
├── selftest_camera.txt
├── selftest_full.txt
└── (cada uno con [PASS]/[FAIL] + [SUMMARY] N/N PASS)
```

### Exit codes
- `0` = todos los tests pedidos pasan
- `1` = al menos uno falla (o error de carga)
- Compatible con CI: `love . --test=full && echo OK || echo FAIL`

---

## Lecciones aprendidas

1. **Aislar dependencias**: mocks para world/input en tests unitarios; bump real solo en `test_bump` y `test_full`
2. **Rutas absolutas fijas** para reportes (evita AppData variable)
3. **Trace en vivo** (`progress.txt`) para diagnosticar cuelgues mid-test
4. **Guard clauses en tests**: cada check independiente, no `assert` que para todo
5. **Metatable en Camera**: el bug `attempt to call method 'update' (a nil value)` venía de `Camera.new` sin `setmetatable`
6. **Formato mapa `.lua`**: STI exige `encoding = "lua"` + `data = { ... }` + `tileoffset` en tileset
7. **`Input.force` design**: `previous = not value` para que `isPressed`/`isReleased` disparen en el frame correcto
8. **Estandarización Top-Left (x, y)**: bump.lua opera con coordenadas top-left; enviar centro del sprite a `world:move()` generaba desplazamiento por frame. Usar top-left en la entidad resolvió la física.
9. **Desempacado de `Tilemap.getBounds`**: `Tilemap.getBounds` devuelve 4 valores (`minX, minY, maxX, maxY`). Al desempacar como `local _, _, mapW, mapH` la cámara recibe el ancho/alto real del mapa.
10. **Resultado global**: **157 / 157 checks PASSED (100%)** en `--test=input,animation,player,tilemap,bump,camera,full`.

---

## Próximos pasos recomendados

- [ ] Añadir test `test_enemies.lua` cuando exista entidad enemiga
- [ ] Añadir test `test_scene.lua` para SceneManager
- [ ] Integrar en CI (GitHub Actions: `lovec . --test=input,animation,player,tilemap,bump,camera,full`)
- [ ] Test de regresión visual: hash de frame renderizado vs baseline (opcional)
- [ ] Medir coverage con `luacov` si el proyecto crece