import Foundation

// MARK: - ¿Hay una versión más nueva en la App Store?
//
// Es la ÚNICA llamada de red de toda la app, y pide un dato público: la versión
// publicada de este bundle id. No manda nada del niño ni del dispositivo, así
// que la ficha sigue diciendo "no se recopilan datos".
//
// Esto no existía en Toss; aquí se escribió desde cero contra el iTunes Lookup.
// Ojo con el lookup: devuelve lo que está publicado en la tienda del país que se
// le pase, y una versión recién aprobada tarda en aparecer. Por eso un "no hay
// nada nuevo" nunca se presenta como una promesa.

enum UpdateChecker {

    struct Resultado: Equatable {
        let versionPublicada: String
        let versionInstalada: String
        let enlace: URL?

        var hayNueva: Bool {
            UpdateChecker.esMasNueva(versionPublicada, que: versionInstalada)
        }
    }

    enum Fallo: Error {
        case sinRed
        case sinRespuesta
    }

    static var versionInstalada: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static var buildInstalada: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    static func busca(bundleId: String = Bundle.main.bundleIdentifier ?? "",
                      pais: String? = nil) async throws -> Resultado {
        let region = pais ?? Locale.current.region?.identifier.lowercased() ?? "mx"
        var componentes = URLComponents(string: "https://itunes.apple.com/lookup")
        componentes?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleId),
            URLQueryItem(name: "country", value: region),
            // Sin esto, la respuesta puede venir de una caché de horas.
            URLQueryItem(name: "t", value: String(Int(Date().timeIntervalSince1970)))
        ]
        guard let url = componentes?.url else { throw Fallo.sinRespuesta }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultados = json["results"] as? [[String: Any]],
              let primero = resultados.first,
              let version = primero["version"] as? String
        else { throw Fallo.sinRespuesta }

        let enlace = (primero["trackViewUrl"] as? String).flatMap(URL.init(string:))
        return Resultado(versionPublicada: version,
                         versionInstalada: versionInstalada,
                         enlace: enlace)
    }

    /// Compara "1.10" con "1.9" por número, no por texto: alfabéticamente "1.10"
    /// es menor que "1.9" y la app diría que no hay nada nuevo.
    static func esMasNueva(_ a: String, que b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
