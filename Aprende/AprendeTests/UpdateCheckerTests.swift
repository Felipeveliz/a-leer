import XCTest
@testable import Aprende

/// Comparar versiones como texto es el error clásico: "1.10" es alfabéticamente
/// menor que "1.9" y la app diría que está al día cuando no lo está.
final class UpdateCheckerTests: XCTestCase {

    func testUnaVersionMayorEsMasNueva() {
        XCTAssertTrue(UpdateChecker.esMasNueva("1.2", que: "1.1"))
    }

    func testLaMismaVersionNoEsMasNueva() {
        XCTAssertFalse(UpdateChecker.esMasNueva("1.1", que: "1.1"))
    }

    func testUnaVersionMenorNoEsMasNueva() {
        XCTAssertFalse(UpdateChecker.esMasNueva("1.1", que: "1.2"))
    }

    func testDiezEsMayorQueNueve() {
        XCTAssertTrue(UpdateChecker.esMasNueva("1.10", que: "1.9"))
        XCTAssertFalse(UpdateChecker.esMasNueva("1.9", que: "1.10"))
    }

    func testCompararConDistintaCantidadDePartes() {
        XCTAssertTrue(UpdateChecker.esMasNueva("1.1.1", que: "1.1"))
        XCTAssertFalse(UpdateChecker.esMasNueva("1.1", que: "1.1.0"))
        XCTAssertTrue(UpdateChecker.esMasNueva("2", que: "1.9.9"))
    }

    /// Si la tienda devolviera algo raro, la app no debe anunciar una versión
    /// nueva inexistente.
    func testTextoQueNoEsVersionNoAnunciaNada() {
        XCTAssertFalse(UpdateChecker.esMasNueva("", que: "1.1"))
        XCTAssertFalse(UpdateChecker.esMasNueva("beta", que: "1.1"))
    }
}
