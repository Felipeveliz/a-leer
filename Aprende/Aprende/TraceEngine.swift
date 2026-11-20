import CoreGraphics

// MARK: - Motor de validación de trazos
//
// Compara el trazo del niño con el trazo objetivo del glifo.
// Filosofía pedagógica: se valida DIRECCIÓN y FORMA APROXIMADA,
// no caligrafía perfecta. Los umbrales son generosos a propósito.

struct TraceResult {
    let passed: Bool
    let startOK: Bool
    let meanDistance: CGFloat
}

enum TraceEngine {

    /// Tolerancias relativas a la altura de dibujo del glifo.
    static let startTolerance: CGFloat = 0.24   // qué tan cerca debe empezar
    static let endTolerance: CGFloat = 0.26     // qué tan cerca debe terminar
    static let shapeTolerance: CGFloat = 0.13   // desviación media permitida
    static let resampleCount = 48

    /// Valida el trazo del usuario contra el trazo objetivo.
    /// - Parameters:
    ///   - user: puntos del trazo del niño (en coordenadas de pantalla).
    ///   - target: puntos del trazo objetivo YA escalados a pantalla.
    ///   - height: altura de dibujo del glifo en pantalla (referencia de escala).
    ///   - isDot: el objetivo es un punto (como el de la "i").
    static func validate(user: [CGPoint], target: [CGPoint],
                         height: CGFloat, isDot: Bool) -> TraceResult {
        guard user.count >= 2 || isDot, let targetFirst = target.first else {
            return TraceResult(passed: false, startOK: false, meanDistance: .infinity)
        }

        // Caso especial: un puntito (el de la "i") = toque corto cerca del lugar.
        if isDot {
            guard let uFirst = user.first else {
                return TraceResult(passed: false, startOK: false, meanDistance: .infinity)
            }
            let len = pathLength(user)
            let near = dist(centroid(user), targetFirst) < 0.22 * height
            let short = len < 0.25 * height
            return TraceResult(passed: near && short, startOK: near,
                               meanDistance: dist(uFirst, targetFirst))
        }

        let u = resample(user, count: resampleCount)
        let t = resample(target, count: resampleCount)
        guard u.count == resampleCount, t.count == resampleCount else {
            return TraceResult(passed: false, startOK: false, meanDistance: .infinity)
        }

        // 1. Debe EMPEZAR cerca del punto verde (ahí vive la dirección correcta).
        let startOK = dist(u[0], t[0]) < startTolerance * height

        // 2. Debe TERMINAR cerca del final del trazo.
        let endOK = dist(u[u.count - 1], t[t.count - 1]) < endTolerance * height

        // 3. La forma: distancia media punto a punto (el orden castiga ir al revés).
        var sum: CGFloat = 0
        for i in 0..<resampleCount { sum += dist(u[i], t[i]) }
        let mean = sum / CGFloat(resampleCount)
        let shapeOK = mean < shapeTolerance * height

        // 4. Longitud razonable (ni un puntito ni garabato gigante).
        let uLen = pathLength(user), tLen = max(pathLength(target), 0.001)
        let ratio = uLen / tLen
        let lengthOK = ratio > 0.45 && ratio < 2.2

        return TraceResult(passed: startOK && endOK && shapeOK && lengthOK,
                           startOK: startOK, meanDistance: mean)
    }

    /// Une varios trazos del glifo en un solo camino continuo, metiendo el
    /// recorrido que hace el lápiz de uno al siguiente.
    ///
    /// Es lo que de verdad dibuja un niño cuando escribe la "m" sin despegar el
    /// lápiz: baja el palito, **vuelve a subir por él** y de ahí sale la primera
    /// montañita. Ese tramo de vuelta no está en la definición del glifo, pero sí
    /// está en el trazo del niño, así que hay que añadirlo o las longitudes no
    /// cuadran y el trazo bueno se rechaza.
    static func joinStrokes(_ tramos: [[CGPoint]]) -> [CGPoint] {
        var out: [CGPoint] = []
        for tramo in tramos {
            guard let primero = tramo.first else { continue }
            if let ultimo = out.last, dist(ultimo, primero) > 0.001 {
                let n = 10
                for i in 1..<n {
                    let t = CGFloat(i) / CGFloat(n)
                    out.append(CGPoint(x: ultimo.x + (primero.x - ultimo.x) * t,
                                       y: ultimo.y + (primero.y - ultimo.y) * t))
                }
            }
            out.append(contentsOf: tramo)
        }
        return out
    }

    // MARK: Utilidades geométricas

    static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    static func centroid(_ pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else { return .zero }
        let sx = pts.reduce(CGFloat(0)) { $0 + $1.x }
        let sy = pts.reduce(CGFloat(0)) { $0 + $1.y }
        return CGPoint(x: sx / CGFloat(pts.count), y: sy / CGFloat(pts.count))
    }

    static func pathLength(_ pts: [CGPoint]) -> CGFloat {
        guard pts.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<pts.count { total += dist(pts[i - 1], pts[i]) }
        return total
    }

    /// Re-muestrea una polilínea a `count` puntos equidistantes sobre su longitud.
    static func resample(_ pts: [CGPoint], count: Int) -> [CGPoint] {
        guard pts.count >= 2, count >= 2 else { return pts }
        let total = pathLength(pts)
        guard total > 0 else { return Array(repeating: pts[0], count: count) }

        let step = total / CGFloat(count - 1)
        var out: [CGPoint] = [pts[0]]
        var acc: CGFloat = 0
        var i = 1
        var prev = pts[0]

        while out.count < count - 1 && i < pts.count {
            let d = dist(prev, pts[i])
            if acc + d >= step {
                let t = (step - acc) / d
                let p = CGPoint(x: prev.x + (pts[i].x - prev.x) * t,
                                y: prev.y + (pts[i].y - prev.y) * t)
                out.append(p)
                prev = p
                acc = 0
            } else {
                acc += d
                prev = pts[i]
                i += 1
            }
        }
        while out.count < count { out.append(pts[pts.count - 1]) }
        return out
    }
}
