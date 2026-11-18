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
- Los errores de compilación se arreglan antes de seguir. No acumular warnings.
- Si lo que se observa en el código contradice este archivo o el git log, **frenar y
  reconciliar** antes de afirmar nada: uno de los dos está desactualizado.
- No generalizar el estado de un conjunto de archivos a partir de una muestra:
  verificar con `grep` o un script sobre todos.

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

No hay tests ni linter. Todo pasa por Xcode o `xcodebuild`.

```bash
open Aprende/Aprende.xcodeproj
```

```bash
cd Aprende && xcodebuild -project Aprende.xcodeproj -scheme Aprende -destination 'generic/platform=iOS Simulator' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

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

`scripts/make_icon.swift` genera el icono de 1024 y `scripts/render_glyphs.swift` ayuda
a revisar los trazos de la biblioteca de glifos.

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
- **`ProgressStore`** — singleton `ObservableObject` que guarda las estrellas ganadas
  en `UserDefaults` bajo la clave `aprende.progreso`, con logros `"palabra:<texto>"` y
  `"digito:<d>"`. Es lo único que persiste.
- **`GlyphLibrary` (`Glyphs.swift`)** — los trazos de cada letra y dígito en una caja
  unitaria con Y hacia abajo (ascendentes 0.08, x-height 0.38, línea base 0.88,
  descendentes 1.00). El **orden de los puntos codifica la dirección correcta** de
  escritura: por eso el motor puede castigar trazar al revés.
- **`TraceEngine`** — valida el trazo del niño contra el del glifo: inicio, final, forma
  (distancia media punto a punto tras re-muestrear a 48 puntos) y longitud. Las
  tolerancias son **generosas a propósito**; es pedagogía, no caligrafía.
- **`TraceCanvasView`** — `UIViewRepresentable` sobre `PKCanvasView`. Captura la tinta y
  entrega los puntos de cada trazo. Soporta borrar (`clearTrigger`) y deshacer el último
  trazo (`undoTrigger`), ambos por contador que se incrementa.
- **`DrawingGuard`** — singleton que marca "hay un trazo en curso". `ScreenScaffold`
  lo observa y desactiva su `ScrollView` mientras dura, para que un trazo vertical no
  se convierta en scroll.
- **`LetterTraceView`** — junta glifo + guías + demo animada + lienzo + validación.
  Es el componente central del módulo Escribe.
- **`Theme.swift`** — paleta, tipografía redondeada y los componentes compartidos
  (`Card`, `MenuCard`, `BigButton`, `UndoButton`, `TagPill`, `HintText`, `ScreenHeader`,
  `StarBadge`, `ScreenScaffold`).

## 4. Estructura del proyecto

```
.
├── CLAUDE.md
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
    └── Aprende/
        ├── AprendeApp.swift    @main; fuerza esquema claro
        ├── Models.swift        AppData: todo el contenido estático
        ├── Glyphs.swift        GlyphLibrary: trazos de letras, dígitos y calentamiento
        ├── TraceEngine.swift   Validación de trazos
        ├── TraceCanvasView.swift  PKCanvasView + DrawingGuard
        ├── LetterTraceView.swift  Glifo guiado: guías, demo, validación
        ├── ProgressStore.swift    Estrellas en UserDefaults
        ├── PrivacyInfo.xcprivacy  Manifiesto de privacidad (UserDefaults, CA92.1)
        ├── Theme.swift            Paleta y componentes compartidos
        ├── Assets.xcassets/       AppIcon (1024) y AccentColor
        └── Views/
            ├── HomeView.swift          Raíz de navegación (3 módulos)
            ├── EspanolMenuView.swift
            ├── SilabasView.swift       Sílaba aleatoria
            ├── PalabrasView.swift      Palabra aleatoria + separar sílabas
            ├── OracionView.swift       Sílabas / palabras / oración completa
            ├── MatematicasView.swift   Sumas con 5 opciones
            └── Escribe/
                ├── EscribeMenuView.swift
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
- **El modelo de la palabra va arriba a la IZQUIERDA.** Eliab es diestro: a la derecha
  su propia mano lo taparía.
- **En "¡Tú solo!" el modelo empieza oculto**, con un botón "👀 Ver otra vez" que lo
  enseña 3 segundos. La idea es recordar, no copiar.
