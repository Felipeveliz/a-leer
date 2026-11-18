---
name: capturas-app-store
description: Toma las capturas de Aprende para la ficha de App Store, en los tamaños exactos que acepta Apple. Úsala al preparar un deploy o cuando haya que renovar las capturas.
---

# Capturas para App Store

## Tamaños (esto es lo que más tiempo cuesta si se equivoca)

| Ranura en App Store Connect | Píxeles | Simulador |
|---|---|---|
| iPhone con Dynamic Island (medium display) | **1206 × 2622** | iPhone 17 Pro |
| iPad 13" | **2064 × 2752** | iPad Pro 13-inch (M4) |

Apple escala hacia abajo al resto de tamaños, así que con esas dos ranuras basta.

**1320 × 2868 (iPhone 17 Pro Max) lo rechaza.** La ranura de iPhone acepta
2556 × 1179, 1179 × 2556, 2622 × 1206 y 1206 × 2622, nada más. Verificar el tamaño con
`sips -g pixelWidth -g pixelHeight` antes de subir nada.

## Preparar el simulador

```
xcrun simctl boot "iPhone 17 Pro"
```

Esperar ~30 s a que arranque. Luego barra de estado limpia:

```
xcrun simctl status_bar <UDID> override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi
```

Instalar y lanzar el build Debug, y **esperar de verdad a que la app pinte**: una captura
tomada demasiado pronto sale en negro y no se nota hasta que la miras. Siempre revisar
cada PNG antes de darla por buena.

## Capturar

```
xcrun simctl io <UDID> screenshot AppStoreMetadata/screenshots/iphone-6.3/01-inicio.png
```

`simctl io screenshot` da el PNG al tamaño correcto; la captura del panel del simulador
no sirve para subir, solo para que tú mires.

## Navegar entre pantallas

Los toques van con la herramienta del simulador (`control` con `action: "tap"`), pero
**llegan con retraso**: entre el toque y el cambio de pantalla pueden pasar varios
segundos, y si encadenas dos toques seguidos el segundo se pierde o cae en la pantalla
equivocada. Un toque, esperar 4 s, capturar, mirar. Para volver al inicio es más fiable
`terminate` + `launch` que ir hacia atrás a toques.

Coordenadas en puntos (iPhone 17 Pro, 402 × 874):

| Destino | Toque |
|---|---|
| Español | (201, 280) |
| Matemáticas | (201, 481) |
| Escribe | (201, 721) |
| Escribe › Palabras | (201, 367) |
| Escribe › Números | (201, 553) |
| Primera palabra de la lista | (106, 268) |

## Qué capturar

Cuatro o cinco, en este orden:

1. **Inicio** con los tres módulos.
2. **Escribe › lista de palabras**, que enseña las estrellas.
3. **Escribe › fase 1 de una palabra**, con el modelo arriba, el punto verde y la flecha:
   es la pantalla que distingue a esta app.
4. **Matemáticas** con una suma. Si sale con un cero (`4 + 0`), tocar "Otra suma" y
   repetir: queda raro en la ficha.
5. Opcional: **Español › palabra separada en sílabas** de colores.

## Dónde van

`AppStoreMetadata/screenshots/iphone-6.3/` y `AppStoreMetadata/screenshots/ipad-13/`,
numeradas por el orden en que deben salir en la ficha.

## Subirlas

En la página de la versión, pestaña **App Previews and Screenshots**, eligiendo primero
la ranura del dispositivo. Son archivos grandes: hasta 10 MB por tanda.
