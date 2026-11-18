# Ficha de App Store — es-MX

Idioma principal de la app: **español (México)**. Es el único localizado.

## Datos de la app

| Campo | Valor |
|---|---|
| Bundle ID | `com.eduardovelross.aprende` |
| SKU | `aprende-001` |
| Apple ID | 6836391055 |
| Nombre a mostrar en el dispositivo | Aprende |
| Categoría principal | Educación |
| Categoría secundaria | (ninguna) |
| Precio | Gratis |
| Compras dentro de la app | Ninguna |
| Publicidad | Ninguna |
| Clasificación por edad | 4+ |
| Made for Kids | **No** (ver nota al final) |
| Versión | 1.0 (build 1) |

## Nombre (30 caracteres máx.)

```
Aprende
```

El nombre estaba libre en la App Store.

## Subtítulo (30 caracteres máx.)

```
Sílabas, sumas y trazo
```

Ya cargado en App Store Connect.

## Texto promocional (170 caracteres máx.)

```
Tres módulos para los primeros pasos: leer sílabas y palabras, sumar del 2 al 6 y escribir letras y números trazando con el dedo o con Apple Pencil.
```

## Descripción (4000 caracteres máx.)

**Sin emoji: App Store Connect los rechaza en este campo**
("This field contains one or more invalid characters").

```
Aprende es una app sencilla para acompañar a un niño en sus primeros pasos con la
lectura, los números y la escritura a mano. Sin anuncios, sin compras, sin cuentas y
sin conexión a internet.

ESPAÑOL
Sílabas para leer en voz alta, agrupadas por familia (la, le, li, lo, lu / ra, re, ri...).
Palabras que se pueden separar en sílabas de colores con un toque, para ver cómo se
arman. Y una oración completa que se practica por partes: primero las sílabas, luego
las palabras y al final la frase entera.

MATEMÁTICAS
Sumas con resultado del 2 al 6, el rango con el que se empieza. El niño toca la
respuesta entre cinco opciones grandes; si acierta, el botón se pone verde, y si no,
se mueve un poco y lo vuelve a intentar. Nunca hay un tache rojo.

ESCRIBE
Lo más cuidado de la app. Cada letra y cada número se traza siguiendo un punto verde y
una flecha que marcan por dónde empezar y hacia dónde ir, porque la dirección del trazo
importa tanto como la forma. La app primero enseña cómo se hace con una animación, y
después toca al niño.

Cada palabra pasa por tres fases: las letras una por una, la palabra completa letra por
letra, y al final "¡Tú solo!", un cuaderno en blanco sin guías donde escribe la palabra
de memoria y luego la compara con el modelo.

Funciona con el dedo y con Apple Pencil. Las palabras están ordenadas de la más fácil de
trazar a la más difícil, y los números también.

PROGRESO
Cada palabra y cada número terminados dan una estrella, que se guarda en el dispositivo
para que el niño vea lo que ya logró.

PRIVACIDAD
Aprende no recopila ningún dato. No tiene cuentas, ni analítica, ni publicidad, ni
conexión a ningún servidor. Las estrellas se guardan solo en el dispositivo y se borran
si se borra la app.

Pensada para niños de preescolar y primero de primaria, para usarse con un adulto cerca.
```

## Novedades de esta versión (4000 máx.)

```
Primera versión.
```

## Palabras clave (100 caracteres máx., separadas por comas, sin espacios)

```
leer,escribir,silabas,trazar,abecedario,preescolar,caligrafia,sumas,lectura,niños,primaria
```

## URLs

| Campo | Valor |
|---|---|
| URL de soporte (obligatoria) | https://felipeveliz.github.io/a-leer/soporte.html |
| URL de marketing | https://felipeveliz.github.io/a-leer/ |
| URL de política de privacidad (obligatoria) | https://felipeveliz.github.io/a-leer/privacidad.html |

## Privacidad de la app (cuestionario de App Store Connect)

**Respuesta: "No se recopilan datos" (Data Not Collected).**

La app no tiene red, ni SDK de terceros, ni analítica. Lo único que persiste es el
conjunto de estrellas en `UserDefaults`, que nunca sale del dispositivo: eso no cuenta
como recopilación según las definiciones de Apple.

## Clasificación por edad

Todas las preguntas del cuestionario en "Ninguno". Resultado esperado: **4+**.

- Sin violencia, sin lenguaje, sin temas de adultos, sin juegos de azar.
- Sin acceso web sin restricciones: la app no tiene navegador.
- Sí hay **un** enlace externo (el perfil del desarrollador en X, en el pie de la
  pantalla de inicio).

## Notas al revisor

```
Aprende es una app educativa para un niño de preescolar. No requiere cuenta ni conexión:
se puede revisar todo desde la pantalla de inicio sin configurar nada.

Para probar el módulo Escribe: Escribe › Palabras › elegir una palabra. Hay que trazar
empezando en el punto verde y siguiendo la flecha; la app valida la dirección del trazo,
no solo la forma. Funciona con el dedo en el simulador.

La app no recopila ningún dato y no se conecta a internet.
```

## Nota: categoría Kids

La app se envía en **Educación sin marcar "Made for Kids"**. Si algún día se marca como
Kids, Apple exige puerta parental para enlaces externos y habría que quitar o proteger el
enlace a X del pie de la pantalla de inicio (`Views/HomeView.swift`).

## Capturas

- `screenshots/iphone-6.3/` — **1206 × 2622** (iPhone 17 Pro). Es el tamaño que pide
  App Store Connect hoy para iPhone (6.1" o 6.3"); 1320 × 2868 lo rechaza.
- `screenshots/ipad-13/` — 2064 × 2752 (iPad Pro 13"). Obligatorias porque la app
  soporta iPad.

Tomadas de simuladores limpios, con la barra de estado fijada en 9:41 y batería llena.
