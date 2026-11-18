import SwiftUI

// MARK: - Paleta (los mismos colores de la versión web)

enum Palette {
    static let bg      = Color(hex: 0xFEF6E4)
    static let bgWarm  = Color(hex: 0xFFE8CC)
    static let card    = Color.white
    static let ink     = Color(hex: 0x2B2D42)
    static let coral   = Color(hex: 0xFF6B6B)
    static let blue    = Color(hex: 0x4D96FF)
    static let blueDark = Color(hex: 0x3A7BD5)
    static let green   = Color(hex: 0x38B000)
    static let yellow  = Color(hex: 0xFFD166)
    static let purple  = Color(hex: 0x9B5DE5)
    static let purpleDark = Color(hex: 0x6930C3)
    static let orange  = Color(hex: 0xF3722C)
    static let orangeLight = Color(hex: 0xF8961E)
    static let teal    = Color(hex: 0x2A9D8F)
    static let tealDark = Color(hex: 0x1D7870)
    static let gray    = Color(hex: 0x9AA0A6)
    static let grayLight = Color(hex: 0xC9CCD1)

    /// Colores que rotan para las sílabas (como en la web: azul, coral, verde)
    static let sylColors: [Color] = [blue, coral, green]
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Tipografía amigable (redondeada)

extension Font {
    /// Fuente redondeada para niños.
    static func kid(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Fondo de pantalla

struct ScreenBackground: View {
    var body: some View {
        RadialGradient(
            colors: [Palette.bgWarm, Palette.bg],
            center: .topLeading,
            startRadius: 40,
            endRadius: 700
        )
        .ignoresSafeArea()
    }
}

// MARK: - Componentes compartidos

/// Tarjeta blanca redondeada (contenedor principal de cada pantalla).
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 24) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Palette.card)
                .shadow(color: .black.opacity(0.12), radius: 15, y: 8)
        )
    }
}

/// Tarjeta grande de menú con emoji, título y subtítulo (como en la web).
struct MenuCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let colors: [Color]

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 52))
            Text(title)
                .font(.kid(30))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.kid(15, .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 8)
        )
    }
}

/// Botón de acción grande (verde "Otra palabra", azul "Separar sílabas", etc.).
struct BigButton: View {
    let title: String
    let color: Color
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kid(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(color)
                        .shadow(color: .black.opacity(0.18), radius: 0, y: 5)
                )
        }
        .buttonStyle(PressDownButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

/// Deshace el último trazo del lienzo libre. Cuadrado y angosto para que
/// quepa al lado de "Borrar" y "¡Listo!" incluso en iPhone.
struct UndoButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("↩️")
                .font(.kid(24))
                .frame(width: 60)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Palette.blue)
                        .shadow(color: .black.opacity(0.18), radius: 0, y: 5)
                )
        }
        .buttonStyle(PressDownButtonStyle())
        .accessibilityLabel("Deshacer el último trazo")
    }
}

/// Estilo que "hunde" el botón al tocarlo.
struct PressDownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}

/// Pastilla amarilla de etiqueta (grupo "Ll", progreso "3 / 11", etc.).
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.kid(16))
            .foregroundStyle(Color(hex: 0x6B4E00))
            .padding(.vertical, 7)
            .padding(.horizontal, 18)
            .background(Capsule().fill(Palette.yellow))
    }
}

/// Texto de pista gris bajo el contenido.
struct HintText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.kid(17, .semibold))
            .foregroundStyle(Palette.gray)
            .multilineTextAlignment(.center)
    }
}

/// Encabezado de pantalla: título grande de color + subtítulo gris.
struct ScreenHeader: View {
    let emoji: String
    let title: String
    let subtitle: String
    var color: Color = Palette.coral

    var body: some View {
        VStack(spacing: 6) {
            Text("\(emoji) \(title)")
                .font(.kid(32))
                .foregroundStyle(color)
            Text(subtitle)
                .font(.kid(15, .semibold))
                .foregroundStyle(Palette.gray)
                .multilineTextAlignment(.center)
        }
    }
}

/// Estrella de progreso (ganada o pendiente).
struct StarBadge: View {
    let earned: Bool

    var body: some View {
        Image(systemName: earned ? "star.fill" : "star")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(earned ? Palette.yellow : Palette.grayLight)
    }
}

/// Contenedor estándar de pantalla con fondo y scroll.
///
/// El scroll se desactiva mientras hay un trazo en curso (`DrawingGuard`):
/// antes, un trazo vertical lento dentro de un lienzo movía la pantalla en
/// vez de pintar. El `ScrollView` sigue ahí siempre (no se sustituye por un
/// `VStack`) para no cambiar la identidad de las vistas hijas: si cambiara,
/// PencilKit se recrearía y perdería el dibujo.
struct ScreenScaffold<Content: View>: View {
    @ViewBuilder var content: Content

    @ObservedObject private var trazo = DrawingGuard.shared

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 24) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .scrollDisabled(trazo.activo)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
