import SwiftUI

// MARK: - Lectura de palabras
// Palabra aleatoria (sin repetir la anterior) con historial para volver atrás
// y modo "separado" que colorea las sílabas, igual que la versión web.

struct PalabrasView: View {
    /// Historial de índices de `AppData.palabras` ya mostrados.
    @State private var historial: [Int]
    /// Posición actual dentro del historial.
    @State private var pos: Int
    /// Último índice aleatorio elegido (para no repetirlo).
    @State private var ultimo: Int
    /// ¿La palabra está separada en sílabas?
    @State private var separado = false

    init() {
        // Al aparecer la vista ya hay una palabra elegida.
        let primero = RandomPick.next(count: AppData.palabras.count, avoiding: nil)
        _historial = State(initialValue: [primero])
        _pos = State(initialValue: 0)
        _ultimo = State(initialValue: primero)
    }

    private var palabra: Palabra { AppData.palabras[historial[pos]] }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "📖",
                title: "Lectura de palabras",
                subtitle: "Lee la palabra en voz alta · separa en sílabas · pasa a la siguiente",
                color: Palette.coral
            )

            Card {
                TagPill(text: palabra.grupo)

                textoPalabra
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
    }

    // MARK: Texto de la palabra (junta o separada)

    /// Un solo `Text` compuesto: así el ajuste de tamaño escala TODO por igual.
    private var textoPalabra: Text {
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

    // MARK: Lógica (igual que la web)

    private func siguientePalabra() {
        if pos < historial.count - 1 {
            // Si volvimos atrás, avanzamos por el historial ya visto.
            pos += 1
        } else {
            let i = RandomPick.next(count: AppData.palabras.count, avoiding: ultimo)
            ultimo = i
            historial.append(i)
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
