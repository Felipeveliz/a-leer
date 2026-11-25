import SwiftUI

// MARK: - Zona de adultos
//
// Lo que no es para el niño: cómo va, la información de la app, el café y las
// ideas. Entra detrás de una puerta porque la app la usa un niño de cinco años
// con el iPad en la mano, y aquí hay una compra.
//
// La puerta es la de siempre en apps infantiles: un número ESCRITO CON LETRA que
// hay que teclear con dígitos. No es un candado de verdad —no hace falta—, es
// que leer "cuarenta y siete" exige leer, y un niño que está aprendiendo a leer
// no pasa. Un número en dígitos sí lo sabe copiar.

struct AdultosView: View {
    @State private var desbloqueado: Bool

    /// `desbloqueado` solo se pasa desde el atajo de QA, para poder mirar el
    /// menú sin teclear el código. En la app siempre entra por la puerta.
    init(desbloqueado: Bool = false) {
        _desbloqueado = State(initialValue: desbloqueado)
    }

    var body: some View {
        ScreenScaffold {
            if desbloqueado {
                menu
            } else {
                PuertaDeAdulto { withAnimation(.easeOut(duration: 0.25)) { desbloqueado = true } }
            }
        }
    }

    private var menu: some View {
        VStack(spacing: 14) {
            ScreenHeader(emoji: "👋", title: "Métricas de aprendizaje",
                         subtitle: "Esta parte no es para el niño",
                         color: Palette.purple)
                .padding(.bottom, 6)

            NavigationLink {
                EstadisticasView()
            } label: {
                FilaDeAdulto(emoji: "📈", titulo: tituloDeAvance,
                             detalle: "Qué domina, qué le cuesta y por qué falla",
                             color: Palette.blue)
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                AcercaDeView()
            } label: {
                FilaDeAdulto(emoji: "ℹ️", titulo: "Acerca de Aprende",
                             detalle: "Versión, privacidad y actualizaciones",
                             color: Palette.teal)
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                CafeView()
            } label: {
                FilaDeAdulto(emoji: "☕️", titulo: "Invítame un café",
                             detalle: "La app es gratis y seguirá siéndolo",
                             color: Palette.orange)
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                IdeaView()
            } label: {
                FilaDeAdulto(emoji: "💡", titulo: "Envíame una idea",
                             detalle: "Un problema, una idea o un saludo",
                             color: Palette.coral)
            }
            .buttonStyle(PressDownButtonStyle())
        }
    }

    /// Con el nombre del niño la pantalla deja de ser "Estadísticas" y pasa a ser
    /// sobre alguien. Sin nombre capturado todavía, el título genérico.
    private var tituloDeAvance: String {
        let nombre = PerfilStore.shared.partes.first ?? ""
        return nombre.isEmpty ? "Cómo va el avance" : "Cómo va \(nombre)"
    }
}

// MARK: - Fila del menú

/// Fila tranquila, de adulto: nada de tarjetas de colores con emoji gigante.
struct FilaDeAdulto: View {
    let emoji: String
    let titulo: String
    let detalle: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(Circle().fill(color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 3) {
                Text(titulo)
                    .font(.kid(19))
                    .foregroundStyle(Palette.ink)
                Text(detalle)
                    .font(.kid(14, .semibold))
                    .foregroundStyle(Palette.gray)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.grayLight)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.card)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }
}

// MARK: - Puerta de adulto

private struct PuertaDeAdulto: View {
    let alEntrar: () -> Void

    @State private var reto = Reto.aleatorio()
    @State private var texto = ""
    @State private var fallo = false
    @FocusState private var tecleando: Bool

    var body: some View {
        VStack(spacing: 22) {
            ScreenHeader(emoji: "🔒", title: "Métricas de aprendizaje",
                         subtitle: "Escribe el número con dígitos para entrar",
                         color: Palette.purple)

            Card {
                Text(reto.palabras)
                    .font(.kid(34))
                    .foregroundStyle(Palette.purple)
                    .multilineTextAlignment(.center)

                TextField("", text: $texto)
                    .font(.kid(40))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($tecleando)
                    .frame(maxWidth: 180)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Palette.bg)
                    )
                    .onChange(of: texto) { _, _ in fallo = false }

                if fallo {
                    Text("Ese no es. Inténtalo otra vez.")
                        .font(.kid(15, .semibold))
                        .foregroundStyle(Palette.coral)
                }

                BigButton(title: "Entrar", color: Palette.purple,
                          isEnabled: !texto.isEmpty) {
                    comprueba()
                }
            }
        }
        .onAppear { tecleando = true }
    }

    private func comprueba() {
        if Int(texto.trimmingCharacters(in: .whitespaces)) == reto.valor {
            tecleando = false
            alEntrar()
        } else {
            withAnimation { fallo = true }
            texto = ""
            // Otro reto en cada fallo: así no se acierta por insistencia.
            reto = Reto.aleatorio(distintoDe: reto)
        }
    }

    /// Un número de dos cifras escrito con letra. Van escritos a mano y no
    /// generados: una app que deletrea números en español necesita reglas
    /// (dieciséis, veintidós, treinta y uno…) y aquí no hace falta ninguna.
    fileprivate struct Reto: Equatable {
        let palabras: String
        let valor: Int

        static let todos: [Reto] = [
            Reto(palabras: "cuarenta y siete", valor: 47),
            Reto(palabras: "treinta y dos", valor: 32),
            Reto(palabras: "sesenta y ocho", valor: 68),
            Reto(palabras: "veintitrés", valor: 23),
            Reto(palabras: "setenta y cinco", valor: 75),
            Reto(palabras: "cincuenta y uno", valor: 51),
            Reto(palabras: "ochenta y nueve", valor: 89),
            Reto(palabras: "noventa y cuatro", valor: 94),
            Reto(palabras: "dieciséis", valor: 16),
            Reto(palabras: "cuarenta y tres", valor: 43)
        ]

        static func aleatorio(distintoDe anterior: Reto? = nil) -> Reto {
            let posibles = todos.filter { $0 != anterior }
            return posibles.randomElement() ?? Reto(palabras: "cuarenta y siete", valor: 47)
        }
    }
}

#Preview {
    NavigationStack {
        AdultosView()
    }
}
