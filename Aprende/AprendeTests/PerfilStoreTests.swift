import XCTest
@testable import Aprende

/// El nombre que teclea el adulto es lo que el niño va a trazar letra por letra en
/// Escribe. Si se guarda "eliab", el niño aprende a escribir su nombre con minúscula,
/// justo al revés de lo que la app le enseña con Lola, Rosa o Nena.
final class PerfilStoreTests: XCTestCase {

    private func normalizado(_ texto: String) -> String {
        PerfilStore.conMayusculaInicial(texto)
    }

    func testPoneMayusculaEnCadaParte() {
        XCTAssertEqual(normalizado("eliab veliz"), "Eliab Veliz")
    }

    func testBajaLoQueSeTecleoTodoEnMayusculas() {
        XCTAssertEqual(normalizado("ELIAB VELIZ"), "Eliab Veliz")
    }

    func testDejaIgualLoQueYaEstabaBien() {
        XCTAssertEqual(normalizado("Eliab Veliz"), "Eliab Veliz")
    }

    /// En español las partículas van en minúscula si no encabezan el nombre.
    func testLasParticulasSeQuedanEnMinuscula() {
        XCTAssertEqual(normalizado("juan de la cruz"), "Juan de la Cruz")
        XCTAssertEqual(normalizado("maría del carmen ríos"), "María del Carmen Ríos")
    }

    /// Pero sí se capitaliza si la partícula es la primera parte (hay quien se
    /// apellida solo "De la Cruz").
    func testUnaParticulaAlPrincipioSiLlevaMayuscula() {
        XCTAssertEqual(normalizado("de la cruz"), "De la Cruz")
    }

    /// Las mayúsculas internas se respetan: bajarlas rompería estos apellidos.
    func testRespetaLasMayusculasInternas() {
        XCTAssertEqual(normalizado("D'Angelo"), "D'Angelo")
        XCTAssertEqual(normalizado("McAllister"), "McAllister")
    }

    func testLimpiaLosEspaciosDeSobra() {
        XCTAssertEqual(normalizado("  eliab   veliz  "), "Eliab Veliz")
        XCTAssertEqual(normalizado(""), "")
        XCTAssertEqual(normalizado("   "), "")
    }

    /// Los acentos no se pierden al subir la inicial, y tienen glifo en mayúscula.
    func testLasInicialesAcentuadasSuben() {
        XCTAssertEqual(normalizado("ángel"), "Ángel")
        XCTAssertEqual(normalizado("óscar iñigo"), "Óscar Iñigo")
    }

    /// Lo que sale de aquí tiene que ser trazable, o el flujo de Escribe se salta
    /// letras sin avisar al niño.
    func testTodaLetraDelNombreNormalizadoTieneGlifo() {
        for nombre in ["eliab veliz", "maría del carmen", "ángel óscar iñigo", "juan de la cruz"] {
            for letra in normalizado(nombre) where !letra.isWhitespace {
                XCTAssertNotNil(GlyphLibrary.glyph(for: letra),
                                "'\(letra)' de '\(nombre)' no tiene glifo")
            }
        }
    }
}
