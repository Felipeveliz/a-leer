import SwiftUI

// MARK: - Estadísticas de avance (derivadas de PracticeLog + ProgressStore)
//
// Todo lo que la pantalla del adulto necesita saber, calculado aquí y no en el
// `body` de la vista. Son estadísticas de APRENDIZAJE: qué domina, qué le cuesta,
// por qué falla y si va mejorando. Nada de uso de la app.

/// Qué tan suya es una letra. El umbral es de intentos por acierto, no de
/// "¿la logró?": a un niño de cinco años todas las letras le salen tarde o
/// temprano, y lo que distingue una letra aprendida de una que no es cuántas
/// veces tuvo que intentarla.
enum NivelDominio {
    case sinPracticar
    case leCuesta
    case enCamino
    case dominada

    var color: Color {
        switch self {
        case .sinPracticar: return Palette.grayLight
        case .leCuesta:     return Palette.coral
        case .enCamino:     return Palette.yellow
        case .dominada:     return Palette.green
        }
    }

    var nombre: String {
        switch self {
        case .sinPracticar: return "sin practicar"
        case .leCuesta:     return "le cuesta"
        case .enCamino:     return "en camino"
        case .dominada:     return "ya la domina"
        }
    }
}

/// Una letra con problema, ya con lo que hay que hacer y dónde practicarla.
struct LetraQueCuesta: Identifiable {
    let glifo: String
    let intentosPorAcierto: Double
    let fallo: TraceFault?
    /// Palabras que todavía no ha logrado y que llevan esta letra: es donde se
    /// practica. La app no tiene pantalla de letra suelta, y tampoco hace falta.
    let palabras: [String]

    var id: String { glifo }
}

/// Un punto del avance: una semana con su precisión media.
struct SemanaDeAvance: Identifiable {
    let inicio: Date
    let precision: Double
    let trazos: Int

    var id: Date { inicio }

    var etiqueta: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d MMM"
        return f.string(from: inicio)
    }
}

/// Un día del calendario de constancia.
struct DiaDePractica: Identifiable {
    let fecha: Date
    let trazos: Int

    var id: Date { fecha }
    var practico: Bool { trazos > 0 }
}

struct Estadisticas {

    let log: PracticeLog
    let progreso: ProgressStore
    let perfil: PerfilStore

    init(log: PracticeLog = .shared,
         progreso: ProgressStore = .shared,
         perfil: PerfilStore = .shared) {
        self.log = log
        self.progreso = progreso
        self.perfil = perfil
    }

    // MARK: Universo

