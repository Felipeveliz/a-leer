import SwiftUI

// MARK: - Cómo va el niño
//
// Estadísticas de APRENDIZAJE, no de uso: ni minutos de pantalla, ni sesiones,
// ni veces que abrió la app. Cada bloque contesta una pregunta de un adulto:
//   · ¿qué letras ya son suyas?            → mapa de dominio
//   · ¿cuáles le cuestan y por qué?        → diagnóstico + qué hacer
//   · ¿está mejorando o solo acumulando?   → precisión por semana
//   · ¿practica seguido?                   → constancia
//   · ¿cómo va con las sumas?              → tino y apoyo del ábaco
//
// Todo se calcula en `Estadisticas` y se lee de `PracticeLog`, que nunca sale
// del dispositivo.

struct EstadisticasView: View {
    @ObservedObject private var log = PracticeLog.shared
    @ObservedObject private var progreso = ProgressStore.shared

    private var stats: Estadisticas { Estadisticas(log: log, progreso: progreso) }

    var body: some View {
        ScreenScaffold {
            ScreenHeader(emoji: "📈", title: titulo,
                         subtitle: "Lo que la app midió mientras practicaba",
                         color: Palette.blue)

            if stats.vacio {
                Card {
                    Text("Todavía no hay nada que contar 🙂")
                        .font(.kid(22))
                        .foregroundStyle(Palette.ink)
                    HintText(text: "En cuanto trace unas letras en Escribe, aquí aparece qué domina y qué le cuesta.")
                }
            } else {
                resumen
                BloqueDominio(stats: stats)
                BloqueLoQueCuesta(stats: stats)
                BloqueAvance(stats: stats)
                BloqueConstancia(stats: stats)
                BloqueSumas(stats: stats)
                BloquePendientes(stats: stats)
            }
        }
        .navigationTitle("Avance")
    }

    private var titulo: String {
        let nombre = PerfilStore.shared.partes.first ?? ""
        return nombre.isEmpty ? "Cómo va el avance" : "Cómo va \(nombre)"
    }

    // MARK: Resumen

    private var resumen: some View {
        HStack(spacing: 10) {
            Insignia(valor: "\(stats.cuenta(.dominada, entre: stats.letras))",
                     de: "\(stats.letras.count)", titulo: "letras", color: Palette.green)
            Insignia(valor: "\(stats.palabrasLogradas)",
                     de: "\(stats.palabrasTotales.count)", titulo: "palabras", color: Palette.blue)
            Insignia(valor: "\(stats.digitosLogrados)",
                     de: "10", titulo: "números", color: Palette.purple)
        }
    }
}

// MARK: - Insignia de resumen

private struct Insignia: View {
    let valor: String
    let de: String
    let titulo: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(valor).font(.kid(30)).foregroundStyle(color)
                Text("/\(de)").font(.kid(15)).foregroundStyle(Palette.gray)
            }
            Text(titulo)
                .font(.kid(13, .semibold))
                .foregroundStyle(Palette.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.card)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }
}

// MARK: - Mapa de dominio

private struct BloqueDominio: View {
    let stats: Estadisticas

    var body: some View {
        BloqueDeAdulto(titulo: "Letra por letra",
                       nota: "El color es cuántos intentos le cuesta cada letra, no si la logró.") {
            grupo("Minúsculas", stats.minusculas)
            grupo("Mayúsculas", stats.mayusculas)
            grupo("Números", stats.digitos)
            leyenda
        }
    }

    @ViewBuilder
    private func grupo(_ titulo: String, _ glifos: [String]) -> some View {
        if !glifos.isEmpty {
            Text(titulo)
                .font(.kid(14, .semibold))
                .foregroundStyle(Palette.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            Rejilla(glifos: glifos, stats: stats)
        }
    }

    private var leyenda: some View {
        // En dos filas: en iPhone, los cuatro en una sola partían "en camino" y
        // "sin practicar" a la mitad.
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading),
                                 count: 2), spacing: 6) {
            ForEach([NivelDominio.dominada, .enCamino, .leCuesta, .sinPracticar], id: \.nombre) { nivel in
                HStack(spacing: 5) {
                    Circle().fill(nivel.color).frame(width: 10, height: 10)
                    Text(nivel.nombre)
                        .font(.kid(12, .semibold))
                        .foregroundStyle(Palette.gray)
                        .lineLimit(1)
                }
            }
        }
    }

    private struct Rejilla: View {
        let glifos: [String]
        let stats: Estadisticas

        var body: some View {
            // Las letras se dibujan con sus propios trazos, igual que en Escribe:
            // la "a" del mapa tiene que ser la misma "a" que se le pide trazar.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 8)], spacing: 8) {
                ForEach(glifos, id: \.self) { glifo in
                    let nivel = stats.nivel(de: glifo)
                    GlyphText(texto: glifo, alto: 26, color: { _ in nivel.color })
                        .frame(width: 34, height: 30)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(nivel.color.opacity(0.14))
                        )
                        .accessibilityLabel("\(glifo), \(nivel.nombre)")
                }
            }
        }
    }
}

// MARK: - Lo que le cuesta

private struct BloqueLoQueCuesta: View {
    let stats: Estadisticas

