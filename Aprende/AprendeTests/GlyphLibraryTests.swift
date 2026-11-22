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
}
