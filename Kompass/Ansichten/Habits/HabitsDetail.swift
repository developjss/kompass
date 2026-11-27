import SwiftUI

/// Habits im Detail (öffnet sich über „Habits ›“) – nur Aussehen, feste Beispielwerte, keine Rechnung.
/// Aufbau nach Opals Bildschirmzeit-Seite: „Ablenkende Apps“ (Balken rot) → Habits heute und Weitere Habits,
/// „Andere Apps“ (Balken Limette → Aqua) → Erfolgsquote. Maße aus den Vorlagen gemessen (Zeilenabstand 59 pt, Bild 32 pt).
struct HabitsDetail: View {
    @Environment(\.dismiss) private var dismiss
    /// Wie weit gescrollt ist – der Kopf wird erst beim Scrollen dunkel/unscharf, oben leuchtet das Licht frei hinter der Insel
    @State private var versatz: CGFloat = 0

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
                              mehr: Zeile(name: "Stretching", bild: "habit-3", wert: "", anteil: 0), start: 0.3)
                Trennlinie()
                QuotenAbschnitt(titel: "Erfolgsquote", schnitt: "63 %", zeilen: quote, start: 0.5)
            }
            .padding(.top, 70)
            .padding(.bottom, 170)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, neu in versatz = neu }
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
                .opacity(Double(min(max(versatz / 50, 0), 1)))
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

/// Aufbau wie Opals „Ablenkende Apps“: Kopf mit Summe rechts, je Zeile Bild (38 pt, 20 % größer als im Vorbild), Name,
/// türkiser Balken in Compass-Farben mit wanderndem Sternenstaub (7 pt), Wert dahinter, „Alle anzeigen“ unten.
private struct ZeitAbschnitt: View {
    var titel: String
    var summe: String
    var zeilen: [Zeile]
    var mehr: Zeile
    /// Verzögerung des ersten Balkens (Abschnitte fahren nacheinander ein)
    var start: Double = 0
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
                ForEach(Array(zeilen.enumerated()), id: \.element.id) { i, z in
                    HStack(alignment: .center, spacing: 18) {
                        HabitBild(bild: z.bild, groesse: 38)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(z.name).font(.system(size: 17))
                            EinfahrBalken(breite: max(18, maxBalken * z.anteil), hoehe: 7, art: .staub,
                                          wert: z.wert, wertFarbe: Color(0x7FE9E6), verzoegerung: start + Double(i) * 0.07)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                HStack(spacing: 18) {
                    HabitBild(bild: mehr.bild, groesse: 29).frame(width: 38)
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
    var start: Double = 0
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
                ForEach(Array(zeilen.enumerated()), id: \.element.id) { i, z in
                    HStack(alignment: .center, spacing: 18) {
                        HabitBild(bild: z.bild, groesse: 38)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(z.name).font(.system(size: 17))
                            EinfahrBalken(breite: max(18, maxBalken * z.anteil), hoehe: 4, art: .limette,
                                          wert: z.wert, wertFarbe: Color(0xDAEEE8), verzoegerung: start + Double(i) * 0.06)
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

/// Balken, der beim Öffnen von links nach rechts einfährt (nacheinander, mit Feder). Bei „Bewegung reduzieren“ sofort voll.
private struct EinfahrBalken: View {
    enum Art { case staub, limette }
    var breite: CGFloat
    var hoehe: CGFloat
    var art: Art
    var wert: String
    var wertFarbe: Color
    var verzoegerung: Double
    @State private var an = false
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        HStack(spacing: 8) {
            balken
                .frame(width: an ? breite : 0, height: hoehe, alignment: .leading)
            Text(wert).font(.system(size: 14, weight: .semibold)).foregroundStyle(wertFarbe).monospacedDigit()
                .opacity(an ? 1 : 0)
                .offset(x: an ? 0 : -breite * 0.6)
        }
        .onAppear {
            guard !an else { return }
            if ruhig { an = true; return }
            withAnimation(.spring(response: 0.85, dampingFraction: 0.82).delay(0.15 + verzoegerung)) { an = true }
        }
    }

    @ViewBuilder private var balken: some View {
        switch art {
        case .staub:
            // Compass-Türkis wie der Erledigt-Balken, mit wanderndem Sternenstaub und leichtem Leuchten
            ZStack {
                Capsule().fill(LinearGradient(colors: [Color(0x0B5E5B), Color(0x1AA6A3), Color(0x5DE8E4)], startPoint: .leading, endPoint: .trailing))
                Funkelstaub().clipShape(Capsule())
                Capsule().strokeBorder(Color(0xA7FFFF).opacity(0.45), lineWidth: 0.5)
            }
            .shadow(color: Color(0x2FD0D1).opacity(0.55), radius: 5)
        case .limette:
            Capsule().fill(LinearGradient(colors: [Color(0xDFFAB7), Color(0xC7F8DE), Color(0xDDFFFF)], startPoint: .leading, endPoint: .trailing))
        }
    }
}
