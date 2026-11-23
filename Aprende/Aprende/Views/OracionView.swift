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

    /// Tamaño de la frase completa. No se encoge nunca: antes bajaba hasta ~18 pt en
    /// iPhone y pasar de una sílaba de 110 pt a eso era un salto feo.
    private static let tamanoFrase: CGFloat = 34

    private var tarjetaOracion: some View {
        Card {
            // La frase SIEMPRE se ve entera. En iPad entra en un renglón; en iPhone
            // baja al segundo, pero ninguna palabra se parte ni se queda fuera.
            // Antes iba en un solo renglón deslizable y aparecía cortada a media
            // palabra ("…elo"): quien entra aquí viene a leer, no a descubrir que
            // la frase sigue si arrastra de lado.
            FlujoDePalabras(separacionH: 2, separacionV: 4) {
                ForEach(Array(oracion.enumerated()), id: \.offset) { i, palabra in
                    palabraTocable(i, texto: palabra.texto)
                }
            }
            .frame(maxWidth: .infinity)

            HintText(text: "Lee la oración completa. Toca una palabra para señalarla 🙂")
        }
    }

    /// Una palabra de la frase: se resalta en amarillo al tocarla.
    private func palabraTocable(_ i: Int, texto: String) -> some View {
        Text(texto)
            .font(.kid(Self.tamanoFrase))
            .lineLimit(1)
            .fixedSize()
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

// MARK: - Acomodo de las palabras

/// Reparte las palabras en los renglones que hagan falta **sin partir ninguna** y
/// centrando cada renglón. Hace lo que un `HStack` no puede (bajar de renglón) y lo
/// que un `Text` corrido tampoco (dejar cada palabra tocable por separado).
private struct FlujoDePalabras: Layout {

    var separacionH: CGFloat = 2
    var separacionV: CGFloat = 4

    private struct Renglon {
        var indices: [Int] = []
        var ancho: CGFloat = 0
        var alto: CGFloat = 0
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let disponible = proposal.width ?? .infinity
        let renglones = repartir(subviews, en: disponible)
        let alto = renglones.reduce(0) { $0 + $1.alto }
            + separacionV * CGFloat(max(renglones.count - 1, 0))
        let ancho = renglones.map(\.ancho).max() ?? 0
        return CGSize(width: disponible.isFinite ? disponible : ancho, height: alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for renglon in repartir(subviews, en: bounds.width) {
            var x = bounds.minX + (bounds.width - renglon.ancho) / 2
            for i in renglon.indices {
                let medida = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(
                    at: CGPoint(x: x, y: y + (renglon.alto - medida.height) / 2),
                    proposal: ProposedViewSize(medida)
                )
                x += medida.width + separacionH
            }
            y += renglon.alto + separacionV
        }
    }

    /// Mete palabras en el renglón hasta que la siguiente ya no cabe. Una palabra
    /// sola más ancha que el renglón se queda igual en el suyo: partirla sería peor.
    private func repartir(_ subviews: Subviews, en disponible: CGFloat) -> [Renglon] {
        var renglones: [Renglon] = []
        var actual = Renglon()

        for i in subviews.indices {
            let medida = subviews[i].sizeThatFits(.unspecified)
            if actual.indices.isEmpty {
                actual = Renglon(indices: [i], ancho: medida.width, alto: medida.height)
                continue
            }
            let conEsta = actual.ancho + separacionH + medida.width
            if conEsta > disponible {
                renglones.append(actual)
                actual = Renglon(indices: [i], ancho: medida.width, alto: medida.height)
            } else {
                actual.indices.append(i)
                actual.ancho = conEsta
                actual.alto = max(actual.alto, medida.height)
            }
        }
        if !actual.indices.isEmpty { renglones.append(actual) }
        return renglones
    }
}

#Preview {
    NavigationStack { OracionView() }
}
