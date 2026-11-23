import SwiftUI

// MARK: - Escribir mi nombre
//
// Toma el nombre guardado (PerfilStore) y lo enseña a trazar: primero cada
// parte (nombre y apellidos) por separado, luego el nombre completo. Reutiliza
// el flujo de 3 fases de las palabras, así que hereda modelo, estrellas y el
// "¡tú solo!". Abajo, "Modificar nombre" abre el teclado (para un adulto).

struct MiNombreView: View {
    @ObservedObject private var perfil = PerfilStore.shared
    @ObservedObject private var progreso = ProgressStore.shared
    @State private var modificando = false

    private let columnas = [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 14)]

    /// Cada parte del nombre como una "palabra" trazable y, si hay más de una,
    /// el nombre completo al final.
    private var items: [Palabra] {
        let partes = perfil.partes
        var out = partes.map { Palabra(grupo: "Nombre", silabas: [$0]) }
        if partes.count > 1 {
            out.append(Palabra(grupo: "Nombre", silabas: [perfil.nombre]))
        }
        return out
    }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "🙂",
                title: "Escribir mi nombre",
                subtitle: "Primero cada parte, luego el nombre completo",
                color: Palette.coral
            )

            LazyVGrid(columns: columnas, spacing: 14) {
                ForEach(items) { p in
                    NavigationLink {
                        PalabraEscribeFlowView(palabra: p)
                    } label: {
                        VStack(spacing: 8) {
                            // Un nombre completo no cabe a 30 de alto en la tarjeta:
                            // GlyphText se encoge hasta el ancho que le toca.
                            GlyphText(texto: p.texto, alto: 30)
                            StarBadge(earned: progreso.isWordDone(p))
                        }
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Palette.card)
                                .shadow(color: .black.opacity(0.10), radius: 8, y: 5)
                        )
                    }
                    .buttonStyle(PressDownButtonStyle())
                }
            }

            Button {
                modificando = true
            } label: {
                HStack(spacing: 8) {
                    Text("✏️").font(.system(size: 22))
                    Text("Modificar nombre").font(.kid(18))
                }
                .foregroundStyle(Palette.gray)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    Capsule()
                        .fill(Palette.card)
                        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
                )
            }
            .buttonStyle(PressDownButtonStyle())
            .padding(.top, 8)
        }
        .sheet(isPresented: $modificando) {
            CapturaNombreView()
        }
    }
}

#Preview {
    MiNombreView()
}
