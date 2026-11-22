import SwiftUI

// MARK: - Perfil del niño (quién usa la app)
//
// Lo que la app no puede adivinar y un adulto captura una sola vez: el nombre
// del niño y con qué mano escribe. Antes esto estaba fijo en código porque la
// app era de un solo niño (Eliab, diestro); cuando la usa un salón entero, cada
// niño trae su nombre y su mano. Se guarda en UserDefaults y se pregunta en el
// primer arranque (ver HomeView); se corrige desde "Escribir mi nombre".

enum Mano: String {
    case derecha, izquierda

    var esZurdo: Bool { self == .izquierda }
}

final class PerfilStore: ObservableObject {

    static let shared = PerfilStore()

    private static let claveNombre = "aprende.nombre"
    private static let claveMano = "aprende.mano"

    @Published var nombre: String {
        didSet { UserDefaults.standard.set(nombre, forKey: Self.claveNombre) }
    }

    @Published var mano: Mano {
        didSet { UserDefaults.standard.set(mano.rawValue, forKey: Self.claveMano) }
    }

    private init() {
        nombre = UserDefaults.standard.string(forKey: Self.claveNombre) ?? ""
        mano = UserDefaults.standard.string(forKey: Self.claveMano)
            .flatMap(Mano.init(rawValue:)) ?? .derecha
    }

    /// ¿Ya configuró un adulto el perfil? Si no, el primer arranque lo pregunta.
    var configurado: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// El nombre partido en sus partes (nombre de pila y apellidos), para
    /// practicar cada una por separado y luego el nombre completo.
    var partes: [String] {
        nombre.split(whereSeparator: \.isWhitespace).map(String.init)
    }
}
