# CLAUDE.md — Aprende

Este archivo es la fuente de verdad del proyecto, para Claude Code y para Codex.
**No crear ni mantener `AGENTS.md`.** Es **estado actual, no historial**: lo que queda
obsoleto se borra, no se acumula. El changelog es git.

**Aprende** es una app nativa de iPhone/iPad para que Eliab (5 años) practique lectura,
sumas y escritura a mano con el dedo o con Apple Pencil. Interfaz en español mexicano.

- **Bundle ID**: `com.eduardovelross.aprende`
- **Deployment target**: iOS 17.0 · `TARGETED_DEVICE_FAMILY = 1,2` (iPhone y iPad)
- **Equipo de firma**: `AZDP5Q3YFJ`, firma automática
- **Stack**: SwiftUI + PencilKit + UserDefaults. Sin dependencias externas.
- **Versión web**: `index.html` en la raíz (GitHub Pages). Es el origen de los contenidos
  de la app nativa, pero **ya no hay paridad obligatoria**: la nativa avanzó con el módulo
  Escribe, que la web no tiene.

## 1. Cómo trabajar en este proyecto

### Interacción
- Español en toda la comunicación.
- Si hay duda sobre una decisión técnica o de producto, **preguntar antes de asumir**.
  No inventar features.
- No preguntar lo que se puede deducir del código.
- No crear documentos, artefactos ni archivos adicionales sin que Felipe lo pida.
- **Si el bloqueo es que se cayó su sesión** (App Store Connect, el portal de
  desarrollador), la respuesta es una línea: *"inicia sesión y yo sigo"*. Sin hipótesis
  de lo que puede haber pasado ni listas de causas probables: el análisis va después de
  ver el dato. Esto no aplica cuando él tiene que **decidir** algo; ahí sí hace falta
  el contexto.
- Los errores de compilación se arreglan antes de seguir. No acumular warnings.
- Si lo que se observa en el código contradice este archivo o el git log, **frenar y
  reconciliar** antes de afirmar nada: uno de los dos está desactualizado.
- No generalizar el estado de un conjunto de archivos a partir de una muestra:
  verificar con `grep` o un script sobre todos.

### Deploy: se libera lo antes posible
Regla de Felipe (18 de noviembre de 2026, después del primer envío de Aprende):
**un deploy tiene que quedar reflejado para los usuarios cuanto antes.** Mandar a
revisión y esperar a aprobarla para liberarla a mano no es terminar el deploy.

- Al preparar la versión, dejar **"Automatically release this version"** en App Store
  Version Release. Nunca "Manually release" salvo que Felipe lo pida.
- Si una versión quedó en manual y Apple la aprueba (**Pending Developer Release**),
  liberarla de inmediato, sin preguntar.
- "Haz deploy" significa dejar la app **publicada**, no "enviada".

### Cómo se trabaja
- **Reproducir antes de corregir.** Un bug se ve fallar primero. Si no se puede
  reproducir, no se sabe si el arreglo arregló algo.
- **Evidencia real, no "debería funcionar".** Un build verde no prueba que el trazo
  funcione: `TraceEngine` y la identidad de las vistas de SwiftUI solo fallan en
  ejecución. Antes de decir que algo quedó, haberlo visto en el simulador.
- **Diff quirúrgico.** Tocar lo que el cambio pide y nada más. Los refactors de paso
  esconden el arreglo y rompen cosas que nadie estaba mirando.
- **Toda corrección deja lección.** Si la causa no era obvia, la convención va a la
  sección 6 y el estado a la sección 8, en el mismo commit. Un bug que vuelve es un bug
  que no se documentó.
- **Un flujo que se repite tres veces merece su skill** en `.claude/skills/`.

### Skills del proyecto
Antes de una tarea, revisar si hay un skill que la cubra:
- `ios-deploy` — archive, subida, ficha, cuestionarios y envío a revisión.
- `capturas-app-store` — capturas en los tamaños que Apple acepta.
- `qa-aprende` — recorrido de QA con las dos personas de prueba y las regresiones
  conocidas del módulo Escribe.

### Commits
- **Al terminar cada tarea, commit y push automáticamente, sin preguntar.** (Esta regla
  es propia de este repo; en Delivery Network y Karol es al revés.)
