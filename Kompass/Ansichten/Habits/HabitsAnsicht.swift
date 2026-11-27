import SwiftUI

/// Mein Weg (dritter Tab, später englisch „Path“; 27.11.2026) – nur Aussehen, nichts reagiert auf Antippen.
/// Oben die Kreis-Reihe im Aufbau der „Mixes“-Reihe des Vorbilds: Überschrift mit Pfeil, graue Zeile, Kreise mit Ring,
/// Bild und Dreieck, Name darunter. Viereinhalb Kreise sichtbar, die Reihe lässt sich wischen.
struct HabitsAnsicht: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 44) {
                KreisReihe(titel: "Habits", text: "Deine Gewohnheiten für Fokus, Ruhe und Schlaf – jeden Tag ein Stück.",
                           eintraege: [("Lesen", "habit-1"), ("Sport", "habit-2"), ("Meditieren", "habit-3"), ("Lernen", "habit-4"), ("Wasser", "habit-5")])
                // Aufgaben (englisch später „To-dos“) – Aussehen 1:1 wie die Habit-Reihe
                KreisReihe(titel: "Aufgaben", text: "Was heute erledigt werden will – Schritt für Schritt abhaken.",
                           eintraege: [("E-Mails", "habit-4"), ("Einkaufen", "habit-1"), ("Anrufen", "habit-3"), ("Lernplan", "habit-2"), ("Steuer", "habit-5")])
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

/// Reihe im Aufbau der „Mixes“-Reihe des Vorbilds: Überschrift mit Pfeil, graue Zeile, Kreise mit Ring, Bild und Dreieck,
/// Name darunter, am Ende ein Plus-Feld. Viereinhalb Kreise sichtbar, die Reihe lässt sich wischen. Noch ohne Funktion.
private struct KreisReihe: View {
    var titel: String
    var text: String
    var eintraege: [(name: String, bild: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(titel).font(.system(size: 19, weight: .semibold))
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                }
                Text(text)
                    .font(.system(size: 17)).foregroundStyle(Color(0x8E8E93)).lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 30)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 11) {
                    ForEach(eintraege, id: \.name) { e in HabitKreis(name: e.name, bild: e.bild) }
                    HabitPlus()
                }
                .padding(.horizontal, 17)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 24)
        }
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

/// Plus-Feld am Ende der Reihe (Vorlage: dunkler Kreis mit feiner heller Kante, weißes Plus, graue Beschriftung) – noch ohne Funktion.
private struct HabitPlus: View {
    private let durchmesser: CGFloat = 73
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(0x232323), Color(0x1C1C1C)], startPoint: .top, endPoint: .bottom))
                Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.05), .white.opacity(0.28)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
                Image(systemName: "plus").font(.system(size: durchmesser * 0.3, weight: .bold)).foregroundStyle(.white)
            }
            .frame(width: durchmesser, height: durchmesser)
            Text("Neu").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(0x9A9A9A))
        }
        .frame(width: durchmesser)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Neuer Habit")
    }
}
