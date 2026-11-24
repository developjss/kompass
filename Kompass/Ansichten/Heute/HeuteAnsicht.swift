import SwiftUI

/// Home (Struktur v3 §3, geführt wie ein Reel): Jetzt-Karte, „Dein Tag“ als Reel, Hinweise, Heute offen, Liegen geblieben, Tagesabschluss.
struct HeuteAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var reel = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let jetzt = speicher.jetztMinuten
        let naechste = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:), anzahl: 4)
        let fokus = HomeRechnung.fokus(zustand: z, heute: T, jetzt: jetzt, naechste: naechste)
        let hinweise = Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:))
        let liegen = z.aufgaben.filter { a in a.datum.map { $0 < T } == true && !a.erledigt }.sorted { ($0.datum ?? T) < ($1.datum ?? T) }
        let ohne = Tagesplan.ohneZeit(am: T, zustand: z)
        let offenA = ohne.aufgaben.filter { !$0.erledigt }.sorted { ($0.prio == .hoch ? 0 : 1, $0.reihenfolge) < ($1.prio == .hoch ? 0 : 1, $1.reihenfolge) }
        let offenH = ohne.habits.filter { !$0.voll(am: T) }
        let slides = z.ziele.contains { $0.status == .aktiv } ? 6 : 5

        Seite(titel: "Home", info: .heute) {
            JetztKarte(fokus: fokus)

            // Als Nächstes (vom Kalender hierher, 24.11.2026)
            NaechsteStapel().padding(.top, 12)

            TagReelKarte(slides: slides, teaser: reelTeaser(naechste: naechste, hinweise: hinweise, offen: offenA.count + offenH.count)) { reel = true }
                .padding(.top, 12)

            if !hinweise.isEmpty {
                AbschnittKopf(titel: hinweise.count == 1 ? "Ein Hinweis" : "\(min(hinweise.count, 3)) Hinweise")
                GruppierteListe {
                    ForEach(hinweise.prefix(3)) { HinweisZeile(hinweis: $0) }
                }
            }

            AbschnittKopf(titel: "Heute offen") {
                Text(offenA.isEmpty && offenH.isEmpty ? "alles erledigt" : "\(offenA.count + offenH.count)").foregroundStyle(Farbe.zweitrangig)
            }
            GruppierteListe {
                ForEach(offenH) { HomeHabitZeile(habit: $0) }
                ForEach(offenA) { AufgabeZeile(aufgabe: $0) }
                AufgabeHinzufuegen(platzhalter: "Aufgabe für heute", datum: T, prio: .normal)
            }

            if !liegen.isEmpty {
                AbschnittKopf(titel: "Liegen geblieben") {
                    Button("Alle auf heute") {
                        speicher.aendern { s in for a in liegen { if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) { s.aufgaben[i].datum = T } } }
                    }
                }
                GruppierteListe {
                    ForEach(liegen.prefix(3)) { AufgabeZeile(aufgabe: $0, datumZeigen: true) }
                    if liegen.count > 3 { LeerZeile(text: "\(liegen.count - 3) weitere im Kalender") }
                }
            }

            PfeilZeile(symbol: "moon", text: z.reflexionen["tag:\(T.text)"] == nil ? "Tagesabschluss · 2 Min." : "Tagesabschluss ✓") {
                nav.blatt = .reflexion(woche: false)
            }
            .padding(.top, Mass.abschnitt)
        }
        .fullScreenCover(isPresented: $reel) { TagReel() }
    }

    private func reelTeaser(naechste: [Tagesplan.Block], hinweise: [Tagesplan.Hinweis], offen: Int) -> String {
        var t: [String] = []
        if !naechste.isEmpty { t.append("\(naechste.count) mit Uhrzeit") }
        if offen > 0 { t.append("\(offen) offen") }
        if let h = hinweise.first(where: { $0.tag == speicher.heute }) { t.append(h.art == .eng ? "enger Tag" : h.art == .ueberschneidung ? "eine Überschneidung" : "wenig Zeit") }
        return (t.isEmpty ? "Heute ist frei" : t.joined(separator: " · ")) + " · 1 Min."
    }
}

/// Was die Jetzt-Karte zeigt (rein): ein Block (läuft oder in ≤ 60 Min), sonst die wichtigste offene Aufgabe ohne Uhrzeit, sonst ein offener Habit.
enum HomeRechnung {
    struct Fokus {
        var block: Tagesplan.Block?
        var aufgabe: Aufgabe?
        var habit: Habit?
        var geschafft: Int
        var gesamt: Int
    }