- Un bloque funcional por commit, con **build verde**.
- Mensajes de commit en **inglés, imperativo** ("Fix free canvas identity", no "Fixed...").
- Ningún secreto en commits.

### Idiomas
- **Código** (tipos, funciones, variables, archivos): inglés.
- **Nombres de dominio ya establecidos en español** (`Palabra`, `Silaba`, `Suma`,
  `palabrasEscribe`, `fase`, `actual`): se respetan, no se traducen. El codebase es
  mixto a propósito y es demasiado tarde para cambiarlo sin ruido.
- **Comentarios**: español, y explican el **por qué**, no el qué.
- **Copy de la UI**: español mexicano, tuteando al niño.

## 2. Build & run

No hay linter. Todo pasa por Xcode o `xcodebuild`.

```bash
open Aprende/Aprende.xcodeproj
```

```bash
cd Aprende && xcodebuild -project Aprende.xcodeproj -scheme Aprende -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

### Tests
El target `AprendeTests` cubre la lógica pura: `TraceEngine`, la tabla de `AppData` y
los invariantes de `GlyphLibrary`. No cubre vistas; eso va por el skill `qa-aprende`.

```bash
cd Aprende && xcodebuild test -project Aprende.xcodeproj -scheme Aprende -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Los tests tienen que pasar antes de cada commit que toque `TraceEngine.swift`,
`Glyphs.swift` o `Models.swift`.

Para archivar y subir a TestFlight / App Store:

```bash
cd Aprende && xcodebuild -project Aprende.xcodeproj -scheme Aprende -configuration Release -destination 'generic/platform=iOS' -archivePath build/Aprende.xcarchive -allowProvisioningUpdates archive
```

```bash
cd Aprende && xcodebuild -exportArchive -archivePath build/Aprende.xcarchive -exportOptionsPlist Config/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates
```

Subir a App Store Connect **necesita que Xcode tenga la cuenta de Apple con sesión
iniciada** (Xcode › Settings › Accounts). Sin ella, el archive falla con
`No Accounts: Add a new account in Accounts settings`. Hay que subir
`CURRENT_PROJECT_VERSION` en cada subida: App Store Connect rechaza un build repetido.
El proyecto declara `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`, así que los
builds nuevos ya no se quedan en "Missing Compliance" esperando una respuesta a mano.

`scripts/make_icon.swift` genera el icono de 1024 y `scripts/render_glyphs.swift` ayuda
a revisar los trazos de la biblioteca de glifos.

### Si el simulador se cuelga
Esta Mac no tiene `Simulator.app`, pero el simulador funciona sin él. Si `simctl launch`
no termina o la app se queda con el icono atenuado, el servicio de CoreSimulator está en
mal estado. Reiniciarlo (no borra datos de las apps) y volver a arrancar el dispositivo:

```bash
xcrun simctl shutdown all; killall -9 com.apple.CoreSimulator.CoreSimulatorService
```

El primer arranque después tarda; la pantalla blanca de los primeros segundos al lanzar
la app es normal.

### Añadir archivos al proyecto
El target usa un **grupo sincronizado con el sistema de archivos**
(`PBXFileSystemSynchronizedRootGroup` sobre `Aprende/Aprende`), así que las fases
`Sources` y `Resources` del `pbxproj` están vacías a propósito: **basta con dejar el
archivo dentro de `Aprende/Aprende/` y Xcode lo compila**. No hay que tocar el
`project.pbxproj` para añadir código ni recursos.

## 3. Arquitectura

No hay ViewModels ni capa de servicios: es una app de vistas con estado local
(`@State`) más un único store compartido.

- **`AppData` (`Models.swift`)** — todo el contenido es estático y está en código:
  sílabas, palabras, oración, sumas, orden de dificultad de Escribe. No hay backend,
  ni archivos de datos, ni red.
- **`Hoja`** — el contenido viene de las hojas que Eliab trae de la escuela. Cada
  sílaba, palabra y palabra de la oración lleva un `Set<Hoja>`, **no una sola hoja**:
  "pelota" y "rata" vienen en la 2 y en la 3, y si fuera una sola, al marcar solo la
  hoja 3 faltarían palabras que sí están en su hoja. La hoja 1 se perdió.
