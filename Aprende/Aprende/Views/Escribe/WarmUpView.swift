import SwiftUI

// MARK: - Calentamiento de la mano (pre-escritura)
//
// Recorre los 4 trazos de GlyphLibrary.warmups en orden:
// línea, raya, círculo y zigzag.

struct WarmUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var indice = 0
    @State private var listo = false

    private let titulos = ["¡Una línea!", "¡Una raya!", "¡Un círculo!", "¡Zigzag!"]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🖐️",
                title: "Calienta la mano",
                subtitle: "Traza siguiendo el punto verde",
                color: Palette.purple
            )

            if listo {
                VStack(spacing: 20) {
                    Text("¡Mano lista! 💪")
                        .font(.kid(34))
                        .foregroundStyle(Palette.purple)
                        .transition(.scale.combined(with: .opacity))
                    BigButton(title: "¡A escribir!", color: Palette.green) { dismiss() }
                }
                .padding(.top, 30)
            } else {
                VStack(spacing: 14) {
                    Text(titulo)
                        .font(.kid(26))
                        .foregroundStyle(Palette.purple)

                    TagPill(text: "\(indice + 1) / \(GlyphLibrary.warmups.count)")

                    LetterTraceView(
                        glyph: GlyphLibrary.warmups[indice],
                        accent: Palette.purple,
                        onCompleted: { avanzar() }
                    )
                    .id(indice)   // resetea el trazado al cambiar de ejercicio
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 240, idealHeight: 340, maxHeight: 360)

                    HintText(text: "Empieza en el punto verde 🟢")
                }
            }
        }
    }

    private var titulo: String {
        indice < titulos.count ? titulos[indice] : "¡Sigue así!"
    }

    private func avanzar() {
        if indice + 1 < GlyphLibrary.warmups.count {
            withAnimation { indice += 1 }
        } else {
            withAnimation(.spring(duration: 0.5)) { listo = true }
        }
    }
}
