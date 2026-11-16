import SwiftUI

// MARK: - Lista de palabras para escribir (ordenadas por dificultad)

struct PalabrasEscribeListView: View {
    @ObservedObject private var progreso = ProgressStore.shared

    /// 2-3 columnas adaptativas según el ancho disponible.
    private let columnas = [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 14)]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🔤",
                title: "Escribe palabras",
                subtitle: "Elige una palabra",
                color: Palette.coral
            )

            LazyVGrid(columns: columnas, spacing: 14) {
                ForEach(AppData.palabrasEscribe) { p in
                    NavigationLink {
                        PalabraEscribeFlowView(palabra: p)
                    } label: {
                        VStack(spacing: 8) {
                            Text(p.texto)
                                .font(.kid(26))
                                .foregroundStyle(Palette.ink)
                            StarBadge(earned: progreso.isWordDone(p))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Palette.card)
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 5)
                        )
                    }
                    .buttonStyle(PressDownButtonStyle())
                }
            }
        }
    }
}