- **Al pulsar "¡Listo!" el trazo del niño NO se borra.** Se queda en el lienzo junto al
  modelo para que pueda compararlos. Es el punto pedagógico de la fase.
- **Feedback amable, nunca tache rojo.** Un fallo da "¡Casi! Otra vez 🙂", háptica suave y
  limpia el lienzo; a los 3 intentos se vuelve a demostrar el trazo.
- **Las tolerancias de `TraceEngine` son generosas a propósito.** Se valida dirección y
  forma aproximada. Subirlas convierte el juego en frustración.
- **Las estrellas solo existen en Escribe.** Español y Matemáticas no guardan progreso.
- **Matemáticas siempre ofrece las mismas 5 opciones (2–6).** Es el rango que Eliab está
  practicando.
- **Sin red, sin cuentas, sin analítica.** Lo único que persiste es `UserDefaults`.

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
| Herramienta, script o paso de CI nuevo | 2. Build & run |
| Pendiente resuelto o nuevo | 8. Pendientes |

**No hace falta** actualizarlo por: un typo en el copy, un cambio de color o padding, un
refactor interno que no cambia nada observable, o un bug fix que no toca ninguna de las
secciones de arriba.

Regla práctica: si una sesión que lea este archivo en frío se llevaría una **sorpresa** al
abrir el código, el cambio necesitaba actualizar el archivo.

## 8. Pendientes

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
- [ ] Volver a correr una revisión adversaria del código Swift.

### Mejoras propuestas, sin decidir
- [ ] **Voz** (`AVSpeechSynthesizer` es-MX): la app dice "lee en voz alta" en tres
      pantallas y no pronuncia nada. Es lo de mayor impacto pedagógico que falta.
- [ ] Progreso (estrellas) también en Español y Matemáticas.
- [ ] Matemáticas: restas, dificultad progresiva, racha.
- [ ] Más glifos: hoy solo hay a, e, i, l, m, n, o, p, r, s, t, u, L, N, R y los dígitos.
      En cuanto Eliab avance a b/c/d/g/ñ o vocales acentuadas, Escribe se queda corto.
- [ ] Zona de adultos: reiniciar el progreso, ver qué ha hecho.
- [ ] Accesibilidad: los botones son puro emoji sin `accessibilityLabel` y las fuentes
      son de tamaño fijo (ignoran Dynamic Type).
- [ ] Target de tests: `TraceEngine` y el armado de `palabrasEscribe` son lógica pura.
      Hay que crearlo desde Xcode (el pbxproj se mantiene a mano).

### Prueba en dispositivo real
- [ ] iPad físico con Apple Pencil: trazo, rechazo de palma, tolerancias de validación.

### TestFlight y primer deploy

Estado al 18 de noviembre de 2026: **bloqueado en la ficha de App Store Connect.**

- [x] Cuenta de Apple Developer Program (team `AZDP5Q3YFJ`, certificado de distribución
      en el llavero).
- [x] `DEVELOPMENT_TEAM` configurado en las dos configuraciones.
- [x] `PrivacyInfo.xcprivacy` con la razón CA92.1 para `UserDefaults`.
- [x] URLs de privacidad y soporte, publicadas en GitHub Pages.
- [x] Copy de la ficha y respuestas de los cuestionarios: `AppStoreMetadata/es-MX.md`.
- [x] Capturas de iPhone 6.9" (4) y de iPad 13" (1, solo la de inicio).
- [x] Archive firmado, versión 1.0 build 1.
- [ ] **Crear la ficha en App Store Connect.** La API de App Store Connect no permite
      crear el registro inicial de una app, solo versiones de una que ya existe: hay que
      hacerlo en appstoreconnect.apple.com. Hasta que exista, `-exportArchive` falla con
      `App record with bundle identifier "com.eduardovelross.aprende" not found`.
- [ ] Subir el build.
- [ ] Más capturas de iPad (hacen falta toques en el simulador; el panel pide aprobar
      el acceso al dispositivo).
- [ ] Rellenar la ficha, los cuestionarios y enviar a revisión.
- [ ] El enlace a X en el footer: la ficha se envía como Educación **sin** marcar
      "Made for Kids" justamente para no toparse con la exigencia de puerta parental
      para enlaces externos. Si algún día se marca como Kids, hay que quitarlo o
      protegerlo.
