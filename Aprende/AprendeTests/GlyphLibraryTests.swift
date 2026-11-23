import XCTest
import CoreGraphics
@testable import Aprende

/// Si una palabra de Escribe tuviera una letra sin glifo, la app se la saltaría en
/// silencio: el niño nunca llegaría a trazarla y nadie se enteraría. Esto lo impide.
final class GlyphLibraryTests: XCTestCase {

    func testTodaLetraDeEscribeTieneGlifo() {
        for palabra in AppData.palabrasEscribe(en: Set(Hoja.allCases)) {
            for letra in palabra.texto {
                XCTAssertNotNil(GlyphLibrary.glyph(for: letra),
                                "falta el glifo de '\(letra)' (palabra '\(palabra.texto)')")
            }
        }
    }

    func testTodoDigitoDeEscribeTieneGlifo() {
        for d in AppData.digitosEscribe {
            XCTAssertNotNil(GlyphLibrary.glyph(for: d), "falta el glifo del \(d)")
        }
    }

    /// Las letras que estrenó la hoja 3: la "ó" de "limón" y la "I" de "Irma".
    func testLosGlifosNuevosDeLaHojaTres() {
        XCTAssertNotNil(GlyphLibrary.glyph(for: "ó"))
        XCTAssertNotNil(GlyphLibrary.glyph(for: "I"))
        XCTAssertEqual(GlyphLibrary.glyph(for: "ó")?.strokes.count, 2,
                       "la ó son dos trazos: el círculo y el acento")
    }

    func testHayCuatroEjerciciosDeCalentamiento() {
        XCTAssertEqual(GlyphLibrary.warmups.count, 4)
    }

    /// Para "Escribir mi nombre" cualquier letra de un nombre tiene que poder
    /// trazarse: el abecedario completo, con acentos y ñ, en minúscula y mayúscula.
    func testAbecedarioCompletoParaNombres() {
        let requeridos = "abcdefghijklmnopqrstuvwxyzñáéíóúü"
            + "ABCDEFGHIJKLMNOPQRSTUVWXYZÑÁÉÍÓÚ"
        for ch in requeridos {
            XCTAssertNotNil(GlyphLibrary.glyph(for: ch), "falta el glifo de '\(ch)'")
        }
    }

    // MARK: Invariantes de cada glifo

    private var todos: [Glyph] { Array(GlyphLibrary.all.values) + GlyphLibrary.warmups }

    func testCadaGlifoTieneAnchoYTrazos() {
        for g in todos {
            XCTAssertGreaterThan(g.width, 0, "\(g.name) sin ancho")
            XCTAssertFalse(g.strokes.isEmpty, "\(g.name) sin trazos")
            for (i, s) in g.strokes.enumerated() {
                XCTAssertFalse(s.points.isEmpty, "\(g.name): el trazo \(i) está vacío")
            }
        }
    }

    /// Los trazos que no son punto necesitan al menos dos puntos: con uno solo,
    /// `TraceEngine` no puede comparar forma ni dirección.
    func testLosTrazosNormalesTienenAlMenosDosPuntos() {
        for g in todos {
            for (i, s) in g.strokes.enumerated() where !s.isDot {
                XCTAssertGreaterThanOrEqual(s.points.count, 2,
                                            "\(g.name): el trazo \(i) tiene un solo punto")
            }
        }
    }

    /// La caja es unitaria: alto 1.0 y ancho `width`, con Y hacia abajo. Un punto muy
    /// fuera suele ser un dedazo en las coordenadas.
    func testLosPuntosCaenDentroDeLaCaja() {
        let margen: CGFloat = 0.06
        for g in todos {
            for (i, s) in g.strokes.enumerated() {
                for p in s.points {
                    XCTAssertTrue(p.y >= -margen && p.y <= 1 + margen,
                                  "\(g.name) trazo \(i): y = \(p.y) fuera de la caja")
                    XCTAssertTrue(p.x >= -margen && p.x <= g.width + margen,
                                  "\(g.name) trazo \(i): x = \(p.x) fuera del ancho \(g.width)")
                }
            }
        }
    }

    // MARK: Escalado