- **`HojaStore`** — singleton con las hojas marcadas, guardado en `UserDefaults`
  (`aprende.hojas`). Nunca queda vacío: la última casilla marcada no se puede
  desmarcar, porque una pantalla sin nada que practicar no le dice nada a un niño.
- **`ProgressStore`** — singleton `ObservableObject` que guarda las estrellas ganadas
  en `UserDefaults` bajo la clave `aprende.progreso`, con logros `"palabra:<texto>"` y
  `"digito:<d>"`. Es lo único que persiste.
- **`PerfilStore`** — singleton `ObservableObject` con lo que la app no puede adivinar y
  un adulto captura una vez: el **nombre** del niño (`aprende.nombre`) y su **mano**
  dominante (`aprende.mano`, diestro/zurdo). Antes la app era de un solo niño y esto
  estaba fijo en código; con un salón entero cada niño trae el suyo. Se pregunta en el
  primer arranque (`CapturaNombreView` sobre `HomeView` mientras `!configurado`) y se
  corrige desde "Escribir mi nombre". La mano decide de qué lado va el modelo en Escribe.
- **`GlyphLibrary` (`Glyphs.swift`)** — los trazos de cada letra y dígito en una caja
  unitaria con Y hacia abajo (ascendentes 0.08, x-height 0.38, línea base 0.88,
  descendentes 1.00). El **orden de los puntos codifica la dirección correcta** de
  escritura: por eso el motor puede castigar trazar al revés. Cubre el **abecedario
  completo** —minúsculas, mayúsculas, acentos (á é í ó ú, Á É Í Ó Ú, ü) y ñ/Ñ— para que
  "Escribir mi nombre" funcione con cualquier nombre. `scripts/render_glyphs.swift`
  los vuelca a un HTML con SVGs (con punto de inicio y dirección) para revisarlos sin
  simulador.
- **`TraceEngine`** — valida el trazo del niño contra el del glifo: inicio, final, forma
  (distancia media punto a punto tras re-muestrear a 48 puntos) y longitud. Las
  tolerancias son **generosas a propósito**; es pedagogía, no caligrafía.
  `joinStrokes` une varios trazos del glifo en un camino continuo **metiendo el
  recorrido de vuelta** entre uno y otro: al escribir la "m" sin despegar el lápiz se
  vuelve a subir por el palito, y ese tramo está en el trazo del niño aunque no esté en
  la definición del glifo.
- **`TraceCanvasView`** — `UIViewRepresentable` sobre `PKCanvasView`. Captura la tinta y
  entrega los puntos de cada trazo. Soporta borrar (`clearTrigger`) y deshacer el último
  trazo (`undoTrigger`), ambos por contador que se incrementa.
- **`DrawingGuard`** — singleton que marca "hay un trazo en curso". `ScreenScaffold`
  lo observa y desactiva su `ScrollView` mientras dura, para que un trazo vertical no
  se convierta en scroll.
- **`LetterTraceView`** — junta glifo + guías + demo animada + lienzo + validación.
  Es el componente central del módulo Escribe.
- **`GlyphText`** — dibuja una palabra con los trazos de `GlyphLibrary` en vez de con
  la fuente. En Escribe el modelo, las letras ya logradas y la lista usan esto, no
  `Text`: la fuente del sistema escribe la "a" de dos pisos y lo que el niño aprende a
  trazar es la de bola y palito. Enseñarle una forma y pedirle la otra lo confunde.
- **`Theme.swift`** — paleta, tipografía redondeada y los componentes compartidos
  (`Card`, `MenuCard`, `BigButton`, `UndoButton`, `TagPill`, `HintText`, `ScreenHeader`,
  `StarBadge`, `ScreenScaffold`).

## 4. Estructura del proyecto

