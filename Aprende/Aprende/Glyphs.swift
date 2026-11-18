import CoreGraphics

// MARK: - Biblioteca de trazos
//
// Cada glifo (letra o número) se define en una caja unitaria con Y hacia ABAJO:
// la altura total es 1.0 y `width` es el ancho del glifo en esas unidades.
// Métricas de escritura escolar (imprenta):
//   - tope de ascendentes (l, t):        y ≈ 0.08
//   - tope de minúsculas (x-height):     y ≈ 0.38
//   - línea base:                        y ≈ 0.88
//   - fondo de descendentes (p):         y ≈ 1.00
// Cada trazo es una secuencia ORDENADA de puntos: el orden codifica la
// dirección correcta de escritura (donde empieza y hacia dónde va).

struct GlyphStroke {
    let points: [CGPoint]
    var isDot: Bool = false   // el punto de la "i": se acepta un toque corto
}

struct Glyph {
    let name: String
    let width: CGFloat
    let strokes: [GlyphStroke]

    /// Trazos escalados a una altura de dibujo concreta (escala uniforme).
    /// `dx` desplaza el glifo cuando la caja es más ancha que él.
    func scaledStrokes(height: CGFloat, dx: CGFloat = 0) -> [[CGPoint]] {
        strokes.map { $0.points.map { CGPoint(x: $0.x * height + dx, y: $0.y * height) } }
    }

    /// Ancho de la caja de trazo, en unidades de altura.
    ///
    /// Nunca baja de `GlyphLibrary.minBoxFactor`: la "l" y la "i" miden 0.18 de
    /// ancho, así que su caja quedaba tan estrecha que el niño pintaba fuera del
    /// lienzo y el trazo se perdía. El glifo va centrado en la caja ancha.
    var boxFactor: CGFloat { max(width, GlyphLibrary.minBoxFactor) }
}

