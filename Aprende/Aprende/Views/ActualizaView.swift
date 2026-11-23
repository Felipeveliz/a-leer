import SwiftUI

// MARK: - Pantalla de "hay que actualizar"
//
// Tapa la app entera cuando hay una versión más nueva publicada. Habla con el
// adulto, no con el niño: el que puede resolverlo es quien tiene la contraseña
// de la App Store. No tiene salida a propósito —ese es el punto del candado—,
// pero tampoco aparece nunca si Apple no contestó (ver `UpdateGate`).

struct ActualizaView: View {
    let version: String
    let enlace: URL?

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 24) {
                Text("🚀").font(.system(size: 72))

                Text("Hay una versión nueva")
                    .font(.kid(32))
                    .foregroundStyle(Palette.coral)
                    .multilineTextAlignment(.center)

                Text("Actualiza Aprende para seguir practicando.")
                    .font(.kid(18, .semibold))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)

                if let enlace {
                    Link(destination: enlace) {
                        Text("Actualizar")
                            .font(.kid(22))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Palette.green)
                                    .shadow(color: .black.opacity(0.18), radius: 0, y: 5)
                            )
                    }
                    .buttonStyle(PressDownButtonStyle())
                }

                Text("Versión \(version) en la App Store")
                    .font(.kid(14, .semibold))
                    .foregroundStyle(Palette.gray)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: 480)
        }
    }
}

#Preview {
    ActualizaView(version: "1.2", enlace: URL(string: "https://apps.apple.com"))
}
