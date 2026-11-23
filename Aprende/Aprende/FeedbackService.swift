import Foundation
import UIKit

// MARK: - Envíame una idea
//
// Un JSON por envío, subido a Google Drive, con cola local que reintenta si no
// hay red. Copiado de Toss, con una diferencia decidida el 23 de noviembre:
//
// AQUÍ NO VA EL NOMBRE DEL NIÑO. Técnicamente estaba a una línea
// (`PerfilStore.nombre`), y es justo lo que no se manda: es el dato de un menor
// de cinco años. Tampoco va nada de su práctica —ni estrellas, ni letras, ni
// hojas—. Lo que viaja es lo que escribió el adulto más el contexto grueso del
// dispositivo para poder entender un bug. Eso es lo que sostiene el
// "Data Not Collected" de la ficha y deja `PrivacyInfo.xcprivacy` como está.

/// Las cuatro categorías. Los `rawValue` se serializan en el JSON: no se tocan
/// ni se traducen. Las etiquetas que ve el adulto viven en `IdeaView`.
enum FeedbackType: String, Codable, CaseIterable, Identifiable {
    case bug          // algo no funciona
    case ideaApp      // idea para Aprende
    case ideaOtra     // idea para otra app
    case saludo       // un hola

    var id: String { rawValue }

    var etiqueta: String {
        switch self {
        case .bug:      return "Algo no funciona"
        case .ideaApp:  return "Una idea para Aprende"
        case .ideaOtra: return "Una idea para otra app"
        case .saludo:   return "Solo un saludo"
        }
    }

    var emoji: String {
        switch self {
        case .bug:      return "🐞"
        case .ideaApp:  return "💡"
        case .ideaOtra: return "🚀"
        case .saludo:   return "👋"
        }
    }
}

/// Un envío. Anónimo a propósito: sin identificador de dispositivo, sin nombre
/// y sin cuenta, nada ata dos envíos entre sí ni a una persona. El `id` es solo
/// el nombre del archivo y se regenera en cada envío.
struct FeedbackEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let type: FeedbackType
    let message: String
    let createdAt: Date
    let appVersion: String
    let build: String
    let osVersion: String
    let deviceModel: String
    let locale: String
}

@MainActor
final class FeedbackService: ObservableObject {

    static let shared = FeedbackService()

    /// Envíos que todavía no se confirmaron subidos. Se guardan para que un
    /// envío sin red sobreviva a cerrar la app.
    @Published private(set) var pendientes: [FeedbackEntry] = []

    private let client = DriveFeedbackClient()
    private let clave = "aprende.feedback.pendientes"
    private var vaciando = false

    private init() {
        carga()
        if !pendientes.isEmpty {
            Task { await vacia() }
        }
    }

    var configurado: Bool { DriveCredentials.isConfigured }

    /// Encola el envío, lo persiste y arranca la subida. Vuelve enseguida: la
    /// pantalla confirma sin esperar a la red, que es lo que hace que funcione
    /// en un iPad sin wifi en el salón.
    func envia(tipo: FeedbackType, mensaje: String) {
        let limpio = mensaje.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }

        let entrada = FeedbackEntry(
            id: UUID(),
            type: tipo,
            message: limpio,
            createdAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?",
            osVersion: UIDevice.current.systemVersion,
            deviceModel: Self.modeloDeHardware(),
            locale: Locale.current.identifier
        )
        pendientes.append(entrada)
        guarda()
        Task { await vacia() }
    }

    /// Sube los pendientes de uno en uno, por el frente. Si uno falla, se para
    /// y se queda en la cola: mejor reintentar luego que machacar una red caída.
    func vacia() async {
        guard DriveCredentials.isConfigured, !vaciando else { return }
        vaciando = true
        defer { vaciando = false }

        while let entrada = pendientes.first {
            guard await sube(entrada) else { break }
            pendientes.removeAll { $0.id == entrada.id }
            guarda()
        }
    }

    // MARK: Subida

    private func sube(_ entrada: FeedbackEntry) async -> Bool {
        let esperas: [UInt64] = [0, 2, 5]
        for espera in esperas {
            if espera > 0 {
                try? await Task.sleep(nanoseconds: espera * 1_000_000_000)
            }
            do {
                let data = try Self.encoder.encode(entrada)
                _ = try await client.uploadFeedback(filename: Self.nombreDeArchivo(entrada),
                                                    data: data)
                return true
            } catch {
                continue
            }
        }
        return false
    }

    // MARK: Persistencia de la cola

    private func carga() {
        guard let data = UserDefaults.standard.data(forKey: clave) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        pendientes = (try? decoder.decode([FeedbackEntry].self, from: data)) ?? []
    }

    private func guarda() {
        guard let data = try? Self.encoder.encode(pendientes) else { return }
        UserDefaults.standard.set(data, forKey: clave)
    }

    // MARK: Helpers

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    /// "feedback-2026-11-23T17-31-04Z-9F3A1C2D.json": los dos puntos se quitan
    /// para que el nombre sirva en Drive, y el id corto evita que dos envíos del
    /// mismo segundo se pisen.
    private static func nombreDeArchivo(_ entrada: FeedbackEntry) -> String {
        let sello = ISO8601DateFormatter().string(from: entrada.createdAt)
            .replacingOccurrences(of: ":", with: "-")
        return "feedback-\(sello)-\(entrada.id.uuidString.prefix(8)).json"
    }

    /// "iPad13,4". Grueso y público: no identifica a nadie y sirve para entender
    /// un reporte de que algo se ve mal.
    private static func modeloDeHardware() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) { puntero in
            puntero.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}