// MARK: - Helpers de geometría (ángulos en grados; Y hacia abajo:
// 0° = derecha, 90° = abajo, -90° = arriba; ángulo creciente = sentido horario)

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func line(_ a: CGPoint, _ b: CGPoint, n: Int = 14) -> [CGPoint] {
    (0...n).map { i in
        let t = CGFloat(i) / CGFloat(n)
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

private func arc(c: CGPoint, rx: CGFloat, ry: CGFloat,
                 from fromDeg: CGFloat, to toDeg: CGFloat, n: Int = 30) -> [CGPoint] {
    (0...n).map { i in
        let t = CGFloat(i) / CGFloat(n)
        let deg = fromDeg + (toDeg - fromDeg) * t
        let rad = deg * .pi / 180
        return CGPoint(x: c.x + rx * cos(rad), y: c.y + ry * sin(rad))
    }
}

private func quad(_ p0: CGPoint, _ ctrl: CGPoint, _ p1: CGPoint, n: Int = 24) -> [CGPoint] {
    (0...n).map { i in
        let t = CGFloat(i) / CGFloat(n)
        let mt = 1 - t
        let x = mt * mt * p0.x + 2 * mt * t * ctrl.x + t * t * p1.x
        let y = mt * mt * p0.y + 2 * mt * t * ctrl.y + t * t * p1.y
        return CGPoint(x: x, y: y)
    }
}

/// Concatena segmentos en un solo trazo continuo.
private func joined(_ segments: [[CGPoint]]) -> [CGPoint] {
    var out: [CGPoint] = []
    for seg in segments {
        if let last = out.last, let first = seg.first,
           hypot(last.x - first.x, last.y - first.y) < 0.02 {
            out.append(contentsOf: seg.dropFirst())
        } else {
            out.append(contentsOf: seg)
        }
    }
    return out
}

private func stroke(_ segments: [[CGPoint]]...) -> GlyphStroke {
    GlyphStroke(points: joined(segments.flatMap { $0 }))
}

// MARK: - Catálogo

enum GlyphLibrary {

    /// Ancho mínimo de la caja de trazo (en unidades de altura). Ver `Glyph.boxFactor`.
    static let minBoxFactor: CGFloat = 0.34

    static func glyph(for ch: Character) -> Glyph? { all[ch] }

    static let all: [Character: Glyph] = {
        var g: [Character: Glyph] = [:]

        // ---------- MINÚSCULAS ----------
        g["a"] = Glyph(name: "a", width: 0.62, strokes: [
            // 1: círculo (empieza a las 2 en punto, gira a la izquierda)
            GlyphStroke(points: arc(c: pt(0.28, 0.63), rx: 0.26, ry: 0.25, from: -45, to: -405, n: 44)),
            // 2: palito derecho de arriba a abajo
            GlyphStroke(points: line(pt(0.54, 0.38), pt(0.54, 0.88))),
        ])

        g["e"] = Glyph(name: "e", width: 0.56, strokes: [
            // barra del medio y vuelta por arriba, sale abajo a la derecha
            stroke([line(pt(0.06, 0.60), pt(0.50, 0.60), n: 10),
                    arc(c: pt(0.28, 0.63), rx: 0.24, ry: 0.25, from: -7, to: -300, n: 40)]),
        ])

        g["i"] = Glyph(name: "i", width: 0.18, strokes: [
            GlyphStroke(points: line(pt(0.09, 0.38), pt(0.09, 0.88))),
            GlyphStroke(points: [pt(0.09, 0.20)], isDot: true),
        ])

        g["l"] = Glyph(name: "l", width: 0.18, strokes: [
            GlyphStroke(points: line(pt(0.09, 0.08), pt(0.09, 0.88))),
        ])

        g["m"] = Glyph(name: "m", width: 0.92, strokes: [
            GlyphStroke(points: line(pt(0.08, 0.38), pt(0.08, 0.88))),
            stroke([arc(c: pt(0.26, 0.635), rx: 0.18, ry: 0.255, from: 180, to: 360, n: 24),
                    line(pt(0.44, 0.635), pt(0.44, 0.88), n: 8)]),
            stroke([arc(c: pt(0.62, 0.635), rx: 0.18, ry: 0.255, from: 180, to: 360, n: 24),
                    line(pt(0.80, 0.635), pt(0.80, 0.88), n: 8)]),
        ])

        g["n"] = Glyph(name: "n", width: 0.56, strokes: [
            GlyphStroke(points: line(pt(0.08, 0.38), pt(0.08, 0.88))),
            stroke([arc(c: pt(0.26, 0.635), rx: 0.18, ry: 0.255, from: 180, to: 360, n: 24),
                    line(pt(0.44, 0.635), pt(0.44, 0.88), n: 8)]),
        ])

        g["o"] = Glyph(name: "o", width: 0.56, strokes: [
            // empieza arriba y gira a la izquierda (contra reloj)
            GlyphStroke(points: arc(c: pt(0.28, 0.63), rx: 0.25, ry: 0.25, from: -90, to: -450, n: 44)),
        ])

        g["p"] = Glyph(name: "p", width: 0.60, strokes: [
            // 1: palito largo que baja hasta el sótano
            GlyphStroke(points: line(pt(0.08, 0.38), pt(0.08, 1.00))),
            // 2: pancita hacia la derecha
            GlyphStroke(points: arc(c: pt(0.30, 0.63), rx: 0.245, ry: 0.25, from: -150, to: 150, n: 40)),
        ])

        g["r"] = Glyph(name: "r", width: 0.42, strokes: [
            GlyphStroke(points: line(pt(0.08, 0.38), pt(0.08, 0.88))),
            // hombrito
            GlyphStroke(points: arc(c: pt(0.23, 0.60), rx: 0.15, ry: 0.22, from: 180, to: 310, n: 20)),
        ])

        g["s"] = Glyph(name: "s", width: 0.50, strokes: [
            stroke([arc(c: pt(0.26, 0.50), rx: 0.17, ry: 0.12, from: -35, to: -255, n: 26),
                    arc(c: pt(0.24, 0.74), rx: 0.175, ry: 0.13, from: -105, to: 155, n: 30)]),
        ])

        g["t"] = Glyph(name: "t", width: 0.44, strokes: [
            GlyphStroke(points: line(pt(0.20, 0.16), pt(0.20, 0.88))),
            GlyphStroke(points: line(pt(0.04, 0.42), pt(0.38, 0.42), n: 10)),
        ])

        g["u"] = Glyph(name: "u", width: 0.56, strokes: [
            // baja, curva en el fondo y sube
            stroke([line(pt(0.08, 0.38), pt(0.08, 0.66), n: 8),
                    arc(c: pt(0.26, 0.66), rx: 0.18, ry: 0.22, from: 180, to: 0, n: 24),
                    line(pt(0.44, 0.66), pt(0.44, 0.38), n: 8)]),
            // palito derecho
            GlyphStroke(points: line(pt(0.44, 0.38), pt(0.44, 0.88))),
        ])

        // ---------- MAYÚSCULAS (para nombres propios) ----------
        g["L"] = Glyph(name: "L", width: 0.54, strokes: [
            stroke([line(pt(0.08, 0.10), pt(0.08, 0.88)),
                    line(pt(0.08, 0.88), pt(0.48, 0.88), n: 10)]),
        ])

        g["N"] = Glyph(name: "N", width: 0.62, strokes: [
            GlyphStroke(points: line(pt(0.08, 0.10), pt(0.08, 0.88))),
            GlyphStroke(points: line(pt(0.08, 0.10), pt(0.54, 0.88))),
            GlyphStroke(points: line(pt(0.54, 0.88), pt(0.54, 0.10))),
        ])

        g["R"] = Glyph(name: "R", width: 0.58, strokes: [
            GlyphStroke(points: line(pt(0.08, 0.10), pt(0.08, 0.88))),
            // panza superior
            GlyphStroke(points: arc(c: pt(0.10, 0.30), rx: 0.36, ry: 0.20, from: -83, to: 83, n: 28)),
            // patita diagonal
            GlyphStroke(points: line(pt(0.12, 0.49), pt(0.50, 0.88))),
        ])

        // ---------- NÚMEROS ----------
        g["0"] = Glyph(name: "0", width: 0.58, strokes: [
            GlyphStroke(points: arc(c: pt(0.29, 0.50), rx: 0.24, ry: 0.38, from: -90, to: -450, n: 48)),
        ])

        g["1"] = Glyph(name: "1", width: 0.22, strokes: [
            GlyphStroke(points: line(pt(0.11, 0.12), pt(0.11, 0.88))),
        ])

        g["2"] = Glyph(name: "2", width: 0.54, strokes: [
            stroke([arc(c: pt(0.27, 0.33), rx: 0.21, ry: 0.21, from: -160, to: 15, n: 26),
                    line(pt(0.473, 0.384), pt(0.06, 0.88)),
                    line(pt(0.06, 0.88), pt(0.48, 0.88), n: 10)]),
        ])

        g["3"] = Glyph(name: "3", width: 0.52, strokes: [
            stroke([arc(c: pt(0.25, 0.31), rx: 0.20, ry: 0.19, from: -140, to: 90, n: 28),
                    arc(c: pt(0.25, 0.69), rx: 0.21, ry: 0.19, from: -90, to: 140, n: 28)]),
        ])

        g["4"] = Glyph(name: "4", width: 0.58, strokes: [
            stroke([line(pt(0.34, 0.12), pt(0.06, 0.58)),
                    line(pt(0.06, 0.58), pt(0.52, 0.58), n: 10)]),
            GlyphStroke(points: line(pt(0.42, 0.12), pt(0.42, 0.88))),
        ])

        g["5"] = Glyph(name: "5", width: 0.54, strokes: [
            stroke([line(pt(0.14, 0.12), pt(0.14, 0.45), n: 10),
                    arc(c: pt(0.27, 0.655), rx: 0.225, ry: 0.225, from: -115, to: 125, n: 36)]),
            GlyphStroke(points: line(pt(0.14, 0.12), pt(0.48, 0.12), n: 10)),
        ])

        g["6"] = Glyph(name: "6", width: 0.54, strokes: [
            stroke([quad(pt(0.46, 0.13), pt(0.13, 0.30), pt(0.105, 0.62), n: 20),
                    arc(c: pt(0.28, 0.665), rx: 0.175, ry: 0.215, from: 180, to: -180, n: 36)]),
        ])

        g["7"] = Glyph(name: "7", width: 0.52, strokes: [
            stroke([line(pt(0.06, 0.12), pt(0.47, 0.12), n: 10),
                    line(pt(0.47, 0.12), pt(0.17, 0.88))]),
        ])

        g["8"] = Glyph(name: "8", width: 0.56, strokes: [
            // figura en 8: empieza arriba, baja en "S" y regresa cerrando
            GlyphStroke(points: (0...64).map { i in
                let t = CGFloat(i) / 64 * 2 * .pi
                return CGPoint(x: 0.28 + 0.185 * sin(2 * t), y: 0.50 - 0.38 * cos(t))
            }),
        ])

        g["9"] = Glyph(name: "9", width: 0.54, strokes: [
            // 1: bolita (contra reloj desde la derecha)
            GlyphStroke(points: arc(c: pt(0.27, 0.335), rx: 0.185, ry: 0.215, from: 0, to: -360, n: 40)),
            // 2: palito que baja
            GlyphStroke(points: line(pt(0.455, 0.335), pt(0.455, 0.88))),
        ])

        return g
    }()

    // ---------- CALENTAMIENTO (pre-escritura) ----------
    static let warmups: [Glyph] = [
        Glyph(name: "línea", width: 0.30, strokes: [
            GlyphStroke(points: line(pt(0.15, 0.08), pt(0.15, 0.92))),
        ]),
        Glyph(name: "raya", width: 1.0, strokes: [
            GlyphStroke(points: line(pt(0.05, 0.50), pt(0.95, 0.50), n: 20)),
        ]),
        Glyph(name: "círculo", width: 0.80, strokes: [
            GlyphStroke(points: arc(c: pt(0.40, 0.50), rx: 0.36, ry: 0.38, from: -90, to: -450, n: 44)),
        ]),
        Glyph(name: "zigzag", width: 0.85, strokes: [
            stroke([line(pt(0.05, 0.25), pt(0.30, 0.75)),
                    line(pt(0.30, 0.75), pt(0.55, 0.25)),
                    line(pt(0.55, 0.25), pt(0.80, 0.75))]),
        ]),
    ]

    /// Glifos de una palabra, en orden. Devuelve nil si falta alguna letra.
    static func glyphs(for word: String) -> [Glyph]? {
        var out: [Glyph] = []
        for ch in word {
            guard let g = glyph(for: ch) else { return nil }
            out.append(g)
        }
        return out
    }
}
