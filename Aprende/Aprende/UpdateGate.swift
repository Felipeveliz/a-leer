import SwiftUI

// MARK: - Candado de versión
//
// Cuando hay una versión más nueva publicada, la app se bloquea hasta que el
// adulto actualiza (decisión de Felipe, 23 de noviembre). La idea es que nadie
// se quede practicando con una versión vieja.
//
// REGLA DE ORO: **solo bloquea con un sí de Apple.** Si no hay red, si la
// consulta falla o si la respuesta no se entiende, la app sigue funcionando. Un
// candado que se cierra porque el wifi del salón se cayó deja a un niño sin
// practicar por algo que no tiene nada que ver con su versión.

@MainActor
final class UpdateGate: ObservableObject {

    static let shared = UpdateGate()

    enum Estado: Equatable {
        /// Todavía no se sabe (arrancando, sin red o la consulta falló).
        case sinSaber
        case alDia
        case bloqueada(version: String, enlace: URL?)
    }

    @Published private(set) var estado: Estado = .sinSaber

    /// Lo único que mira la vista raíz.
    var bloquea: Bool {
        if case .bloqueada = estado { return true }
        return false
    }

    private var consultando = false

    /// Evita machacar la tienda cuando la app entra y sale de primer plano
    /// varias veces seguidas.
    private var ultimaConsulta: Date?
    private let esperaMinima: TimeInterval = 60 * 30

    private init() {}

    func comprueba(forzando: Bool = false) async {
        guard !consultando else { return }
        if !forzando, let ultima = ultimaConsulta,
           Date().timeIntervalSince(ultima) < esperaMinima, estado != .sinSaber {
            return
        }
        consultando = true
        defer { consultando = false }

        do {
            let resultado = try await UpdateChecker.busca()
            ultimaConsulta = Date()
            estado = Self.decide(resultado)
        } catch {
            // Sin red o respuesta rara: no se bloquea nada.
            estado = .sinSaber
        }
    }

    /// Decisión pura, para poder probarla sin red.
    static func decide(_ resultado: UpdateChecker.Resultado) -> Estado {
        resultado.hayNueva
            ? .bloqueada(version: resultado.versionPublicada, enlace: resultado.enlace)
            : .alDia
    }
}
