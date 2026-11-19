import SwiftUI

// MARK: - Qué hojas está practicando el niño
//
// Una sola selección compartida por las cuatro pantallas donde se practica
// (las tres de Español y la lista de palabras de Escribe), guardada en
// UserDefaults para que siga igual al volver a abrir la app.

final class HojaStore: ObservableObject {

    static let shared = HojaStore()

    private static let clave = "aprende.hojas"

    @Published var seleccionadas: Set<Hoja> {
        didSet {
            // Nunca vacío: una pantalla sin nada que practicar no le dice nada
            // a un niño de cinco años. La última casilla marcada no se puede
            // desmarcar. (Asignar aquí no vuelve a disparar el didSet.)
            if seleccionadas.isEmpty {
                seleccionadas = oldValue
                return
            }
            UserDefaults.standard.set(seleccionadas.map(\.rawValue).sorted(), forKey: Self.clave)
        }
    }

    private init() {
        let guardadas = (UserDefaults.standard.array(forKey: Self.clave) as? [Int] ?? [])
            .compactMap(Hoja.init(rawValue:))
        // Por defecto, todas: el niño practica todo lo que ha visto en la escuela.
        seleccionadas = guardadas.isEmpty ? Set(Hoja.allCases) : Set(guardadas)
    }

    func alterna(_ hoja: Hoja) {
        if seleccionadas.contains(hoja) {
            seleccionadas.remove(hoja)
        } else {
            seleccionadas.insert(hoja)
        }
    }

    /// Para que una vista se redibuje cuando cambia la selección.
    var clave: String { seleccionadas.map(\.rawValue).sorted().map(String.init).joined(separator: "-") }
}
