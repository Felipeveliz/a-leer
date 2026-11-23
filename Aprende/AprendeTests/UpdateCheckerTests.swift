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

/// El candado de versión: bloquea con un sí de Apple y con nada más.
@MainActor
final class UpdateGateTests: XCTestCase {

    private func resultado(publicada: String, instalada: String) -> UpdateChecker.Resultado {
        UpdateChecker.Resultado(versionPublicada: publicada,
                                versionInstalada: instalada,
                                enlace: URL(string: "https://apps.apple.com/app/id6836391055"))
    }

    func testBloqueaCuandoHayUnaVersionMasNueva() {
        let estado = UpdateGate.decide(resultado(publicada: "1.2", instalada: "1.1"))
        guard case .bloqueada(let version, _) = estado else {
            return XCTFail("debería bloquear")
        }
        XCTAssertEqual(version, "1.2")
    }

    func testNoBloqueaConLaMismaVersion() {
        XCTAssertEqual(UpdateGate.decide(resultado(publicada: "1.1", instalada: "1.1")), .alDia)
    }

    /// Pasa en TestFlight todo el tiempo: la build de pruebas va por delante de
    /// lo publicado. Bloquear ahí sería dejar al tester fuera de su propia app.
    func testNoBloqueaSiLoInstaladoEsMasNuevoQueLaTienda() {
        XCTAssertEqual(UpdateGate.decide(resultado(publicada: "1.0", instalada: "1.1")), .alDia)
    }

    func testDiezEsMasNuevoQueNueveTambienEnElCandado() {
        let estado = UpdateGate.decide(resultado(publicada: "1.10", instalada: "1.9"))
        XCTAssertNotEqual(estado, .alDia)
    }
}
