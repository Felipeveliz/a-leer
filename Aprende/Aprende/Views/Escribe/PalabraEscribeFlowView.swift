import SwiftUI
import UIKit

// MARK: - Flujo de escritura de una palabra (3 fases)
//
// Fase 1 "Las letras": traza cada letra guiada, una por una, en orden.
// Fase 2 "La palabra completa": toda la palabra a la vista, letra por letra.
// Fase 3 "¡Tú solo!": lienzo libre sin guías, con el modelo ocultable.
// El modelo va arriba, del lado que NO tapa la mano del niño: a la izquierda si
// es diestro, a la derecha si es zurdo (ver PerfilStore / encabezadoModelo).

struct PalabraEscribeFlowView: View {
    let palabra: Palabra

    private enum Fase: Int {
        case letras = 0, palabraCompleta, tuSolo
    }

    @ObservedObject private var progreso = ProgressStore.shared
    @ObservedObject private var perfil = PerfilStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var fase: Fase = .letras
    @State private var actual = 0              // índice de la letra en curso (fases 1 y 2)
    @State private var clearTrigger = 0        // borra el lienzo libre
    @State private var undoTrigger = 0         // quita el último trazo del lienzo
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
            // Zurdo: el modelo va a la DERECHA; diestro: a la IZQUIERDA. En los
            // dos casos del lado que su propia mano no tapa al escribir debajo.
            if perfil.mano.esZurdo { Spacer() }
            if fase != .tuSolo || modeloVisible || terminado {
                modeloDibujado
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.85))
                    )
                    // Primero el modelo y luego el Spacer: si el nombre es largo,
                    // el modelo toma todo el ancho antes de tener que encogerse.
                    .layoutPriority(1)
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
            if !perfil.mano.esZurdo { Spacer() }
        }
    }

    /// La palabra modelo, dibujada con los mismos trazos que el niño tiene que
    /// hacer (ver `GlyphText`). En fase 1 la letra actual va en coral.
    private var modeloDibujado: some View {
        GlyphText(texto: palabra.texto, alto: 34) { i in
            fase == .letras && i == actual ? Palette.coral : Palette.gray
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

                TagPill(text: "\((indicesTrazables.firstIndex(of: actual) ?? 0) + 1) / \(indicesTrazables.count)")
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

    /// Índices de las letras que sí se trazan. El espacio del nombre completo (y
    /// cualquier carácter sin glifo) no es una letra: si contara, el contador se
    /// brincaría números ("3 / 9" → "5 / 9" en "Ana López").
    private var indicesTrazables: [Int] {
        letras.indices.filter { GlyphLibrary.glyph(for: letras[$0]) != nil }
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
                let separadores = espacio * CGFloat(max(letras.count - 1, 0))
                let unidades = letras.reduce(CGFloat(0)) { $0 + anchoUnidad(de: $1) }
                let disponible = max(geo.size.width - separadores, 50)
                // Tope arriba por estética y SUELO abajo para que la letra siga
                // siendo trazable: con "maleta" en iPhone, repartir el ancho
                // entre 6 letras dejaba la "l" en 16 pt y era imposible escribir.
                // Si así la fila no cabe, se desplaza en vez de encogerse más.
                let alto = max(130, min(170, disponible / max(unidades, 0.2)))
                let anchoFila = alto * unidades + separadores

                HStack(spacing: espacio) {
                    ForEach(Array(letras.enumerated()), id: \.offset) { i, ch in
                        letraFase2(indice: i, letra: ch, alto: alto)
                    }
                }
                .frame(width: anchoFila, height: geo.size.height)
                .offset(x: desplazamientoFila(anchoFila: anchoFila,
                                              ancho: geo.size.width,
                                              alto: alto,
                                              espacio: espacio))
                .frame(width: geo.size.width, alignment: .leading)
                // Recorta solo a lo ancho: el aviso "¡Casi! Otra vez" vive
                // debajo de la caja de la letra y tiene que seguir visible.
                .mask { Rectangle().padding(.vertical, -80) }
                .animation(.easeOut(duration: 0.25), value: actual)
            }
            .frame(height: 190)

            HintText(text: "Ahora la palabra completa, letra por letra ✏️")
        }
    }

    /// Ancho de la caja de una letra, en unidades de altura.
    private func anchoUnidad(de ch: Character) -> CGFloat {
        GlyphLibrary.glyph(for: ch)?.boxFactor ?? GlyphLibrary.minBoxFactor
    }

    /// Si la palabra completa no cabe a lo ancho, corre la fila para dejar la
    /// letra en curso al centro, sin pasarse de los extremos.
    private func desplazamientoFila(anchoFila: CGFloat, ancho: CGFloat,
                                    alto: CGFloat, espacio: CGFloat) -> CGFloat {
        guard anchoFila > ancho else { return (ancho - anchoFila) / 2 }   // cabe: centrada
        let i = min(max(actual, 0), max(letras.count - 1, 0))
        var x: CGFloat = 0
        for j in 0..<i { x += alto * anchoUnidad(de: letras[j]) + espacio }
        let centro = x + alto * anchoUnidad(de: letras[i]) / 2
        return min(0, max(ancho - anchoFila, ancho / 2 - centro))
    }

    @ViewBuilder
    private func letraFase2(indice i: Int, letra ch: Character, alto: CGFloat) -> some View {
        if let glifo = GlyphLibrary.glyph(for: ch) {
            let acento = ch.isUppercase ? Palette.coral : Palette.blue
            let ancho = glifo.boxFactor * alto
            if i == actual {
                // La letra en curso: la única que acepta trazos.
                LetterTraceView(
                    glyph: glifo,
                    accent: acento,
                    showsDemo: false,
                    onCompleted: { avanzarFase2() }
                )
                .frame(width: ancho, height: alto)
            } else {
                // Las demás solo acompañan, pero con los trazos del glifo: si la
                // letra ya lograda se dibujara con la fuente, el niño vería una
                // forma distinta de la que acaba de trazar.
                GlyphText(texto: String(ch), alto: alto) { _ in
                    i < actual ? acento : Palette.grayLight
                }
                .frame(width: ancho, height: alto)
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

    private var faseTuSolo: some View {
        VStack(spacing: 16) {
            if terminado {
                VStack(spacing: 12) {
                    if estrellaVisible {
                        Text("⭐️")
                            .font(.system(size: 64))
                            .transition(.scale.combined(with: .opacity))
                    }
                    Text("¿Se parece? ¡Ahora escríbela 3 veces en tu cuaderno! 📓")
                        .font(.kid(20))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                }
            } else {
                HintText(text: "Escribe la palabra tú solo, sin guía 💪")
            }

            // UNA sola instancia, fuera del if/else y con la misma altura en los
            // dos estados. Si estuviera dentro de cada rama, SwiftUI la trataría
            // como dos vistas distintas, recrearía el PKCanvasView al pulsar
            // "¡Listo!" y borraría justo lo que hay que comparar con el modelo.
            FreeWritePad(clearTrigger: clearTrigger,
                         undoTrigger: undoTrigger,
                         isEnabled: !terminado)
                .frame(height: 300)

            if terminado {
                BigButton(title: "Terminar ⭐️", color: Palette.coral) { dismiss() }
            } else {
                HStack(spacing: 12) {
                    UndoButton { undoTrigger += 1 }
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
    var undoTrigger: Int = 0
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
                undoTrigger: undoTrigger,
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
