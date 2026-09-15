# Lua Concepts — What You Need to Know
## Based on the code we have built so far

This document explains the Lua patterns actually used in our project.
The tutorial transcripts covered the basics (variables, loops, tables, functions).
What follows is the next level — the patterns that make a real modular game possible.

---

## 1. Tables as Modules

In the tutorials, tables stored data — player position, scores, etc.
In our project, tables also store **behaviour** (functions).
This is the foundation of everything we build.

```lua
-- A table that holds only data (tutorial style)
local player = {
    x = 100,
    y = 200,
    speed = 5
}

-- A table that holds functions too (our style)
local Input = {}

function Input.update()   -- this function lives INSIDE the table
    -- ...
end

function Input.isDown(action)
    -- ...
end

return Input   -- we hand this table to whoever requires the file
```

When `main.lua` does `local Input = require("src/input")`,
it receives that table. Then `Input.update()` calls the function inside it.

**The key mental model:** a module file is just a Lua file that
builds a table, puts functions in it, and returns it.
That table IS the module.

---

## 2. The `return` at the End of a File

Every module file ends with `return SomeName`.
This is not optional — it is what makes `require()` work.

```lua
-- src/input.lua
local Input = {}
-- ... define functions ...
return Input      -- <-- this is what require("src/input") receives
```

```lua
-- main.lua
local Input = require("src/input")   -- Input is now that table
Input.update()                        -- calls the function inside it
```

If you forget `return Input`, the `require` call returns `nil`
and everything that tries to use it crashes immediately.

---

## 3. `require()` — How the Module System Works

`require("src/input")` does three things:
1. Finds the file at `src/input.lua`
2. Runs it (executes all the code in it)
3. Returns whatever that file returned

**Critical:** Lua caches the result. If two files both `require("src/input")`,
the file only runs ONCE. Both get the exact same table back.
This means module state is shared — there is only one `Input` in the whole game.

```lua
-- This is safe — input.lua only executes once no matter how many
-- files require it. The same table is returned each time.
local Input = require("src/input")   -- in main.lua
local Input = require("src/input")   -- in player.lua — same table, no re-run
```

---

## 4. Dot `.` vs Colon `:` — The Most Confusing Thing in Lua

This is the thing that trips everyone up. Here is the rule:

**Dot `.`** — you are calling a regular function.
**Colon `:`** — you are calling a METHOD and Lua secretly passes `self` as the first argument.

```lua
-- Defining with a dot — no hidden argument
function Input.isDown(action)
    return current[action] == true
end

-- Defining with a colon — "self" is secretly the first argument
function Animation:setState(name)
    -- "self" here refers to the specific Animation instance that was called
    if self.currentState == name then return end
    self.currentState = name
end
```

When you CALL them:

```lua
-- Dot call — you pass all arguments yourself
Input.isDown("jump")

-- Colon call — Lua automatically passes the table as the first argument
myAnim:setState("walk")
-- This is exactly the same as: Animation.setState(myAnim, "walk")
```

**Why does this matter?**
`Input` is a single global module — there is only one of it.
So dot notation is fine: `Input.isDown("jump")`.

`Animation` creates multiple INSTANCES (one per entity).
Each instance needs to know which one it IS — that is what `self` provides.
So we use colon notation: `myAnim:setState("walk")`.

The rule of thumb:
- **Dot** → the function does not need to know which table called it
- **Colon** → the function needs `self` to access its own data

---

## 5. `local` — Why We Use It Everywhere

The tutorials mentioned local vs global. In our project it is not optional — 
we use `local` for almost everything. Here is why it matters at scale:

```lua
-- src/input.lua

local bindings = { ... }   -- ONLY this file can see this variable
local current  = {}        -- ONLY this file can see this variable
local previous = {}        -- ONLY this file can see this variable
```

If `bindings` were global (no `local`), any other file in the game
could accidentally overwrite it. With 10 files in the project,
that becomes a serious debugging nightmare.

**The pattern we follow:**
- The module table itself (`local Input = {}`) is local to the file
- All internal state (`local bindings`, `local current`) is local to the file  
- Only what we put INTO the module table is accessible from outside

```lua
local Input = {}            -- local: only this file holds the reference
local bindings = { ... }   -- local: completely private, no one else can touch it

function Input.isDown(action)   -- PUBLIC: exposed through the module table
    return current[action]
end

-- bindings is PRIVATE — no one outside this file can read or change it
-- Input.isDown is PUBLIC — anyone with the Input table can call it

return Input
```

This is called **encapsulation** — hiding internal details and
only exposing what other code actually needs to use.

---

## 6. Metatables and the Class Pattern

This is used in `src/animation.lua`. It looks strange at first but
the idea is simple: we want to create multiple independent Animation objects,
each with its own state, all sharing the same methods.

```lua
local Animation = {}
Animation.__index = Animation   -- the magic line — explained below
```

```lua
function Animation.new(spritesheet, frameW, frameH, states)
    local self = setmetatable({}, Animation)
    -- setmetatable({}, Animation) means:
    --   1. Create a new empty table {}
    --   2. When Lua can't find a key in it, look in Animation instead
    --      (that's what __index = Animation means)
    
    self.currentState = nil   -- this instance's own data
    self.currentAnim  = nil
    self.direction    = 1
    
    return self
end
```

