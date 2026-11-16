import SwiftUI

// MARK: - Progreso del módulo Escribe
//
// Guarda las estrellas ganadas (palabras y dígitos) en UserDefaults
// para que el progreso sobreviva al cerrar la app.
// Formato de los logros: "palabra:<texto>" y "digito:<d>".

final class ProgressStore: ObservableObject {

    static let shared = ProgressStore()

    private static let clave = "aprende.progreso"

    /// Conjunto de logros conseguidos.
    @Published var done: Set<String> {
        didSet { UserDefaults.standard.set(Array(done), forKey: Self.clave) }
    }

    private init() {
        done = Set(UserDefaults.standard.stringArray(forKey: Self.clave) ?? [])
    }

    // MARK: Palabras

    func isWordDone(_ palabra: Palabra) -> Bool {
        done.contains("palabra:" + palabra.texto)
    }

    func markWordDone(_ palabra: Palabra) {
        done.insert("palabra:" + palabra.texto)
    }

    // MARK: Dígitos

    func isDigitDone(_ d: Character) -> Bool {
        done.contains("digito:" + String(d))
    }

    func markDigitDone(_ d: Character) {
        done.insert("digito:" + String(d))
    }

    /// Total de estrellas ganadas (palabras + dígitos).
    var totalStars: Int { done.count }
}
