import SwiftUI

// MARK: - Registro de práctica (lo que alimenta las estadísticas del adulto)
//
// Guarda ACUMULADOS, no un evento por intento. Un registro crudo habría que
// podarlo cada tanto y lo primero que se poda es justo el historial que muestra
// el avance ("¿la 's' le cuesta menos que hace un mes?"). Tres tablas que crecen
// despacio: una fila por glifo, una por día y una por suma.
//
// Nada de esto sale del dispositivo: por eso la ficha de la App Store sigue
// diciendo "no se recopilan datos" y `PrivacyInfo.xcprivacy` no cambia.
//
// Lo que se mide es el AVANCE del niño, no el uso de la app: no hay minutos de
// pantalla, ni sesiones, ni veces que la abrió. Cada número de aquí tiene que
// poder contestarle algo a un adulto sobre cómo va aprendiendo.

// MARK: - Por qué falló un trazo

/// La distinción es el punto pedagógico de todo esto: empezar lejos del punto
/// verde es no saber POR DÓNDE empieza la letra (se corrige enseñándosela), la
/// forma desviada es pulso (se corrige practicando) y el largo es no terminarla.
/// Hoy las tres cosas se ven iguales en pantalla: "¡Casi! Otra vez 🙂".
enum TraceFault: String, Codable, CaseIterable {
    case inicio
    case forma
    case largo

    /// Qué pasó, en las palabras de un adulto que no programa.
    var descripcion: String {
        switch self {
        case .inicio: return "empieza en otro punto"
        case .forma:  return "la forma se desvía"
        case .largo:  return "se queda corta o se pasa"
        }
    }

    /// Qué hacer al respecto. Una estadística que no termina en algo que hacer
    /// solo informa; esta app es para que el adulto sepa qué practicar.
    var consejo: String {
        switch self {
        case .inicio:
            return "No sabe por dónde empieza: señálale el punto verde antes de que trace."
        case .forma:
            return "Es pulso. Calentamiento de mano y trazos grandes y despacio."
        case .largo:
            return "Se detiene antes de terminar: pídele que llegue hasta el final sin levantar el dedo."
        }
    }

    /// Diagnóstico a partir de lo que midió el motor, en orden de importancia:
    /// si empezó mal, lo demás es consecuencia.
    static func desde(_ r: TraceResult) -> TraceFault {
        if !r.startOK { return .inicio }
        if !r.lengthOK || !r.endOK { return .largo }
        return .forma
    }
}

// MARK: - Acumulados

/// Lo que se sabe de un glifo: una letra, un dígito o un trazo de calentamiento.
struct GlyphStat: Codable, Equatable {
    var intentos = 0
    var aciertos = 0
    /// Suma de las precisiones de los aciertos, para poder promediar.
    var precisionTotal = 0.0
    /// `TraceFault.rawValue` → cuántas veces falló así.
    var fallos: [String: Int] = [:]
    var ultima: Date?

    /// Cuántos intentos le cuesta cada letra lograda. 1.0 = le sale de una.
    var intentosPorAcierto: Double {
        aciertos > 0 ? Double(intentos) / Double(aciertos) : Double(intentos)
    }

    var precisionPromedio: Double {
        aciertos > 0 ? precisionTotal / Double(aciertos) : 0
    }

    /// El error que más repite, que es el que hay que corregirle.
    var falloMasComun: TraceFault? {
        guard let clave = fallos.max(by: { $0.value < $1.value })?.key else { return nil }
        return TraceFault(rawValue: clave)
    }
}

/// Un día de práctica. Es lo que permite ver el avance en el tiempo sin guardar
/// un evento por trazo.
struct DayStat: Codable, Equatable {
    var trazos = 0
    var trazosOK = 0
    var precisionTotal = 0.0
    var sumas = 0
    var sumasOK = 0

    var precisionPromedio: Double {
        trazosOK > 0 ? precisionTotal / Double(trazosOK) : 0
    }
}

/// Una suma concreta ("4+2"): si la acierta y si necesitó el ábaco.
struct SumStat: Codable, Equatable {
    var intentos = 0
    var aciertos = 0
    /// Veces que la respondió con el ábaco puesto. Apoyarse en él no es malo;
    /// dejar de necesitarlo es el avance.
    var conApoyo = 0
}

