// Renderiza todos los glifos de Glyphs.swift a un HTML con SVGs para revisión visual.
// Uso (swiftc multi-archivo exige que el que lleva código suelto se llame main.swift):
//   cp scripts/render_glyphs.swift /tmp/main.swift
//   swiftc Aprende/Aprende/Glyphs.swift /tmp/main.swift -o /tmp/render_glyphs
//   /tmp/render_glyphs glyphs.html
import Foundation
import CoreGraphics

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "glyphs.html"
let H: CGFloat = 160
let colors = ["#4d96ff", "#ff6b6b", "#38b000"]

func svg(for glyph: Glyph) -> String {
    let w = glyph.width * H
    var body = ""
    // líneas de referencia (ascendente, x-height, base)
    for (y, dash) in [(0.08, "2,3"), (0.38, "2,3"), (0.88, ""), (0.12, "1,4"), (0.5, "1,6")] {
        body += "<line x1='0' y1='\(y * H)' x2='\(w)' y2='\(y * H)' stroke='#ddd' stroke-width='1' stroke-dasharray='\(dash)'/>"
    }
    for (i, stroke) in glyph.strokes.enumerated() {
        let pts = stroke.points.map { CGPoint(x: $0.x * H, y: $0.y * H) }
        let color = colors[i % colors.count]
        if stroke.isDot {
            body += "<circle cx='\(pts[0].x)' cy='\(pts[0].y)' r='6' fill='\(color)'/>"
            continue
        }
        let d = "M " + pts.map { "\($0.x.rounded(toPlaces: 1)) \($0.y.rounded(toPlaces: 1))" }.joined(separator: " L ")
        body += "<path d='\(d)' fill='none' stroke='\(color)' stroke-width='7' stroke-linecap='round' stroke-linejoin='round'/>"
        // punto de inicio (verde) y flecha de dirección
        body += "<circle cx='\(pts[0].x)' cy='\(pts[0].y)' r='5' fill='#1b9000' stroke='white'/>"
        if pts.count > 5 {
            let a = pts[1], b = pts[5]
            body += "<line x1='\(a.x)' y1='\(a.y)' x2='\(b.x)' y2='\(b.y)' stroke='#1b9000' stroke-width='3'/>"
        }
    }
    return "<div class='g'><svg width='\(w)' height='\(H)' viewBox='0 0 \(w) \(H)'>\(body)</svg><div>\(glyph.name)</div></div>"
}

extension CGFloat {
    func rounded(toPlaces p: Int) -> CGFloat {
        let m = pow(10, CGFloat(p)); return (self * m).rounded() / m
    }
}

var html = "<html><head><meta charset='utf-8'><style>body{font-family:sans-serif;background:#fef6e4;padding:20px}.g{display:inline-block;margin:10px;padding:10px;background:white;border-radius:10px;text-align:center;vertical-align:top;font-size:20px}</style></head><body><h2>Glifos — trazo 1 azul, trazo 2 coral, trazo 3 verde; punto verde = inicio</h2>"
// Todos los glifos, ordenados por nombre (minúsculas, mayúsculas, dígitos).
let glifos: [Glyph] = GlyphLibrary.all.values.sorted { a, b in
    let la = a.name.lowercased()
    let lb = b.name.lowercased()
    if la != lb { return la < lb }
    return a.name > b.name
}
for g in glifos {
    html += svg(for: g)
}
html += "<h2>Calentamiento</h2>"
for g in GlyphLibrary.warmups { html += svg(for: g) }
html += "</body></html>"
try! html.write(toFile: out, atomically: true, encoding: .utf8)
print("escrito \(out)")