    func testScaledStrokesEscalaYDesplaza() {
        guard let l = GlyphLibrary.glyph(for: "l") else { return XCTFail("sin glifo de l") }
        let sinDesplazar = l.scaledStrokes(height: 100)
        let desplazado = l.scaledStrokes(height: 100, dx: 20)
        XCTAssertEqual(sinDesplazar.count, l.strokes.count)
        for (a, b) in zip(sinDesplazar.flatMap { $0 }, desplazado.flatMap { $0 }) {
            XCTAssertEqual(b.x - a.x, 20, accuracy: 0.0001)
            XCTAssertEqual(b.y, a.y, accuracy: 0.0001)
        }
        for p in sinDesplazar.flatMap({ $0 }) {
            XCTAssertTrue(p.y >= -6 && p.y <= 106)
        }
    }

    /// La "l" y la "i" miden 0.18 de ancho: sin suelo, su caja táctil quedaba tan
    /// estrecha que el trazo del niño caía fuera del lienzo y se perdía.
    func testBoxFactorNuncaBajaDelMinimo() {
        for g in todos {
            XCTAssertGreaterThanOrEqual(g.boxFactor, GlyphLibrary.minBoxFactor,
                                        "\(g.name) tiene una caja más estrecha que el mínimo")
            XCTAssertGreaterThanOrEqual(g.boxFactor, g.width,
                                        "\(g.name): la caja no puede ser menor que el glifo")
        }
    }

    func testLaLTieneCajaMasAnchaQueSuGlifo() {
        guard let l = GlyphLibrary.glyph(for: "l") else { return XCTFail("sin glifo de l") }
        XCTAssertLessThan(l.width, GlyphLibrary.minBoxFactor)
        XCTAssertEqual(l.boxFactor, GlyphLibrary.minBoxFactor, accuracy: 0.0001)
    }

    // MARK: Forma

    /// La "U" salió al revés (∩) por un arco de 180° a 360°, que con Y hacia abajo
    /// pasa por ARRIBA. Pasaba todos los tests porque ninguno miraba la forma.
    func testLaUTieneLaCurvaAbajo() {
        for ch: Character in ["U", "u", "Ú", "ú"] {
            guard let g = GlyphLibrary.glyph(for: ch) else { return XCTFail("sin glifo de \(ch)") }
            let cuerpo = g.strokes[0].points
            let centro = g.width / 2
            guard let medio = cuerpo.min(by: { abs($0.x - centro) < abs($1.x - centro) }) else {
                return XCTFail("\(ch) sin puntos")
            }
            XCTAssertGreaterThan(medio.y, 0.75,
                                 "\(ch): el punto central del trazo debería estar abajo, en la línea base")
        }
    }

    /// La barrita de la "G" sale de donde termina el arco y va HACIA ADENTRO. Antes
    /// flotaba en la boca de la C y se trazaba hacia afuera.
    func testLaGCierraConBarritaHaciaAdentro() {
        guard let g = GlyphLibrary.glyph(for: "G"), g.strokes.count == 2,
              let finArco = g.strokes[0].points.last,
              let inicioBarra = g.strokes[1].points.first,
              let finBarra = g.strokes[1].points.last else { return XCTFail("G mal formada") }
        XCTAssertLessThan(hypot(finArco.x - inicioBarra.x, finArco.y - inicioBarra.y), 0.02,
                          "la barrita de la G tiene que salir de donde termina el arco")
        XCTAssertGreaterThan(inicioBarra.x, finBarra.x, "la barrita de la G va hacia adentro")
    }

    /// Las pancitas de la "B" se tocan en un punto del palito; si se traslapan, se
    /// cruzan y en la cintura se ve una equis.
    func testLasPancitasDeLaBSeJuntanSinCruzarse() {
        guard let b = GlyphLibrary.glyph(for: "B"), b.strokes.count == 3,
              let finArriba = b.strokes[1].points.last,
              let inicioAbajo = b.strokes[2].points.first else { return XCTFail("B mal formada") }
        XCTAssertLessThan(hypot(finArriba.x - inicioAbajo.x, finArriba.y - inicioAbajo.y), 0.02)
        let fondoArriba = b.strokes[1].points.map(\.y).max() ?? 0
        let topeAbajo = b.strokes[2].points.map(\.y).min() ?? 1
        XCTAssertLessThanOrEqual(fondoArriba, topeAbajo + 0.001, "las pancitas de la B se traslapan")
    }

