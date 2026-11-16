import SwiftUI

// MARK: - Lectura de sílabas
// Muestra una sílaba aleatoria (sin repetir la anterior) para leerla en voz alta.

struct SilabasView: View {
    /// Índice de la sílaba actual; al aparecer ya hay una elegida.
    @State private var indice: Int

    init() {
        _indice = State(initialValue: RandomPick.next(count: AppData.silabas.count, avoiding: nil))
    }

    private var silaba: Silaba { AppData.silabas[indice] }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🔤",
                title: "Lectura de sílabas",
                subtitle: "Lee la sílaba en voz alta · pasa a la siguiente",
                color: Palette.purple
            )

            Card {
                TagPill(text: silaba.grupo)

                Text(silaba.texto)
                    .font(.kid(110))
                    .foregroundStyle(Palette.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .id(indice)   // reinicia la animación "pop" al cambiar
                    .transition(.scale.combined(with: .opacity))

                HintText(text: "Lee la sílaba en voz alta 🙂")
            }

            BigButton(title: "🔀 Otra sílaba", color: Palette.green) {
                withAnimation(.easeOut(duration: 0.25)) {
                    indice = RandomPick.next(count: AppData.silabas.count, avoiding: indice)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { SilabasView() }
}
