import XCTest
import CoreGraphics
@testable import Aprende

/// `TraceEngine` es la pieza con la que el niño pelea de verdad: decide si un trazo
/// cuenta. No se puede probar en el simulador con toques sintéticos (salen perfectos),
/// así que aquí se fija lo que tiene que aceptar y lo que tiene que rechazar.
final class TraceEngineTests: XCTestCase {

    private let alto: CGFloat = 300

    /// Una línea recta de arriba abajo, como la "l".
    private func linea(desde a: CGPoint, hasta b: CGPoint, n: Int = 40) -> [CGPoint] {
        (0...n).map { i in
            let t = CGFloat(i) / CGFloat(n)
            return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
    }

    private var objetivoVertical: [CGPoint] {
        linea(desde: CGPoint(x: 50, y: 24), hasta: CGPoint(x: 50, y: 264))
    }

    // MARK: Lo que tiene que aceptar

    func testTrazoIdenticoPasa() {
        let objetivo = objetivoVertical
        let r = TraceEngine.validate(user: objetivo, target: objetivo, height: alto, isDot: false)
        XCTAssertTrue(r.passed)
        XCTAssertTrue(r.startOK)
    }

    /// Un niño de cinco años no traza recto: se va abriendo y volviendo con una
    /// ondulación lenta. Las tolerancias son generosas a propósito (ver "Decisiones de
    /// producto" en CLAUDE.md); si alguien las aprieta, esto avisa.
    func testTrazoOndulanteDeNinoPasa() {
        let objetivo = objetivoVertical
        let ondulado = objetivo.enumerated().map { i, p -> CGPoint in
            let t = CGFloat(i) / CGFloat(objetivo.count - 1)
            return CGPoint(x: p.x + 14 * sin(t * .pi * 2), y: p.y)
        }
        let r = TraceEngine.validate(user: ondulado, target: objetivo, height: alto, isDot: false)
        XCTAssertTrue(r.passed, "un trazo con pulso de niño tiene que valer")
    }

    /// Pero un garabato en zigzag sobre el camino correcto no vale, aunque empiece y
    /// acabe donde toca: recorre más del doble de camino que el trazo objetivo y el
    /// motor lo caza por longitud. Es la diferencia entre un pulso tembloroso y rayar.
    func testZigzagSobreElCaminoFalla() {
        let objetivo = objetivoVertical
        let zigzag = objetivo.enumerated().map { i, p in
            CGPoint(x: p.x + (i % 2 == 0 ? 9 : -9), y: p.y)
        }
        let r = TraceEngine.validate(user: zigzag, target: objetivo, height: alto, isDot: false)
        XCTAssertTrue(r.startOK, "el inicio sí está donde toca")
        XCTAssertFalse(r.passed, "rayar en zigzag no es trazar")
    }

    /// Empezar un poco lejos del punto verde, pero dentro de la tolerancia de inicio.
    func testInicioLigeramenteDesplazado() {
        let objetivo = objetivoVertical
        let desplazado = objetivo.map { CGPoint(x: $0.x + 18, y: $0.y) }
        let r = TraceEngine.validate(user: desplazado, target: objetivo, height: alto, isDot: false)
        XCTAssertTrue(r.startOK)
        XCTAssertTrue(r.passed)
    }

    // MARK: Lo que tiene que rechazar

    /// El orden de los puntos codifica la dirección de escritura. Trazar de abajo
    /// arriba es justo lo que la app está enseñando a no hacer.
    func testTrazoAlRevesFalla() {
        let objetivo = objetivoVertical
        let r = TraceEngine.validate(user: objetivo.reversed(), target: objetivo,
                                     height: alto, isDot: false)
        XCTAssertFalse(r.passed, "trazar al revés no puede contar como acierto")
    }

    func testEmpezarLejosDelPuntoVerdeFalla() {
        let objetivo = objetivoVertical
        let tarde = Array(objetivo.dropFirst(objetivo.count / 2))
        let r = TraceEngine.validate(user: tarde, target: objetivo, height: alto, isDot: false)
        XCTAssertFalse(r.startOK)
        XCTAssertFalse(r.passed)
    }

    func testGarabatoCortoFalla() {
        let objetivo = objetivoVertical
        let pellizco = linea(desde: CGPoint(x: 50, y: 24), hasta: CGPoint(x: 52, y: 40))
        let r = TraceEngine.validate(user: pellizco, target: objetivo, height: alto, isDot: false)
        XCTAssertFalse(r.passed, "un trazo mucho más corto que el objetivo no vale")
    }

    func testGarabatoGiganteFalla() {
        let objetivo = objetivoVertical
        let largo = linea(desde: CGPoint(x: 50, y: 24), hasta: CGPoint(x: 50, y: 900))
        let r = TraceEngine.validate(user: largo, target: objetivo, height: alto, isDot: false)
        XCTAssertFalse(r.passed, "pasarse de largo tampoco vale")
    }

    /// Forma equivocada: empieza y acaba donde toca, pero se va por otro lado.
    func testFormaEquivocadaFalla() {
        let objetivo = objetivoVertical
        let desvio = linea(desde: CGPoint(x: 50, y: 24), hasta: CGPoint(x: 230, y: 144))
            + linea(desde: CGPoint(x: 230, y: 144), hasta: CGPoint(x: 50, y: 264))
        let r = TraceEngine.validate(user: desvio, target: objetivo, height: alto, isDot: false)
        XCTAssertFalse(r.passed)
    }

    // MARK: El punto de la "i"

    func testPuntoConToqueCortoPasa() {
        let objetivo = [CGPoint(x: 30, y: 40)]
        let toque = [CGPoint(x: 32, y: 42), CGPoint(x: 34, y: 43)]
        let r = TraceEngine.validate(user: toque, target: objetivo, height: alto, isDot: true)
        XCTAssertTrue(r.passed)
    }

    func testPuntoConRayaFalla() {
        let objetivo = [CGPoint(x: 30, y: 40)]
        let raya = linea(desde: CGPoint(x: 30, y: 40), hasta: CGPoint(x: 30, y: 200))
        let r = TraceEngine.validate(user: raya, target: objetivo, height: alto, isDot: true)
        XCTAssertFalse(r.passed, "el punto de la i es un toque, no una raya")
    }

    func testPuntoLejosFalla() {
        let objetivo = [CGPoint(x: 30, y: 40)]
        let lejos = [CGPoint(x: 200, y: 240)]
        let r = TraceEngine.validate(user: lejos, target: objetivo, height: alto, isDot: true)
        XCTAssertFalse(r.passed)
    }

    // MARK: Entradas degeneradas (no deben reventar)

    func testEntradasVacias() {
        let vacio = TraceEngine.validate(user: [], target: objetivoVertical,
                                         height: alto, isDot: false)
        XCTAssertFalse(vacio.passed)

        let sinObjetivo = TraceEngine.validate(user: objetivoVertical, target: [],
                                               height: alto, isDot: false)
        XCTAssertFalse(sinObjetivo.passed)

        let unPunto = TraceEngine.validate(user: [CGPoint(x: 1, y: 1)], target: objetivoVertical,
                                           height: alto, isDot: false)
        XCTAssertFalse(unPunto.passed)
    }

    // MARK: Geometría

    func testPathLength() {
        XCTAssertEqual(TraceEngine.pathLength([]), 0)
        XCTAssertEqual(TraceEngine.pathLength([CGPoint(x: 5, y: 5)]), 0)
        let l = TraceEngine.pathLength([CGPoint(x: 0, y: 0), CGPoint(x: 3, y: 4)])
        XCTAssertEqual(l, 5, accuracy: 0.0001)
    }

    func testResampleDevuelveElNumeroPedido() {
        let r = TraceEngine.resample(objetivoVertical, count: 48)
        XCTAssertEqual(r.count, 48)
    }

    func testResampleConservaExtremos() {
        let original = objetivoVertical
        let r = TraceEngine.resample(original, count: 48)
        XCTAssertEqual(r.first!.x, original.first!.x, accuracy: 0.001)
        XCTAssertEqual(r.first!.y, original.first!.y, accuracy: 0.001)
        XCTAssertEqual(r.last!.x, original.last!.x, accuracy: 0.001)
        XCTAssertEqual(r.last!.y, original.last!.y, accuracy: 0.001)
    }

    /// Re-muestrear reparte los puntos por longitud, no por índice: en una recta
    /// tienen que quedar equidistantes.
    func testResampleEquidistanteEnUnaRecta() {
        let recta = linea(desde: CGPoint(x: 0, y: 0), hasta: CGPoint(x: 0, y: 100), n: 7)
        let r = TraceEngine.resample(recta, count: 11)
        for i in 1..<r.count {
            XCTAssertEqual(TraceEngine.dist(r[i - 1], r[i]), 10, accuracy: 0.5)
        }
    }

    func testResampleConPuntosRepetidos() {
        let quieto = Array(repeating: CGPoint(x: 7, y: 7), count: 5)
        let r = TraceEngine.resample(quieto, count: 48)
        XCTAssertEqual(r.count, 48)
        XCTAssertTrue(r.allSatisfy { $0 == CGPoint(x: 7, y: 7) })
    }

    func testResampleConMenosDeDosPuntos() {
        let uno = [CGPoint(x: 1, y: 2)]
        XCTAssertEqual(TraceEngine.resample(uno, count: 48).count, 1)
    }

    func testCentroid() {
        let c = TraceEngine.centroid([CGPoint(x: 0, y: 0), CGPoint(x: 10, y: 20)])
        XCTAssertEqual(c.x, 5, accuracy: 0.0001)
        XCTAssertEqual(c.y, 10, accuracy: 0.0001)
        XCTAssertEqual(TraceEngine.centroid([]), .zero)
    }
}
