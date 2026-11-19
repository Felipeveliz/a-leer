import XCTest
@testable import Aprende

/// El contenido de la app es una tabla escrita a mano. El bug de noviembre de 2026
/// ("rosa" en minúscula en la lista de orden y "remo" ausente) no lo cazó nadie durante
/// semanas porque fallaba en silencio. Estas pruebas son el guardián de esa tabla.
final class AppDataTests: XCTestCase {

    // MARK: Escribe: la lista de palabras

    private let todasLasHojas = Set(Hoja.allCases)

    func testPalabrasEscribeTieneExactamenteLasMismasPalabras() {
        let enEscribe = Set(AppData.palabrasEscribe(en: todasLasHojas).map(\.texto))
        let todas = Set(AppData.palabras.map(\.texto))
        XCTAssertEqual(enEscribe, todas,
                       "sobra o falta alguna palabra en palabrasEscribe")
    }

    func testPalabrasEscribeNoRepite() {
        for hojas in [Set([Hoja.dos]), Set([Hoja.tres]), todasLasHojas] {
            let textos = AppData.palabrasEscribe(en: hojas).map(\.texto)
            XCTAssertEqual(Set(textos).count, textos.count,
                           "hay una palabra duplicada con \(hojas)")
        }
    }

    /// Una palabra que está en las dos hojas ("pelota", "rata") sale una sola vez
    /// cuando las dos están marcadas, pero tiene que salir si se marca cualquiera
    /// de las dos por separado.
    func testPalabrasEnDosHojasSalenEnAmbasYSinDuplicar() {
        let enDosHojas = AppData.palabras.filter { $0.hojas.count > 1 }.map(\.texto)
        XCTAssertFalse(enDosHojas.isEmpty, "se esperaba al menos una palabra compartida")
        for texto in enDosHojas {
            for hoja in Hoja.allCases {
                let textos = AppData.palabrasEscribe(en: [hoja]).map(\.texto)
                XCTAssertTrue(textos.contains(texto),
                              "'\(texto)' debería estar en la hoja \(hoja.rawValue)")
            }
            let juntas = AppData.palabrasEscribe(en: todasLasHojas).map(\.texto)
            XCTAssertEqual(juntas.filter { $0 == texto }.count, 1,
                           "'\(texto)' sale dos veces al marcar las dos hojas")
        }
    }

    /// El síntoma exacto del bug: "remo" faltaba en la lista de orden y el bucle de
    /// respaldo lo empujaba al final, después de "maleta".
    func testRemoNoCaeAlFinal() {
        let textos = AppData.palabrasEscribe(en: [.dos]).map(\.texto)
        let remo = textos.firstIndex(of: "remo")
        XCTAssertNotNil(remo)
        XCTAssertLessThan(remo!, textos.count - 1,
                          "remo volvió a caer al final: falta en la lista `orden`")
    }

    /// La promesa de la lista es "de la más fácil de trazar a la más difícil":
    /// dentro de cada hoja, las largas van al final.
    func testLasPalabrasLargasVanAlFinalDeCadaHoja() {
        for hoja in Hoja.allCases {
            let lista = AppData.palabrasEscribe(en: [hoja])
            let largas = lista.enumerated().filter { $0.element.silabas.count >= 3 }.map(\.offset)
            let cortas = lista.enumerated().filter { $0.element.silabas.count < 3 }.map(\.offset)
            guard let primeraLarga = largas.min(), let ultimaCorta = cortas.max() else { continue }
            XCTAssertGreaterThan(primeraLarga, ultimaCorta,
                                 "en la hoja \(hoja.rawValue) una palabra larga se coló antes de las cortas")
        }
    }

    // MARK: Hojas

    /// La hoja 3 es la foto que trajo Eliab: "Lectura de palabras", 20 palabras.
    func testLaHojaTresTieneVeintePalabras() {
        XCTAssertEqual(AppData.palabras(en: [.tres]).count, 20)
    }

    func testCadaPalabraPerteneceAAlgunaHoja() {
        for p in AppData.palabras {
            XCTAssertFalse(p.hojas.isEmpty, "'\(p.texto)' no está en ninguna hoja")
        }
    }

    /// Filtrar por todas las hojas no puede perder nada.
    func testFiltrarPorTodasLasHojasDevuelveTodo() {
        XCTAssertEqual(AppData.palabras(en: todasLasHojas).count, AppData.palabras.count)
        XCTAssertEqual(AppData.silabas(en: todasLasHojas).count, AppData.silabas.count)
        XCTAssertEqual(AppData.oracion(en: todasLasHojas).count, AppData.oracion.count)
    }

    /// Cada orden de Escribe tiene que cubrir exactamente su hoja: si sobra o
    /// falta una entrada, `palabrasEscribe` dispara `assertionFailure`.
    func testElOrdenDeCadaHojaCubreSuHoja() {
        for hoja in Hoja.allCases {
            let enLaHoja = Set(AppData.palabras.filter { $0.hojas.contains(hoja) }.map(\.texto))
            let enElOrden = Set(AppData.ordenEscribe[hoja] ?? [])
            XCTAssertEqual(enElOrden, enLaHoja,
                           "el orden de la hoja \(hoja.rawValue) no cuadra con sus palabras")
        }
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
        let todas = Set(Hoja.allCases)
        XCTAssertEqual(AppData.oracionSilabas(en: todas), AppData.oracion.flatMap(\.silabas))
        XCTAssertFalse(AppData.oracionSilabas(en: todas).isEmpty)
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
