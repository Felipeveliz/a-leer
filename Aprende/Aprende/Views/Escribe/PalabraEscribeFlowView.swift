import SwiftUI
import UIKit

// MARK: - Flujo de escritura de una palabra (3 fases)
//
// Fase 1 "Las letras": traza cada letra guiada, una por una, en orden.
// Fase 2 "La palabra completa": toda la palabra a la vista, letra por letra.
// Fase 3 "¡Tú solo!": lienzo libre sin guías, con el modelo ocultable.
// El modelo va SIEMPRE arriba a la IZQUIERDA (niño diestro: su mano no lo tapa).

struct PalabraEscribeFlowView: View {
    let palabra: Palabra

    private enum Fase: Int {
        case letras = 0, palabraCompleta, tuSolo
    }

    @ObservedObject private var progreso = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var fase: Fase = .letras
    @State private var actual = 0              // índice de la letra en curso (fases 1 y 2)
    @State private var clearTrigger = 0        // borra el lienzo libre
    @State private var modeloVisible = true    // en fase 3 empieza oculto
    @State private var terminado = false       // fase 3: ya pulsó "¡Listo!"
    @State private var estrellaVisible = false
    @State private var ocultarModelo: DispatchWorkItem?

    private var letras: [Character] { Array(palabra.texto) }

    var body: some View {
        ScreenScaffold {
            barraDeFases
            encabezadoModelo

            switch fase {
            case .letras: faseLetras
            case .palabraCompleta: fasePalabra
            case .tuSolo: faseTuSolo
            }
        }
        .onAppear {
            // Por si la primera letra no tuviera glifo (no debería pasar).
            if let primero = indiceValido(desde: 0) {
                actual = primero
            } else {
                irAFase3()
            }
        }
    }

    // MARK: Barra de progreso de fase (3 segmentos)

    private var nombreFase: String {
        switch fase {
        case .letras: return "Las letras"
        case .palabraCompleta: return "La palabra completa"
        case .tuSolo: return "¡Tú solo!"
        }
    }

