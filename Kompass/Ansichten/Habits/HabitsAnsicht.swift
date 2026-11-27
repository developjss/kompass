import SwiftUI

/// Habits (Tab statt Timer, 27.11.2026) – nur Aussehen, nichts reagiert auf Antippen.
/// Oben die Kreis-Reihe im Aufbau der „Mixes“-Reihe des Vorbilds: Überschrift mit Pfeil, graue Zeile, Kreise mit Ring,
/// Bild und Dreieck, Name darunter. Viereinhalb Kreise sichtbar, die Reihe lässt sich wischen.
struct HabitsAnsicht: View {
    private let habits: [(name: String, bild: String)] = [
        ("Lesen", "habit-1"), ("Sport", "habit-2"), ("Meditieren", "habit-3"), ("Lernen", "habit-4"), ("Wasser", "habit-5"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Habits").font(.system(size: 19, weight: .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    }
                    Text("Deine Gewohnheiten für Fokus, Ruhe und Schlaf – jeden Tag ein Stück.")
                        .font(.system(size: 17)).foregroundStyle(Color(0x8E8E93)).lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 30)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 11) {
                        ForEach(habits, id: \.name) { h in HabitKreis(name: h.name, bild: h.bild) }
                    }
                    .padding(.horizontal, 17)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 24)

                VStack(spacing: 12) {
                    Text("Habits").font(DSchrift.grosserTitel)
                    Text("Wird neu gebaut.").font(DSchrift.zeile).foregroundStyle(DFarbe.zweitrangig)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 150)
            }
            .padding(.top, 28)
            .padding(.bottom, 170)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(DFarbe.text)
        .strahlenGrund()
        .accessibilityIdentifier("seite.habits")
    }
}

/// Ein Kreis: dunkler Ring, Bild, weißes Dreieck mit weichem Schatten, Name darunter.
private struct HabitKreis: View {
    var name: String
    var bild: String
    private let durchmesser: CGFloat = 73

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(bild).resizable().scaledToFill()
                    .frame(width: durchmesser - 8, height: durchmesser - 8)
                    .clipShape(Circle())
                // Ring: dunkles Grau, innen eine feine helle Kante
                Circle().strokeBorder(Color(0x2B2B2D), lineWidth: 4).frame(width: durchmesser, height: durchmesser)
                Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5).frame(width: durchmesser - 8, height: durchmesser - 8)
                Image(systemName: "play.fill").font(.system(size: durchmesser * 0.3))
                    .foregroundStyle(.white).shadow(color: .black.opacity(0.45), radius: 5, y: 1)
                    .offset(x: 1.5)
            }
            Text(name).font(.system(size: 13, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(width: durchmesser)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
    }
}
