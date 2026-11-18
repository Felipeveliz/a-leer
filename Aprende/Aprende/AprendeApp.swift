import SwiftUI

@main
struct AprendeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(Palette.blue)
                // La paleta es fija y clara (tarjetas blancas, tinta oscura).
                // Sin esto, en modo oscuro la barra de navegación y los
                // controles del sistema se van a negro y rompen el conjunto.
                .preferredColorScheme(.light)
        }
    }
}
