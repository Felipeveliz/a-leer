---
name: ios-deploy
description: Compila Aprende en Release, la sube a App Store Connect y la deja enviada a revisión. Úsala cuando Felipe diga "haz deploy", "súbela" o "mándala a revisión".
---

# Deploy de Aprende

**"Haz deploy" significa dejar la app publicada, no "enviada".** Mientras la versión no
esté disponible para los usuarios, el deploy no terminó. Ver el paso 7.

No se intercala nada: ni wording, ni refactors, ni backlog. Lo que aparezca en el camino
se anota y se hace después. Lo único que detiene el deploy es algo que solo puede hacer
Felipe: una contraseña, un código 2FA, aceptar un contrato legal.

**Este repo es público.** Nunca escribir aquí el teléfono, el correo ni ningún dato
personal de Felipe: se le piden en el momento y se teclean directamente en la consola
de Apple.

## Antes de empezar

1. **Xcode tiene que tener la cuenta de Apple con sesión iniciada** (Xcode › Settings ›
   Accounts). Sin ella el archive falla con `No Accounts: Add a new account in Accounts
   settings` y no hay forma de seguir desde la terminal. Es un bloqueo de Felipe.
2. **Subir `CURRENT_PROJECT_VERSION`** en `Aprende/Aprende.xcodeproj/project.pbxproj`.
   Aparece dos veces (Debug y Release). App Store Connect rechaza un build repetido.
3. Build Debug verde.
4. Al menos 3 GB libres en disco.

## 1. Archive

```
cd Aprende && xcodebuild -project Aprende.xcodeproj -scheme Aprende \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Aprende.xcarchive -allowProvisioningUpdates archive
```

Tiene que terminar en `** ARCHIVE SUCCEEDED **`. Tarda uno o dos minutos, pero puede
pasar de diez: darle tiempo antes de darlo por colgado. Lanzarlo en segundo plano y
avanzar con las capturas mientras corre.

## 2. Subir

```
cd Aprende && xcodebuild -exportArchive -archivePath build/Aprende.xcarchive \
  -exportOptionsPlist Config/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
```

Tiene que decir `Upload succeeded` y `** EXPORT SUCCEEDED **`. Después borrar
`Aprende/build/export` (ya está en Apple; `Aprende/build/` está ignorado por git).

## 3. La primera vez de un bundle ID nuevo

El archive con firma automática **no deja el App ID registrado**. Si App Store Connect
no lo lista al crear la ficha, registrarlo a mano en
developer.apple.com/account/resources/identifiers/bundleId/add/bundle: descripción
`Aprende`, Bundle ID explícito `com.eduardovelross.aprende`, sin capabilities. Después
recargar App Store Connect para que aparezca en el desplegable.

La ficha inicial de una app **solo se crea desde la web**: la API de App Store Connect
permite crear versiones, no el registro inicial. Si falta, `-exportArchive` falla con
`App record with bundle identifier "..." not found`.

## 4. Ficha

El copy vive en `AppStoreMetadata/es-MX.md`. Dos trampas comprobadas:

- **La descripción no admite emoji.** Devuelve "This field contains one or more invalid
  characters" sin decir en qué campo ni en qué carácter. Secciones en MAYÚSCULAS, sin
  emoji, sin `·` ni `…`.
- En el diálogo de creación de la app, los campos **no aceptan valores puestos por
  script**: se revierten. Ahí hay que hacer clic y escribir. En la página de la versión
  sí funciona rellenarlos directamente.

## 5. Capturas

Ver el skill `capturas-app-store`. **1206 × 2622 para iPhone**, no 1320 × 2868.

## 5bis. Cada build nuevo pide compliance de exportación

Al terminar de procesarse, un build aparece como **"Missing Compliance"** y no se
distribuye a los testers hasta contestarlo. Desde el 19 de noviembre el proyecto lleva
`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` en las dos configuraciones del target
de la app, así que **ya no debería preguntarlo**. Si vuelve a aparecer: TestFlight ›
el build › Manage › "None of the algorithms mentioned above" › Save.

## 6. Cuestionarios

Las respuestas están en `AppStoreMetadata/es-MX.md` y no cambian mientras la app no
cambie: Content Rights sin contenido de terceros, edad **4+** (todo en "ninguno", sin
marcar Made for Kids), privacidad **Data Not Collected** —hay que pulsar **Publish**, no
solo guardar— y cumplimiento de exportación **sin cifrado**.

Dos campos más no se piden hasta que pulsas "Add for Review", y entonces te frenan:
**precio** (gratis) y **copyright**.

También hay que **desmarcar "Sign-in required"** (la app no tiene cuentas) y rellenar el
contacto de App Review: nombre, correo y teléfono. **Esos datos se le piden a Felipe en
el momento**; no viven en el repo.

## 7. Salida: automática, siempre

En App Store Version Release dejar **"Automatically release this version"**. Nunca
"Manually release" salvo que Felipe lo pida. Si una versión quedó en manual y Apple la
aprueba (estado **Pending Developer Release**), liberarla de inmediato sin preguntar.

## 7bis. Si la versión está rechazada

Responder en Resolution Center **no la devuelve a la cola de revisión**: se queda en
"Rejected". Para reenviarla hay que **cancelar la submission** (botón "Cancel
Submission" abajo del todo; queda como "Removed"), lo que devuelve la versión a
*Prepare for Submission*. Desde ahí se puede cambiar el build —pasar el ratón por
encima de la fila del build saca un "−" rojo para quitarlo— y enviar otra vez. Las
notas del revisor, la salida automática y el resto de la ficha sobreviven.

## 8. Enviar

"Add for Review" → panel de Draft Submission → **"Submit for Review"**. Confirmar que el
estado queda en **Waiting for Review**. La comprobación buena es la **lista de apps**:
en amarillo está en cola, en rojo está parada. No dar por enviada una app sin verla
amarilla ahí.

## Si el navegador deja de responder

Si las capturas fallan con timeout y los clics no entran, comprobar
`innerWidth`/`innerHeight` de la pestaña: si son `0`, la ventana de Chrome está
minimizada. No es un fallo de la página; hay que pedirle a Felipe que la levante.

## Solo subir a TestFlight

Cuando Felipe solo quiere probarla en su iPad ("súbela y yo la pruebo"), basta con los
pasos 1 y 2 más el 5bis. El grupo interno **"Pruebas"** tiene distribución automática,
así que el build entra solo y TestFlight le avisa. Confirmar en el grupo que el build
queda en **"Testing"**: mientras diga "Ready to Submit" sin grupo, no le ha llegado.

## Después

Actualizar el estado del deploy en la sección 8 de `CLAUDE.md`, en el mismo commit.
