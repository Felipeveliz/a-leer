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

## Ningún paso depende de una sesión iniciada a mano

Regla del estándar (§4) después de que la sesión de App Store Connect dentro de Xcode
tumbara el deploy dos días seguidos, con un error que ni siquiera dice que sea de
sesión: `exportArchive Failed to Use Accounts`. Todo lo que habla con Apple usa la
**llave de API**, que no caduca y no necesita a nadie delante:

```
ASC_KEY_ID=8A52V34NP7
ASC_ISSUER_ID=b45b7034-6055-4ad6-a6a7-efe178190a1b
~/.appstoreconnect/private_keys/AuthKey_8A52V34NP7.p8   (permisos 600, fuera de git)
```

Es una llave **de equipo**: la misma de las demás apps de la cuenta. Si ese archivo
falta, nada de esto funciona y hay que crear otra en App Store Connect › Users and
Access › Integrations, que es lo único de la cadena que tiene que hacer Felipe. Apple
solo deja descargar el `.p8` una vez y **no hay copia fuera de esta Mac**: si se muere
el disco, se crea una llave nueva (no se pierde nada del proyecto).

`scripts/asc.py` es el cliente de la API: `estado`, `leer`, `escribir` y `novedades`.
Firma el token con OpenSSL —esta Mac no tiene PyJWT ni cryptography— y nunca imprime la
llave ni el token.

## Antes de empezar

1. **Subir `CURRENT_PROJECT_VERSION`** (y `MARKETING_VERSION`, si cambia la versión) en
   `Aprende/Aprende.xcodeproj/project.pbxproj`. Cada una aparece **cuatro** veces, no
   dos: cambiarlas todas con `sed` y contar antes y después. App Store Connect rechaza
   un build repetido.
2. Build Debug verde y los 101 tests en verde.
3. Al menos 3 GB libres en disco.

## 1. Archive

```
cd Aprende && xcodebuild -project Aprende.xcodeproj -scheme Aprende \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Aprende.xcarchive -allowProvisioningUpdates archive
```

Tiene que terminar en `** ARCHIVE SUCCEEDED **`. Tarda uno o dos minutos, pero puede
pasar de diez: darle tiempo antes de darlo por colgado. **En primer plano**: lanzado en
segundo plano ha fallado al firmar con `errSecInternalComponent` con el llavero
desbloqueado, y el mismo comando en primer plano firmó a la primera.

## 2. Exportar el .ipa (sin cuenta) y subirlo con la llave

Son dos pasos, y esa es la gracia: `ExportOptions.plist` dice `destination = export`,
así que el primero **no habla con Apple** y no puede fallar por una sesión caída.

```
cd Aprende && xcodebuild -exportArchive -archivePath build/Aprende.xcarchive \
  -exportOptionsPlist Config/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates
```

```
cd Aprende && xcrun altool --upload-app -f build/export/Aprende.ipa -t ios \
  --apiKey 8A52V34NP7 --apiIssuer b45b7034-6055-4ad6-a6a7-efe178190a1b
```

Termina en `UPLOAD SUCCEEDED with no errors`. La línea de arriba sobre
`CDUploaderStateInfoResumeFilePath` sale siempre y **no** es un error. Después borrar
`Aprende/build/export` (ya está en Apple; `Aprende/build/` está ignorado por git).

Procesar el build tarda uno o dos minutos y hay que esperar a que quede `VALID` antes
de engancharlo a una versión; se consulta en
`/v1/builds?filter[app]=<id>&sort=-version`.

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

**La disponibilidad NO se pide y es obligatoria.** En *Precio y disponibilidad*, la tabla
de precios dice "175 países o regiones" aunque la app no esté disponible en ninguno. La
sección **"Disponibilidad de la app"** tiene que mostrar un resumen por estado ("En
proceso", "Disponible"). Si solo enseña el botón "Configurar disponibilidad", está
vacía: Apple aprueba la versión igual, y la lista de apps la muestra como **"Removed
from App Store"** sin mandar ningún correo. Configurarla antes de enviar: "Determinados
países o regiones" con los 18 hispanohablantes (ver la sección 5 de `CLAUDE.md`).
Los checkboxes del diálogo no tienen nombre accesible; hay que localizarlos por la
etiqueta del DOM.

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
