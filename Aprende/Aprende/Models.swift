import Foundation

// MARK: - Modelos del repositorio de aprendizaje
//
// El contenido viene de las hojas que Eliab trae de la escuela. Cada sílaba,
// palabra y palabra de la oración sabe en qué hojas aparece, y el niño elige
// en pantalla con cuáles quiere practicar. La hoja 1 se perdió.
//
// Una palabra puede estar en VARIAS hojas ("pelota" y "rata" vienen en la 2 y
// en la 3): por eso `hojas` es un conjunto y no una sola hoja. Si fuera una
// sola, al marcar solo la hoja 3 faltarían palabras que sí están en su hoja.

enum Hoja: Int, CaseIterable, Identifiable, Hashable {
    case dos = 2
    case tres = 3

    var id: Int { rawValue }
    var nombre: String { "Hoja \(rawValue)" }
}

struct Silaba: Identifiable, Hashable {
    let grupo: String
    let texto: String
    var hojas: Set<Hoja> = [.dos]
    var id: String { grupo + texto }
}

struct Palabra: Identifiable, Hashable {
    let grupo: String
    let silabas: [String]
    var hojas: Set<Hoja> = [.dos]
    var texto: String { silabas.joined() }
    var id: String { texto }
}

struct PalabraOracion: Identifiable, Hashable {
    let texto: String
    let silabas: [String]
    var hojas: Set<Hoja> = [.dos]
    var id: String { texto }
}

struct Suma: Identifiable, Hashable {
    let a: Int
    let b: Int
    var total: Int { a + b }
    var id: String { "\(a)+\(b)" }
}

enum AppData {

    // MARK: Lectura de sílabas
    static let silabas: [Silaba] = [
        .init(grupo: "Ll", texto: "la"), .init(grupo: "Ll", texto: "le"), .init(grupo: "Ll", texto: "li"), .init(grupo: "Ll", texto: "lo"), .init(grupo: "Ll", texto: "lu"),
        .init(grupo: "Rr", texto: "ra"), .init(grupo: "Rr", texto: "re"), .init(grupo: "Rr", texto: "ri"), .init(grupo: "Rr", texto: "ro"), .init(grupo: "Rr", texto: "ru"),
        .init(grupo: "Nn", texto: "na"), .init(grupo: "Nn", texto: "ne"), .init(grupo: "Nn", texto: "ni"), .init(grupo: "Nn", texto: "no"), .init(grupo: "Nn", texto: "nu"),
        .init(grupo: "Mm", texto: "ma"), .init(grupo: "Mm", texto: "me"), .init(grupo: "Mm", texto: "mi"), .init(grupo: "Mm", texto: "mo"), .init(grupo: "Mm", texto: "mu"),
        .init(grupo: "Ss", texto: "sa"), .init(grupo: "Ss", texto: "se"), .init(grupo: "Ss", texto: "si"), .init(grupo: "Ss", texto: "so"), .init(grupo: "Ss", texto: "su"),
        .init(grupo: "Tt", texto: "ta"), .init(grupo: "Tt", texto: "te"), .init(grupo: "Tt", texto: "ti"), .init(grupo: "Tt", texto: "to"), .init(grupo: "Tt", texto: "tu"),
        .init(grupo: "Pp", texto: "pa"), .init(grupo: "Pp", texto: "pe"), .init(grupo: "Pp", texto: "pi"), .init(grupo: "Pp", texto: "po"), .init(grupo: "Pp", texto: "pu"),
        .init(grupo: "Repaso", texto: "am"), .init(grupo: "Repaso", texto: "amo"), .init(grupo: "Repaso", texto: "mo"), .init(grupo: "Repaso", texto: "mor"),
    ]

