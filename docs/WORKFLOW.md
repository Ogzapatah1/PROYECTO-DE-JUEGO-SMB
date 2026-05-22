# Flujo de trabajo — My Game Project

Este archivo define cómo trabajamos juntos en cada sesión de desarrollo.
El objetivo es no perder contexto entre sesiones y tomar mejores decisiones técnicas.

---

## Al inicio de cada sesión

**Tú haces:**
1. Compartes el contenido de `SESSION.md`
2. Compartes el contenido de `DECISIONS.md` (aunque no haya nada pendiente)

**Yo hago:**
1. Confirmo que entendí el estado actual y el objetivo del día
2. Si hay decisiones abiertas en `DECISIONS.md`, te hago preguntas para ayudarte
   a elegir — no basado en lo primero que encontramos, sino evaluando criterios
   concretos (¿qué es más fácil de implementar ahora? ¿qué crea menos fricción
   de aprendizaje? ¿qué es más fácil de cambiar después si nos equivocamos?)
3. Si el objetivo del día no está claro, te propongo cómo dividirlo en pasos
   pequeños antes de arrancar

---

## Durante la sesión

- Trabajamos en el objetivo definido en `SESSION.md`
- Si aparece un concepto nuevo que no entiendes bien, lo marcamos con 📌
  para agregarlo a `CONCEPTS.md` al final
- Si aparece una bifurcación técnica (dos formas de hacer algo y no está claro
  cuál), paramos y la documentamos en `DECISIONS.md` antes de seguir
- No avanzamos sobre una decisión importante sin documentarla primero

---

## Al final de cada sesión

Yo te lo recuerdo. Actualizamos juntos estos archivos en orden:

### 1. `PROGRESS.md`
- ¿Qué quedó completado hoy? Lo movemos a ✅
- ¿Qué quedó en progreso? Lo actualizamos en 🔄
- ¿Apareció algo nuevo pendiente? Lo agregamos a ⬜

### 2. `DECISIONS.md`
- Si tomamos una decisión hoy, completamos los campos **Decisión** y **Resultado**
- Si apareció una nueva bifurcación técnica, creamos una entrada nueva con las
  opciones evaluadas y la dejamos en estado _pendiente_ si no se resolvió hoy

### 3. `CONCEPTS.md`
- Cualquier concepto marcado con 📌 durante la sesión lo escribimos aquí
- Lo escribimos en tus propias palabras + un ejemplo del juego específicamente
- Si ya existe una entrada del concepto, la expandimos o corregimos

### 4. `SESSION.md`
- Actualizamos **Dónde estamos** para reflejar el estado real al terminar hoy
- Limpiamos **Objetivo de hoy** (ya fue)
- Si quedó algo bloqueado o hay una decisión pendiente, lo dejamos anotado

---

## Reglas del sistema

- **Simple beats complex:** si algo de este sistema se siente como trabajo extra
  sin valor claro, lo eliminamos o simplificamos
- **No avanzar sobre decisiones sin documentar:** si hay dos caminos posibles y
  no está claro cuál tomar, documentar primero, decidir después
- **El código no es el único progreso:** entender un concepto nuevo, documentar
  una decisión, o aclarar un bloqueante también cuenta como avance del proyecto
- **Sesión mínima válida:** si no hay tiempo o energía, con solo actualizar
  `SESSION.md` es suficiente para no perder el hilo

---

*Sistema creado: Mayo 2026*
*Revisar y ajustar el flujo después de las primeras 3 sesiones usando este sistema*
