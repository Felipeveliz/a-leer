import SwiftUI

// Menú de Español: sílabas, palabras y oración.
struct EspanolMenuView: View {
    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                emoji: "📖",
                title: "Español",
                subtitle: "Elige qué quieres practicar",
                color: Palette.blue
            )

            NavigationLink {
                SilabasView()
            } label: {
                MenuCard(
                    emoji: "🔤",
                    title: "Lectura de sílabas",
                    subtitle: "la · ra · na · ne · no …",
                    colors: [Palette.purple, Palette.purpleDark]
                )
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                PalabrasView()
            } label: {
                MenuCard(
                    emoji: "📖",
                    title: "Lectura de palabras",
                    subtitle: "Lola · Rosa · Nena · maleta …",
                    colors: [Palette.blue, Palette.blueDark]
                )
            }
            .buttonStyle(PressDownButtonStyle())

            NavigationLink {
                OracionView()
            } label: {
                MenuCard(
                    emoji: "📝",
                    title: "Leer una oración",
                    subtitle: "mi mamá me da elote de cenar",
                    colors: [Palette.orange, Palette.orangeLight]
                )
            }
            .buttonStyle(PressDownButtonStyle())
        }
    }
}

#Preview {
    NavigationStack { EspanolMenuView() }
}
