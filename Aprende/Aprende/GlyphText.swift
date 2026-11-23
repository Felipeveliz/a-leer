import SwiftUI

// MARK: - Una palabra dibujada con los trazos del glifo
//
// La fuente del sistema escribe la "a" de dos pisos, la de imprenta de libro,
// con su gancho arriba. Pero lo que el niño aprende a trazar —y lo que la app
// le pide— es la "a" de bola y palito. Enseñarle una forma y exigirle la otra
// es confundirlo, así que en el módulo Escribe el modelo se dibuja con los
// MISMOS trazos que tiene que hacer él.
//
// Las letras sin glifo (no debería haber ninguna en Escribe) caen a texto.

struct GlyphText: View {
    let texto: String
    /// Altura de la caja de cada letra, en puntos.
    let alto: CGFloat
    /// Color de cada letra por posición. Permite pintar la letra en curso.
    var color: (Int) -> Color = { _ in Palette.ink }
    var espacio: CGFloat = 2

    private var letras: [Character] { Array(texto) }

    private func ancho(de ch: Character) -> CGFloat {
        (GlyphLibrary.glyph(for: ch)?.boxFactor ?? 0.5) * alto
    }

    private var anchoTotal: CGFloat {
        letras.reduce(0) { $0 + ancho(de: $1) } + espacio * CGFloat(max(letras.count - 1, 0))
    }

    var body: some View {
        Canvas { ctx, size in
            // Un nombre completo puede no caber a lo ancho ("José Luis García
            // García" mide unos 440 pt a 34 de alto y el iPhone deja 362). Se encoge
            // entero, centrado en su alto, en vez de salirse de la pantalla.
            let escala = min(1, size.width / max(anchoTotal, 1))
            ctx.translateBy(x: 0, y: alto * (1 - escala) / 2)
            ctx.scaleBy(x: escala, y: escala)

            var x: CGFloat = 0
            for (i, ch) in letras.enumerated() {
                let anchoLetra = ancho(de: ch)
                defer { x += anchoLetra + espacio }

                guard let glifo = GlyphLibrary.glyph(for: ch) else {
                    ctx.draw(Text(String(ch)).font(.kid(alto * 0.76)).foregroundColor(color(i)),
                             at: CGPoint(x: x + anchoLetra / 2, y: alto * 0.56))
                    continue
                }

                // El glifo va centrado en su caja, igual que en LetterTraceView.
                let dx = x + (anchoLetra - glifo.width * alto) / 2
                let grosor = max(2, alto * 0.11)

                for (j, tramo) in glifo.scaledStrokes(height: alto, dx: dx).enumerated() {
                    guard let primero = tramo.first else { continue }
                    if glifo.strokes[j].isDot {
                        let r = grosor * 0.5
                        ctx.fill(Path(ellipseIn: CGRect(x: primero.x - r, y: primero.y - r,
                                                        width: r * 2, height: r * 2)),
                                 with: .color(color(i)))
                    } else {
                        var p = Path()
                        p.move(to: primero)
                        for q in tramo.dropFirst() { p.addLine(to: q) }
                        ctx.stroke(p, with: .color(color(i)),
                                   style: StrokeStyle(lineWidth: grosor,
                                                      lineCap: .round, lineJoin: .round))
                    }
                }
            }
        }
        // Ancho natural = el de la palabra, pero puede recibir menos (y encogerse).
        .frame(idealWidth: anchoTotal, maxWidth: anchoTotal)
        .frame(height: alto)
        .accessibilityLabel(texto)
    }
}
