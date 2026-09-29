# SESSION.md — Estado de sesión actual

Comparte este archivo al inicio de cada sesión junto con DECISIONS.md.

---

## Dónde estamos

Phase 2 (World) está implementada. El mapa actual de Tiled (`level_1_1.tmx` / `.lua`) mide 80×11 tiles; `main.lua` usa `CAMERA_SCALE = 1` y el salto del jugador sigue en `JUMP_SPEED = -340`.

La versión actual añade tres vidas, muerte por foso con respawn, game over, un mensaje de fin de etapa con teclas `C`/`F`, y el primer enemigo Dude Monster. El enemigo se anima, cae, colisiona con el terreno y avanza horizontalmente hacia el jugador. Jugador y enemigo se atraviesan: todavía no hay daño ni combate. El 29 de septiembre de 2026 se ejecutaron las ocho suites: 157 checks originales más 9 de `enemy`, **166/166 PASS**. El flujo de vidas y fin de etapa aún no tiene pruebas específicas. Estos cambios de juego y mapa siguen en el árbol de trabajo, sin commit.

**Completado (Sesión 6):**
- **Documentación del Proyecto**: `README.md` creado cubriendo arquitectura, inventario de archivos, decisiones técnicas y roadmap.
- **Git & GitHub Sync**: `.gitignore` creado y todo el proyecto commiteado y pusheado a `https://github.com/Ogzapatah1/PROYECTO-DE-JUEGO-SMB`.
- **Integración Tiled (.tmx)**: Archivo `assets/maps/level_1_1.tmx` creado para editar niveles visualmente y exportar a `.lua` mediante "Repeat last export on save".
- **Ajuste de Viewport**: `CAMERA_SCALE = 2` configurado en `main.lua` para ampliar el campo de visión.
- **Tuning de Salto**: `JUMP_SPEED = -340` configurado en `player.lua` para poder saltar sobre estructuras de 2 tiles de altura (64px).

**Pendiente (próxima sesión — Game Feel, nivel y gameplay):**
- Probar manualmente el recorrido completo, muerte/respawn, game over, fin de etapa y Dude Monster; las ocho suites automáticas ya pasaron.
- Decidir e implementar la interacción jugador-enemigo; ahora ambos se atraviesan.
- Diseñar escenarios más extensos y complejos en Tiled usando `level_1_1.tmx`.
- Agregar animaciones adicionales del jugador (`hurt`, `climb`, `attack`).
- Integrar efectos de sonido (FX de salto, impacto) y música de fondo.
- Crear el módulo `SceneManager` para transiciones de pantalla.

## Objetivo de la próxima sesión

- Verificar el estado actual del juego y escoger la regla de interacción con Dude Monster antes de ampliar los sistemas de enemigos.

## Bloqueado / pendiente de decisión

- Definir si el contacto con Dude Monster causa daño, permite derrotarlo saltando, u otra regla de juego. Documentar la decisión antes de implementarla.

## Recordatorio para próxima sesión

- Para probar el juego manualmente: `lovec .` (o `love .`).
- Para ejecutar los tests automáticos: `lovec . --test=full`.
- En el juego: Flechas = Mover, Z = Saltar, X = Correr, R = Recargar Mapa.
- El juego inicia con 3 vidas. El foso resta una; tras 5 segundos hay respawn. Con 0 vidas se muestra game over 6 segundos y se reinicia. Al llegar al extremo derecho, `C` indica que no hay más etapas y `F` finaliza; ambos caminos cierran tras 5 segundos.
- Al editar en Tiled (`assets/maps/level_1_1.tmx`), presionar `Ctrl + S` auto-exporta a `level_1_1.lua`. Presionar `R` en el juego recarga el nivel al instante.