```
.
├── CLAUDE.md
├── .claude/skills/            ios-deploy · capturas-app-store · qa-aprende
├── index.html                  Versión web (GitHub Pages), origen de los contenidos
├── scripts/
│   ├── make_icon.swift         Genera el AppIcon de 1024
│   └── render_glyphs.swift     Revisión visual de los trazos
├── privacidad.html             Política de privacidad (la pide App Store Connect)
├── soporte.html                Página de soporte (la pide App Store Connect)
├── AppStoreMetadata/
│   ├── es-MX.md                Copy de la ficha, respuestas de los cuestionarios
│   └── screenshots/            Capturas 1320x2868 (iPhone) y 2064x2752 (iPad)
└── Aprende/
    ├── Aprende.xcodeproj/      pbxproj mínimo; el código entra por grupo sincronizado
    ├── Config/ExportOptions.plist  Subida a App Store Connect
    ├── AprendeTests/           Tests de TraceEngine, AppData y GlyphLibrary
    └── Aprende/
        ├── AprendeApp.swift    @main; fuerza esquema claro
        ├── Models.swift        AppData: todo el contenido estático
        ├── Glyphs.swift        GlyphLibrary: trazos de letras, dígitos y calentamiento
        ├── TraceEngine.swift   Validación de trazos
        ├── TraceCanvasView.swift  PKCanvasView + DrawingGuard
        ├── LetterTraceView.swift  Glifo guiado: guías, demo, validación
        ├── ProgressStore.swift    Estrellas en UserDefaults
        ├── HojaStore.swift         Hojas marcadas, en UserDefaults
        ├── PerfilStore.swift       Nombre y mano del niño, en UserDefaults
        ├── GlyphText.swift         Palabra dibujada con los trazos del glifo
        ├── PrivacyInfo.xcprivacy  Manifiesto de privacidad (UserDefaults, CA92.1)
        ├── Theme.swift            Paleta y componentes compartidos
        ├── Assets.xcassets/       AppIcon (1024) y AccentColor
        └── Views/
            ├── HomeView.swift          Raíz de navegación (3 módulos) + primer arranque
            ├── CapturaNombreView.swift Captura de nombre y mano (teclado de un adulto)
            ├── EspanolMenuView.swift
            ├── SilabasView.swift       Sílaba aleatoria
            ├── PalabrasView.swift      Palabra aleatoria + separar sílabas
            ├── OracionView.swift       Sílabas / palabras / oración completa
            ├── MatematicasView.swift   Sumas con 5 opciones
            └── Escribe/
                ├── EscribeMenuView.swift
                ├── MiNombreView.swift            Partes del nombre + nombre completo
                ├── PalabrasEscribeListView.swift
                ├── PalabraEscribeFlowView.swift  3 fases + FreeWritePad
                ├── NumerosEscribeView.swift      Lista + flujo de 2 pasos por dígito
                └── WarmUpView.swift              4 trazos de calentamiento
```

## 5. Decisiones de producto (son decisiones, no bugs)

No "arreglar" nada de esto sin consultarlo con Felipe:

- **Solo español, sin catálogo de strings.** La app es para un niño mexicano; el copy va
  escrito en el código. Si algún día se publica en más mercados, ahí se decide el contrato
  de i18n (Toss tiene uno de 87 locales que sirve de modelo).
- **Esquema claro siempre.** La paleta es fija y cálida; `AprendeApp` fuerza
  `.preferredColorScheme(.light)` para que la barra de navegación y los controles del
  sistema no se vayan a negro contra tarjetas blancas.
- **El modelo va arriba, del lado que NO tapa la mano del niño.** Diestro: a la
  izquierda; zurdo: a la derecha. La mano se elige en el primer arranque y se guarda en
  `PerfilStore`. Antes estaba fijo a la izquierda porque la app era de un solo niño
  diestro (Eliab); al bajarla un salón entero dejó de poder asumirse, igual que el
  nombre.
- **En "¡Tú solo!" el modelo empieza oculto**, con un botón "👀 Ver otra vez" que lo
  enseña 3 segundos. La idea es recordar, no copiar.
- **Al pulsar "¡Listo!" el trazo del niño NO se borra.** Se queda en el lienzo junto al
  modelo para que pueda compararlos. Es el punto pedagógico de la fase.
- **En Escribe las letras se dibujan, no se escriben con la fuente.** El modelo tiene
  que enseñar exactamente la forma que se le pide al niño. Fuera de Escribe (Español,
  Matemáticas) se usa la fuente normal: ahí se lee, no se copia.
- **Un movimiento del niño puede valer por varios trazos del glifo.** La "m" está
  definida en tres trazos, pero se escribe de un tirón; `LetterTraceView` prueba el
  trazo suelto y luego va uniendo los siguientes. Exigir que levante el lápiz entre
  parte y parte es exigir algo que nadie hace al escribir. El punto de la "i" es la
  excepción: va aparte y no se une a nada.
