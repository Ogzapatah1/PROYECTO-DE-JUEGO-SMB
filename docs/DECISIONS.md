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

**Resultado:** Pendiente de implementar en próxima sesión. El nuevo formato de
definición de estados será:
```lua
{
  idle = { path = "assets/sprites/Pink_Monster_Idle_4.png", frames = 4, duration = 0.15 },
  walk = { path = "assets/sprites/Pink_Monster_Walk_6.png", frames = 6, duration = 0.10 },
}
```

---

_(Las nuevas decisiones se agregan abajo en orden cronológico)_
