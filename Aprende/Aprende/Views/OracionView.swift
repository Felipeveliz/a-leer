import SwiftUI

// MARK: - Leer una oración
// Tres pestañas: practicar las sílabas en orden, luego las palabras
// y al final la oración completa (tocando una palabra para señalarla).

struct OracionView: View {

    private enum Pestana: CaseIterable {
        case silabas, palabras, oracion

        var titulo: String {
            switch self {
            case .silabas:  return "🔤 Sílabas"
            case .palabras: return "📖 Palabras"
            case .oracion:  return "📝 Oración"
            }
        }
    }

    @ObservedObject private var hojas = HojaStore.shared

    @State private var pestana: Pestana = .silabas
    /// Índice del elemento actual (sílaba o palabra, según la pestaña).
    @State private var indice = 0
    /// Palabra resaltada en la pestaña "Oración" (solo una a la vez).
    @State private var resaltada: Int? = nil

    /// Café del texto sobre fondo amarillo (igual que la web).
    private let cafe = Color(hex: 0x6B4E00)

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "📝",
                title: "Leer una oración",
                subtitle: "Practica las sílabas, luego las palabras y al final la oración completa",
                color: Palette.orange
            )

            HojaPicker()

            if esRespaldo {
                AvisoRespaldo(hojas: hojas.seleccionadas, que: "oración")
            }

            if !oracion.isEmpty {
                pestanas

                switch pestana {
                case .silabas:
                    tarjetaPaso(
                        texto: Text(silabas[min(indice, silabas.count - 1)]).foregroundStyle(Palette.blue),
                        total: silabas.count,
                        pista: "Léela en voz alta 🙂"
                    )
                    navegacion(total: silabas.count)

                case .palabras:
                    let p = oracion[min(indice, oracion.count - 1)]
                    tarjetaPaso(
                        texto: Text(p.texto).foregroundStyle(Palette.blue),
                        total: oracion.count,
                        pista: "Sílabas: " + p.silabas.joined(separator: " · ")
                    )
                    navegacion(total: oracion.count)

                case .oracion:
                    tarjetaOracion
                }
            }
        }
        .onChange(of: hojas.clave) {
            indice = 0
            resaltada = nil
        }
    }

    /// La oración de las hojas marcadas. Hoy solo la hoja 2 trae oración, así que
    /// si la hoja elegida no la tiene se enseña la que hay: quien entra a "Leer una
    /// oración" viene a leer una oración, no a que le digan que no hay.
    private var oracion: [PalabraOracion] {
        let deLasHojas = AppData.oracion(en: hojas.seleccionadas)
        return deLasHojas.isEmpty ? AppData.oracion : deLasHojas
    }

    private var silabas: [String] { oracion.flatMap(\.silabas) }

    /// ¿Se está enseñando el respaldo porque la hoja marcada no trae oración?
    private var esRespaldo: Bool { AppData.oracion(en: hojas.seleccionadas).isEmpty }

    // MARK: Pestañas tipo pastilla

    private var pestanas: some View {
        HStack(spacing: 10) {
            ForEach(Pestana.allCases, id: \.self) { p in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        pestana = p
                        indice = 0          // cambiar de pestaña reinicia el recorrido
                        resaltada = nil
                    }
                } label: {
                    Text(p.titulo)
                        .font(.kid(16))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(pestana == p ? .white : Palette.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(pestana == p ? Palette.orange : Palette.card)
                                .shadow(color: .black.opacity(0.1), radius: 0, y: 4)
                        )
                }
                .buttonStyle(PressDownButtonStyle())
            }
        }
    }

    // MARK: Pestañas Sílabas / Palabras (un elemento a la vez, EN ORDEN)

    private func tarjetaPaso(texto: Text, total: Int, pista: String) -> some View {
        Card {
            TagPill(text: "\(indice + 1) / \(total)")

            texto
                .font(.kid(110))
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .id("\(pestana.titulo)-\(indice)")   // animación "pop" al cambiar
                .transition(.scale.combined(with: .opacity))

            HintText(text: pista)
        }
    }

    private func navegacion(total: Int) -> some View {
        HStack(spacing: 16) {
            BigButton(title: "⬅️ Anterior", color: Palette.gray, isEnabled: indice > 0) {
                withAnimation(.easeOut(duration: 0.25)) {
                    indice = max(0, indice - 1)
                }
            }
            BigButton(title: "Siguiente ➡️", color: Palette.green, isEnabled: indice < total - 1) {
                withAnimation(.easeOut(duration: 0.25)) {
                    indice = min(total - 1, indice + 1)
                }
            }
        }
    }

    // MARK: Pestaña Oración (frase completa en UNA sola línea)

    private var tarjetaOracion: some View {
        Card {
            HStack(spacing: 2) {
                ForEach(Array(oracion.enumerated()), id: \.offset) { i, palabra in
                    Text(palabra.texto)
                        .font(.kid(40))
                        .foregroundStyle(resaltada == i ? cafe : Palette.ink)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(resaltada == i ? Palette.yellow : .clear)
                        )
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.15)) { resaltada = i }
                        }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.15)

            HintText(text: "Lee la oración completa. Toca una palabra para señalarla 🙂")
        }
    }
}

#Preview {
    NavigationStack { OracionView() }
}
