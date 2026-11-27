import SwiftUI

/// Mein Weg (dritter Tab, später englisch „Path“; 27.11.2026) – nur Aussehen, nichts reagiert auf Antippen.
/// Oben die Kreis-Reihe im Aufbau der „Mixes“-Reihe des Vorbilds: Überschrift mit Pfeil, graue Zeile, Kreise mit Ring,
/// Bild und Dreieck, Name darunter. Viereinhalb Kreise sichtbar, die Reihe lässt sich wischen.
struct HabitsAnsicht: View {
    /// Startargument „-habitsDetail“ öffnet die Detailseite direkt (Prüfen im Simulator)
    @State private var detail = ProcessInfo.processInfo.arguments.contains("-habitsDetail")
    /// Startargument „-habitNeu“ öffnet das Blatt direkt (Prüfen im Simulator)
    @State private var neu = ProcessInfo.processInfo.arguments.contains("-habitNeu")

    var body: some View {
        NavigationStack {
            inhalt
                .navigationDestination(isPresented: $detail) { HabitsDetail() }
                .sheet(isPresented: $neu) { HabitNeuBlatt() }
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var inhalt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 44) {
                KreisReihe(titel: "Habits", text: "Deine Gewohnheiten für Fokus, Ruhe und Schlaf – jeden Tag ein Stück.",
                           eintraege: [("Lesen", "habit-1"), ("Sport", "habit-2"), ("Meditieren", "habit-3"), ("Lernen", "habit-4"), ("Wasser", "habit-5")],
                           oeffnen: { detail = true }, plus: { neu = true })
                // Aufgaben (englisch später „To-dos“) – Aussehen 1:1 wie die Habit-Reihe
                KreisReihe(titel: "Aufgaben", text: "Was heute erledigt werden will – Schritt für Schritt abhaken.",
                           eintraege: [("E-Mails", "habit-4"), ("Einkaufen", "habit-1"), ("Anrufen", "habit-3"), ("Lernplan", "habit-2"), ("Steuer", "habit-5")])
                ZieleReihe()
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
    /// Tipp auf Überschrift oder Pfeil öffnet die Detailseite (nur wo gesetzt)
    var oeffnen: (() -> Void)? = nil
    /// Tipp auf das Plus-Feld (nur wo gesetzt)
    var plus: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Button { oeffnen?() } label: {
                    HStack(spacing: 8) {
                        Text(titel).font(.system(size: 19, weight: .semibold))
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    }
                    .frame(minHeight: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -10)
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
                    Button { plus?() } label: { HabitPlus() }.buttonStyle(.plain)
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

/// Ziele – Aufbau 1:1 wie die „Digital Detox“-Reihe des Vorbilds: Überschrift ohne Pfeil, graue Zeile, hohe Bildkarten
/// (229 × 294 pt, Radius 32), unten unscharf und dunkel, Titel, getönte Unterzeile und eine Glas-Pille mit Dreieck. Noch ohne Funktion.
private struct ZieleReihe: View {
    private let ziele: [(titel: String, unter: String, dauer: String, bild: String)] = [
        ("Pilotenschein", "Theorie und Praxis", "4 Monate", "ziel-1"),
        ("Erster Alleinflug", "Ohne Fluglehrer", "6 Wochen", "ziel-2"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ziele").font(.system(size: 19, weight: .semibold))
                Text("Wohin du langfristig willst.").font(.system(size: 17)).foregroundStyle(Color(0x8E8E93))
            }
            .padding(.horizontal, 32)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(ziele, id: \.titel) { z in ZielKarte(titel: z.titel, unter: z.unter, dauer: z.dauer, bild: z.bild) }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 26)
        }
    }
}

private struct ZielKarte: View {
    var titel: String
    var unter: String
    var dauer: String
    var bild: String
    private let breite: CGFloat = 229, hoehe: CGFloat = 294, radius: CGFloat = 32

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Bild, unten weich unscharf (gleiches Bild unscharf darübergelegt, nach unten eingeblendet)
            ZStack {
                Image(bild).resizable().scaledToFill().frame(width: breite, height: hoehe).clipped()
                Image(bild).resizable().scaledToFill().frame(width: breite, height: hoehe).clipped()
                    .blur(radius: 18)
                    .mask(LinearGradient(stops: [.init(color: .clear, location: 0.42), .init(color: .black, location: 0.7)], startPoint: .top, endPoint: .bottom))
                LinearGradient(stops: [.init(color: .clear, location: 0.45), .init(color: .black.opacity(0.55), location: 0.78), .init(color: .black.opacity(0.92), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(titel).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
                Text(unter).font(.system(size: 16)).foregroundStyle(.white.opacity(0.42)).lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 14))
                    Text(dauer).font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14).frame(height: 40)
                .background { ZStack { Capsule().fill(.ultraThinMaterial); Capsule().fill(Color.black.opacity(0.38)) } }
                .environment(\.colorScheme, .dark)
                .padding(.top, 20)
            }
            .padding(.leading, 24).padding(.bottom, 23)
        }
        .frame(width: breite, height: hoehe)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.08), .white.opacity(0.16)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(titel), \(unter), \(dauer)")
    }
}