    var body: some View {
        let duras = stats.letrasQueCuestan()

        BloqueDeAdulto(titulo: "Lo que le cuesta",
                       nota: duras.isEmpty
                           ? nil
                           : "Lo importante no es que falle, es por qué falla.") {
            if duras.isEmpty {
                Text("Ninguna letra se le está atorando 👏")
                    .font(.kid(17, .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(duras) { letra in
                    FilaDeLetraDura(letra: letra)
                }
                if let dominante = stats.falloDominante {
                    Text(dominante.fallo.consejo)
                        .font(.kid(15, .semibold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Palette.yellow.opacity(0.35))
                        )
                }
            }
        }
    }

    private struct FilaDeLetraDura: View {
        let letra: LetraQueCuesta

        var body: some View {
            HStack(alignment: .top, spacing: 14) {
                GlyphText(texto: letra.glifo, alto: 40, color: { _ in Palette.coral })
                    .frame(width: 46, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: "%.1f intentos por letra", letra.intentosPorAcierto))
                        .font(.kid(16))
                        .foregroundStyle(Palette.ink)
                    if let fallo = letra.fallo {
                        Text(fallo.descripcion)
                            .font(.kid(14, .semibold))
                            .foregroundStyle(Palette.coral)
                    }
                    if !letra.palabras.isEmpty {
                        Text("practícala en: " + letra.palabras.joined(separator: ", "))
                            .font(.kid(14, .semibold))
                            .foregroundStyle(Palette.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Avance

private struct BloqueAvance: View {
    let stats: Estadisticas

    var body: some View {
        let semanas = stats.avancePorSemana()

        BloqueDeAdulto(titulo: "Si está mejorando",
                       nota: "Qué tan pegado al modelo traza, semana por semana. Las estrellas solo suben; esto puede bajar.") {
            if semanas.count < 2 {
                Text("Hace falta otra semana de práctica para poder comparar.")
                    .font(.kid(15, .semibold))
                    .foregroundStyle(Palette.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(semanas) { semana in
                        VStack(spacing: 6) {
                            Text("\(Int(semana.precision * 100))")
                                .font(.kid(13))
                                .foregroundStyle(Palette.gray)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Palette.blue)
                                .frame(height: max(6, 90 * semana.precision))
                            Text(semana.etiqueta)
                                .font(.kid(11, .semibold))
                                .foregroundStyle(Palette.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140, alignment: .bottom)
            }
        }
    }
}

// MARK: - Constancia

private struct BloqueConstancia: View {
    let stats: Estadisticas

    var body: some View {
        let dias = stats.calendario()

        BloqueDeAdulto(titulo: "Constancia",
                       nota: "\(stats.diasPracticados) de los últimos \(dias.count) días.") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                      spacing: 6) {
                ForEach(dias) { dia in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(dia.practico ? Palette.green.opacity(intensidad(dia.trazos)) : Palette.grayLight.opacity(0.4))
                        .frame(height: 26)
                }
            }
        }
    }

    /// Más trazos ese día, más fuerte el verde. Tope en 30 trazos: a partir de
    /// ahí ya fue una sesión completa y el tono no tiene que seguir subiendo.
    private func intensidad(_ trazos: Int) -> Double {
        0.35 + 0.65 * min(1, Double(trazos) / 30)
    }
}

// MARK: - Sumas

private struct BloqueSumas: View {
    let stats: Estadisticas

    var body: some View {
        BloqueDeAdulto(titulo: "Sumas", nota: nil) {
            if let tino = stats.tinoEnSumas {
                Text("\(Int(tino * 100)) de cada 100 respuestas, a la primera")
                    .font(.kid(17))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let falladas = stats.sumasQueFalla()
                if !falladas.isEmpty {
                    Text("Las que más falla: " + falladas.map { "\($0.suma)" }.joined(separator: " · "))
                        .font(.kid(15, .semibold))
                        .foregroundStyle(Palette.coral)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let apoyo = stats.apoyoDelAbaco {
                    Text("Usa el ábaco en \(Int(apoyo * 100)) de cada 100 respuestas.")
                        .font(.kid(15, .semibold))
                        .foregroundStyle(Palette.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Todavía no ha contestado ninguna suma.")
                    .font(.kid(15, .semibold))
                    .foregroundStyle(Palette.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Lo que falta

private struct BloquePendientes: View {
    let stats: Estadisticas

    var body: some View {
        let pendientes = stats.palabrasPendientes

        BloqueDeAdulto(titulo: "Le falta por lograr", nota: nil) {
            if pendientes.isEmpty {
                Text("Ya logró todas las palabras 🎉")
                    .font(.kid(17))
                    .foregroundStyle(Palette.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Dibujadas con los trazos del glifo, como en Escribe.
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                    ForEach(pendientes, id: \.self) { palabra in
                        GlyphText(texto: palabra, alto: 22, color: { _ in Palette.gray })
                            .frame(height: 26)
                    }
                }
            }
        }
    }
}

// MARK: - Contenedor de bloque

/// Tarjeta blanca con título y una nota que explica qué se está viendo. La nota
/// es la mitad del valor: un número sin su significado se malinterpreta.
private struct BloqueDeAdulto<Content: View>: View {
    let titulo: String
    let nota: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.kid(20))
                .foregroundStyle(Palette.ink)
            if let nota {
                Text(nota)
                    .font(.kid(13, .semibold))
                    .foregroundStyle(Palette.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Palette.card)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        )
    }
}

#Preview {
    NavigationStack {
        EstadisticasView()
    }
}
