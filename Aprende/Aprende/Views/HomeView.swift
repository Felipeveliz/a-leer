import SwiftUI

// Pantalla de inicio: raíz de navegación con los tres módulos.
struct HomeView: View {
    @ObservedObject private var perfil = PerfilStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Título y saludo
                        VStack(spacing: 6) {
                            Text("👦 Aprende")
                                .font(.kid(44))
                                .foregroundStyle(Palette.coral)
                            Text("¿Qué quieres practicar hoy?")
                                .font(.kid(18, .semibold))
                                .foregroundStyle(Palette.gray)
                        }
                        .padding(.top, 24)

                        // Menú principal
                        NavigationLink {
                            EspanolMenuView()
                        } label: {
                            MenuCard(
                                emoji: "📖",
                                title: "Español",
                                subtitle: "sílabas · palabras · oración",
                                colors: [Palette.blue, Palette.purpleDark]
                            )
                        }
                        .buttonStyle(PressDownButtonStyle())

                        NavigationLink {
                            MatematicasView()
                        } label: {
                            MenuCard(
                                emoji: "➕",
                                title: "Matemáticas",
                                subtitle: "sumas: 2 · 3 · 4 · 5 · 6",
                                colors: [Palette.teal, Palette.tealDark]
                            )
                        }
                        .buttonStyle(PressDownButtonStyle())

                        NavigationLink {
                            EscribeMenuView()
                        } label: {
                            MenuCard(
                                emoji: "✍️",
                                title: "Escribe",
                                subtitle: "diseñado para iPad y Apple Pencil",
                                colors: [Palette.coral, Palette.orangeLight]
                            )
                        }
                        .buttonStyle(PressDownButtonStyle())

                        // Entrada a la zona de adultos: discreta a propósito, debajo
                        // de los tres módulos y sin color de tarjeta. El niño puede
                        // tocarla; la puerta de adulto es la que no pasa.
                        NavigationLink {
                            AdultosView()
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Para adultos")
                                    .font(.kid(15, .semibold))
                            }
                            .foregroundStyle(Palette.gray)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Capsule().fill(.white.opacity(0.7)))
                        }
                        .buttonStyle(PressDownButtonStyle())
                        .padding(.top, 6)

                        footer
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        // Primer arranque: sin nombre no se puede pasar. En cuanto un adulto lo
        // captura, `perfil.configurado` pasa a true y el cover se cierra solo.
        .fullScreenCover(isPresented: .init(get: { !perfil.configurado },
                                            set: { _ in })) {
            CapturaNombreView(esPrimerArranque: true)
        }
    }

    /// Crédito pequeño con enlace a X.
    private var footer: some View {
        HStack(spacing: 5) {
            Text("Desarrollado por")
                .font(.kid(13, .semibold))
                .foregroundStyle(Palette.gray)
            Link(destination: URL(string: "https://x.com/eduardovelross")!) {
                HStack(spacing: 3) {
                    Text("𝕏")
                        .font(.system(size: 12, weight: .bold))
                    Text("EduardoVelross")
                        .font(.kid(13, .bold))
                }
                .foregroundStyle(Palette.blue)
            }
        }
    }
}

#Preview {
    HomeView()
}
