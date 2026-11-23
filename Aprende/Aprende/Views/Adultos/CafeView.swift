import StoreKit
import SwiftUI
import UIKit

// MARK: - Invítame un café
//
// Propinas voluntarias. No desbloquean nada y la pantalla lo dice: es la regla
// de Apple y es la verdad. Vive detrás de la puerta de adultos porque quien
// tiene el iPad en la mano casi siempre es un niño de cinco años.

struct CafeView: View {
    @ObservedObject private var store = StoreManager.shared
    @State private var gracias = false

    var body: some View {
        ScreenScaffold {
            cabecera
            opciones
            nota
        }
        .navigationTitle("Un café")
        .task {
            if store.productos.isEmpty { await store.carga() }
        }
        .onChange(of: store.estado) { _, nuevo in
            if nuevo == .gracias {
                gracias = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                store.reinicia()
            }
        }
        .alert("¡Gracias! ☕️", isPresented: $gracias) {
            Button("De nada") { }
        } message: {
            Text("En serio: gracias. Esto ayuda a que Aprende siga creciendo.")
        }
    }

    // MARK: Cabecera

    private var cabecera: some View {
        Card {
            Text("☕️").font(.system(size: 56))
            Text("Aprende es gratis")
                .font(.kid(26))
                .foregroundStyle(Palette.orange)
            Text("Sin anuncios, sin suscripciones y sin cuentas. Si le sirve a tu hijo y quieres echar una mano, aquí puedes invitarme un café.")
                .font(.kid(16, .semibold))
                .foregroundStyle(Palette.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Opciones

    @ViewBuilder
    private var opciones: some View {
        if !store.productos.isEmpty {
            VStack(spacing: 12) {
                ForEach(store.productos, id: \.id) { producto in
                    FilaDeCafe(producto: producto)
                }
            }
        } else if store.consultado {
            // Honesto en vez de un spinner eterno: si los productos no están
            // dados de alta o la tienda no responde, se dice.
            Card {
                Text("Las opciones no están disponibles en este momento.")
                    .font(.kid(16, .semibold))
                    .foregroundStyle(Palette.gray)
                    .multilineTextAlignment(.center)
            }
        } else {
            ProgressView().tint(Palette.orange).padding(.vertical, 30)
        }
    }

    // MARK: Nota legal

    private var nota: some View {
        Text("Las propinas son voluntarias y no desbloquean nada: la app es completa sin pagar, y siempre lo será.")
            .font(.kid(13, .semibold))
            .foregroundStyle(Palette.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
    }
}

// MARK: - Una opción

private struct FilaDeCafe: View {
    let producto: Product
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        Button {
            Task { await store.compra(producto) }
        } label: {
            HStack(spacing: 14) {
                Text(emoji)
                    .font(.system(size: 26))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Palette.orange.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(producto.displayName)
                        .font(.kid(18))
                        .foregroundStyle(Palette.ink)
                    Text(producto.description)
                        .font(.kid(13, .semibold))
                        .foregroundStyle(Palette.gray)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if comprando {
                    ProgressView().tint(Palette.orange)
                } else {
                    // El precio viene de StoreKit con su moneda: la app se vende
                    // en 18 países y escribirlo a mano sería mentir en 17.
                    Text(producto.displayPrice)
                        .font(.kid(18))
                        .foregroundStyle(Palette.orange)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.card)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
        .buttonStyle(PressDownButtonStyle())
        .disabled(comprando)
    }

    private var comprando: Bool {
        store.estado == .comprando(producto.id)
    }

    /// Un emoji por tamaño, del café al pastel.
    private var emoji: String {
        switch producto.id {
        case StoreManager.productIds[0]: return "☕️"
        case StoreManager.productIds[1]: return "🥤"
        case StoreManager.productIds[2]: return "🥐"
        default: return "🎂"
        }
    }
}

#Preview {
    NavigationStack {
        CafeView()
    }
}
