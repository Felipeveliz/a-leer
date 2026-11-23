#if DEBUG
import SwiftUI

// MARK: - Atajo de QA (solo DEBUG)
//
// Esta Mac no tiene Simulator.app y `simctl` no sabe dar toques, así que la
// única forma de MIRAR una pantalla de dentro era llegar a ella a mano. Con
// esto se arranca directamente:
//
//   xcrun simctl launch booted com.eduardovelross.aprende -pantalla avance
//
// No existe en Release: el `#if DEBUG` envuelve el archivo entero.

enum QAShortcut: String {
    case adultos, menu, avance, acerca, cafe, idea

    /// La pantalla pedida por argumento de lanzamiento, si hay alguna.
    static var pedida: QAShortcut? {
        guard let valor = UserDefaults.standard.string(forKey: "pantalla") else { return nil }
        return QAShortcut(rawValue: valor)
    }

    @ViewBuilder
    var vista: some View {
        NavigationStack {
            switch self {
            case .adultos: AdultosView()
            case .menu:    AdultosView(desbloqueado: true)
            case .avance:  EstadisticasView()
            case .acerca:  AcercaDeView()
            case .cafe:    CafeView()
            case .idea:    IdeaView()
            }
        }
    }
}
#endif
