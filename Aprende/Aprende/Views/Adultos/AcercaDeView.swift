import SwiftUI

// MARK: - Acerca de Aprende
//
// Qué es la app, de dónde salió, qué versión trae y si hay una más nueva.
// La versión se lee del bundle, nunca escrita a mano: una versión desactualizada
// en pantalla es peor que no ponerla.

struct AcercaDeView: View {
    @State private var buscando = false
    @State private var resultado: UpdateChecker.Resultado?
    @State private var fallo = false

    private static let privacidad = URL(string: "https://felipeveliz.github.io/a-leer/privacidad.html")
    private static let soporte = URL(string: "https://felipeveliz.github.io/a-leer/soporte.html")

    var body: some View {
        ScreenScaffold {
            cabecera
            queEs
            version
            enlaces
        }
        .navigationTitle("Acerca de")
    }

    // MARK: Cabecera

    private var cabecera: some View {
        VStack(spacing: 10) {
            Text("👦")
                .font(.system(size: 64))
                .frame(width: 110, height: 110)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.bgWarm, Palette.yellow.opacity(0.6)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            Text("Aprende")
                .font(.kid(34))
                .foregroundStyle(Palette.coral)
            Text("Leer, sumar y escribir a mano")
                .font(.kid(15, .semibold))
                .foregroundStyle(Palette.gray)
        }
        .padding(.top, 8)
    }

    // MARK: Qué es

    private var queEs: some View {
        Card {
            Text("Aprende nació de las hojas que un niño de cinco años traía de la escuela. Cada sílaba, palabra y suma de la app salió de ahí.")
                .font(.kid(16, .semibold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("Sin anuncios, sin cuentas y sin internet: lo que practica se queda en este dispositivo.")
                .font(.kid(15, .semibold))
                .foregroundStyle(Palette.gray)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Versión y actualizaciones

    private var version: some View {
        Card {
            HStack {
                Text("Versión")
                    .font(.kid(17))
                    .foregroundStyle(Palette.gray)
                Spacer()
                Text("\(UpdateChecker.versionInstalada) (\(UpdateChecker.buildInstalada))")
                    .font(.kid(17))
                    .foregroundStyle(Palette.ink)
            }

            if let resultado, resultado.hayNueva {
                VStack(spacing: 10) {
                    Text("Hay una versión nueva: \(resultado.versionPublicada)")
                        .font(.kid(16))
                        .foregroundStyle(Palette.green)
                    if let enlace = resultado.enlace {
                        Link(destination: enlace) {
                            Text("Actualizar en la App Store")
                                .font(.kid(16))
                                .foregroundStyle(Palette.blue)
                        }
                    }
                }
            } else if let resultado {
                Text("Es la versión más reciente publicada (\(resultado.versionPublicada)).")
                    .font(.kid(15, .semibold))
                    .foregroundStyle(Palette.gray)
                    .multilineTextAlignment(.center)
            } else if fallo {
                Text("No se pudo consultar. Revisa la conexión e inténtalo otra vez.")
                    .font(.kid(15, .semibold))
                    .foregroundStyle(Palette.coral)
                    .multilineTextAlignment(.center)
            }

            BigButton(title: buscando ? "Buscando…" : "Buscar actualizaciones",
                      color: Palette.teal, isEnabled: !buscando) {
                busca()
            }
        }
    }

    // MARK: Enlaces

    private var enlaces: some View {
        VStack(spacing: 12) {
            if let url = Self.privacidad {
                Link("Política de privacidad", destination: url)
                    .font(.kid(16))
                    .foregroundStyle(Palette.blue)
            }
            if let url = Self.soporte {
                Link("Soporte", destination: url)
                    .font(.kid(16))
                    .foregroundStyle(Palette.blue)
            }
            Text("Hecho por Eduardo Veliz")
                .font(.kid(13, .semibold))
                .foregroundStyle(Palette.gray)
                .padding(.top, 4)
        }
    }

    // MARK: Lógica

    private func busca() {
        buscando = true
        fallo = false
        Task {
            do {
                let r = try await UpdateChecker.busca()
                await MainActor.run {
                    resultado = r
                    buscando = false
                }
            } catch {
                await MainActor.run {
                    fallo = true
                    buscando = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AcercaDeView()
    }
}
