// Genera el icono 1024x1024 de la app "Aprende" con CoreGraphics (macOS).
// Uso: swift scripts/make_icon.swift <ruta-salida.png>
import AppKit

let size = CGFloat(1024)
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("sin contexto") }

// Fondo: degradado coral → naranja (los colores de la app)
let colors = [
    NSColor(calibratedRed: 1.00, green: 0.42, blue: 0.42, alpha: 1).cgColor, // #ff6b6b
    NSColor(calibratedRed: 0.97, green: 0.59, blue: 0.12, alpha: 1).cgColor, // #f8961e
] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

// Tarjeta blanca redondeada sutil detrás de la letra
let cardRect = CGRect(x: 152, y: 152, width: 720, height: 720)
let card = NSBezierPath(roundedRect: cardRect, xRadius: 160, yRadius: 160)
NSColor(calibratedWhite: 1.0, alpha: 0.22).setFill()
card.fill()

// Letra "A" grande, blanca, redondeada
let font = NSFont.systemFont(ofSize: 560, weight: .heavy)
let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 560) ?? font
let attrs: [NSAttributedString.Key: Any] = [
    .font: rounded,
    .foregroundColor: NSColor.white,
]
let letter = NSAttributedString(string: "A", attributes: attrs)
let lsize = letter.size()
letter.draw(at: NSPoint(x: (size - lsize.width) / 2, y: (size - lsize.height) / 2 + 20))

// Trazo de "lápiz": subrayado curvo verde bajo la A
let path = NSBezierPath()
path.move(to: NSPoint(x: 270, y: 215))
path.curve(to: NSPoint(x: 754, y: 215), controlPoint1: NSPoint(x: 420, y: 130), controlPoint2: NSPoint(x: 604, y: 130))
path.lineWidth = 44
path.lineCapStyle = .round
NSColor(calibratedRed: 0.22, green: 0.69, blue: 0.0, alpha: 1).setStroke() // #38b000
path.stroke()

// Estrella amarilla arriba a la derecha
let star = NSBezierPath()
let cx = CGFloat(812), cy = CGFloat(812), rOut = CGFloat(86), rIn = CGFloat(36)
for i in 0..<10 {
    let ang = CGFloat(i) * .pi / 5 - .pi / 2
    let r = i % 2 == 0 ? rOut : rIn
    let p = NSPoint(x: cx + r * cos(ang), y: cy + r * sin(ang))
    if i == 0 { star.move(to: p) } else { star.line(to: p) }
}
star.close()
NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.40, alpha: 1).setFill() // #ffd166
star.fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { fatalError("sin PNG") }
try! png.write(to: URL(fileURLWithPath: out))
print("icono escrito en \(out) (\(png.count) bytes)")