- **Feedback amable, nunca tache rojo.** Un fallo da "¡Casi! Otra vez 🙂", háptica suave y
  limpia el lienzo; a los 3 intentos se vuelve a demostrar el trazo.
- **Las tolerancias de `TraceEngine` son generosas a propósito.** Se valida dirección y
  forma aproximada. Subirlas convierte el juego en frustración.
- **Las estrellas solo existen en Escribe.** Español y Matemáticas no guardan progreso.
- **Matemáticas siempre ofrece las mismas 5 opciones (2–6).** Es el rango que Eliab está
  practicando. **Las sumas no dependen de la hoja**: por eso Matemáticas no lleva
  selector.
- **Las casillas de hoja van en cuatro pantallas** (las tres de Español y la lista de
  palabras de Escribe), compartiendo una sola selección. Por defecto están las dos
  marcadas. Son casillas, no botones de opción: se puede practicar con las dos a la vez.
- **Las sílabas de una hoja salen de sus palabras.** Una hoja sin página de sílabas (la 3)
  igual las tiene: las de descomponer sus propias palabras. Lo hace `AppData.silabas(en:)`
  y por eso Sílabas nunca se queda vacía. Las derivadas van en minúscula y sin repetir:
  en sílabas se lee el sonido, y las mayúsculas se practican en las palabras.
- **La hoja 3 no trae oración.** Si se marca sola, "Leer una oración" enseña la de la
  hoja 2, **sin avisar**: quien entra viene a leer una oración, no a que le expliquen de
  dónde salió. El aviso amarillo que lo explicaba se quitó porque Felipe lo leyó tres
  veces como un error de la app, con razón.
- **El nombre lo captura un adulto, una vez.** "Escribir mi nombre" (en Escribe) enseña
  a trazar el nombre del niño: primero cada parte (nombre y apellidos), luego el nombre
  completo, con el mismo flujo de 3 fases de las palabras. La app no puede adivinar el
  nombre, así que lo teclea un adulto en el primer arranque (`CapturaNombreView`) y lo
  corrige con "Modificar nombre"; **es el único teclado de la app** y el niño nunca
  escribe en él. El nombre se parte por espacios: una "palabra" trazable por parte. Por
  eso `GlyphLibrary` tuvo que crecer al abecedario completo.
- **Sin red, sin cuentas, sin analítica.** Lo único que persiste es `UserDefaults`.
- **Solo en países hispanohablantes** (decisión de Felipe, 22 de noviembre): los 18
  territorios de habla hispana con App Store propia. Cuba y Guinea Ecuatorial no están
  en la lista de Apple, y Puerto Rico usa la tienda de Estados Unidos. Estados Unidos
  **no** está incluido.

## 6. Convenciones de código

### Swift
- `struct` sobre `class`; `let` sobre `var`.
- **Nunca** force unwrap (`!`), `try!` ni `as!`.
- `guard let` para early returns, no pirámides de `if let`.
- Nombres descriptivos completos.
- Funciones ~40 líneas, archivos ~300 líneas; si crece, dividir.

### SwiftUI
- Vistas pequeñas; extraer subvistas al pasar de 50 líneas.
- `#Preview` en cada vista de pantalla.
- Nada de lógica de negocio dentro del `body`.
- **La identidad de las vistas importa.** Una vista con estado interno (cualquier
  `UIViewRepresentable`, y `FreeWritePad` en particular) **nunca** va dentro de las dos
  ramas de un `if/else`: SwiftUI la trata como dos vistas distintas, recrea la vista de
  UIKit y pierde su contenido. Va una sola vez, fuera del condicional, y lo que cambia
  es un parámetro (`isEnabled`). Este fue un bug real en Escribe.
- Lo mismo con `ScrollView`: no se sustituye por un `VStack` según el estado. Si hay que
  bloquearlo, `.scrollDisabled(...)`.
- Cuando una lista de contenido se arma buscando por texto (como `palabrasEscribe`), la
  construcción lleva `assertionFailure` en los casos imposibles: un dedazo ahí se salta
  en silencio y nadie lo nota.

