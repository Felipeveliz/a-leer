---
name: qa-aprende
description: Recorrido de QA de Aprende en el simulador, con las dos personas de prueba y los puntos donde ya se rompió antes. Úsala antes de un deploy o después de tocar el módulo Escribe.
---

# QA de Aprende

Nunca dar por buena una pantalla sin verla. Un build verde no dice nada del trazo:
`TraceEngine` y la identidad de las vistas de SwiftUI solo fallan en ejecución.

**El simulador no sustituye al iPad.** Los toques sintéticos son limpios y rectos; un
niño de cinco años con el dedo no lo es. Todo lo que diga este skill sobre tolerancias y
rechazo de palma hay que confirmarlo en un iPad físico con Apple Pencil.

## Las dos personas

**Eliab, 5 años, diestro.** No lee instrucciones. Toca dos veces seguidas sin querer.
Empieza a trazar donde le parece, no en el punto verde. Se sale del lienzo. Apoya la
palma en la pantalla. Traza despacio y en vertical. Si falla tres veces, se aburre y se
va. Si algo se borra sin que él lo borre, lo vive como un castigo.

**El adulto que lo acompaña.** Quiere ver qué ha hecho el niño, repetir una palabra,
y que nada se pierda al cerrar la app. No va a configurar nada.

## Recorrido

### Español
- Sílabas: "🔀 Otra sílaba" nunca repite la anterior.
- Palabras: separar y juntar sílabas; "Palabra anterior" vuelve por el historial y se
  desactiva en la primera.
- Oración: las tres pestañas; cambiar de pestaña reinicia el recorrido; la frase completa
  cabe en una línea y al tocar una palabra se resalta solo esa.

### Matemáticas
- Acertar: el botón se pone verde y las opciones se bloquean hasta "Otra suma".
- Fallar: coral, sacudida, vuelve a blanco y **deja volver a intentar**. Nunca un tache.

### Escribe — aquí es donde se ha roto

Estas cuatro son **regresiones conocidas**, todas arregladas el 18 de noviembre de 2026.
Comprobarlas una por una después de tocar `PalabraEscribeFlowView`, `NumerosEscribeView`,
`LetterTraceView`, `TraceCanvasView` o `Theme.swift`:

1. **El trazo del niño no se borra al pulsar "¡Listo!"** (palabras y números). Dibujar
   algo, pulsar "¡Listo!" y confirmar que la tinta **sigue ahí** junto al modelo y la
   estrella. Causa original: el `FreeWritePad` estaba en las dos ramas de un `if/else` y
   SwiftUI recreaba el `PKCanvasView`.
2. **Fase 2 en iPhone con palabras largas** (maleta, pelota): la letra en curso tiene que
   ser trazable, no una rendija. La fila se desplaza para seguirla.
3. **Un trazo vertical lento no mueve la pantalla.** Trazar despacio de arriba abajo
   dentro de un lienzo: tiene que pintar, no hacer scroll.
4. **Deshacer** quita el último trazo y deja los anteriores.

Y el recorrido normal:
- Calentar la mano: los cuatro trazos en orden, y "¡Mano lista!" al final.
- Una palabra completa de punta a punta: fase 1 letra por letra, fase 2, fase 3.
- La estrella aparece y **sobrevive a cerrar y abrir la app** (`UserDefaults`).
- Números: el flujo de dos pasos de un dígito.

### Como Eliab lo usa de verdad
- Trazar **al revés** (de abajo arriba): tiene que rechazarlo, porque la dirección es
  parte de lo que se enseña.
- Trazar **fuera** de la caja: no debe dar por bueno un garabato.
- **Fallar tres veces seguidas**: tiene que volver a demostrar el trazo solo.
- El punto de la "i" con **un toque corto**.
- Tocar dos veces seguidas una tarjeta del menú: no debe abrir dos pantallas.

## Qué no hace falta revisar

- **Modo oscuro**: la app fuerza esquema claro en `AprendeApp`. Si alguien quita ese
  `preferredColorScheme(.light)`, vuelve a entrar en el recorrido.
- Rotación: las cuatro orientaciones están permitidas, pero el contenido va en un
  `ScrollView` con ancho máximo y no hay layouts específicos de horizontal.

## Cerrar

Lo que se rompa y se arregle se anota en la sección 8 de `CLAUDE.md`, y si la causa no
era obvia, la lección va a las convenciones de la sección 6. Un bug que vuelve es un bug
que no se documentó.
