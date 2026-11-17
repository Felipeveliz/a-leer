import SwiftUI
import PencilKit

// MARK: - Lienzo de escritura (PencilKit)
//
// Captura el trazo del niño con Apple Pencil o dedo y entrega los puntos
// al terminar cada trazo. El dibujo "bonito" de la letra lo pinta la vista
// de guías; este lienzo solo captura la tinta en vivo.

struct TraceCanvasView: UIViewRepresentable {
    var inkColor: UIColor
    var inkWidth: CGFloat
    var clearTrigger: Int          // al incrementarse, se borra el lienzo
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
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: TraceCanvasView
        var lastClear = 0
        var knownStrokes = 0
        var suppressEvents = false

        init(parent: TraceCanvasView) { self.parent = parent }

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