### Glifos
- **Todo glifo nuevo o tocado se mira dibujado** con `scripts/render_glyphs.swift`
  antes de commitear. Los tests comprueban que existe y que cae en la caja, no su
  forma: la "U" salió al revés (∩) con todos los tests en verde.
- En los arcos, **Y va hacia abajo**: 90° es el fondo y -90° (o 270°) la cima. Un arco
  de 180° a 0° pasa por abajo (∪); de 180° a 360°, por arriba (∩).
- Los acentos de las mayúsculas caben solo entre y = 0 y 0.04 (la letra empieza en
  0.10), con la punta de abajo fuera de la parte más alta de la letra.
  `testLosAcentosNoTocanSuLetra` lo vigila.

**Reglas de trazo (decisión de Felipe, 23 de noviembre).** La app enseña la **convención
estándar**, no el método de la escuela de Eliab. No hay un estándar mundial único, así
que la forma de que esto sea verificable y no una opinión es que estas reglas estén
escritas y **las cumplan los 75 glifos sin excepción**:
1. De **arriba abajo**.
2. De **izquierda a derecha** (`testLosTrazosHorizontalesVanDeIzquierdaADerecha`).
3. Los redondeles **contra reloj**, empezando como a las 2
   (`testLasLetrasRedondasGiranContraReloj`).
4. Primero el **cuerpo** y al final la **barra, el punto o el acento**, que siempre es más
   corto (`testLaMarcaFinalVaAlFinalYEsMasCorta`).
Un glifo nuevo pasa esos tres tests o no entra. Hoy 0, 1, 2, 3, 6, 7 y 8 van en 1 trazo;
4, 5 y 9 en 2 (el 5: cuerpo y luego el sombrerito).

## 7. Protocolo de actualización de este archivo

Cada cambio que toque arquitectura, estructura, decisiones, stack o estado **actualiza
este archivo en el mismo commit**. No "después", no "en la siguiente sesión".

| Tipo de cambio | Sección a actualizar |
|---|---|
| Archivo Swift nuevo, movido o eliminado | 4. Estructura del proyecto |
| Componente compartido, store o motor nuevo | 3. Arquitectura + 4. Estructura |
| Decisión de producto que no hay que "arreglar" | 5. Decisiones de producto |
| Patrón o invariante que las próximas sesiones deben respetar | 6. Convenciones |
| Cambio de bundle ID, deployment target, familia de dispositivos, firma | Encabezado + 2. Build & run |
| Framework o dependencia nueva | Encabezado + 3. Arquitectura (y por qué) |
| Herramienta, script, test o paso de CI nuevo | 2. Build & run |
| Skill nuevo en `.claude/skills/` | 1. Skills del proyecto |
| Pendiente resuelto o nuevo | 8. Pendientes |

**No hace falta** actualizarlo por: un typo en el copy, un cambio de color o padding, un
refactor interno que no cambia nada observable, o un bug fix que no toca ninguna de las
secciones de arriba.

Regla práctica: si una sesión que lea este archivo en frío se llevaría una **sorpresa** al
abrir el código, el cambio necesitaba actualizar el archivo.

## 8. Pendientes

### Pedidos de Felipe (hechos en la 1.1 build 7, 23 de noviembre)

Los nueve que dictó el 23 de noviembre, ya implementados y probados:

- [x] **1.** Captura de nombre: mano **izquierda a la izquierda**, **derecha a la derecha**,
      y **ninguna marcada por defecto** (`PerfilStore.mano` es `Mano?`). "Listo" no se
      activa hasta que haya nombre **y** mano, y `configurado` exige las dos cosas.
- [x] **2.** **Las sílabas de una hoja salen de sus palabras.** `AppData.silabas(en:)`
      devuelve las de la lista marcadas con esas hojas **más** las de descomponer sus
      palabras (en minúscula y sin repetir). Con eso la hoja 3 pasó de 0 a 26 sílabas,
      incluidas las 8 que no existían (`ir`, `is`, `mue`, `món`, `o`, `pas`, `rre`, `sol`).
      De paso salió un duplicado viejo: "mo" estaba en Mm y otra vez en Repaso.