When you later call `myAnim:setState("walk")`:
1. Lua looks for `setState` in `myAnim` — not there
2. Because of `__index`, Lua looks in `Animation` — found it
3. Calls it with `myAnim` passed as `self`

**In plain English:**
- `Animation` is the blueprint (the class)
- `Animation.new()` stamps out a fresh copy (an instance)
- Each instance has its OWN data (`self.currentState`, etc.)
- All instances SHARE the same methods (`setState`, `update`, `draw`)

The player will have ONE animation object. An enemy will have ANOTHER.
They each track their own state independently, but use the same code.

```lua
-- In player.lua (coming next session):
local playerAnim = Animation.new(sheet, 16, 16, { idle = {...}, walk = {...} })

-- In enemy.lua:
local enemyAnim  = Animation.new(sheet, 16, 16, { walk = {...}, die  = {...} })

-- These are independent — changing one does not affect the other
playerAnim:setState("walk")   -- only affects playerAnim
enemyAnim:setState("die")     -- only affects enemyAnim
```

---

## 7. Two-Frame Input — The Pattern Behind isPressed

This is our own pattern, not a Lua language feature, but it is important enough
to understand clearly.

```lua
local current  = {}   -- keyboard state THIS frame
local previous = {}   -- keyboard state LAST frame
```

Every frame, before reading the keyboard, we copy current into previous:

```lua
function Input.update()
    for action, _ in pairs(bindings) do
        previous[action] = current[action]  -- step back in time
    end
    for action, key in pairs(bindings) do
        current[action] = love.keyboard.isDown(key)  -- read now
    end
end
```

This gives us three questions we can answer:

```
previous = false, current = true  →  isPressed  (key just went down)
previous = true,  current = true  →  isDown     (key is held)
previous = true,  current = false →  isReleased (key just came up)
previous = false, current = false →  nothing    (key is up)
```

```lua
function Input.isPressed(action)
    -- Was up last frame AND is down this frame = just pressed
    return current[action] == true and previous[action] == false
end
```

**Why this matters for a platformer:**
- Walking uses `isDown` — keep moving while held
- Jumping uses `isPressed` — trigger once per tap, not every frame
- Variable jump height uses `isReleased` — cut upward speed when you let go early
  (this is what makes Mario's short tap = small jump, held = big jump)

---

## 8. `pairs()` — Iterating Tables with String Keys

The tutorials showed `ipairs` for tables with numbered indexes (1, 2, 3...).
We use `pairs` for tables with string keys, like our bindings table.

```lua
local bindings = {
    move_left  = "left",
    move_right = "right",
    jump       = "z",
}

-- pairs gives you key AND value for every entry
for action, key in pairs(bindings) do
    -- action = "move_left",  key = "left"
    -- action = "move_right", key = "right"
    -- action = "jump",       key = "z"
    current[action] = love.keyboard.isDown(key)
end
```

Note: `pairs` does NOT guarantee order. That is fine here because
we are just reading every binding — order does not matter.

---

## 9. Guard Clauses — Early Returns for Safety

You will see this pattern throughout the codebase:

```lua
function Animation:setState(name)
    if self.currentState == name then return end   -- guard clause

    if not self.anims[name] then                   -- guard clause
        print("WARNING: state '" .. name .. "' does not exist")
        return
    end

    -- actual logic only runs if both guards passed
    self.currentState = name
    self.currentAnim  = self.anims[name]
end
```

Instead of wrapping all the logic in a big `if-then-else`,
we check failure conditions early and `return` immediately.
The "happy path" logic stays unindented and easy to read.
This also prevents bugs: calling `setState` with a typo prints a warning
instead of silently doing nothing or crashing.

---

## 10. `nil` as "not yet set"

We initialise several things to `nil` explicitly:

```lua
self.currentState = nil
self.currentAnim  = nil
```

`nil` in Lua means "this variable exists but holds nothing".
It lets us write defensive checks:

```lua
function Animation:update(dt)
    if self.currentAnim then    -- only run if it's not nil
        self.currentAnim:update(dt)
    end
end
```

This prevents crashes during startup when the entity exists
but hasn't been given an animation state yet.

---

## Quick Reference — Patterns We Use

| Pattern | Where | Purpose |
|---|---|---|
| `local Module = {}` ... `return Module` | Every src/ file | Creates a module |
| `require("src/file")` | main.lua, entities | Imports a module |
| `function Module.fn()` | input.lua | Public function, no self |
| `function Class:method()` | animation.lua | Method with implicit self |
| `setmetatable({}, Class)` | animation.lua | Creates a class instance |
| `local x = ...` | Everywhere | Keeps variables private |
| `if thing then return end` | setState, draw | Guard clause |
| `previous[k] = current[k]` | input.lua | Two-frame state snapshot |
| `pairs(table)` | input.lua | Iterate string-keyed tables |
| `function love.keypressed(key)` | main.lua | Event handler for single keypress (R = hot-reload) |
| `string:gmatch("[^,]+")` | main.lua | Splits comma-separated test names in dispatcher |

---

*Last updated: Phase 2 completion — STI, Bump physics alignment, Camera clamping, Selftests (157 PASS)*