    static func fokus(zustand z: Zustand, heute T: Tag, jetzt: Int, naechste: [Tagesplan.Block]) -> Fokus {
        // Heute geplant: Aufgaben mit Datum heute + geplante Habits
        let aufgaben = z.aufgaben.filter { $0.datum == T }
        let habits = z.habits.filter { T >= $0.angelegt && HabitRechnung.geplant($0, am: T) }
        let geschafft = aufgaben.filter(\.erledigt).count + habits.filter { $0.voll(am: T) }.count
        let gesamt = aufgaben.count + habits.count
        if let b = naechste.first, b.tag == T, b.start - jetzt <= 60 {
            return Fokus(block: b, geschafft: geschafft, gesamt: gesamt)
        }
        let offen = aufgaben.filter { !$0.erledigt && $0.uhrzeit == nil }
            .sorted { ($0.prio == .hoch ? 0 : 1, $0.reihenfolge) < ($1.prio == .hoch ? 0 : 1, $1.reihenfolge) }
        if let a = offen.first { return Fokus(aufgabe: a, geschafft: geschafft, gesamt: gesamt) }
        if let h = habits.first(where: { !$0.voll(am: T) && $0.zeit(am: T) == nil }) { return Fokus(habit: h, geschafft: geschafft, gesamt: gesamt) }
        if let b = naechste.first { return Fokus(block: b, geschafft: geschafft, gesamt: gesamt) }
        return Fokus(geschafft: geschafft, gesamt: gesamt)
    }
}

/// Große Karte oben: Titel, wann, Knöpfe (Fokus, Erledigt, Menge), darunter „x von y geschafft“.
private struct JetztKarte: View {
    var fokus: HomeRechnung.Fokus
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let farbe = fokus.block?.farbe ?? fokus.habit?.farbe ?? fokus.aufgabe.flatMap { z.ziel($0.zielID)?.farbe }
        Verlaufskarte(farben: farbe.map(Farbe.verlauf) ?? Farbe.indigo) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    KartenLabel(text: label)
                    Text(titel).font(.kompass(.title2, .heavy)).fixedSize(horizontal: false, vertical: true)
                    if let u = unter { Text(u).font(.unterzeile).opacity(0.88) }
                }
                Spacer(minLength: 8)
                Image(systemName: symbol).font(.system(size: 20, weight: .semibold))
                    .frame(width: 48, height: 48).background(.white.opacity(0.2), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
                    .accessibilityHidden(true)
            }
            knoepfe.padding(.top, 10)
            if fokus.gesamt > 0 {
                Balken(anteil: Double(fokus.geschafft) / Double(fokus.gesamt)).padding(.top, 12)
                let sek = z.sitzungen.filter { $0.tag == T }.reduce(0) { $0 + $1.sekunden } + z.timerSekunden(jetzt: speicher.jetzt())
                Text("\(fokus.geschafft) von \(fokus.gesamt) geschafft · \(Zahl.dauer(sek)) Fokus").font(.klein).opacity(0.9)
            }
        }
    }

    private var label: String {
        if let b = fokus.block { return Tagesplan.laeuft(b, heute: speicher.heute, jetzt: speicher.jetztMinuten) ? "Läuft gerade" : "Als Nächstes · \(Tagesplan.wannText(b, heute: speicher.heute, jetzt: speicher.jetztMinuten))" }
        if fokus.aufgabe != nil { return "Jetzt dran" }
        if fokus.habit != nil { return "Heute noch offen" }
        return "Alles erledigt"
    }

    private var titel: String { fokus.block?.titel ?? fokus.aufgabe?.titel ?? fokus.habit?.titel ?? "Für heute ist nichts mehr offen." }

    private var unter: String? {
        let z = speicher.zustand
        if let b = fokus.block {
            let zeit = "\(Tagesplan.uhr(b.start))–\(Tagesplan.uhr(b.ende))"
            if Tagesplan.laeuft(b, heute: speicher.heute, jetzt: speicher.jetztMinuten) { return "\(zeit) · noch \(b.ende - speicher.jetztMinuten) Min" }
            return [zeit, z.ziel(b.zielID)?.titel].compactMap { $0 }.joined(separator: " · ")
        }
        if let a = fokus.aufgabe { return z.ziel(a.zielID)?.titel }
        if let h = fokus.habit { return HabitRechnung.mengenText(h, am: speicher.heute) }
        return nil
    }

    private var symbol: String {
        if let b = fokus.block { return b.art == .termin ? "calendar" : b.art == .habit ? "repeat" : "checkmark.circle" }
        if fokus.habit != nil { return "repeat" }
        if fokus.aufgabe != nil { return "scope" }
        return "sparkles"
    }

    @ViewBuilder private var knoepfe: some View {
        let T = speicher.heute
        HStack(spacing: 8) {
            if let id = aufgabeID {
                let laeuft = speicher.zustand.timer?.aufgabeID == id
                HauptKnopf(text: laeuft ? "Fokus öffnen" : "Fokus starten", symbol: laeuft ? "pause.fill" : "play.fill") { nav.blatt = .fokus(id) }
                NebenKnopf(text: "Erledigt", symbol: "checkmark") { speicher.aendern { $0.erledigen(id, jetzt: speicher.jetzt()) } }
            } else if let h = habitID.flatMap({ speicher.zustand.habit($0) }) {
                if h.menge != nil {
                    HauptKnopf(text: "Menge eintragen", symbol: "plus") { nav.blatt = .habitMenge(h.id, tag: T.text) }
                    NebenKnopf(text: "Ganz", symbol: "checkmark") { speicher.aendern { $0.habitUmschalten(h.id, am: T) } }
                } else {
                    HauptKnopf(text: "Abhaken", symbol: "checkmark") { speicher.aendern { $0.habitUmschalten(h.id, am: T) } }
                }
            } else if let b = fokus.block {
                HauptKnopf(text: "Im Kalender", symbol: "calendar") { nav.oeffneKalender(b.tag) }
                if b.eigenID != nil { NebenKnopf(text: "Ändern", symbol: "pencil") { KalenderAktion.oeffnen(b, nav: nav) } }
            } else {
                HauptKnopf(text: "Plan für morgen", symbol: "calendar") { nav.oeffneKalender(T.plus(tage: 1)) }
            }
        }
    }

    private var aufgabeID: UUID? { fokus.block?.aufgabeID ?? fokus.aufgabe?.id }
    private var habitID: UUID? { fokus.block?.art == .habit ? fokus.block?.habitID : fokus.habit?.id }
}