// MARK: - Store

final class PracticeLog: ObservableObject {

    static let shared = PracticeLog()

    private static let claveGlifos = "aprende.practica.glifos"
    private static let claveDias = "aprende.practica.dias"
    private static let claveSumas = "aprende.practica.sumas"

    /// Glifo (el `name` del `Glyph`) → acumulado.
    @Published private(set) var glifos: [String: GlyphStat]
    /// Día en formato "yyyy-MM-dd" (calendario local) → acumulado.
    @Published private(set) var dias: [String: DayStat]
    /// Suma ("4+2") → acumulado.
    @Published private(set) var sumas: [String: SumStat]

    private let defaults: UserDefaults

    /// `defaults` se inyecta para que los tests no pisen el progreso real.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        glifos = Self.leer([String: GlyphStat].self, de: Self.claveGlifos, en: defaults) ?? [:]
        dias = Self.leer([String: DayStat].self, de: Self.claveDias, en: defaults) ?? [:]
        sumas = Self.leer([String: SumStat].self, de: Self.claveSumas, en: defaults) ?? [:]
    }

    // MARK: Registro

    /// Un movimiento del niño sobre un glifo. `precision` solo cuenta cuando
    /// acertó: promediar la precisión de un garabato que no cuadró con nada no
    /// significaría nada.
    func registra(glifo: String, ok: Bool, precision: Double, fallo: TraceFault?) {
        var stat = glifos[glifo] ?? GlyphStat()
        stat.intentos += 1
        stat.ultima = Date()
        if ok {
            stat.aciertos += 1
            stat.precisionTotal += max(0, min(1, precision))
        } else if let fallo {
            stat.fallos[fallo.rawValue, default: 0] += 1
        }
        glifos[glifo] = stat

        var dia = dias[Self.claveDeHoy()] ?? DayStat()
        dia.trazos += 1
        if ok {
            dia.trazosOK += 1
            dia.precisionTotal += max(0, min(1, precision))
        }
        dias[Self.claveDeHoy()] = dia

        guardar()
    }

    /// Una respuesta a una suma.
    func registra(suma: Suma, ok: Bool, conApoyo: Bool) {
        var stat = sumas[suma.id] ?? SumStat()
        stat.intentos += 1
        if ok { stat.aciertos += 1 }
        if conApoyo { stat.conApoyo += 1 }
        sumas[suma.id] = stat

        var dia = dias[Self.claveDeHoy()] ?? DayStat()
        dia.sumas += 1
        if ok { dia.sumasOK += 1 }
        dias[Self.claveDeHoy()] = dia

        guardar()
    }

    /// Borra todo lo medido. La zona de adultos no la ofrece todavía; existe
    /// para los tests y para cuando se decida el "reiniciar progreso".
    func borraTodo() {
        glifos = [:]
        dias = [:]
        sumas = [:]
        guardar()
    }

    // MARK: Persistencia

    private func guardar() {
        Self.escribir(glifos, en: Self.claveGlifos, defaults: defaults)
        Self.escribir(dias, en: Self.claveDias, defaults: defaults)
        Self.escribir(sumas, en: Self.claveSumas, defaults: defaults)
    }

    private static func leer<T: Decodable>(_ tipo: T.Type, de clave: String,
                                           en defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(tipo, from: data)
    }

    private static func escribir<T: Encodable>(_ valor: T, en clave: String,
                                               defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(valor) else { return }
        defaults.set(data, forKey: clave)
    }

    // MARK: Días

    /// Formateador fijo: `en_US_POSIX` para que la clave no cambie de forma con
    /// el idioma del dispositivo, y calendario local porque "el día que practicó"
    /// es el día de su casa, no UTC.
    private static let formatoDia: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func clave(de fecha: Date) -> String { formatoDia.string(from: fecha) }

    static func claveDeHoy() -> String { clave(de: Date()) }

    static func fecha(de clave: String) -> Date? { formatoDia.date(from: clave) }
}