    private var barraDeFases: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i <= fase.rawValue ? Palette.coral : Palette.grayLight.opacity(0.45))
                        .frame(height: 10)
                }
            }
            TagPill(text: nombreFase)
        }
    }

    // MARK: Modelo arriba a la izquierda

    @ViewBuilder
    private var encabezadoModelo: some View {
        HStack {
            if fase != .tuSolo || modeloVisible || terminado {
                modeloTexto
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
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
            Spacer()
        }
    }

    /// La palabra modelo en gris; en fase 1 la letra actual en coral y negrita.
    private var modeloTexto: Text {
        var t = Text("")
        for (i, ch) in Array(letras.enumerated()) {
            var parte = Text(String(ch))
            if fase == .letras && i == actual {
                parte = parte.foregroundStyle(Palette.coral).fontWeight(.heavy)
            } else {
                parte = parte.foregroundStyle(Palette.gray)
            }
            t = t + parte
        }
        return t.font(.kid(30))
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

    // MARK: Fase 1 — Las letras, una por una

    @ViewBuilder
    private var faseLetras: some View {
        if actual < letras.count, let glifo = GlyphLibrary.glyph(for: letras[actual]) {
            VStack(spacing: 14) {
                LetterTraceView(
                    glyph: glifo,
                    accent: letras[actual].isUppercase ? Palette.coral : Palette.blue,
                    onCompleted: { avanzarFase1() }
                )
                .id(actual)   // resetea el trazado al cambiar de letra
                .frame(maxWidth: .infinity)
                .frame(minHeight: 240, idealHeight: 340, maxHeight: 360)

                TagPill(text: "\(actual + 1) / \(letras.count)")
                HintText(text: "Empieza en el punto verde 🟢")
            }
        }
    }

    private func avanzarFase1() {
        if let siguiente = indiceValido(desde: actual + 1) {
            withAnimation { actual = siguiente }
        } else if let primero = indiceValido(desde: 0) {
            // Todas las letras logradas → fase 2.
            withAnimation {
                fase = .palabraCompleta
                actual = primero
            }
        } else {
            irAFase3()
        }
    }

    /// Primer índice (desde `i`) cuya letra tiene glifo; nil si no queda ninguno.
    private func indiceValido(desde i: Int) -> Int? {
        var j = i
        while j < letras.count {
            if GlyphLibrary.glyph(for: letras[j]) != nil { return j }
            j += 1
        }
        return nil
    }

    // MARK: Fase 2 — La palabra completa

    private var fasePalabra: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let espacio: CGFloat = 6
                let unidades = letras.reduce(CGFloat(0)) {
                    $0 + (GlyphLibrary.glyph(for: $1)?.width ?? 0.4)
                }
                let disponible = max(geo.size.width - espacio * CGFloat(max(letras.count - 1, 0)), 50)
                let alto = min(170, disponible / max(unidades, 0.2))

                HStack(spacing: espacio) {
                    ForEach(Array(letras.enumerated()), id: \.offset) { i, ch in
                        letraFase2(indice: i, letra: ch, alto: alto)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)   // centrado
            }
            .frame(height: 190)

            HintText(text: "Ahora la palabra completa, letra por letra ✏️")
        }
    }

    @ViewBuilder
    private func letraFase2(indice i: Int, letra ch: Character, alto: CGFloat) -> some View {
        if let glifo = GlyphLibrary.glyph(for: ch) {
            let acento = ch.isUppercase ? Palette.coral : Palette.blue
            if i < actual {
                // Ya lograda: se muestra sólida y bonita.
                Text(String(ch))
                    .font(.kid(alto * 0.76))
                    .foregroundStyle(acento)
                    .frame(width: glifo.width * alto, height: alto)
            } else {
                // Actual: acepta trazos. Futuras: guía tenue deshabilitada.
                LetterTraceView(
                    glyph: glifo,
                    accent: acento,
                    showsDemo: false,
                    showsFeedbackText: i == actual,
                    onCompleted: { if i == actual { avanzarFase2() } }
                )
                .frame(width: glifo.width * alto, height: alto)
                .allowsHitTesting(i == actual)
                .opacity(i == actual ? 1 : 0.45)
            }
        } else {
            // Sin glifo (no debería pasar): se muestra sólida y se salta.
            Text(String(ch))
                .font(.kid(alto * 0.76))
                .foregroundStyle(Palette.gray)
                .frame(height: alto)
        }
    }

    private func avanzarFase2() {
        if let siguiente = indiceValido(desde: actual + 1) {
            withAnimation { actual = siguiente }
        } else {
            irAFase3()
        }
    }

    private func irAFase3() {
        withAnimation {
            fase = .tuSolo
            modeloVisible = false   // en fase 3 el modelo empieza oculto
        }
    }

    // MARK: Fase 3 — ¡Tú solo!

    @ViewBuilder
    private var faseTuSolo: some View {
        if terminado {
            VStack(spacing: 16) {
                if estrellaVisible {
                    Text("⭐️")
                        .font(.system(size: 64))
                        .transition(.scale.combined(with: .opacity))
                }
                Text("¿Se parece? ¡Ahora escríbela 3 veces en tu cuaderno! 📓")
                    .font(.kid(20))
                    .foregroundStyle(Palette.ink)
                    .multilineTextAlignment(.center)

                FreeWritePad(clearTrigger: clearTrigger, isEnabled: false)
                    .frame(height: 260)

                BigButton(title: "Terminar ⭐️", color: Palette.coral) { dismiss() }
            }
        } else {
            VStack(spacing: 16) {
                HintText(text: "Escribe la palabra tú solo, sin guía 💪")

                FreeWritePad(clearTrigger: clearTrigger, isEnabled: true)
                    .frame(height: 300)

                HStack(spacing: 14) {
                    BigButton(title: "🧽 Borrar", color: Palette.gray) { clearTrigger += 1 }
                    BigButton(title: "¡Listo! ✅", color: Palette.green) { terminar() }
                }
            }
        }
    }

    private func terminar() {
        ocultarModelo?.cancel()
        progreso.markWordDone(palabra)
        withAnimation(.spring(duration: 0.5)) {
            terminado = true
            modeloVisible = true    // el modelo vuelve para comparar
            estrellaVisible = true
        }
    }
}

// MARK: - Lienzo libre reutilizable (fase "¡Tú solo!")
//
// Fondo blanco redondeado con 2 líneas de caligrafía: base sólida y media
// punteada. SIN validación: solo tinta libre. También lo usa NumerosEscribeView.

struct FreeWritePad: View {
    var clearTrigger: Int
    var isEnabled: Bool = true

    var body: some View {
        ZStack {
            // Líneas de caligrafía.
            GeometryReader { geo in
                let margen: CGFloat = 24
                let yBase = geo.size.height * 0.74
                let yMedia = geo.size.height * 0.42

                // Línea base sólida.
                Path { p in
                    p.move(to: CGPoint(x: margen, y: yBase))
                    p.addLine(to: CGPoint(x: geo.size.width - margen, y: yBase))
                }
                .stroke(Palette.grayLight, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                // Línea media punteada.
                Path { p in
                    p.move(to: CGPoint(x: margen, y: yMedia))
                    p.addLine(to: CGPoint(x: geo.size.width - margen, y: yMedia))
                }
                .stroke(Palette.grayLight.opacity(0.8),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 8]))
            }

            // Tinta libre (sin validación).
            TraceCanvasView(
                inkColor: UIColor(Palette.ink),
                inkWidth: 12,
                clearTrigger: clearTrigger,
                isEnabled: isEnabled,
                onStrokeEnded: { _ in }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
        )
    }
}