/// Weißer Kapsel-Knopf auf Verlaufskarten (Gapless-Stil)
struct HauptKnopf: View {
    var text: String
    var symbol: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Label(text, systemImage: symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 16).frame(minHeight: 44)
                .background(Farbe.seladon, in: Capsule()).foregroundStyle(Farbe.nacht)
        }
        .buttonStyle(.plain)
    }
}

/// Glas-Knopf auf Verlaufskarten
struct NebenKnopf: View {
    var text: String
    var symbol: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Label(text, systemImage: symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 16).frame(minHeight: 44)
                .background(.white.opacity(0.18), in: Capsule()).overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

/// Hinweis: Symbol im Kreis (Bernstein/Rose), Text, Tag; Tipp öffnet den Tag im Kalender.
private struct HinweisZeile: View {
    var hinweis: Tagesplan.Hinweis
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        Button { nav.oeffneKalender(hinweis.tag) } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(farbe.opacity(0.14), in: Circle()).foregroundStyle(farbe)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.zeile).foregroundStyle(Farbe.text)
                    Text(hinweis.text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .frame(minHeight: Mass.zeile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var tagText: String {
        let T = speicher.heute
        if hinweis.tag == T { return "Heute" }
        if hinweis.tag == T.plus(tage: 1) { return "Morgen" }
        return hinweis.tag.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
    }

    private var titel: String {
        switch hinweis.art {
        case .eng: "\(tagText): enger Tag"
        case .ueberschneidung: "\(tagText): Überschneidung"
        case .keinPlatz: "\(tagText): zu wenig Zeit"
        }
    }

    private var symbol: String {
        switch hinweis.art {
        case .eng: "gauge.with.dots.needle.67percent"
        case .ueberschneidung: "rectangle.on.rectangle"
        case .keinPlatz: "hourglass"
        }
    }

    private var farbe: Color { hinweis.art == .ueberschneidung ? Color(hex: "#B8456E") : Farbe.warnung }
}

/// Als-Nächstes-Zeile: Uhrzeit groß links, Titel, Unterzeile, Haken für Aufgaben/Habits.
private struct NaechsteZeile: View {
    var block: Tagesplan.Block
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(Tagesplan.uhr(block.start)).font(.kompass(.subheadline, .bold)).monospacedDigit().foregroundStyle(Farbe.text)
                if block.tag != speicher.heute {
                    Text(block.tag == speicher.heute.plus(tage: 1) ? "morgen" : block.tag.datum().formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "de_DE"))))
                        .font(.caption2).foregroundStyle(Farbe.zweitrangig)
                }
            }
            .frame(width: 52)
            .padding(.leading, 8)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: block.farbe)).frame(width: 4, height: 34)
            Button { KalenderAktion.oeffnen(block, nav: nav) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if block.art != .termin {
                Haken(an: block.erledigt, farbe: Color(hex: block.farbe), beschriftung: block.titel) { KalenderAktion.abhaken(block, speicher: speicher) }
                    .padding(.trailing, 6)
            } else {
                Color.clear.frame(width: 16)
            }
        }
        .frame(minHeight: Mass.zeile)
    }

    private var unter: String {
        var t = "\(block.dauer) Min"
        if let g = speicher.zustand.ziel(block.zielID) { t += " · \(g.titel)" }
        else if block.art == .habit { t += " · Habit" }
        return t
    }
}

/// Habit ohne Uhrzeit auf Home: Kachel · Titel · Stand · Haken; Tipp = Menge eintragen.
private struct HomeHabitZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: habit.farbe)
        HStack(spacing: 10) {
            Haken(an: habit.voll(am: T), farbe: c, beschriftung: habit.titel) { speicher.aendern { $0.habitUmschalten(habit.id, am: T) } }
                .padding(.leading, 4)
            Button {
                if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: T.text) } else { nav.oeffneHabit(habit.id) }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text("\(HabitRechnung.mengenText(habit, am: T)) · Habit").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Image(systemName: habit.symbol).font(.footnote.weight(.semibold)).foregroundStyle(c).padding(.trailing, 16).accessibilityHidden(true)
        }
        .frame(minHeight: Mass.zeileKompakt)
    }
}