    /// Todas las letras que la app le pide trazar: las de las palabras de las dos
    /// hojas más las de su propio nombre. Solo las que tienen glifo —las catalanas
    /// se saltan en el flujo, así que contarlas sería inventarle pendientes.
    var letras: [String] {
        var vistas: [String] = []
        var set = Set<String>()
        let fuentes = AppData.palabrasEscribe(en: Set(Hoja.allCases)).map(\.texto) + perfil.partes
        for palabra in fuentes {
            for ch in palabra where GlyphLibrary.glyph(for: ch) != nil {
                let s = String(ch)
                if set.insert(s).inserted { vistas.append(s) }
            }
        }
        return vistas.sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    /// Separadas por caja a propósito: la "l" minúscula y la "I" de Irma se
    /// trazan igual (una barra vertical), y mezcladas en una sola rejilla el
    /// adulto no sabe cuál está mirando. La posición las distingue.
    var minusculas: [String] { letras.filter { $0 == $0.lowercased() } }

    var mayusculas: [String] { letras.filter { $0 != $0.lowercased() } }

    var digitos: [String] { AppData.digitosEscribe.map(String.init).sorted() }

    // MARK: Dominio

    func nivel(de glifo: String) -> NivelDominio {
        guard let stat = log.glifos[glifo], stat.intentos > 0 else { return .sinPracticar }
        guard stat.aciertos > 0 else { return .leCuesta }
        let coste = stat.intentosPorAcierto
        if coste <= 1.3 && stat.aciertos >= 2 { return .dominada }
        if coste < 2 { return .enCamino }
        return .leCuesta
    }

    /// Cuántas letras hay en cada nivel, para el resumen de arriba.
    func cuenta(_ nivel: NivelDominio, entre glifos: [String]) -> Int {
        glifos.filter { self.nivel(de: $0) == nivel }.count
    }

    // MARK: Lo que le cuesta

    /// Las letras más caras primero. Pide al menos 3 intentos para no colgar un
    /// diagnóstico de un solo trazo mal hecho.
    func letrasQueCuestan(_ limite: Int = 3) -> [LetraQueCuesta] {
        let pendientes = palabrasPendientes
        return log.glifos
            .filter { $0.key.count == 1 && $0.value.intentos >= 3 && $0.value.intentosPorAcierto >= 1.5 }
            .sorted {
                $0.value.intentosPorAcierto == $1.value.intentosPorAcierto
                    ? $0.value.intentos > $1.value.intentos
                    : $0.value.intentosPorAcierto > $1.value.intentosPorAcierto
            }
            .prefix(limite)
            .map { glifo, stat in
                LetraQueCuesta(
                    glifo: glifo,
                    intentosPorAcierto: stat.intentosPorAcierto,
                    fallo: stat.falloMasComun,
                    palabras: pendientes.filter { $0.contains(glifo) }.prefix(3).map { $0 }
                )
            }
    }

    /// El error que más repite en todo el módulo, que es el que conviene
    /// corregirle primero.
    var falloDominante: (fallo: TraceFault, veces: Int)? {
        var total: [TraceFault: Int] = [:]
        for stat in log.glifos.values {
            for (clave, veces) in stat.fallos {
                guard let fallo = TraceFault(rawValue: clave) else { continue }
                total[fallo, default: 0] += veces
            }
        }
        guard let mejor = total.max(by: { $0.value < $1.value }), mejor.value > 0 else { return nil }
        return (mejor.key, mejor.value)
    }

    // MARK: Palabras y números

    var palabrasTotales: [Palabra] { AppData.palabrasEscribe(en: Set(Hoja.allCases)) }

    var palabrasLogradas: Int { palabrasTotales.filter { progreso.isWordDone($0) }.count }

    var palabrasPendientes: [String] {
        palabrasTotales.filter { !progreso.isWordDone($0) }.map(\.texto)
    }

    var digitosLogrados: Int {
        AppData.digitosEscribe.filter { progreso.isDigitDone($0) }.count
    }

    // MARK: Avance en el tiempo

    /// Precisión media por semana, de la más vieja a la más nueva. Es la única
    /// serie que contesta "¿le está sirviendo?": las estrellas solo suben.
    func avancePorSemana(_ semanas: Int = 6) -> [SemanaDeAvance] {
        let calendario = Calendar.current
        var porSemana: [Date: (precision: Double, trazos: Int)] = [:]

        for (clave, dia) in log.dias where dia.trazosOK > 0 {
            guard let fecha = PracticeLog.fecha(de: clave),
                  let inicio = calendario.dateInterval(of: .weekOfYear, for: fecha)?.start
            else { continue }
            let previo = porSemana[inicio] ?? (0, 0)
            porSemana[inicio] = (previo.precision + dia.precisionTotal,
                                 previo.trazos + dia.trazosOK)
        }

        return porSemana
            .sorted { $0.key < $1.key }
            .suffix(semanas)
            .map { inicio, valor in
                SemanaDeAvance(inicio: inicio,
                               precision: valor.trazos > 0 ? valor.precision / Double(valor.trazos) : 0,
                               trazos: valor.trazos)
            }
    }

    /// Los últimos `dias` días, el más viejo primero. Es constancia de práctica,
    /// no una racha de premio: a esta edad practicar seguido es lo que avanza.
    func calendario(_ dias: Int = 28) -> [DiaDePractica] {
        let calendario = Calendar.current
        let hoy = calendario.startOfDay(for: Date())
        return (0..<dias).reversed().compactMap { atras in
            guard let fecha = calendario.date(byAdding: .day, value: -atras, to: hoy) else { return nil }
            return DiaDePractica(fecha: fecha,
                                 trazos: log.dias[PracticeLog.clave(de: fecha)]?.trazos ?? 0)
        }
    }

    var diasPracticados: Int { calendario().filter(\.practico).count }

    // MARK: Matemáticas

    var sumasIntentos: Int { log.sumas.values.reduce(0) { $0 + $1.intentos } }
    var sumasAciertos: Int { log.sumas.values.reduce(0) { $0 + $1.aciertos } }

    /// De cada 10 respuestas, cuántas a la primera. Sin intentos no hay dato.
    var tinoEnSumas: Double? {
        guard sumasIntentos > 0 else { return nil }
        return Double(sumasAciertos) / Double(sumasIntentos)
    }

    /// Las sumas que más falla. Con las mismas 5 opciones siempre, fallar una
    /// suma concreta muchas veces señala el número que todavía no tiene.
    func sumasQueFalla(_ limite: Int = 4) -> [(suma: String, fallos: Int)] {
        log.sumas
            .map { (suma: $0.key, fallos: $0.value.intentos - $0.value.aciertos) }
            .filter { $0.fallos > 0 }
            .sorted { $0.fallos > $1.fallos }
            .prefix(limite)
            .map { $0 }
    }

    /// Qué parte de las respuestas dio con el ábaco puesto. Apoyarse en él está
    /// bien; dejar de necesitarlo es el avance.
    var apoyoDelAbaco: Double? {
        guard sumasIntentos > 0 else { return nil }
        let conApoyo = log.sumas.values.reduce(0) { $0 + $1.conApoyo }
        return Double(conApoyo) / Double(sumasIntentos)
    }

    // MARK: ¿Hay algo que mostrar?

    /// Sin un solo trazo medido la pantalla no tiene nada que decir, y es mejor
    /// decirlo que pintar ceros.
    var vacio: Bool { log.glifos.isEmpty && log.sumas.isEmpty }
}
