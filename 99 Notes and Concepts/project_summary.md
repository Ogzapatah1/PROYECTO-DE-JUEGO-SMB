# 2D Platformer Game — Project Summary

## What We Want to Build

A 2D platformer game inspired by **Super Mario Bros (NES/SNES)** built from scratch
as both a learning project and a functional game. Core gameplay includes:

- A player character that walks, runs, and jumps across tile-based levels
- Scrolling worlds made of tile maps
- Enemies with basic AI behavior
- Collectibles and hazards
- A camera that follows the player across large levels

The goal is not just to ship a game but to **deeply understand how game systems
work** — physics, collision, animation, input, camera — by building each one
intentionally.

---

## Technology Choices

### Language: Lua

Lua was chosen over Python for the following reasons:

- Python is not designed for real-time game loops — it works against you
- Lua was specifically designed to be embedded inside game engines
- Lua is fast (especially with LuaJIT), lightweight (~250KB runtime), and clean
- It is the native language of Love2D, Defold, Roblox, and many other game platforms
- Its minimalism makes every design decision visible — ideal for learning

### Game Framework: Love2D

Love2D was chosen over Defold after evaluating both options:

**Why Love2D won:**
- Imperative, code-first framework — you see and control everything
- The game loop (`love.load`, `love.update`, `love.draw`) maps directly to how
  game systems actually work
- No editor layer hiding the underlying logic
- Mature community, excellent documentation, strong indie track record
- Ideal for learning because there is no magic

**Why Defold was not chosen (yet):**
- Defold has a component-based, editor-driven architecture that abstracts away
  the problems we specifically want to understand (tile collision, physics feel,
  camera systems)
- Better suited as a future step once core systems are understood
- Migration path exists: pure Lua logic and all assets are portable to Defold
  later; only the engine-facing API layer would need rewriting

**Why a fighting game (Street Fighter 2 style) was ruled out:**
- Deceptively complex: state machines per character, hitbox/hurtbox separation,
  frame data engine, input buffering — harder than a platformer, not easier
- Platformer skills (physics, tile collision, camera) are the correct prerequisite
  before tackling fighting game architecture

---

## Architecture: Modular Design

Rather than writing monolithic code, the game is built as a stack of focused,
reusable Lua modules layered on top of Love2D. Each module has one job.

### Module Stack

| Module | Responsibility | Approach |
|---|---|---|
| **Input** | Abstracts keyboard/gamepad into named game actions | Built on `love.keyboard` |
| **Animation** | Sprite sheet frame management, state transitions | Built on `love.graphics` quads |
| **Tilemap** | Loads tile grid, renders tiles, exposes solid tiles | Built on `love.graphics` |
| **Collision** | AABB rectangle collision against tiles | Uses **bump.lua** (proven library) |
| **Camera** | Follows player, clamps to world edges, screenshake | Built on `love.graphics.translate` |
| **Entity System** | Manages player, enemies, coins, pipes cleanly | Pure Lua tables |
| **Scene Manager** | Title screen → gameplay → game over transitions | Built on Love2D callbacks |

### Design Principles

- Every module is a separate `.lua` file with a single clear responsibility
- Modules call Love2D's built-in API internally — they extend it, not replace it
- Game logic (math, physics calculations, state) is kept separate from
  rendering and input — this makes the code portable and testable
- **bump.lua** is used for collision rather than building from scratch — tile
  collision has well-known edge case bugs (corner clipping, tunneling) that a
  proven library handles correctly

### What Love2D Provides (Foundation Layer)

Our modules are built on top of these Love2D systems:

- **Game loop** — `love.load()`, `love.update(dt)`, `love.draw()` — never written by us
- **Rendering** — `love.graphics` for images, quads, shapes, text
- **Input** — `love.keyboard`, `love.mouse`, `love.joystick`
- **Audio** — `love.audio` for sound effects and music
- **Asset loading** — `love.graphics.newImage()`, sprite sheets
- **Window management** — resolution, fullscreen, vsync

---

## Art Assets

### Philosophy

Art and code are developed in parallel. Placeholder assets unblock coding;
custom art replaces them once systems are working. The goal is to never let
art block code progress or vice versa.

### Toolchain

| Tool | Purpose | Cost |
|---|---|---|
| **Aseprite** | Pixel art creation and sprite animation | ~$20 (Steam) or free (compile from source) |
| **Tiled Map Editor** | Visual level and tilemap design, exports JSON for Love2D | Free |
| **OpenGameArt.org** | Free placeholder assets while coding | Free |
| **Kenney.nl** | High quality free platformer asset packs | Free |
| **itch.io free assets** | Community pixel art packs | Free |
| **Midjourney / Adobe Firefly** | AI-generated reference art and drafts | Free tier / subscription |
| **Scenario.gg** | Game-specific AI asset generation with style training | Free tier available |

### Aseprite (Primary Art Tool)

Chosen as the non-negotiable pixel art tool because:
- Industry standard for pixel art and 8/16-bit style games
- Built-in animation timeline with onion skinning
- Exports sprite sheets directly in the format Love2D expects
- Native 8-bit and 16-bit palette support

### Tiled Map Editor

Used for designing Mario-style tile levels visually. Exports to JSON/Lua format.
Love2D reads it via **STI (Simple Tiled Implementation)** library.
Workflow: design in Tiled → export → Love2D renders.

### AI Tools — Honest Assessment

AI is useful for **reference and drafts**, not final assets:

- ✅ Good for: color palette ideas, concept art, background elements
- ❌ Not reliable for: consistent animation frames, precise pixel grid alignment,
  seamlessly tile-able textures

Recommended workflow for AI-assisted art:
1. Generate reference in Midjourney or Firefly
2. Redraw and refine pixel by pixel in Aseprite
3. Animate in Aseprite using the AI reference as a guide

### Asset Development Workflow

```
Start coding
    ↓
Use OpenGameArt / Kenney placeholder assets
    ↓
Game systems working and tested
    ↓
Generate AI reference art (Midjourney / Firefly)
    ↓
Draw and animate final sprites in Aseprite
    ↓
Design levels visually in Tiled
    ↓
Import sprite sheets + tilemap JSON into Love2D
```

---

## Development Path

### Phase 1 — Core (First milestone: character moves and jumps)
- Project setup in Love2D
- Input module
- Animation state machine
- Basic physics (gravity, velocity, jumping)
- Flat ground collision

### Phase 2 — World
- Tilemap module
- Tile-based collision via bump.lua
- Camera module with world clamping

### Phase 3 — Game Feel
- Sprite sheet animations (idle, walk, jump, fall)
- Sound effects and background music
- Screen transitions via Scene Manager

### Phase 4 — Enemies and Gameplay
- Entity system
- Enemy movement and basic AI
- Collectibles, hazards
- Lives, score, game over

---

## Future Considerations

**Migration to Defold:**
If the project grows beyond what Love2D handles comfortably, migration to Defold
is viable. What migrates: all assets, all pure Lua game logic. What requires
rewriting: all engine-facing API calls (rendering, input, audio). The architectural
knowledge transfers completely even when code does not.

**Version Control:**
Use Git + GitHub from day one. Commit after every working milestone.
This protects progress and makes it easy to revert broken experiments.
Visual Studio Code has built-in Git support that makes this straightforward.

---

*Project started: May 2026*
*Engine: Love2D | Language: Lua | Style: 8/16-bit pixel art*
