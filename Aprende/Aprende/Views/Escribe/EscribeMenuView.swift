import SwiftUI

// MARK: - Menú del módulo Escribe

struct EscribeMenuView: View {
    @ObservedObject private var progreso = ProgressStore.shared

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "✍️",
                title: "Escribe",
                subtitle: "Traza con tu lápiz: primero mira cómo, luego tú",
                color: Palette.coral
            )

            // Fila pequeña con el total de estrellas ganadas.
            TagPill(text: "⭐️ x \(progreso.totalStars)")

            NavigationLink {
                PalabrasEscribeListView()
            } label: {
                MenuCard(
                    emoji: "🔤",
                    title: "Palabras",
                    subtitle: "Lola · lima · pelota …",
                    colors: [Palette.coral, Palette.orangeLight]
                )
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                MiNombreView()
            } label: {
                MenuCard(
                    emoji: "🙂",
                    title: "Mi nombre",
                    subtitle: "Aprende a escribir tu nombre",
                    colors: [Palette.purple, Palette.purpleDark]
                )
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                NumerosEscribeView()
            } label: {
                MenuCard(
                    emoji: "🔢",
                    title: "Números",
                    subtitle: "del 0 al 9",
                    colors: [Palette.teal, Palette.tealDark]
                )
            }
            .buttonStyle(PressDownButtonStyle())

            // Tarjeta pequeña para calentar la mano antes de escribir.
            NavigationLink {
                WarmUpView()
            } label: {
                HStack(spacing: 10) {
                    Text("🖐️").font(.system(size: 28))
                    Text("Calentar la mano")
                        .font(.kid(22))
                        .foregroundStyle(Palette.purple)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Palette.card)
                        .shadow(color: .black.opacity(0.10), radius: 10, y: 5)
                )
            }
            .buttonStyle(PressDownButtonStyle())
        }
    }
}
