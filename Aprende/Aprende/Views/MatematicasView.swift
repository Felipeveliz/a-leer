import SwiftUI

// MARK: - Matemáticas: sumas con opciones de respuesta
// Réplica del módulo "➕ Sumas" de la versión web.

struct MatematicasView: View {

    /// Estado de cada botón de respuesta.
    private enum EstadoRespuesta {
        case normal, correcta, incorrecta
    }

    // Suma actual (empieza con una aleatoria).
    @State private var indice = RandomPick.next(count: AppData.sumas.count, avoiding: nil)
    @State private var resuelta = false              // bloquea las opciones tras acertar
    @State private var incorrecta: Int? = nil        // respuesta fallida mostrada en coral
    @State private var sacudida: CGFloat = 0         // offset x de la sacudida
    @State private var pista = "Elige el número 🙂"
    /// ¿Se está mostrando el ábaco? Apoyo que el niño pide cuando no le sale,
    /// igual que "Separar sílabas" en palabras.
    @State private var abaco = false

    private var suma: Suma { AppData.sumas[indice] }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "➕",
                title: "Sumas",
                subtitle: "¿Cuánto es? Toca la respuesta correcta",
                color: Palette.teal
            )

            // Tarjeta con la suma enorme y la pista
            Card {
                Text("\(suma.a) + \(suma.b)")
                    .font(.kid(100))
                    .foregroundStyle(Palette.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                if abaco {
                    cuentasDelAbaco
                }

                HintText(text: pista)
            }

            // Fila de 5 opciones de respuesta
            HStack(spacing: 12) {
                ForEach(AppData.respuestasSumas, id: \.self) { numero in
                    botonRespuesta(numero)
                }
            }

            BigButton(
                title: abaco ? "🙈 Quitar el ábaco" : "🧮 Ábaco",
                color: Palette.blue
            ) {
                withAnimation(.easeOut(duration: 0.25)) { abaco.toggle() }
            }

            BigButton(title: "🔀 Otra suma", color: Palette.green) {
                otraSuma()
            }
        }
    }

    // MARK: - Ábaco

    /// Las cuentas de la suma: el primer sumando en azul y el segundo en coral, en
    /// una sola fila. Los dos grupos van separados a propósito — la idea es "juntar
    /// grupos", y en una fila de cuentas iguales se pierde de dónde salió cada parte.
    /// El niño las cuenta en voz alta; la app no le da el resultado.
    private var cuentasDelAbaco: some View {
        // Hasta 7 cuentas (6+0 es la suma más larga): caben en una fila en iPhone.
        HStack(spacing: 10) {
            grupoDeCuentas(suma.a, color: Palette.blue)
            if suma.a > 0 && suma.b > 0 {
                Text("+")
                    .font(.kid(28))
                    .foregroundStyle(Palette.grayLight)
            }
            grupoDeCuentas(suma.b, color: Palette.coral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.bg)
        )
        .transition(.scale.combined(with: .opacity))
    }

    private func grupoDeCuentas(_ cuantas: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<max(cuantas, 0), id: \.self) { _ in
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 2))
            }
        }
        .accessibilityLabel("\(cuantas)")
    }

    // MARK: - Botón de respuesta

    private func botonRespuesta(_ numero: Int) -> some View {
        let estado = estadoDe(numero)

        return Button {
            tocar(numero)
        } label: {
            Text("\(numero)")
                .font(.kid(34))
                .foregroundStyle(estado == .normal ? Palette.teal : .white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 72)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(colorFondo(estado))
                        .shadow(color: .black.opacity(0.15), radius: 0, y: 5)
                )
        }
        .buttonStyle(PressDownButtonStyle())
        .offset(x: estado == .incorrecta ? sacudida : 0)
        .disabled(resuelta)
    }

    private func estadoDe(_ numero: Int) -> EstadoRespuesta {
        if resuelta && numero == suma.total { return .correcta }
        if incorrecta == numero { return .incorrecta }
        return .normal
    }

    private func colorFondo(_ estado: EstadoRespuesta) -> Color {
        switch estado {
        case .normal:     return Palette.card
        case .correcta:   return Palette.green
        case .incorrecta: return Palette.coral
        }
    }

    // MARK: - Lógica

    private func tocar(_ numero: Int) {
        guard !resuelta else { return }

        if numero == suma.total {
            // Acierto: botón verde y opciones bloqueadas hasta la siguiente suma.
            withAnimation(.easeOut(duration: 0.2)) {
                resuelta = true
                incorrecta = nil
                sacudida = 0
            }
            pista = "¡Muy bien! 🎉"
        } else {
            // Fallo: botón coral con sacudida breve, vuelve a blanco a los ~0.5 s.
            pista = "Inténtalo otra vez 🤔"
            incorrecta = numero
            sacudida = 0
            withAnimation(.easeInOut(duration: 0.06).repeatCount(7, autoreverses: true)) {
                sacudida = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sacudida = 0
                if incorrecta == numero {
                    withAnimation(.easeOut(duration: 0.15)) { incorrecta = nil }
                }
            }
        }
    }

    private func otraSuma() {
        withAnimation(.easeOut(duration: 0.2)) {
            indice = RandomPick.next(count: AppData.sumas.count, avoiding: indice)
            resuelta = false
            incorrecta = nil
            sacudida = 0
            abaco = false          // cada suma empieza sin apoyo, como "Separar sílabas"
            pista = "Elige el número 🙂"
        }
    }
}

#Preview {
    NavigationStack {
        MatematicasView()
    }
}
