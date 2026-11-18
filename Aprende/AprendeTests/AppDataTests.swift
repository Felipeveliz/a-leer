import XCTest
@testable import Aprende

/// El contenido de la app es una tabla escrita a mano. El bug de noviembre de 2026
/// ("rosa" en minúscula en la lista de orden y "remo" ausente) no lo cazó nadie durante
/// semanas porque fallaba en silencio. Estas pruebas son el guardián de esa tabla.
final class AppDataTests: XCTestCase {

    // MARK: Escribe: la lista de palabras

    func testPalabrasEscribeTieneExactamenteLasMismasPalabras() {
        let enEscribe = Set(AppData.palabrasEscribe.map(\.texto))
        let todas = Set(AppData.palabras.map(\.texto))
        XCTAssertEqual(enEscribe, todas,
                       "sobra o falta alguna palabra en palabrasEscribe")
        XCTAssertEqual(AppData.palabrasEscribe.count, AppData.palabras.count)
    }

    func testPalabrasEscribeNoRepite() {
        let textos = AppData.palabrasEscribe.map(\.texto)
        XCTAssertEqual(Set(textos).count, textos.count, "hay una palabra duplicada")
    }

    /// El síntoma exacto del bug: "remo" faltaba en la lista de orden y el bucle de
    /// respaldo lo empujaba al final, después de "maleta".
    func testRemoNoCaeAlFinal() {
        let textos = AppData.palabrasEscribe.map(\.texto)
        let remo = textos.firstIndex(of: "remo")
        XCTAssertNotNil(remo)
        XCTAssertLessThan(remo!, textos.count - 1,
                          "remo volvió a caer al final: falta en la lista `orden`")
    }

    /// La promesa de la lista es "de la más fácil de trazar a la más difícil":
    /// las de tres sílabas van al final.
    func testLasPalabrasLargasVanAlFinal() {
        let largas = AppData.palabrasEscribe.enumerated()
            .filter { $0.element.silabas.count >= 3 }
            .map(\.offset)
        XCTAssertFalse(largas.isEmpty)
        let primeraLarga = largas.min()!
        let ultimaCorta = AppData.palabrasEscribe.enumerated()
            .filter { $0.element.silabas.count < 3 }
            .map(\.offset).max()!
        XCTAssertGreaterThan(primeraLarga, ultimaCorta,
                             "una palabra de 3 sílabas se coló antes de las cortas")
    }

    func testTextoDeUnaPalabraEsSusSilabasUnidas() {
        for p in AppData.palabras {
            XCTAssertEqual(p.texto, p.silabas.joined())
        }
    }

    // MARK: Escribe: los dígitos

    func testDigitosEscribeSonLosDiez() {
        XCTAssertEqual(Set(AppData.digitosEscribe), Set("0123456789"))
        XCTAssertEqual(AppData.digitosEscribe.count, 10, "hay un dígito repetido")
    }

    // MARK: Matemáticas

    func testTodasLasSumasCaenEnElRango() {
        for s in AppData.sumas {
            XCTAssertGreaterThanOrEqual(s.total, 2)
            XCTAssertLessThanOrEqual(s.total, 6)
            XCTAssertEqual(s.total, s.a + s.b)
        }
    }

    /// Si una suma no tuviera su resultado entre las cinco opciones, sería imposible
    /// de acertar.
    func testCadaSumaTieneSuRespuestaEnLasOpciones() {
        for s in AppData.sumas {
            XCTAssertTrue(AppData.respuestasSumas.contains(s.total),
                          "la suma \(s.a)+\(s.b) no tiene opción para \(s.total)")
        }
    }

    func testNoHaySumasRepetidas() {
        let ids = AppData.sumas.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: Oración

    func testCadaPalabraDeLaOracionCuadraConSusSilabas() {
        for p in AppData.oracion {
            XCTAssertEqual(p.texto, p.silabas.joined(),
                           "las sílabas de '\(p.texto)' no reconstruyen la palabra")
        }
    }

    func testOracionSilabasVanEnOrden() {
        XCTAssertEqual(AppData.oracionSilabas, AppData.oracion.flatMap(\.silabas))
        XCTAssertFalse(AppData.oracionSilabas.isEmpty)
    }

    // MARK: Sílabas

    func testNoHaySilabasDuplicadasEnElMismoGrupo() {
        let ids = AppData.silabas.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    // MARK: RandomPick

    /// El contrato de "🔀 Otra palabra": nunca repetir la que acabas de ver.
    func testRandomPickNuncaRepiteElAnterior() {
        for _ in 0..<500 {
            XCTAssertNotEqual(RandomPick.next(count: 5, avoiding: 3), 3)
        }
    }

    func testRandomPickConUnSoloElemento() {
        XCTAssertEqual(RandomPick.next(count: 1, avoiding: 0), 0)
    }

    func testRandomPickSiempreEnRango() {
        for _ in 0..<500 {
            let i = RandomPick.next(count: 7, avoiding: nil)
            XCTAssertTrue((0..<7).contains(i))
        }
    }
}