- [x] **3.** Fuera la pastilla del grupo (Ll, Rr, Repaso…) en Sílabas y Palabras. El campo
      `grupo` se queda en los datos como procedencia, pero **ya no se muestra**.
- [x] **4.** Fuera los subtítulos de instrucciones en Sílabas y Palabras. `ScreenHeader`
      ahora acepta `subtitle` opcional.
- [x] **5.** La oración va en **una línea a tamaño fijo (34 pt)** dentro de un carril
      horizontal: en iPad entra completa y centrada, en iPhone **se desliza de lado**.
      Antes se encogía hasta ~18 pt. Se intentó con `ViewThatFits` y no sirve: elegía
      siempre el tamaño mayor y dejaba la frase cortada.
- [x] **6.** Fuera el aviso `AvisoRespaldo` ("Hoja 3 no trae oración…"), componente y usos.
      El respaldo sigue, pero silencioso.
- [x] **7.** Botón **🧮 Ábaco** en Matemáticas, que alterna como "Separar sílabas": muestra
      los dos sumandos en cuentas de colores distintos separadas por un "+", para contar.
      Se esconde solo al pasar a otra suma.
- [x] **8.** La demo del trazo se repite **en cada error**, no a los 3 intentos.
- [x] **9.** Los trazos siguen la **convención estándar**, no la escuela de Eliab (decisión
      de Felipe). Las reglas están en la sección 6 y las vigilan tres tests; la auditoría
      de los 75 glifos salió limpia.

### Revisión de código
- [x] Fase 3 "¡Tú solo!" borraba lo escrito al pulsar "¡Listo!" (también pasaba en
      Números). Arreglado: un solo `FreeWritePad` fuera del `if`.
- [x] `palabrasEscribe` tenía "rosa" en minúscula (entrada muerta) y le faltaba "remo".
      Arreglado, con `assertionFailure` para que no vuelva a pasar en silencio.
- [x] El `ScrollView` de `ScreenScaffold` le robaba el gesto al trazo. Arreglado con
      `DrawingGuard` + `.scrollDisabled`.
- [x] Fase 2 con palabras largas en iPhone. Arreglado: altura mínima por letra, caja de
      trazo con ancho mínimo y la fila se desplaza para seguir la letra en curso.
- [x] Modo oscuro: la app fuerza esquema claro.
- [ ] Validar el punto de la "i" con un solo toque en un dispositivo real (en el
      simulador el toque sintético no es representativo).
- [x] Revisión adversaria del código de la 1.1 (22 de noviembre). Se arreglaron: la "U"
      y la "Ú" al revés (∩), los acentos de Á/É/Í/Ó pegados a la letra, la "G" que se
      leía como "C" con guion, las pancitas de la "B" cruzadas, el nombre completo que
      se salía de la pantalla en iPhone (`GlyphText` ahora se encoge para caber) y el
      contador de la fase 1 que contaba los espacios del nombre.

### Mejoras propuestas, sin decidir
- [ ] **Voz** (`AVSpeechSynthesizer` es-MX): la app dice "lee en voz alta" en tres
      pantallas y no pronuncia nada. Es lo de mayor impacto pedagógico que falta.
- [ ] Progreso (estrellas) también en Español y Matemáticas.
- [ ] Matemáticas: restas, dificultad progresiva, racha.
- [x] Más glifos: ya está el **abecedario completo** (minúsculas, mayúsculas, acentos y
      ñ/Ñ), dibujado para que "Escribir mi nombre" sirva con cualquier nombre. Revisado
      con `render_glyphs.swift` y probado en el simulador el 22 de noviembre.
- [ ] **Letras de nombres catalanes** (Ò, À, È, ç, ï): hoy se saltan y `CapturaNombreView`
      avisa al adulto. Decidir con Felipe si se añaden (la app también sale en España).
- [ ] **Faltan las páginas de sílabas y oración de la hoja 3**, si existen. Hoy la hoja 3
      solo tiene las 20 palabras de "Lectura de palabras".
- [ ] Zona de adultos: reiniciar el progreso, ver qué ha hecho.
- [ ] Accesibilidad: los botones son puro emoji sin `accessibilityLabel` y las fuentes
      son de tamaño fijo (ignoran Dynamic Type).

### Prueba en dispositivo real
- [ ] iPad físico con Apple Pencil: trazo, rechazo de palma, tolerancias de validación.

