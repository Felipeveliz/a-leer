import StoreKit
import SwiftUI

// MARK: - Propinas (StoreKit 2)
//
// Cuatro consumibles que no desbloquean nada: la app es gratis y completa sin
// pagar, y así lo dice la pantalla. Es la regla de Apple para las propinas y
// además es verdad.
//
// Los precios NO se escriben aquí: se piden a StoreKit (`displayPrice`), que ya
// trae la moneda y el formato del país del usuario. Aprende se vende en 18
// países; un "$10" escrito a mano sería mentira en 17 de ellos.

@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    /// Los cuatro productos, de menor a mayor. El orden real lo manda el precio.
    static let productIds = [
        "com.eduardovelross.aprende.tip.small",
        "com.eduardovelross.aprende.tip.medium",
        "com.eduardovelross.aprende.tip.large",
        "com.eduardovelross.aprende.tip.huge"
    ]

    enum Estado: Equatable {
        case listo
        case comprando(String)
        case gracias
        case fallo(String)
    }

    @Published private(set) var productos: [Product] = []
    @Published private(set) var estado: Estado = .listo
    /// Diferencia "todavía no he preguntado" de "pregunté y no hay nada": sin
    /// esto la pantalla se queda con un spinner eterno cuando los productos no
    /// están dados de alta.
    @Published private(set) var consultado = false

    private var escucha: Task<Void, Never>?

    private init() {
        escucha = escuchaTransacciones()
    }

    deinit { escucha?.cancel() }

    func carga() async {
        do {
            let encontrados = try await Product.products(for: Self.productIds)
            productos = encontrados.sorted { $0.price < $1.price }
        } catch {
            productos = []
        }
        consultado = true
    }

    func compra(_ producto: Product) async {
        estado = .comprando(producto.id)
        do {
            switch try await producto.purchase() {
            case .success(let verificacion):
                let transaccion = try verificado(verificacion)
                await transaccion.finish()
                estado = .gracias
            case .userCancelled:
                estado = .listo
            case .pending:
                // Compra que necesita autorización (Ask to Buy): ni gracias ni
                // error, se resolverá por el listener.
                estado = .listo
            @unknown default:
                estado = .listo
            }
        } catch {
            estado = .fallo(error.localizedDescription)
        }
    }

    func reinicia() { estado = .listo }

    /// Transacciones que llegan de fuera de la pantalla (Ask to Buy aprobada,
    /// una compra terminada en otro dispositivo). Hay que cerrarlas o la cola
    /// las vuelve a entregar para siempre.
    private func escuchaTransacciones() -> Task<Void, Never> {
        Task { [weak self] in
            for await resultado in Transaction.updates {
                guard let self else { return }
                guard let transaccion = try? self.verificado(resultado) else { continue }
                await transaccion.finish()
                self.estado = .gracias
            }
        }
    }

    private func verificado<T>(_ resultado: VerificationResult<T>) throws -> T {
        switch resultado {
        case .verified(let valor): return valor
        case .unverified(_, let error): throw error
        }
    }
}
