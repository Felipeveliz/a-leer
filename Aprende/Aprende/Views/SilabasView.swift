import SwiftUI

// MARK: - Lectura de sílabas
// Muestra una sílaba aleatoria (sin repetir la anterior) para leerla en voz alta.
// Las hojas marcadas deciden de dónde salen.

struct SilabasView: View {
    @ObservedObject private var hojas = HojaStore.shared

    /// Índice de la sílaba actual dentro de `disponibles`.
    @State private var indice = 0

    /// Las sílabas de las hojas marcadas. Si esas hojas no traen ninguna —la 3
    /// solo trae palabras—, se enseñan todas en vez de dejar la pantalla muerta:
    /// a un niño que entra a "Lectura de sílabas" hay que darle sílabas.
    private var disponibles: [Silaba] {
        let deLasHojas = AppData.silabas(en: hojas.seleccionadas)
        return deLasHojas.isEmpty ? AppData.silabas : deLasHojas
    }

    /// ¿Se está enseñando el respaldo porque la hoja marcada no trae sílabas?
    private var esRespaldo: Bool { AppData.silabas(en: hojas.seleccionadas).isEmpty }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🔤",
                title: "Lectura de sílabas",
                subtitle: "Lee la sílaba en voz alta · pasa a la siguiente",
                color: Palette.purple
            )

            HojaPicker()

            if esRespaldo {
                AvisoRespaldo(hojas: hojas.seleccionadas, que: "sílabas")
            }

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
