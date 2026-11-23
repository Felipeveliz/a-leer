import SwiftUI

// MARK: - Captura del nombre y la mano (lo que teclea un adulto)
//
// Único teclado de toda la app, y solo para un adulto: el niño nunca escribe
// aquí. Aparece en el primer arranque (obligatorio, sin nombre no se puede
// salir) y desde "Escribir mi nombre" para corregirlo (ahí sí se puede cerrar).

struct CapturaNombreView: View {
    @ObservedObject private var perfil = PerfilStore.shared
    @Environment(\.dismiss) private var dismiss

    /// En el primer arranque es obligatorio y no hay botón de cerrar.
    var esPrimerArranque: Bool = false

    @State private var nombre = ""
    @State private var mano: Mano = .derecha
    @FocusState private var enfocado: Bool

    private var nombreValido: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Letras del nombre que todavía no tienen glifo: el flujo de Escribe se las
    /// salta, así que el adulto tiene que saberlo. NO bloquea "Listo": en el primer
    /// arranque esta pantalla es obligatoria y bloquearla dejaría la app cerrada.
    private var letrasSinGlifo: [Character] {
        var vistas: [Character] = []
        for ch in nombre where !ch.isWhitespace && GlyphLibrary.glyph(for: ch) == nil && !vistas.contains(ch) {
            vistas.append(ch)
        }
        return vistas
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: esPrimerArranque ? "👋" : "✏️",
                title: esPrimerArranque ? "¡Hola!" : "Modificar nombre",
                subtitle: "Un adulto escribe el nombre completo del niño",
                color: Palette.coral
            )

            TextField("Nombre completo", text: $nombre)
                .font(.kid(26))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($enfocado)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Palette.card)
                        .shadow(color: .black.opacity(0.10), radius: 8, y: 4)
                )

            if !letrasSinGlifo.isEmpty {
                HintText(text: "Estas letras todavía no se pueden trazar y se saltarán: "
                         + letrasSinGlifo.map(String.init).joined(separator: " "))
            }

            VStack(spacing: 12) {
                HintText(text: "¿Con qué mano escribe?")
                HStack(spacing: 12) {
                    botonMano(.derecha, emoji: "✋", titulo: "Derecha")
                    botonMano(.izquierda, emoji: "🤚", titulo: "Izquierda")
                }
            }

            BigButton(title: "Listo ✅", color: Palette.green, isEnabled: nombreValido) {
                guardar()
            }

            if !esPrimerArranque {
                Button("Cancelar") { dismiss() }
                    .font(.kid(18))
                    .foregroundStyle(Palette.gray)
            }
        }
        .onAppear {
            nombre = perfil.nombre
            mano = perfil.mano
        }
    }

    /// Una de las dos opciones de mano, estilo casilla grande.
    private func botonMano(_ opcion: Mano, emoji: String, titulo: String) -> some View {
        let elegida = mano == opcion
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { mano = opcion }
        } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 34))
                Text(titulo).font(.kid(18))
            }
            .foregroundStyle(elegida ? .white : Palette.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(elegida ? Palette.blue : Palette.card)
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
            )
        }
        .buttonStyle(PressDownButtonStyle())
        .accessibilityLabel(elegida ? "\(titulo), elegida" : titulo)
    }

    private func guardar() {
        perfil.nombre = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        perfil.mano = mano
        enfocado = false
        if !esPrimerArranque { dismiss() }
        // En el primer arranque no hace falta cerrar a mano: al quedar un nombre,
        // `perfil.configurado` pasa a true y el cover de HomeView desaparece solo.
    }
}

#Preview {
    CapturaNombreView(esPrimerArranque: true)
}
