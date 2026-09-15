# 🍄 Platformer SMB — LÖVE2D Game Engine & Project

A modular, robust **Super Mario Bros-style 2D platformer engine** built from scratch in Lua using the [LÖVE2D](https://love2d.org/) framework. 

This project is built around a **strict modular architecture**, clean separation of concerns, deterministic tile-based collision physics via [`bump.lua`](https://github.com/kikito/bump.lua), automated test suites, and live hot-reloading for rapid level design.

---

## 🎯 Purpose of the Project

The primary goals of this project are:
1. **Engine Mastery & Educational Clarity**: To build a clean, extensible 2D platformer engine in LÖVE2D without relying on monolithic frameworks or heavy Box2D physics.
2. **Strict Modular Architecture**: To establish clear boundaries between game systems (Input, Animation, Physics, Tilemaps, Camera, Entities, Scenes) so any module can be modified or tested independently.
3. **High-Precision Game Feel**: To replicate responsive platforming mechanics such as variable jump height, gravity integration, wall/ceiling slide responses, and smooth camera tracking with map clamping.
4. **Developer Workflow & Reliability**: To provide built-in automated testing (`157/157 PASS` checks) and instant live hot-reloading (`R` key) for rapid level editing in Tiled.

---

## 🛠️ Tools & Libraries Used

| Tool / Library | Role & Description |
| :--- | :--- |
| **[LÖVE2D](https://love2d.org/)** (v11.x+) | 2D game framework based on Lua / LuaJIT runtime. Handles window creation, rendering, input polling, and game loop execution (`load`, `update`, `draw`). |
| **[bump.lua](https://github.com/kikito/bump.lua)** | Simple AABB (Axis-Aligned Bounding Box) collision detection engine. Handles tile collisions, wall/ceiling bumps, sliding, and tunneling prevention without Box2D overhead. |
| **[anim8](https://github.com/kikito/anim8)** | Sprite sheet animation library. Handles frame timing, looping, sprite clipping (`Quads`), and animation state stepping. |
| **[STI (Simple Tiled Implementation)](https://github.com/karai17/Simple-Tiled-Implementation)** | Tiled map loader for LÖVE2D. Reads exported `.lua` tilemaps, renders tile layers, and integrates collidable tiles directly into the `bump.lua` physics world. |
| **[Tiled Map Editor](https://www.mapeditor.org/)** | External visual level editor used to lay out tile maps, spawn points, and collision object layers. |
| **Custom Camera Module (`src/camera.lua`)** | Custom-built camera replacing HUMP camera to avoid double-transformation bugs with STI. Manages 3x pixel-art scaling, viewport centering, and map boundary clamping. |
| **Automated Test Runner (`src/selftest/`)** | Custom test suite framework and test dispatcher (`--test`) verifying input states, animations, player physics, map loading, camera behavior, and tile collisions. |

---

## 🧠 Modular Architecture & Design Philosophy

The project adheres to five key design principles:

### 1. Separation of Concerns & Zero-Logic Orchestrator
- `main.lua` contains **no game logic**. It acts strictly as a "table of contents" and orchestrator, requiring modules and dispatching calls to `love.load`, `love.update`, `love.draw`, and `love.keypressed`.
- Every game feature lives in its own dedicated file inside `src/`.

### 2. Object-Oriented Instantiation & Clean Interfaces
- **Static Singletons** (e.g., [`src/input.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/input.lua)) use **Dot notation** (`Input.isDown("jump")`) because there is only one global input manager.
- **Instantiable Classes** (e.g., [`src/entities/player.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/entities/player.lua), [`src/animation.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/animation.lua), [`src/camera.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/camera.lua)) use **Colon notation** (`player:update(dt)`) and Lua metatables to maintain independent instance state.

### 3. Top-Left Coordinate System Standardization
- All world positions (`x, y`) and bounding box definitions across entities, `bump.lua`, and STI tilemaps standardly use **Top-Left coordinates**.
- Translating to center offset is deferred exclusively to draw time (`self.x + self.width / 2, self.y + self.height / 2`), eliminating 16px frame-drift collision bugs.

### 4. Input Snapshot Architecture (Two-Frame State)
- The input engine snapshots keyboard state between the current and previous frames to provide distinct checks:
  - `isDown(action)`: Sustained key press (e.g., running right).
  - `isPressed(action)`: Initial press triggered for exactly 1 frame (e.g., jumping).
  - `isReleased(action)`: Release event triggered for exactly 1 frame (e.g., variable jump cut).

### 5. Automated Self-Testing & Live Feedback Loop
- The engine includes a headless/integrated unit testing dispatcher. Running `lovec . --test` executes 157 automated checks with 100% test coverage across 7 test suites.
- Pressing `R` in-game triggers live hot-reloading of map exports from disk without restarting the game.

---

## 📂 Folder Structure & File Inventory

```
PROYECTO DE JUEGO SMB/
├── conf.lua                             # LÖVE2D window configuration & module toggles
├── main.lua                             # Main game orchestrator & test dispatcher
├── README.md                            # Project documentation (this file)
│
├── assets/                              # Game art assets & level maps
│   ├── maps/
│   │   └── level_1_1.lua                # Tiled map export (20x11 tiles, ground + spawn layers)
│   ├── sounds/                          # Audio directory (reserved for Phase 3)
│   └── sprites/
│       ├── Pink_Monster_*.png           # Horizontal PNG animation strips (32x32px per frame)
│       └── Tileset.png                  # Cave tileset PNG (320x192px)
│
├── lib/                                 # Third-party Lua libraries
│   ├── anim8.lua                        # Sprite animation library by Enrique García Cota
│   ├── bump.lua                         # 2D AABB collision detection library by Enrique García Cota
│   ├── hump/                            # Helper Utilities for Multithreaded Programming
│   └── sti/                             # Simple Tiled Implementation loader & STI bump plugin
│
├── src/                                 # Game source code & core engine modules
│   ├── animation.lua                    # Multi-file state animation loader & anim8 wrapper
│   ├── camera.lua                       # Viewport tracking, 3x zoom scaling, & boundary clamping
│   ├── input.lua                        # Two-frame input engine with customizable key bindings
│   ├── tilemap.lua                      # STI map loader, bump collider registration, & bounds helper
│   ├── entities/
│   │   └── player.lua                   # Player class (physics, gravity, jump, bump collision, anims)
│   ├── scenes/                          # Reserved for Phase 3 scene management
│   └── selftest/                        # Automated unit testing suite
│       ├── runner.lua                   # Test assertion runner & summary reporter
│       ├── test_animation.lua           # Selftest: animation state transitions & frame stepping
│       ├── test_bump.lua                # Selftest: AABB box collisions, tile sliding, & responses
│       ├── test_camera.lua              # Selftest: viewport centering & map boundary clamping
│       ├── test_full.lua                # Selftest: comprehensive suite executing all 157 checks
│       ├── test_input.lua               # Selftest: input keybinding & snapshot state testing
│       ├── test_player.lua              # Selftest: player gravity, velocity integration, & movement
│       ├── test_tilemap.lua             # Selftest: STI loading, tile bounds, & spawn point parsing
│       └── TESTING.md                   # Documentation on running & expanding selftests
│
├── docs/                                # Technical documentation & design logs
│   ├── CONCEPTS.md                      # Glossary of Lua, LÖVE2D, & game-dev concepts with examples
│   ├── DECISIONS.md                     # Technical decision log (#001 – #007) with trade-offs
│   ├── LUA_LOVE_REFERENCE.md            # Syntax reference for Lua & LÖVE2D APIs
│   ├── PROGRESS.md                      # Feature roadmap tracking Phases 1 through 4
│   ├── SESSION.md                       # Current active session goals & immediate status
│   └── WORKFLOW.md                      # AI-Human pair-programming guidelines & rules
│
└── 99 Notes and Concepts/               # Initial project design notes & learning material
    ├── lua_concepts.md                  # Introductory Lua notes on tables, functions, & scope
    └── project_summary.md               # Initial project vision document
```

### Key Source File Descriptions

- **[`conf.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/conf.lua)**: Sets window dimensions (512x288, 16:9 friendly at 16x9 tiles of 32px), vsync (`1`), stdout console logging (`t.console = true`), and disables unused LÖVE2D Box2D physics.
- **[`main.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/main.lua)**: Initializes game state, sets pixel-art filter (`nearest`), wires input/player/tilemap/camera, handles camera transform math in `love.draw`, and parses `--test` CLI flags.
- **[`src/input.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/input.lua)**: Maps virtual actions (`left`, `right`, `jump`, `run`) to keyboard keys. Maintains `downState` and `prevState` tables.
- **[`src/animation.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/animation.lua)**: Accepts state definitions mapping animation names to PNG strip paths and frame counts. Manages frame stepping and guard-clause state changes.
- **[`src/camera.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/camera.lua)**: Calculates target camera position based on player center, clamps coordinates between `minX` and `maxX` boundaries, and handles `scale = 3`.
- **[`src/tilemap.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/tilemap.lua)**: Loads STI maps, initializes collidable tiles via `map:bump_init(world)`, extracts spawn object layers, and returns map boundary dimensions.
- **[`src/entities/player.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/entities/player.lua)**: Encapsulates player physics (acceleration, gravity, max speed, variable jump), registers bounding box in `bump.lua`, updates position with `world:move()`, and synchronizes state machine with animation states (`idle`, `walk`, `run`, `jump`).

---

## 🛠️ Major Technical Decisions & Solutions

All architectural decisions are documented in detail in [`docs/DECISIONS.md`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/docs/DECISIONS.md). Below is a summary of key issues resolved:

### 1. Decision #001 & #002: Sprite Strip Selection vs. XML Atlases
- **Issue**: Initial sprite sheets (Kenney XML atlas) used non-uniform frame sizes requiring custom atlas parsing. `anim8` requires uniform grid layouts.
- **Solution**: Adopted 32x32px **Pink Monster** horizontal sprite strips. Each animation state is stored in its own PNG file, allowing uniform grid creation (`anim8.newGrid(32, 32, w, h)`).

### 2. Decision #003: Multi-File PNG Animation Architecture
- **Issue**: Standard `anim8` examples assume one single massive spritesheet with multiple rows. The character assets came as individual PNG files per action (`Pink_Monster_Idle_4.png`, `Pink_Monster_Walk_6.png`).
- **Solution**: Rewrote [`src/animation.lua`](file:///C:/Users/Admin/Desktop/AI%20and%20Programing/Proyects/LOVE2D/PROYECTO%20DE%20JUEGO%20SMB/src/animation.lua) to accept a state table of PNG paths. Key discovery: `anim8.newGrid` parameter order must be `grid("1-N", 1)` (columns first, row second).

### 3. Decision #005: World Scale & STI Camera Integration
- **Issue**: Combining HUMP camera with STI's native rendering (`map:draw(tx, ty, sx)`) caused double transformation (translating and scaling twice).
- **Solution**: Replaced HUMP camera with a clean custom camera (`src/camera.lua`). Standardized world physics to 32px tile space and isolated visual 3x zoom strictly inside the camera transform in `love.draw`.

### 4. Decision #006: Top-Left Coordinate Standardization & Bump Drift Fix
- **Issue**: The original player entity stored its center position in `(x, y)`. When passing goal coordinates to `bump.lua`'s `world:move(self, goalX, goalY)`, bump interpreted them as top-left corner coordinates. This created a cumulative 16px displacement error per frame, breaking ground checks and wall collision.
- **Solution**: Standardized `self.x, self.y` as **Top-Left coordinates** across all entities, `bump.lua`, and STI tilemaps. Drawing offsets the origin by `+ width / 2` and `+ height / 2` at draw time.

### 5. Decision #007: Automated Selftest Suite & Hot-Reload
- **Issue**: Manual testing for physics, tile collision, and map boundary bounds was slow and error-prone.
- **Solution**: Built an automated test suite runner (`src/selftest/runner.lua`) with modular tests (`input`, `animation`, `player`, `tilemap`, `bump`, `camera`, `full`). Added `R` key binding in `main.lua` to hot-reload Tiled `.lua` map files instantaneously.

---

## 🚦 Current Project Status & Next Steps

### Current Status: Phase 2 — 100% Complete & Verified ✅
- **Phase 1 (Core Engine)**: Fully complete. Input system, player physics, variable jump, gravity, multi-file animation engine operational.
- **Phase 2 (World & Physics)**: Fully complete. STI map loading, `bump.lua` AABB collision resolution, custom camera tracking with map clamping, hot-reloading, and 157 selftest checks passing at **100% PASS**.

### Next Steps & Roadmap 🚀

#### 🎨 Phase 3 — Game Feel & Level Design (In Progress)
- [ ] Implement remaining character animation states (`hurt`, `climb`, `attack`, `push`).
- [ ] Add sound effects (jumping, landing, bump tile hit) and background music.
- [ ] Create multi-screen levels in Tiled using `assets/maps/level_1_1.lua` as a template.
- [ ] Implement a `SceneManager` module for level transitions, title screens, and game over screens.

#### 👾 Phase 4 — Enemies & Gameplay Mechanics
- [ ] Build a generic base Entity system for enemies.
- [ ] Implement enemy AI patrol behaviors (Goomba / Pink Monster patrol).
- [ ] Add collectibles (coins, power-ups) and interactive hazard tiles (pits, spikes).
- [ ] Implement player health/lives system, score tracking, and HUD UI elements.

---

## 🚀 How to Run the Game & Tests

### Running the Game
Using LÖVE2D installed on your system:
```bash
love .
```
Or via Windows console (`lovec`):
```bash
lovec .
```

### In-Game Controls
- **Arrow Keys**: Move Left / Right
- **Z**: Jump (Variable jump height: hold for higher jump, release early for short hop)
- **X**: Run (Increased movement speed)
- **R**: Hot-reload map from disk live

### Running Automated Selftests
Run the complete selftest suite (157 checks) via CLI:
```bash
lovec . --test=full
```
Run specific module tests:
```bash
lovec . --test=player,bump,camera
```
