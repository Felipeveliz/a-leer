import SwiftUI

@main
struct AprendeApp: App {
    var body: some Scene {
        WindowGroup {
            raiz
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