    // MARK: Lectura de palabras (también son las palabras del módulo Escribe)
    static let palabras: [Palabra] = [
        // ---- Hoja 2 ----
        .init(grupo: "Ll", silabas: ["Lo", "la"]),
        .init(grupo: "Ll", silabas: ["la", "ta"]),
        .init(grupo: "Ll", silabas: ["lo", "ma"]),
        .init(grupo: "Ll", silabas: ["li", "ma"]),
        .init(grupo: "Rr", silabas: ["Ro", "sa"]),
        .init(grupo: "Rr", silabas: ["ri", "sa"]),
        .init(grupo: "Rr", silabas: ["re", "mo"]),
        .init(grupo: "Rr", silabas: ["ru", "ta"]),
        .init(grupo: "Nn", silabas: ["Ne", "na"]),
        .init(grupo: "Nn", silabas: ["ne", "ne"]),
        .init(grupo: "Nn", silabas: ["no", "ta"]),
        .init(grupo: "Nn", silabas: ["na", "ta"]),
        .init(grupo: "Repaso", silabas: ["a", "to", "le"]),
        .init(grupo: "Repaso", silabas: ["a", "mor"]),
        .init(grupo: "Repaso", silabas: ["ma", "le", "ta"]),
        .init(grupo: "Repaso", silabas: ["e", "lo", "te"]),

        // ---- En las dos hojas ----
        .init(grupo: "Rr", silabas: ["ra", "ta"], hojas: [.dos, .tres]),
        .init(grupo: "Repaso", silabas: ["pe", "lo", "ta"], hojas: [.dos, .tres]),

        // ---- Hoja 3: "Lectura de palabras" ----
        .init(grupo: "Ss", silabas: ["o", "sa"], hojas: [.tres]),
        .init(grupo: "Ss", silabas: ["o", "so"], hojas: [.tres]),
        .init(grupo: "Pp", silabas: ["pa", "le", "ta"], hojas: [.tres]),
        .init(grupo: "Pp", silabas: ["pu", "ma"], hojas: [.tres]),
        .init(grupo: "Pp", silabas: ["pas", "to"], hojas: [.tres]),
        .init(grupo: "Tt", silabas: ["to", "rre"], hojas: [.tres]),
        .init(grupo: "Rr", silabas: ["ro", "sa"], hojas: [.tres]),
        .init(grupo: "Mm", silabas: ["ma", "la"], hojas: [.tres]),
        .init(grupo: "Mm", silabas: ["ma", "pa"], hojas: [.tres]),
        .init(grupo: "Mm", silabas: ["mo", "le"], hojas: [.tres]),
        .init(grupo: "Mm", silabas: ["mue", "la"], hojas: [.tres]),
        .init(grupo: "Mm", silabas: ["ma", "ri", "po", "sa"], hojas: [.tres]),
        .init(grupo: "Ll", silabas: ["li", "món"], hojas: [.tres]),
        .init(grupo: "Ll", silabas: ["lu", "pa"], hojas: [.tres]),
        .init(grupo: "Repaso", silabas: ["Ir", "ma"], hojas: [.tres]),
        .init(grupo: "Repaso", silabas: ["is", "la"], hojas: [.tres]),
        .init(grupo: "Ss", silabas: ["sa", "po"], hojas: [.tres]),
        .init(grupo: "Ss", silabas: ["sol"], hojas: [.tres]),
    ]

    // MARK: Leer una oración
    static let oracion: [PalabraOracion] = [
        .init(texto: "mi", silabas: ["mi"]),
        .init(texto: "mamá", silabas: ["ma", "má"]),
        .init(texto: "me", silabas: ["me"]),
        .init(texto: "da", silabas: ["da"]),
        .init(texto: "elote", silabas: ["e", "lo", "te"]),
        .init(texto: "de", silabas: ["de"]),
        .init(texto: "cenar", silabas: ["ce", "nar"]),
    ]

    // MARK: Filtros por hoja

    static func silabas(en hojas: Set<Hoja>) -> [Silaba] {
        silabas.filter { !$0.hojas.isDisjoint(with: hojas) }
    }

