import SwiftUI

// MARK: - Lectura de sílabas
// Muestra una sílaba aleatoria (sin repetir la anterior) para leerla en voz alta.
// Las hojas marcadas deciden de dónde salen.

struct SilabasView: View {
    @ObservedObject private var hojas = HojaStore.shared

    /// Índice de la sílaba actual dentro de `disponibles`.
    @State private var indice = 0

    private var disponibles: [Silaba] { AppData.silabas(en: hojas.seleccionadas) }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🔤",
                title: "Lectura de sílabas",
                subtitle: "Lee la sílaba en voz alta · pasa a la siguiente",
                color: Palette.purple
            )

            HojaPicker()

            if let silaba = silabaActual {
                Card {
                    TagPill(text: silaba.grupo)

                    Text(silaba.texto)
                        .font(.kid(110))
                        .foregroundStyle(Palette.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .id(silaba.id)   // reinicia la animación "pop" al cambiar
                        .transition(.scale.combined(with: .opacity))

                    HintText(text: "Lee la sílaba en voz alta 🙂")
                }

                BigButton(title: "🔀 Otra sílaba", color: Palette.green) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        indice = RandomPick.next(count: disponibles.count, avoiding: indice)
                    }
                }
            } else {
                SinContenido(que: "sílabas")
            }
        }
        .onAppear { empezarEnUnaAlAzar() }
        .onChange(of: hojas.clave) { empezarEnUnaAlAzar() }
    }

    private var silabaActual: Silaba? {
        disponibles.indices.contains(indice) ? disponibles[indice] : disponibles.first
    }

    /// Al entrar, y cada vez que cambian las hojas, se empieza por una al azar
    /// y se deja el índice dentro de rango.
    private func empezarEnUnaAlAzar() {
        guard !disponibles.isEmpty else { indice = 0; return }
        indice = RandomPick.next(count: disponibles.count, avoiding: nil)
    }
}

#Preview {
    NavigationStack { SilabasView() }
}
