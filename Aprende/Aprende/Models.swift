import Foundation

// MARK: - Modelos del repositorio de aprendizaje
// (los mismos contenidos de la versión web)

struct Silaba: Identifiable, Hashable {
    let grupo: String
    let texto: String
    var id: String { grupo + texto }
}

struct Palabra: Identifiable, Hashable {
    let grupo: String
    let silabas: [String]
    var texto: String { silabas.joined() }
    var id: String { texto }
}

struct PalabraOracion: Identifiable, Hashable {
    let texto: String
    let silabas: [String]
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
        .init(grupo: "Ll", silabas: ["Lo", "la"]),
        .init(grupo: "Ll", silabas: ["la", "ta"]),
        .init(grupo: "Ll", silabas: ["lo", "ma"]),
        .init(grupo: "Ll", silabas: ["li", "ma"]),
        .init(grupo: "Rr", silabas: ["Ro", "sa"]),
        .init(grupo: "Rr", silabas: ["ra", "ta"]),
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
        .init(grupo: "Repaso", silabas: ["pe", "lo", "ta"]),
        .init(grupo: "Repaso", silabas: ["e", "lo", "te"]),
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

    /// Todas las sílabas de la oración, en orden.
    static var oracionSilabas: [String] { oracion.flatMap(\.silabas) }

    // MARK: Matemáticas: todas las combinaciones a+b con resultado 2...6
    static let sumas: [Suma] = (2...6).flatMap { total in
        (0...total).map { a in Suma(a: a, b: total - a) }
    }

    /// Respuestas posibles que se muestran como opciones.
    static let respuestasSumas = [2, 3, 4, 5, 6]

    // MARK: Escribe
    /// Palabras del módulo Escribe, ordenadas por dificultad de trazo:
    /// cortas y de líneas simples → con mayúscula → largas de 3 sílabas.
    /// Ojo: las entradas van con la mayúscula EXACTA de la palabra real
    /// ("Rosa", no "rosa"), porque la búsqueda es por texto literal.
    static let palabrasEscribe: [Palabra] = {
        let orden = ["lata", "lima", "loma", "rata", "ruta", "risa", "remo", "nata", "nota", "nene",
                     "Lola", "Rosa", "Nena", "amor", "elote", "atole", "pelota", "maleta"]
        var porTexto: [String: Palabra] = [:]
        for p in palabras { porTexto[p.texto] = p }
        var resultado: [Palabra] = []
        var vistos = Set<String>()
        for t in orden {
            guard let p = porTexto[t] else {
                // Entrada muerta en `orden`: una palabra mal escrita se saltaría
                // en silencio y el orden de dificultad quedaría roto.
                assertionFailure("palabrasEscribe: '\(t)' no existe en AppData.palabras")
                continue
            }
            if !vistos.contains(p.texto) {
                resultado.append(p); vistos.insert(p.texto)
            }
        }
        for p in palabras where !vistos.contains(p.texto) {
            // Palabra que falta en `orden`: cae al final, después de las más
            // difíciles. Debe quedar vacío.
            assertionFailure("palabrasEscribe: '\(p.texto)' falta en la lista `orden`")
            resultado.append(p); vistos.insert(p.texto)
        }
        return resultado
    }()

    /// Dígitos en orden de dificultad de trazo.
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