    static func palabras(en hojas: Set<Hoja>) -> [Palabra] {
        palabras.filter { !$0.hojas.isDisjoint(with: hojas) }
    }

    static func oracion(en hojas: Set<Hoja>) -> [PalabraOracion] {
        oracion.filter { !$0.hojas.isDisjoint(with: hojas) }
    }

    /// Todas las sílabas de la oración elegida, en orden.
    static func oracionSilabas(en hojas: Set<Hoja>) -> [String] {
        oracion(en: hojas).flatMap(\.silabas)
    }

    // MARK: Matemáticas: todas las combinaciones a+b con resultado 2...6
    static let sumas: [Suma] = (2...6).flatMap { total in
        (0...total).map { a in Suma(a: a, b: total - a) }
    }

    /// Respuestas posibles que se muestran como opciones.
    static let respuestasSumas = [2, 3, 4, 5, 6]

    // MARK: Escribe

    /// Orden de dificultad de trazo dentro de cada hoja: cortas y de líneas
    /// simples → con mayúscula o acento → largas.
    /// Ojo: las entradas van con la mayúscula EXACTA de la palabra real
    /// ("Rosa", no "rosa"), porque la búsqueda es por texto literal. Una palabra
    /// que esté en dos hojas aparece en el orden de las dos.
    static let ordenEscribe: [Hoja: [String]] = [
        .dos: ["lata", "lima", "loma", "rata", "ruta", "risa", "remo", "nata", "nota", "nene",
               "Lola", "Rosa", "Nena", "amor", "elote", "atole", "pelota", "maleta"],
        .tres: ["sol", "osa", "oso", "isla", "lupa", "mala", "mapa", "mole", "puma", "rata",
                "rosa", "sapo", "muela", "pasto", "torre", "limón", "Irma", "paleta", "pelota",
                "mariposa"],
    ]

    /// Palabras del módulo Escribe para las hojas elegidas: hoja por hoja y,
    /// dentro de cada una, por dificultad de trazo. Las que están en dos hojas
    /// salen una sola vez, en la primera hoja marcada.
    static func palabrasEscribe(en hojas: Set<Hoja>) -> [Palabra] {
        var resultado: [Palabra] = []
        var vistos = Set<String>()

        for hoja in Hoja.allCases where hojas.contains(hoja) {
            let deLaHoja = palabras.filter { $0.hojas.contains(hoja) }
            var porTexto: [String: Palabra] = [:]
            for p in deLaHoja { porTexto[p.texto] = p }

            for t in ordenEscribe[hoja] ?? [] {
                guard let p = porTexto[t] else {
                    // Entrada muerta en el orden: una palabra mal escrita se saltaría
                    // en silencio y el orden de dificultad quedaría roto.
                    assertionFailure("palabrasEscribe: '\(t)' no está en la hoja \(hoja.rawValue)")
                    continue
                }
                if !vistos.contains(p.texto) {
                    resultado.append(p); vistos.insert(p.texto)
                }
            }
            for p in deLaHoja where !vistos.contains(p.texto) {
                // Palabra que falta en el orden: cae al final, después de las más
                // difíciles. Debe quedar vacío.
                assertionFailure("palabrasEscribe: '\(p.texto)' falta en el orden de la hoja \(hoja.rawValue)")
                resultado.append(p); vistos.insert(p.texto)
            }
        }
        return resultado
    }

    /// Dígitos en orden de dificultad de trazo. No dependen de la hoja.
    static let digitosEscribe: [Character] = ["1", "7", "4", "0", "2", "3", "5", "6", "9", "8"]
}

// MARK: - Utilidad: elegir índice aleatorio sin repetir el anterior

enum RandomPick {
    static func next(count: Int, avoiding last: Int?) -> Int {
        guard count > 1 else { return 0 }
        var i: Int
        repeat { i = Int.random(in: 0..<count) } while i == last
        return i
    }
}
