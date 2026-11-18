import SwiftUI
import PencilKit

// MARK: - Guardia de trazo
//
// Mientras el niño está trazando, NINGÚN ScrollView de la app debe moverse:
// un trazo vertical lento con el dedo o el lápiz hacía scroll en vez de pintar.
// `ScreenScaffold` observa este objeto y desactiva su scroll mientras `activo`.
// Es global a propósito: solo puede haber un trazo en curso a la vez.

final class DrawingGuard: ObservableObject {
    static let shared = DrawingGuard()
    @Published var activo = false
    private init() {}
}

// MARK: - Lienzo de escritura (PencilKit)
//
// Captura el trazo del niño con Apple Pencil o dedo y entrega los puntos
// al terminar cada trazo. El dibujo "bonito" de la letra lo pinta la vista
// de guías; este lienzo solo captura la tinta en vivo.

struct TraceCanvasView: UIViewRepresentable {
    var inkColor: UIColor
    var inkWidth: CGFloat
    var clearTrigger: Int          // al incrementarse, se borra el lienzo
    var undoTrigger: Int = 0       // al incrementarse, se quita el último trazo
    var isEnabled: Bool = true
    var onStrokeEnded: ([CGPoint]) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput          // Apple Pencil Y dedo
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.bounces = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.overrideUserInterfaceStyle = .light
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: inkWidth)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        canvas.tool = PKInkingTool(.pen, color: inkColor, width: inkWidth)
        canvas.isUserInteractionEnabled = isEnabled
        if context.coordinator.lastClear != clearTrigger {
            context.coordinator.lastClear = clearTrigger
            context.coordinator.suppressEvents = true
            canvas.drawing = PKDrawing()
            context.coordinator.knownStrokes = 0
            context.coordinator.suppressEvents = false
        }
        if context.coordinator.lastUndo != undoTrigger {
            context.coordinator.lastUndo = undoTrigger
            var dibujo = canvas.drawing
            if !dibujo.strokes.isEmpty {
                dibujo.strokes.removeLast()
                context.coordinator.suppressEvents = true
                canvas.drawing = dibujo
                context.coordinator.knownStrokes = dibujo.strokes.count
                context.coordinator.suppressEvents = false
            }
        }
    }

    /// Si el lienzo desaparece a mitad de un trazo (navegar atrás, cambiar de
    /// fase), hay que liberar la guardia o el scroll queda bloqueado para siempre.
    static func dismantleUIView(_ canvas: PKCanvasView, coordinator: Coordinator) {
        if DrawingGuard.shared.activo { DrawingGuard.shared.activo = false }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: TraceCanvasView
        var lastClear = 0
        var lastUndo = 0
        var knownStrokes = 0
        var suppressEvents = false

        init(parent: TraceCanvasView) { self.parent = parent }

        // El tool arranca en el touch-down, antes de que el pan del ScrollView
        // padre alcance su umbral: bloquear el scroll aquí sí llega a tiempo.
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            DrawingGuard.shared.activo = true
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            DrawingGuard.shared.activo = false
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !suppressEvents else { return }
            let strokes = canvasView.drawing.strokes
            guard strokes.count > knownStrokes, let stroke = strokes.last else {
                knownStrokes = strokes.count
                return
            }
            knownStrokes = strokes.count
            let transform = stroke.transform
            let points = stroke.path.map { $0.location.applying(transform) }
            guard points.count >= 1 else { return }
            parent.onStrokeEnded(points)
        }
    }
}
