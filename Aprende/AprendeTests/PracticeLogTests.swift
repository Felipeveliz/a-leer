import XCTest
@testable import Aprende

/// Las estadísticas que ve el adulto se construyen de estos acumulados. Un error
/// aquí no rompe la app: miente sobre cómo va el niño, que es peor, porque nadie
/// lo nota mirando la pantalla.
final class PracticeLogTests: XCTestCase {

    private var defaults = UserDefaults(suiteName: "pruebas.practica")

    private func logLimpio() -> PracticeLog {
        guard let defaults else {
            XCTFail("sin UserDefaults de prueba")
            return PracticeLog()
        }
        for clave in ["aprende.practica.glifos", "aprende.practica.dias", "aprende.practica.sumas"] {
            defaults.removeObject(forKey: clave)
        }
        return PracticeLog(defaults: defaults)
    }

    // MARK: Registro

    func testUnAciertoCuentaIntentoYPrecision() {
        let log = logLimpio()
        log.registra(glifo: "a", ok: true, precision: 0.8, fallo: nil)

        XCTAssertEqual(log.glifos["a"]?.intentos, 1)
        XCTAssertEqual(log.glifos["a"]?.aciertos, 1)
        XCTAssertEqual(log.glifos["a"]?.precisionPromedio ?? 0, 0.8, accuracy: 0.001)
    }

    func testUnFalloGuardaElMotivoYNoEnsuciaLaPrecision() {
        let log = logLimpio()
        log.registra(glifo: "s", ok: false, precision: 0, fallo: .inicio)
        log.registra(glifo: "s", ok: true, precision: 0.6, fallo: nil)

        XCTAssertEqual(log.glifos["s"]?.intentos, 2)
        XCTAssertEqual(log.glifos["s"]?.fallos["inicio"], 1)
        // La precisión promedia solo los aciertos: el 0 del garabato que no
        // cuadró con nada no significa "trazó mal", significa "no se pudo medir".
        XCTAssertEqual(log.glifos["s"]?.precisionPromedio ?? 0, 0.6, accuracy: 0.001)
    }

    func testIntentosPorAciertoEsElCosteDeLaLetra() {
        let log = logLimpio()
        log.registra(glifo: "g", ok: false, precision: 0, fallo: .forma)
        log.registra(glifo: "g", ok: false, precision: 0, fallo: .forma)
        log.registra(glifo: "g", ok: true, precision: 0.5, fallo: nil)

        XCTAssertEqual(log.glifos["g"]?.intentosPorAcierto ?? 0, 3, accuracy: 0.001)
    }

    func testElFalloMasComunEsElQueHayQueCorregir() {
        let log = logLimpio()
        log.registra(glifo: "e", ok: false, precision: 0, fallo: .forma)
        log.registra(glifo: "e", ok: false, precision: 0, fallo: .inicio)
        log.registra(glifo: "e", ok: false, precision: 0, fallo: .inicio)

        XCTAssertEqual(log.glifos["e"]?.falloMasComun, .inicio)
    }

    func testLaSumaGuardaElApoyoDelAbaco() {
        let log = logLimpio()
        log.registra(suma: Suma(a: 4, b: 2), ok: false, conApoyo: false)
        log.registra(suma: Suma(a: 4, b: 2), ok: true, conApoyo: true)

        XCTAssertEqual(log.sumas["4+2"]?.intentos, 2)
        XCTAssertEqual(log.sumas["4+2"]?.aciertos, 1)
        XCTAssertEqual(log.sumas["4+2"]?.conApoyo, 1)
    }

    func testElDiaAcumulaTrazosYSumas() {
        let log = logLimpio()
        log.registra(glifo: "a", ok: true, precision: 1, fallo: nil)
        log.registra(suma: Suma(a: 1, b: 1), ok: true, conApoyo: false)

        let hoy = log.dias[PracticeLog.claveDeHoy()]
        XCTAssertEqual(hoy?.trazos, 1)
        XCTAssertEqual(hoy?.trazosOK, 1)
        XCTAssertEqual(hoy?.sumas, 1)
        XCTAssertEqual(hoy?.sumasOK, 1)
    }

    func testLoRegistradoSobreviveAReabrirLaApp() {
        guard let defaults else { return XCTFail("sin UserDefaults de prueba") }
        let log = logLimpio()
        log.registra(glifo: "m", ok: true, precision: 0.7, fallo: nil)

        let otro = PracticeLog(defaults: defaults)
        XCTAssertEqual(otro.glifos["m"]?.aciertos, 1)
    }

