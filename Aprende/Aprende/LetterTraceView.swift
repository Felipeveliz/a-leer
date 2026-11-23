import SwiftUI
import UIKit

// MARK: - Componente central del módulo Escribe
//
// Enseña a trazar UN glifo (letra, número o trazo de calentamiento):
//  - guía punteada con los trazos pendientes
//  - punto VERDE de inicio + flecha de dirección + número de trazo
//  - animación de demostración ("mira cómo se hace")
//  - captura con PencilKit y validación con TraceEngine
//  - al validar, el trazo se "pinta" perfecto en el color de tinta
//
// Pedagogía: feedback amable (nunca tache rojo) y se vuelve a demostrar el trazo
// en cada error, no tras varios intentos.

struct LetterTraceView: View {
    let glyph: Glyph
    var accent: Color = Palette.blue
    var showsDemo: Bool = true
    var showsFeedbackText: Bool = true
    var onCompleted: () -> Void = {}

    @State private var completed = 0
    @State private var clearTrigger = 0
    @State private var retryVisible = false
    @State private var successVisible = false
    @State private var demoStart: Date?
    @State private var glyphDone = false

    private let demoDuration: Double = 1.1

    var body: some View {
        GeometryReader { geo in
            // La caja puede ser más ancha que el glifo (ver `Glyph.boxFactor`):
            // el glifo se centra con `dx` y el lienzo ocupa la caja completa.
            let height = min(geo.size.height, geo.size.width / glyph.boxFactor)
            let boxWidth = height * glyph.boxFactor
            let dx = (boxWidth - height * glyph.width) / 2
            let strokes = glyph.scaledStrokes(height: height, dx: dx)

            ZStack {
                TimelineView(.animation(minimumInterval: 1 / 40, paused: demoStart == nil)) { timeline in
                    Canvas { ctx, _ in
                        drawGuides(ctx, strokes: strokes, height: height, date: timeline.date)
                    }
                }
                TraceCanvasView(
                    inkColor: UIColor(accent),
                    inkWidth: max(10, height * 0.055),
                    clearTrigger: clearTrigger,
                    isEnabled: demoStart == nil && !glyphDone,
                    onStrokeEnded: { points in
                        handleStroke(points, strokes: strokes, height: height)
                    }
                )
                if successVisible {
                    Text("✨")
                        .font(.system(size: height * 0.3))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: boxWidth, height: height)
            .overlay(alignment: .bottom) {
                if showsFeedbackText && retryVisible {
                    Text("¡Casi! Otra vez 🙂")
                        .font(.kid(16))
                        .foregroundStyle(Palette.orange)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Capsule().fill(.white.opacity(0.95)))
                        .offset(y: 30)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // centrado
        }
        .onAppear { if showsDemo { startDemo() } }
    }

    // MARK: Demostración animada

    private func startDemo(after delay: Double = 0.15) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !glyphDone else { return }
            demoStart = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + demoDuration + 0.35) {
                demoStart = nil
            }
        }
    }

    private func demoProgress(at date: Date) -> CGFloat? {
        guard let start = demoStart else { return nil }
        let t = date.timeIntervalSince(start) / demoDuration
        return t < 0 ? 0 : min(1, CGFloat(t))
    }

    // MARK: Dibujo de guías

    private func drawGuides(_ ctx: GraphicsContext, strokes: [[CGPoint]],
                            height: CGFloat, date: Date) {
        let guideWidth = max(8, height * 0.052)
        let dotRadius = max(5, height * 0.040)

        for (i, pts) in strokes.enumerated() {
            let isDot = glyph.strokes[i].isDot

            if i < completed {
                // Trazo ya logrado: se pinta sólido y perfecto.
                if isDot {
                    ctx.fill(dotPath(at: pts[0], radius: dotRadius), with: .color(accent))
                } else {
                    ctx.stroke(path(from: pts), with: .color(accent),
                               style: StrokeStyle(lineWidth: guideWidth, lineCap: .round, lineJoin: .round))
                }
                continue
            }

            if i == completed && !glyphDone {
                // Trazo actual: guía punteada + inicio verde + flecha.
                if isDot {
                    ctx.stroke(dotPath(at: pts[0], radius: dotRadius),
                               with: .color(accent.opacity(0.45)),
                               style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
                } else {
                    ctx.stroke(path(from: pts), with: .color(accent.opacity(0.30)),
                               style: StrokeStyle(lineWidth: guideWidth, lineCap: .round,
                                                  lineJoin: .round, dash: [1, guideWidth * 1.6]))
                    drawArrow(ctx, pts: pts, height: height)
                }
                // Punto verde de inicio.
                ctx.fill(dotPath(at: pts[0], radius: dotRadius), with: .color(Palette.green))
                ctx.stroke(dotPath(at: pts[0], radius: dotRadius), with: .color(.white),
                           style: StrokeStyle(lineWidth: 2.5))
                // Número de trazo (si hay varios).
                if strokes.count > 1 {
                    let badge = CGPoint(x: pts[0].x - height * 0.085, y: pts[0].y - height * 0.085)
                    ctx.fill(dotPath(at: badge, radius: height * 0.052), with: .color(Palette.yellow))
                    ctx.draw(Text("\(i + 1)").font(.system(size: height * 0.062, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: 0x6B4E00)), at: badge)
                }
                // Animación de demostración del trazo actual.
                if let p = demoProgress(at: date), !isDot, p > 0.01 {
                    let demo = path(from: pts).trimmedPath(from: 0, to: p)
                    ctx.stroke(demo, with: .color(accent.opacity(0.9)),
                               style: StrokeStyle(lineWidth: guideWidth, lineCap: .round, lineJoin: .round))
                }
                continue
            }

            // Trazos futuros: guía muy tenue.
            if isDot {
                ctx.stroke(dotPath(at: pts[0], radius: dotRadius),
                           with: .color(Palette.gray.opacity(0.25)),
                           style: StrokeStyle(lineWidth: 2.5, dash: [4, 4]))
            } else {
                ctx.stroke(path(from: pts), with: .color(Palette.gray.opacity(0.22)),
                           style: StrokeStyle(lineWidth: guideWidth, lineCap: .round,
                                              lineJoin: .round, dash: [1, guideWidth * 1.6]))
            }
        }
    }

    private func path(from pts: [CGPoint]) -> Path {
        var p = Path()
        guard let first = pts.first else { return p }
        p.move(to: first)
        for q in pts.dropFirst() { p.addLine(to: q) }
        return p
    }

    private func dotPath(at c: CGPoint, radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius,
                               width: radius * 2, height: radius * 2))
    }

    private func drawArrow(_ ctx: GraphicsContext, pts: [CGPoint], height: CGFloat) {
        guard pts.count > 4 else { return }
        let a = pts[1], b = pts[4]
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(hypot(dx, dy), 0.001)
        let ux = dx / len, uy = dy / len
        let base = CGPoint(x: pts[0].x + ux * height * 0.11, y: pts[0].y + uy * height * 0.11)
        let tip = CGPoint(x: base.x + ux * height * 0.075, y: base.y + uy * height * 0.075)
        let px = -uy, py = ux
        let w = height * 0.038
        var tri = Path()
        tri.move(to: tip)
        tri.addLine(to: CGPoint(x: base.x + px * w, y: base.y + py * w))
        tri.addLine(to: CGPoint(x: base.x - px * w, y: base.y - py * w))
        tri.closeSubpath()
        ctx.fill(tri, with: .color(Palette.green))
    }

    // MARK: Validación

    private func handleStroke(_ points: [CGPoint], strokes: [[CGPoint]], height: CGFloat) {
        guard !glyphDone, completed < strokes.count else { return }

        // El niño no levanta el lápiz: la "m" la hace de un tirón, no en tres
        // tiempos. Se prueba primero el trazo suelto y, si no cuadra, se van
        // uniendo los siguientes hasta ver si el movimiento cubre varios.
        let evaluacion = evalua(points, strokes: strokes, height: height)

        guard let hasta = evaluacion.hasta else {
            // El intento fallido es la mitad valiosa del registro: de aquí sale
            // si lo que le falta es saber por dónde empieza la letra o pulso.
            PracticeLog.shared.registra(glifo: glyph.name, ok: false, precision: 0,
                                        fallo: TraceFault.desde(evaluacion.base))
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation { retryVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                clearTrigger += 1
                withAnimation { retryVisible = false }
            }
            // Se vuelve a demostrar el trazo en CADA error, no después de tres: un niño
            // que falla necesita ver cómo se hace ahí mismo, y esperar tres intentos
            // parecía que la animación simplemente no se repetía. Va aunque la pantalla
            // no demuestre al entrar (fase 2): si falló, hay que enseñarle.
            // El 0.9 cae justo después de que se limpia el lienzo (0.8).
            startDemo(after: 0.9)
            return
        }

        do {
            PracticeLog.shared.registra(
                glifo: glyph.name, ok: true,
                precision: (evaluacion.logrado ?? evaluacion.base).precision,
                fallo: nil
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.2)) {
                completed = hasta + 1
                retryVisible = false
            }
            clearTrigger += 1
            if completed == strokes.count {
                glyphDone = true
                withAnimation(.spring(duration: 0.4)) { successVisible = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation { successVisible = false }
                    onCompleted()
                }
            } else if showsDemo {
                startDemo(after: 0.3)
            }
        }
    }

    /// Lo que se sacó de un movimiento del niño.
    private struct Evaluacion {
        /// Último trazo del glifo que cubre el movimiento, o `nil` si no cuadró.
        let hasta: Int?
        /// Medición contra el trazo que se le PEDÍA (el suelto). Es la que sirve
        /// para diagnosticar: contra una unión de varios trazos, "empezó lejos"
        /// no querría decir nada.
        let base: TraceResult
        /// La medición que sí cuadró, que puede ser de varios trazos unidos.
        let logrado: TraceResult?
    }

    /// Evalúa el movimiento contra el trazo pendiente y, si no cuadra, contra
    /// las uniones siguientes: un solo movimiento del niño puede valer por
    /// varios trazos de la definición (la "m" se escribe de un tirón).
    private func evalua(_ points: [CGPoint], strokes: [[CGPoint]],
                        height: CGFloat) -> Evaluacion {
        let empiezaEnPunto = glyph.strokes[completed].isDot
        var base = TraceResult.fallido

        for fin in completed..<strokes.count {
            // El punto de la "i" es un toque aparte: ni se une a lo anterior ni
            // arrastra lo que venga después.
            if fin > completed && (empiezaEnPunto || glyph.strokes[fin].isDot) { break }

            let objetivo = fin == completed
                ? strokes[completed]
                : TraceEngine.joinStrokes(Array(strokes[completed...fin]))

            let r = TraceEngine.validate(user: points, target: objetivo,
                                         height: height,
                                         isDot: fin == completed && empiezaEnPunto)
            if fin == completed { base = r }
            if r.passed { return Evaluacion(hasta: fin, base: base, logrado: r) }
        }
        return Evaluacion(hasta: nil, base: base, logrado: nil)
    }
}
