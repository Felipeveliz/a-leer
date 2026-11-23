import SwiftUI

// MARK: - Envíame una idea
//
// Cuatro categorías, un texto y "Enviar". El envío es anónimo: no va el nombre
// del niño ni nada de su práctica (ver `FeedbackService`). La pantalla lo dice,
// porque quien escribe tiene derecho a saber qué se manda.

struct IdeaView: View {
    @ObservedObject private var servicio = FeedbackService.shared

    @State private var tipo: FeedbackType = .ideaApp
    @State private var mensaje = ""
    @State private var enviado = false
    @FocusState private var escribiendo: Bool

    private var puedeEnviar: Bool {
        !mensaje.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(emoji: "💡", title: "Envíame una idea",
                         subtitle: "Lo leo yo, Eduardo. Gracias por tomarte el rato.",
                         color: Palette.coral)

            if enviado {
                recibido
            } else {
                categorias
                texto
                BigButton(title: "Enviar", color: Palette.coral, isEnabled: puedeEnviar) {
                    envia()
                }
                nota
            }
        }
        .navigationTitle("Una idea")
    }

    // MARK: Categorías

    private var categorias: some View {
        VStack(spacing: 10) {
            ForEach(FeedbackType.allCases) { opcion in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { tipo = opcion }
                } label: {
                    HStack(spacing: 12) {
                        Text(opcion.emoji).font(.system(size: 22))
                        Text(opcion.etiqueta)
                            .font(.kid(17))
                            .foregroundStyle(tipo == opcion ? .white : Palette.ink)
                        Spacer()
                        if tipo == opcion {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(tipo == opcion ? Palette.coral : Palette.card)
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                    )
                }
                .buttonStyle(PressDownButtonStyle())
            }
        }
    }

    // MARK: Texto

    private var texto: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $mensaje)
                .font(.kid(17, .semibold))
                .scrollContentBackground(.hidden)
                .focused($escribiendo)
                .frame(minHeight: 150)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Palette.card)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                )
                .overlay(alignment: .topLeading) {
                    if mensaje.isEmpty {
                        Text("Cuéntame…")
                            .font(.kid(17, .semibold))
                            .foregroundStyle(Palette.grayLight)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    // MARK: Nota de privacidad

    private var nota: some View {
        Text("Se envía solo lo que escribiste, con el modelo de iPad y la versión de la app. No va el nombre del niño ni nada de lo que ha practicado.")
            .font(.kid(13, .semibold))
            .foregroundStyle(Palette.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
    }

    // MARK: Recibido

    private var recibido: some View {
        Card {
            Text("¡Recibido! 🙌").font(.kid(28)).foregroundStyle(Palette.green)
            // Con wifi la subida tarda un segundo, así que al confirmar la cola
            // casi siempre sigue llena: decir "en cuanto haya internet" ahí
            // suena a que no hay. El texto tiene que ser cierto en los dos casos.
            Text(servicio.pendientes.isEmpty
                 ? "Ya se envió. Gracias."
                 : "Se está enviando. Puedes cerrar la app: si ahora no hay internet, sale después.")
                .font(.kid(16, .semibold))
                .foregroundStyle(Palette.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            BigButton(title: "Escribir otra", color: Palette.coral) {
                mensaje = ""
                withAnimation { enviado = false }
            }
        }
    }

    // MARK: Lógica

    private func envia() {
        escribiendo = false
        servicio.envia(tipo: tipo, mensaje: mensaje)
        withAnimation(.easeOut(duration: 0.2)) { enviado = true }
    }
}

#Preview {
    NavigationStack {
        IdeaView()
    }
}
