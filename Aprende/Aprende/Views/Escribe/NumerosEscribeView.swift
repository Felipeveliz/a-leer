import SwiftUI

// MARK: - Lista de números para escribir (en orden de dificultad)

struct NumerosEscribeView: View {
    @ObservedObject private var progreso = ProgressStore.shared

    private let columnas = [GridItem(.adaptive(minimum: 110, maximum: 170), spacing: 14)]

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🔢",
                title: "Escribe números",
                subtitle: "Del más fácil al más difícil",
                color: Palette.teal
            )

            LazyVGrid(columns: columnas, spacing: 14) {
                // digitosEscribe ya viene ordenado por dificultad de trazo.
                ForEach(AppData.digitosEscribe, id: \.self) { d in
                    NavigationLink {
                        DigitoEscribeFlowView(digito: d)
                    } label: {
                        VStack(spacing: 8) {
                            Text(String(d))
                                .font(.kid(34))
                                .foregroundStyle(Palette.ink)
                            StarBadge(earned: progreso.isDigitDone(d))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Palette.card)
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 5)
                        )
                    }
                    .buttonStyle(PressDownButtonStyle())
                }
            }
        }
    }
}

// MARK: - Flujo de un dígito (2 pasos)
//
// Paso 1: trazado guiado. Paso 2: "¡Tú solo!" en el lienzo libre,
// con el dígito modelo arriba, del lado que no tapa la mano (ver PerfilStore).

struct DigitoEscribeFlowView: View {
    let digito: Character

    private enum Paso: Int {
        case guiado = 0, tuSolo
    }

    @ObservedObject private var progreso = ProgressStore.shared
    @ObservedObject private var perfil = PerfilStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var paso: Paso = .guiado
    @State private var clearTrigger = 0
    @State private var undoTrigger = 0
    @State private var modeloVisible = false
    @State private var terminado = false
    @State private var estrellaVisible = false
    @State private var ocultarModelo: DispatchWorkItem?

    var body: some View {
        ScreenScaffold {
            // Barra de progreso de paso (2 segmentos).
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule()
                        .fill(i <= paso.rawValue ? Palette.teal : Palette.grayLight.opacity(0.45))
                        .frame(height: 10)
                }
            }

            switch paso {
            case .guiado: pasoGuiado
            case .tuSolo: pasoTuSolo
            }
        }
        .onAppear {
            // Por si el dígito no tuviera glifo (no debería pasar).
            if GlyphLibrary.glyph(for: digito) == nil {
                paso = .tuSolo
            }
        }
    }

    // MARK: Paso 1 — trazado guiado

    @ViewBuilder
    private var pasoGuiado: some View {
        if let glifo = GlyphLibrary.glyph(for: digito) {
            VStack(spacing: 14) {
                Text("Mira y traza el \(String(digito)) 👀")
                    .font(.kid(24))
                    .foregroundStyle(Palette.teal)

                LetterTraceView(
                    glyph: glifo,
                    accent: Palette.teal,
                    onCompleted: { irATuSolo() }
                )
                .frame(maxWidth: .infinity)
                .frame(minHeight: 240, idealHeight: 340, maxHeight: 360)

                HintText(text: "Empieza en el punto verde 🟢")
            }
        }
    }

    private func irATuSolo() {
        withAnimation {
            paso = .tuSolo
            modeloVisible = false   // el modelo empieza oculto
        }
    }

    // MARK: Paso 2 — ¡Tú solo!

    private var pasoTuSolo: some View {
        VStack(spacing: 16) {
            // Modelo arriba, del lado que la mano del niño no tapa: izquierda si
            // es diestro, derecha si es zurdo.
            HStack {
                if perfil.esZurdo { Spacer() }
                if modeloVisible || terminado {
                    Text(String(digito))
                        .font(.kid(72, .heavy))
                        .foregroundStyle(Palette.gray)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.85))
                        )
                } else {
                    Button {
                        mostrarModeloUnMomento()
                    } label: {
                        Text("👀 Ver otra vez")
                            .font(.kid(18))
                            .foregroundStyle(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(Capsule().fill(Palette.blue))
                    }
                    .buttonStyle(PressDownButtonStyle())
                }
                if !perfil.esZurdo { Spacer() }
            }

            if terminado {
                VStack(spacing: 12) {
                    if estrellaVisible {
                        Text("⭐️")
                            .font(.system(size: 64))
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text("¡Ahora escríbelo 3 veces en tu cuaderno! 📓")
                        .font(.kid(20))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                }
            } else {
                HintText(text: "Escribe el número tú solo, sin guía 💪")
            }

            // UNA sola instancia, fuera del if/else: ver la nota en
            // PalabraEscribeFlowView.faseTuSolo (al pulsar "¡Listo!" SwiftUI
            // recreaba el PKCanvasView y se perdía el trazo del niño).
            FreeWritePad(clearTrigger: clearTrigger,
                         undoTrigger: undoTrigger,
                         isEnabled: !terminado)
                .frame(height: 300)

            if terminado {
                BigButton(title: "Terminar ⭐️", color: Palette.teal) { dismiss() }
            } else {
                HStack(spacing: 12) {
                    UndoButton { undoTrigger += 1 }
                    BigButton(title: "🧽 Borrar", color: Palette.gray) { clearTrigger += 1 }
                    BigButton(title: "¡Listo! ✅", color: Palette.green) { terminar() }
                }
            }
        }
    }

    /// Muestra el modelo 3 segundos y lo vuelve a ocultar.
    private func mostrarModeloUnMomento() {
        withAnimation { modeloVisible = true }
        ocultarModelo?.cancel()
        let tarea = DispatchWorkItem {
            withAnimation { modeloVisible = false }
        }
        ocultarModelo = tarea
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: tarea)
    }

    private func terminar() {
        ocultarModelo?.cancel()
        progreso.markDigitDone(digito)
        withAnimation(.spring(duration: 0.5)) {
            terminado = true
            modeloVisible = true    // el modelo vuelve para comparar
            estrellaVisible = true
        }
    }
}