    // MARK: Reglas de trazo (ver CLAUDE.md sección 6)
    //
    // La app enseña la convención estándar, no el método de una escuela concreta.
    // Estas tres reglas son la forma de que eso sea verificable y no una opinión.

    /// Área con signo. Con Y hacia ABAJO, negativa = el trazo gira contra reloj
    /// en pantalla, que es como se enseña a hacer los redondeles.
    private func areaConSigno(_ p: [CGPoint]) -> CGFloat {
        guard p.count > 2 else { return 0 }
        var s: CGFloat = 0
        for i in 0..<p.count {
            let a = p[i], b = p[(i + 1) % p.count]
            s += a.x * b.y - b.x * a.y
        }
        return s / 2
    }

    private func largo(_ p: [CGPoint]) -> CGFloat {
        guard p.count > 1 else { return 0 }
        var t: CGFloat = 0
        for i in 1..<p.count { t += hypot(p[i].x - p[i - 1].x, p[i].y - p[i - 1].y) }
        return t
    }

    /// Regla: los redondeles se trazan **contra reloj**, empezando arriba a la derecha
    /// (como a las 2). Es la convención de todos los métodos de caligrafía.
    func testLasLetrasRedondasGiranContraReloj() {
        for ch: Character in ["a", "c", "d", "g", "o", "q", "O", "C", "Q", "G", "0"] {
            guard let g = GlyphLibrary.glyph(for: ch), let cuerpo = g.strokes.first else {
                return XCTFail("sin glifo de \(ch)")
            }
            XCTAssertLessThan(areaConSigno(cuerpo.points), 0,
                              "\(ch): el redondel debería girar contra reloj")
        }
    }

    /// Regla: todo trazo horizontal va **de izquierda a derecha**, nunca al revés.
    func testLosTrazosHorizontalesVanDeIzquierdaADerecha() {
        for g in todos {
            for (i, s) in g.strokes.enumerated() where !s.isDot {
                guard let a = s.points.first, let b = s.points.last else { continue }
                let dx = b.x - a.x, dy = b.y - a.y
                guard abs(dy) < 0.10, abs(dx) > 0.20 else { continue }   // solo los horizontales
                XCTAssertGreaterThan(dx, 0,
                                     "\(g.name) trazo \(i): un trazo horizontal va de derecha a izquierda")
            }
        }
    }

    /// Regla: primero el cuerpo y al final la barra, el punto o el acento — y esa
    /// marca final siempre es más corta que el cuerpo.
    func testLaMarcaFinalVaAlFinalYEsMasCorta() {
        for ch: Character in ["t", "i", "j", "4", "5", "á", "é", "í", "ó", "ú",
                              "Á", "É", "Í", "Ó", "Ú", "ñ", "Ñ"] {
            guard let g = GlyphLibrary.glyph(for: ch), g.strokes.count > 1,
                  let primero = g.strokes.first, let ultimo = g.strokes.last else {
                return XCTFail("\(ch) debería tener más de un trazo")
            }
            XCTAssertLessThan(largo(ultimo.points), largo(primero.points),
                              "\(ch): la marca final debería ser más corta que el cuerpo")
        }
    }

    /// Con la guía gruesa, un acento a menos de ~0.055 de su letra se pega a ella y
    /// el niño ve un solo garabato. Pasó con Á, É, Í y Ó.
    func testLosAcentosNoTocanSuLetra() {
        for ch: Character in ["á", "é", "í", "ó", "ú", "Á", "É", "Í", "Ó", "Ú"] {
            guard let g = GlyphLibrary.glyph(for: ch), let acento = g.strokes.last else {
                return XCTFail("sin glifo de \(ch)")
            }
            let cuerpo = g.strokes.dropLast().flatMap(\.points)
            let minima = acento.points.flatMap { a in
                cuerpo.map { hypot(a.x - $0.x, a.y - $0.y) }
            }.min() ?? 0
            XCTAssertGreaterThanOrEqual(minima, 0.055, "\(ch): el acento está pegado a la letra")
        }
    }
}