### TestFlight y primer deploy

Estado al 22 de noviembre de 2026: **Apple aprobó Aprende 1.0 (build 2)** a las 7:43 y
quedó en "Ready for Distribution" (Apple ID 6836391055). Gratis, 4+, Data Not Collected,
salida automática. Disponibilidad configurada el 22 de noviembre en los **18 países
hispanohablantes**; ese día quedó "En proceso: 18".

**Precio y disponibilidad son dos cosas distintas** en *Precio y disponibilidad*. La
tabla de precios decía "175 países o regiones" y se anotó como si la app estuviera
disponible ahí, pero la sección **"Disponibilidad de la app"** seguía vacía, con el
botón "Configurar disponibilidad". Una versión aprobada sin ningún país disponible sale
en la lista de apps como **"Removed from App Store"**, aunque nadie la haya retirado y
sin que llegue ningún correo. Se comprueba en esa sección, no en la de precios.

Historia corta: Apple rechazó la primera submission con **Guideline 2.1 — Information
Needed** y se contestaron los seis puntos por escrito, sin vídeo (decisión de Felipe).
**Responder en Resolution Center NO devuelve la versión a la cola**: se quedó en
"Rejected" en rojo todo el día, mientras una app en revisión se ve en amarillo como
"Waiting for Review". Para volver a la cola hubo que **cancelar la submission**
(queda como "Removed"), lo que devuelve la versión a *Prepare for Submission*, cambiar
el build y enviar otra vez. Las notas del revisor y la salida automática sobreviven a
la cancelación.

**El color de la lista de apps es el indicador fiable**: rojo = parada, amarillo = en
cola. Si después de una acción no se pone amarilla, no está en revisión.

**La 1.0 salió con la build 2**, que todavía tiene el mensaje de hoja vacía y la "m"
que no acepta el trazo continuo (decisión de Felipe del 19 de noviembre: no cambiar el
build de la revisión). Los arreglos están en TestFlight y van en la siguiente versión.

**TestFlight**: grupo interno **"Pruebas"** con distribución automática y Felipe como
único tester. La más nueva es la **1.1 (7)**, subida el 23 de noviembre: la 1.1 (6) más
los nueve pedidos de Felipe de ese día (ver la sección 8). La 1.1 (6) llevaba lo de la
build 5 (hojas + respaldo + trazo continuo + modelo dibujado) más el perfil del niño
(nombre y mano), el abecedario completo y "Escribir mi nombre". Un build recién procesado aparece
como **"Missing Compliance"** y no se distribuye hasta contestarlo; desde la build 3 ya
no debería pasar, porque el proyecto declara
`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`.

Lo aprendido antes, que sigue valiendo:
- Las capturas de iPhone tienen que ser **1206 × 2622** (6.1"/6.3").
- **La descripción no admite emoji.**
- El App ID hay que registrarlo a mano en developer.apple.com antes de crear la ficha.
- Las notas del revisor en **inglés**.

### Pendientes del deploy
- [ ] Confirmar que la disponibilidad pasa de "En proceso" a "Disponible" y que Aprende
      aparece en la App Store de México.
- [ ] Probar la **1.1 (7)** en el iPad desde TestFlight y, si está bien, mandarla a
      revisión como siguiente versión de la App Store.
- [ ] De los nueve pedidos, el **8** (demo del trazo en cada error) se revisó en código
      pero **no se vio fallar en pantalla**: el trazo sintético caía fuera del lienzo
      angosto de la "r". Confirmarlo en el iPad.
- [ ] App Store Connect pide revisar las **nuevas preguntas de clasificación por edad**
      (aviso en la lista de apps, sección "Información de la app").
- [ ] **La build 2 se envió sin que nadie la ejecutara**: la Mac se quedó sin runtimes de
      simulador. Probarla en TestFlight, sobre todo "limón" e "Irma" en Escribe, que
      estrenan los glifos "ó" e "I".
- [ ] Si Apple vuelve a pedir el vídeo: instalarla desde TestFlight y grabarla en el iPad.
- [ ] Más capturas de iPad: solo hay la de inicio.
- [ ] Subir `CURRENT_PROJECT_VERSION` antes de cada build nuevo.
