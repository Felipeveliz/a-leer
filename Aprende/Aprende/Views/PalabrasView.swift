import SwiftUI

// MARK: - Lectura de palabras
// Palabra aleatoria (sin repetir la anterior) con historial para volver atrás
// y modo "separado" que colorea las sílabas, igual que la versión web.
// Las hojas marcadas deciden de dónde salen las palabras.

struct PalabrasView: View {
    @ObservedObject private var hojas = HojaStore.shared

    /// Historial de palabras ya mostradas, por texto. Se guarda el texto y no
    /// el índice porque la lista cambia de tamaño al marcar o desmarcar hojas.
    @State private var historial: [String] = []
    /// Posición actual dentro del historial.
    @State private var pos = 0
    /// ¿La palabra está separada en sílabas?
    @State private var separado = false

    private var disponibles: [Palabra] { AppData.palabras(en: hojas.seleccionadas) }

    private var palabra: Palabra? {
        guard historial.indices.contains(pos) else { return disponibles.first }
        return disponibles.first { $0.texto == historial[pos] } ?? disponibles.first
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "📖",
                title: "Lectura de palabras",
                color: Palette.coral
            )

            HojaPicker()

            if let palabra {
                Card {
                    textoPalabra(palabra)
                        .font(.kid(96))
                        .lineLimit(1)
                        .minimumScaleFactor(0.2)
                        .id("\(palabra.id)-\(separado)")   // animación "pop" al cambiar
                        .transition(.scale.combined(with: .opacity))

                    HintText(
                        text: separado
                            ? "Lee sílaba por sílaba: " + palabra.silabas.joined(separator: " · ")
                            : "Lee la palabra en voz alta 🙂"
                    )
                }

                BigButton(
                    title: separado ? "🔗 Juntar sílabas" : "✂️ Separar sílabas",
                    color: Palette.blue
                ) {
                    withAnimation(.easeOut(duration: 0.25)) { separado.toggle() }
                }

                BigButton(title: "🔀 Otra palabra", color: Palette.green) {
                    withAnimation(.easeOut(duration: 0.25)) { siguientePalabra() }
                }

                BigButton(title: "⬅️ Palabra anterior", color: Palette.gray, isEnabled: pos > 0) {
                    withAnimation(.easeOut(duration: 0.25)) { palabraAnterior() }
                }
            }
            // No hay rama vacía: las dos hojas traen palabras y la selección
            // nunca se queda sin ninguna marcada.
        }
        .onAppear { if historial.isEmpty { reiniciar() } }
        .onChange(of: hojas.clave) { reiniciar() }
    }

    // MARK: Texto de la palabra (junta o separada)

    /// Un solo `Text` compuesto: así el ajuste de tamaño escala TODO por igual.
    private func textoPalabra(_ palabra: Palabra) -> Text {
        guard separado else {
            return Text(palabra.texto).foregroundStyle(Palette.blue)
        }
        var resultado = Text(verbatim: "")
        for (i, silaba) in palabra.silabas.enumerated() {
            if i > 0 {
                resultado = resultado + Text("-").foregroundStyle(Palette.grayLight)
            }
            resultado = resultado + Text(silaba).foregroundStyle(Palette.sylColors[i % 3])
        }
        return resultado
    }

    // MARK: Lógica

    /// Al cambiar de hojas se empieza de cero: el historial viejo puede tener
    /// palabras que ya no están en las hojas marcadas.
    private func reiniciar() {
        separado = false
        pos = 0
        guard !disponibles.isEmpty else { historial = []; return }
        historial = [disponibles[RandomPick.next(count: disponibles.count, avoiding: nil)].texto]
    }

    private func siguientePalabra() {
        guard !disponibles.isEmpty else { return }
        if pos < historial.count - 1 {
            // Si volvimos atrás, avanzamos por el historial ya visto.
            pos += 1
        } else {
            let ultimo = historial.last.flatMap { t in disponibles.firstIndex { $0.texto == t } }
            let i = RandomPick.next(count: disponibles.count, avoiding: ultimo)
            historial.append(disponibles[i].texto)
            pos = historial.count - 1
        }
        separado = false
    }

    private func palabraAnterior() {
        guard pos > 0 else { return }
        pos -= 1
        separado = false
    }
}

#Preview {
    NavigationStack { PalabrasView() }
}
