import SwiftUI

@main
struct AprendeApp: App {
    @ObservedObject private var candado = UpdateGate.shared
    @Environment(\.scenePhase) private var fase

    var body: some Scene {
        WindowGroup {
            raiz
                // Candado de versión: tapa la app entera mientras haya una
                // versión más nueva publicada. Va aquí arriba y no dentro de
                // una pantalla para que no se pueda esquivar navegando.
                .overlay {
                    if case .bloqueada(let version, let enlace) = candado.estado {
                        ActualizaView(version: version, enlace: enlace)
                    }
                }
                .task { await candado.comprueba() }
                // Se vuelve a mirar al volver del fondo: así el candado se
                // cierra en cuanto sale una versión, sin reabrir la app.
                .onChange(of: fase) { _, nueva in
                    guard nueva == .active else { return }
                    Task { await candado.comprueba() }
                }
                .tint(Palette.blue)
                // La paleta es fija y clara (tarjetas blancas, tinta oscura).
                // Sin esto, en modo oscuro la barra de navegación y los
                // controles del sistema se van a negro y rompen el conjunto.
                .preferredColorScheme(.light)
        }
    }

    /// Normalmente el inicio. En DEBUG, un argumento de lanzamiento puede abrir
    /// una pantalla de dentro para poder mirarla en el simulador (ver
    /// `QAShortcut`). La rama se decide una vez y no cambia en toda la vida del
    /// proceso, así que ninguna vista con estado pierde su identidad.
    @ViewBuilder
    private var raiz: some View {
        #if DEBUG
        if let atajo = QAShortcut.pedida {
            atajo.vista
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}