    // MARK: Dominio

    func testUnaLetraQueSaleDeUnaSeConsideraDominada() {
        let log = logLimpio()
        log.registra(glifo: "l", ok: true, precision: 0.9, fallo: nil)
        log.registra(glifo: "l", ok: true, precision: 0.9, fallo: nil)

        XCTAssertEqual(Estadisticas(log: log).nivel(de: "l"), .dominada)
    }

    func testUnaLetraQueCuestaTresIntentosNoEstaDominada() {
        let log = logLimpio()
        log.registra(glifo: "z", ok: false, precision: 0, fallo: .forma)
        log.registra(glifo: "z", ok: false, precision: 0, fallo: .forma)
        log.registra(glifo: "z", ok: true, precision: 0.4, fallo: nil)

        XCTAssertEqual(Estadisticas(log: log).nivel(de: "z"), .leCuesta)
    }

    func testUnaLetraSinTrazarNoAparecePracticada() {
        XCTAssertEqual(Estadisticas(log: logLimpio()).nivel(de: "q"), .sinPracticar)
    }

    /// Un solo trazo mal hecho no es un diagnóstico: hacen falta varios intentos
    /// antes de decirle a un adulto que a su hijo le cuesta una letra.
    func testNoSeDiagnosticaConUnSoloIntento() {
        let log = logLimpio()
        log.registra(glifo: "r", ok: false, precision: 0, fallo: .inicio)

        XCTAssertTrue(Estadisticas(log: log).letrasQueCuestan().isEmpty)
    }

    func testLaLetraQueMasCuestaVaPrimero() {
        let log = logLimpio()
        // "b": 4 intentos, 1 acierto. "d": 3 intentos, 1 acierto.
        for _ in 0..<3 { log.registra(glifo: "b", ok: false, precision: 0, fallo: .inicio) }
        log.registra(glifo: "b", ok: true, precision: 0.5, fallo: nil)
        for _ in 0..<2 { log.registra(glifo: "d", ok: false, precision: 0, fallo: .forma) }
        log.registra(glifo: "d", ok: true, precision: 0.5, fallo: nil)

        let duras = Estadisticas(log: log).letrasQueCuestan()
        XCTAssertEqual(duras.first?.glifo, "b")
        XCTAssertEqual(duras.first?.fallo, .inicio)
    }

    /// Los trazos de calentamiento se registran igual, pero no son letras y no
    /// tienen por qué salir en el mapa del abecedario.
    func testElCalentamientoNoCuentaComoLetra() {
        let log = logLimpio()
        for _ in 0..<4 { log.registra(glifo: "zigzag", ok: false, precision: 0, fallo: .forma) }

        XCTAssertTrue(Estadisticas(log: log).letrasQueCuestan().isEmpty)
    }

    // MARK: Diagnóstico

    func testEmpezarLejosDelPuntoVerdeSeDiagnosticaComoInicio() {
        let r = TraceResult(passed: false, startOK: false, endOK: true, shapeOK: true,
                            lengthOK: true, meanDistance: 5, precision: 0.5)
        XCTAssertEqual(TraceFault.desde(r), .inicio)
    }

    func testQuedarseCortoSeDiagnosticaComoLargo() {
        let r = TraceResult(passed: false, startOK: true, endOK: false, shapeOK: true,
                            lengthOK: false, meanDistance: 5, precision: 0.5)
        XCTAssertEqual(TraceFault.desde(r), .largo)
    }

    func testLaFormaDesviadaEsElDiagnosticoDeUltimoRecurso() {
        let r = TraceResult(passed: false, startOK: true, endOK: true, shapeOK: false,
                            lengthOK: true, meanDistance: 5, precision: 0.1)
        XCTAssertEqual(TraceFault.desde(r), .forma)
    }

    // MARK: Precisión

    func testLaPrecisionEsUnoCuandoElTrazoVaEncimaDelModelo() {
        XCTAssertEqual(TraceEngine.precision(0, tolerancia: 10), 1, accuracy: 0.001)
    }

    func testLaPrecisionEsCeroAlBordeDeLaTolerancia() {
        XCTAssertEqual(TraceEngine.precision(10, tolerancia: 10), 0, accuracy: 0.001)
    }

    /// Un trazo peor que el límite no puede dar precisión negativa: se promedia
    /// con las demás y arrastraría la media a cualquier lado.
    func testLaPrecisionNoBajaDeCero() {
        XCTAssertEqual(TraceEngine.precision(100, tolerancia: 10), 0, accuracy: 0.001)
    }
}
