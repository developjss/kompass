import SwiftUI

/// Habits im Detail (öffnet sich über „Habits ›“) – nur Aussehen, feste Beispielwerte, keine Rechnung.
/// Aufbau nach Opals Bildschirmzeit-Seite: „Ablenkende Apps“ (Balken rot) → Habits heute und Weitere Habits,
/// „Andere Apps“ (Balken Limette → Aqua) → Erfolgsquote. Maße aus den Vorlagen gemessen (Zeilenabstand 59 pt, Bild 32 pt).
struct HabitsDetail: View {
    @Environment(\.dismiss) private var dismiss

    private let heute: [Zeile] = [
        Zeile(name: "Lernen", bild: "habit-4", wert: "45m", anteil: 1),
        Zeile(name: "Sport", bild: "habit-2", wert: "40m", anteil: 0.89),
        Zeile(name: "Lesen", bild: "habit-1", wert: "20m", anteil: 0.44),
        Zeile(name: "Meditieren", bild: "habit-3", wert: "10m", anteil: 0.22),
    ]
    private let weitere: [Zeile] = [
        Zeile(name: "Langer Lauf", bild: "habit-2", wert: "60m", anteil: 1),
        Zeile(name: "Wochenplanung", bild: "habit-4", wert: "30m", anteil: 0.5),
        Zeile(name: "Familie anrufen", bild: "habit-5", wert: "20m", anteil: 0.33),
    ]
    private let quote: [Zeile] = [
        Zeile(name: "Wasser", bild: "habit-5", wert: "96 %", anteil: 0.96),
        Zeile(name: "Lesen", bild: "habit-1", wert: "88 %", anteil: 0.88),
        Zeile(name: "Meditieren", bild: "habit-3", wert: "74 %", anteil: 0.74),
        Zeile(name: "Lernen", bild: "habit-4", wert: "61 %", anteil: 0.61),
        Zeile(name: "Sport", bild: "habit-2", wert: "52 %", anteil: 0.52),
        Zeile(name: "Langer Lauf", bild: "habit-2", wert: "40 %", anteil: 0.4),
        Zeile(name: "Wochenplanung", bild: "habit-4", wert: "33 %", anteil: 0.33),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZeitAbschnitt(titel: "Habits heute", summe: "1h 55m", zeilen: heute,
                              mehr: Zeile(name: "Wasser", bild: "habit-5", wert: "", anteil: 0))
                Trennlinie()
                ZeitAbschnitt(titel: "Weitere Habits", summe: "1h 50m", zeilen: weitere,
                              mehr: Zeile(name: "Stretching", bild: "habit-3", wert: "", anteil: 0))
                Trennlinie()
                QuotenAbschnitt(titel: "Erfolgsquote", schnitt: "63 %", zeilen: quote)
            }
            .padding(.top, 70)
            .padding(.bottom, 170)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) { kopf }
        .strahlenGrund()
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("seite.habits.detail")
    }

    private var kopf: some View {
        ZStack {
            Text("Habits").font(.system(size: 17, weight: .semibold))
            HStack { RundKnopf(symbol: "chevron.left", beschriftung: "Zurück") { dismiss() }; Spacer() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 26)
        .background {
            // Inhalt, der unter den Kopf läuft, wird unscharf und dunkel (wie auf Home)
            ZStack { Rectangle().fill(.ultraThinMaterial); Rectangle().fill(Color.black.opacity(0.6)) }
                .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.6), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
        }
    }
}

struct Zeile: Identifiable {
    var id: String { name + wert }
    var name: String
    var bild: String
    var wert: String
    var anteil: Double
}

/// Wie „Ablenkende Apps“: Kopf mit Summe rechts, je Zeile Bild 32 pt, Name, roter Balken mit Wert dahinter, „Alle anzeigen“ unten.
private struct ZeitAbschnitt: View {
    var titel: String
    var summe: String
    var zeilen: [Zeile]
    var mehr: Zeile
    private let rot = [Color(0xFD6180), Color(0xFF7D95)]
    private let maxBalken: CGFloat = 113

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titel).font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(summe).font(.system(size: 17)).foregroundStyle(Color(0x9E9E9E)).monospacedDigit()
            }
            .padding(.bottom, 18)
            VStack(alignment: .leading, spacing: 19) {
                ForEach(zeilen) { z in
                    HStack(alignment: .center, spacing: 20) {
                        HabitBild(bild: z.bild, groesse: 32)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(z.name).font(.system(size: 17))
                            HStack(spacing: 8) {
                                Capsule().fill(LinearGradient(colors: rot, startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(18, maxBalken * z.anteil), height: 4)
                                Text(z.wert).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(0xFF708C)).monospacedDigit()
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                HStack(spacing: 20) {
                    HabitBild(bild: mehr.bild, groesse: 24).frame(width: 32)
                    Text("Alle anzeigen").font(.system(size: 17, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 15, weight: .medium)).foregroundStyle(Color(0x8E8E93))
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }
}

/// Wie „Andere Apps“: Kopf mit Durchschnitt rechts, je Zeile Bild, Name, Balken Limette → Aqua mit Wert dahinter.
private struct QuotenAbschnitt: View {
    var titel: String
    var schnitt: String
    var zeilen: [Zeile]
    private let maxBalken: CGFloat = 230

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(titel).font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(schnitt).font(.system(size: 17)).foregroundStyle(Color(0x9E9E9E)).monospacedDigit()
            }
            .padding(.bottom, 18)
            VStack(alignment: .leading, spacing: 19) {
                ForEach(zeilen) { z in
                    HStack(alignment: .center, spacing: 20) {
                        HabitBild(bild: z.bild, groesse: 32)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(z.name).font(.system(size: 17))
                            HStack(spacing: 8) {
                                Capsule().fill(LinearGradient(colors: [Color(0xDFFAB7), Color(0xC7F8DE), Color(0xDDFFFF)], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(18, maxBalken * z.anteil), height: 4)
                                Text(z.wert).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(0xDAEEE8)).monospacedDigit()
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }
}

private struct HabitBild: View {
    var bild: String
    var groesse: CGFloat
    var body: some View {
        Image(bild).resizable().scaledToFill()
            .frame(width: groesse, height: groesse)
            .clipShape(RoundedRectangle(cornerRadius: groesse * 0.24, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: groesse * 0.24, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 0.5) }
            .accessibilityHidden(true)
    }
}

private struct Trennlinie: View {
    var body: some View { Rectangle().fill(Color(0x2C2C2E)).frame(height: 1).padding(.horizontal, 24) }
}
