import SwiftUI

/// Home (Nachtblau, Hick’s Law): Bühne „Jetzt dran“, Karte vorn mit genau einer Sache (Fokus · Erledigt),
/// darunter „Als Nächstes“ (3 + alle) und höchstens ein Hinweis. Abends der Tagesabschluss.
struct HeuteAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let jetzt = speicher.jetztMinuten
        let naechste = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:), anzahl: 6)
        let fokus = HomeRechnung.fokus(zustand: z, heute: T, jetzt: jetzt, naechste: naechste)
        let hinweise = Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:))
        let liegen = z.aufgaben.filter { a in a.datum.map { $0 < T } == true && !a.erledigt }
        let ohne = Tagesplan.ohneZeit(am: T, zustand: z)
        let offenH = ohne.habits.filter { !$0.voll(am: T) && $0.id != fokus.habit?.id }
        let zeilen = HomeRechnung.alsNaechstes(bloecke: naechste, habits: offenH, fokus: fokus, anzahl: 3)
        let gesamt = naechste.count + offenH.count

        BuehnenSeite(wort: HomeRechnung.wort(fokus, heute: T, jetzt: jetzt), marke: {
            MarkenTitel(text: "Kompass")
            Spacer(minLength: 8)
            MarkenHinweis(text: HomeRechnung.datumText(T))
            RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.heute) }
        }, extra: {
            if HomeRechnung.geschafft(fokus) { Ueberflug(heute: T.text) }
        }) {
            JetztKarte(fokus: fokus)

            AbschnittKopf(titel: "Als Nächstes") {
                if gesamt > zeilen.count {
                    Button("alle \(gesamt) ›") { nav.oeffneKalender(T) }
                }
            }
            .padding(.horizontal, Mass.rand)
            // Hinzufügen wie bei den Meilensteinen: direkt unter der Überschrift, eine Karte für alles – das Blatt fragt, was es sein soll
            HinzufuegenKarte(titel: "Hinzufügen", unter: "Aufgabe · Termin · Habit · Ziel") { nav.blatt = .neu(nil) }
                .padding(.horizontal, Mass.rand).padding(.bottom, 10)
            GruppierteListe {
                if zeilen.isEmpty {
                    LeerZeile(text: "Nichts mehr mit Uhrzeit. Morgen planen – im Kalender.")
                }
                ForEach(zeilen) { e in
                    switch e {
                    case .block(let b): NaechsteZeile(block: b)
                    case .habit(let h): HomeHabitZeile(habit: h)
                    }
                }
            }
            .padding(.horizontal, Mass.rand)

            // Ein Hinweis, der wichtigste: Liegengebliebenes vor engem Tag
            if !liegen.isEmpty {
                GruppierteListe {
                    LiegenZeile(anzahl: liegen.count) {
                        speicher.aendern { s in for a in liegen { if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) { s.aufgaben[i].datum = T } } }
                    }
                }
                .padding(.horizontal, Mass.rand).padding(.top, 12)
            } else if let h = hinweise.first {
                GruppierteListe { HinweisZeile(hinweis: h) }
                    .padding(.horizontal, Mass.rand).padding(.top, 12)
            }

            if jetzt >= 18 * 60 || z.reflexionen["tag:\(T.text)"] != nil {
                PfeilZeile(symbol: "moon", text: z.reflexionen["tag:\(T.text)"] == nil ? "Tagesabschluss · 2 Min." : "Tagesabschluss ✓") {
                    nav.blatt = .reflexion(woche: false)
                }
                .padding(.horizontal, Mass.rand).padding(.top, Mass.abschnitt)
            }
        }
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

    /// Alles geschafft: nichts läuft, nichts offen, nichts mehr mit Uhrzeit – dann der Überflug.
    static func geschafft(_ f: Fokus) -> Bool { f.block == nil && f.aufgabe == nil && f.habit == nil }

    /// Das Wort auf der Bühne – die Aussage des Moments.
    static func wort(_ f: Fokus, heute T: Tag, jetzt: Int) -> Wort {
        if let b = f.block, b.tag == T {
            if Tagesplan.laeuft(b, heute: T, jetzt: jetzt) { return Wort(zeilen: ["Läuft"], akzent: "gerade.") }
            let m = b.start - jetzt
            if m > 0 && m <= 60 { return Wort(zeilen: ["In \(m) Min"], akzent: "dran.") }
        }
        if f.aufgabe != nil { return Wort(zeilen: ["Jetzt"], akzent: "dran.") }
        if f.habit != nil { return Wort(zeilen: ["Heute"], akzent: "offen.") }
        if f.block != nil { return Wort(zeilen: ["Gleich"], akzent: "weiter.") }
        return Wort(zeilen: ["Alles"], akzent: "geschafft.")
    }

    /// „Di · 24. Nov“
    static func datumText(_ T: Tag) -> String {
        T.datum().formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "de_DE"))) + " · " + T.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
    }

    enum Eintrag: Identifiable {
        case block(Tagesplan.Block)
        case habit(Habit)
        var id: String { switch self { case .block(let b): b.id; case .habit(let h): "habit-\(h.id.uuidString)" } }
    }

    /// Als Nächstes: Blöcke mit Uhrzeit (ohne den, der schon vorn steht), aufgefüllt mit offenen Habits – höchstens `anzahl`.
    static func alsNaechstes(bloecke: [Tagesplan.Block], habits: [Habit], fokus: Fokus, anzahl: Int) -> [Eintrag] {
        var out: [Eintrag] = bloecke.filter { $0.id != fokus.block?.id }.map { .block($0) }
        out.append(contentsOf: habits.map { .habit($0) })
        return Array(out.prefix(anzahl))
    }
}

/// Karte vorn: Etikett (Ziel · Dauer), Titel, Fokus starten · Erledigt (oder Menge · Ganz, Im Kalender · Ändern), darunter „x von y geschafft“.
private struct JetztKarte: View {
    var fokus: HomeRechnung.Fokus
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        VornKarte {
            Etikett(text: label)
            Text(titel).font(.karteTitel).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            knoepfe.padding(.top, 4)
            if fokus.gesamt > 0 {
                let sek = z.sitzungen.filter { $0.tag == T }.reduce(0) { $0 + $1.sekunden } + z.timerSekunden(jetzt: speicher.jetzt())
                Balken(anteil: Double(fokus.geschafft) / Double(fokus.gesamt), farbe: Farbe.handlung, spur: Farbe.linie).padding(.top, 8)
                Text("\(fokus.geschafft) von \(fokus.gesamt) geschafft · \(Zahl.dauer(sek)) Fokus").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        }
    }

    private var label: String {
        let z = speicher.zustand
        if let b = fokus.block {
            let zeit = "\(Tagesplan.uhr(b.start))–\(Tagesplan.uhr(b.ende))"
            if Tagesplan.laeuft(b, heute: speicher.heute, jetzt: speicher.jetztMinuten) { return "\(zeit) · noch \(b.ende - speicher.jetztMinuten) Min" }
            return [zeit, z.ziel(b.zielID)?.titel].compactMap { $0 }.joined(separator: " · ")
        }
        if let a = fokus.aufgabe { return "\(z.ziel(a.zielID)?.titel ?? "Ohne Ziel") · \(a.dauer) min" }
        if let h = fokus.habit { return "Habit · \(HabitRechnung.mengenText(h, am: speicher.heute))" }
        return "Heute"
    }

    private var titel: String { fokus.block?.titel ?? fokus.aufgabe?.titel ?? fokus.habit?.titel ?? "Nichts mehr offen. Gute Landung." }

    @ViewBuilder private var knoepfe: some View {
        let T = speicher.heute
        HStack(spacing: 8) {
            if let id = aufgabeID {
                let laeuft = speicher.zustand.timer?.aufgabeID == id
                Button { nav.blatt = .fokus(id) } label: { Label(laeuft ? "Fokus öffnen" : "Fokus starten", systemImage: laeuft ? "pause.fill" : "play.fill") }
                    .buttonStyle(.haupt)
                Button { speicher.aendern { $0.erledigen(id, jetzt: speicher.jetzt()) } } label: { Label("Erledigt", systemImage: "checkmark") }
                    .buttonStyle(.leise)
            } else if let h = habitID.flatMap({ speicher.zustand.habit($0) }) {
                if h.menge != nil {
                    Button { nav.blatt = .habitMenge(h.id, tag: T.text) } label: { Label("Menge eintragen", systemImage: "plus") }.buttonStyle(.haupt)
                    Button { speicher.aendern { $0.habitUmschalten(h.id, am: T) } } label: { Label("Ganz", systemImage: "checkmark") }.buttonStyle(.leise)
                } else {
                    Button { speicher.aendern { $0.habitUmschalten(h.id, am: T) } } label: { Label("Abhaken", systemImage: "checkmark") }.buttonStyle(.haupt)
                }
            } else if let b = fokus.block {
                Button { nav.oeffneKalender(b.tag) } label: { Label("Im Kalender", systemImage: "calendar") }.buttonStyle(.haupt)
                if b.eigenID != nil { Button("Ändern") { KalenderAktion.oeffnen(b, nav: nav) }.buttonStyle(.leise) }
            } else {
                Button { nav.oeffneKalender(T.plus(tage: 1)) } label: { Label("Morgen planen", systemImage: "calendar") }.buttonStyle(.leise)
            }
        }
    }

    private var aufgabeID: UUID? { fokus.block?.aufgabeID ?? fokus.aufgabe?.id }
    private var habitID: UUID? { fokus.block?.art == .habit ? fokus.block?.habitID : fokus.habit?.id }
}

/// Hinweis: Symbol im Kreis, Text, Tag; Tipp öffnet den Tag im Kalender.
private struct HinweisZeile: View {
    var hinweis: Tagesplan.Hinweis
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        Button { nav.oeffneKalender(hinweis.tag) } label: {
            HStack(spacing: 12) {
                SymbolKachel(symbol: symbol, farbe: Farbe.warnung)
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
}

/// Liegengebliebenes als ein Hinweis mit einer Handlung: alles auf heute.
private struct LiegenZeile: View {
    var anzahl: Int
    var aufHeute: () -> Void
    @Environment(Navigation.self) private var nav
    var body: some View {
        HStack(spacing: 12) {
            SymbolKachel(symbol: "tray.full", farbe: Farbe.warnung)
            Button { nav.oeffneKalender(nil) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(anzahl == 1 ? "1 Aufgabe liegen geblieben" : "\(anzahl) Aufgaben liegen geblieben").font(.zeile).foregroundStyle(Farbe.text)
                    Text("Antippen zeigt sie im Kalender").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                }
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button("Auf heute", action: aufHeute).buttonStyle(.hauptKlein)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(minHeight: Mass.zeile)
    }
}

/// Als-Nächstes-Zeile: Zeichen im Rosé-Kreis, Titel, Ziel oder Quelle, rechts die Uhrzeit (Serif) – Aufgaben und Habits mit Haken.
private struct NaechsteZeile: View {
    var block: Tagesplan.Block
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(spacing: 12) {
            ZeichenKreis(symbol: symbol)
                .padding(.leading, 12)
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
                Haken(an: block.erledigt, farbe: Farbe.handlung, beschriftung: block.titel) { KalenderAktion.abhaken(block, speicher: speicher) }
                    .padding(.trailing, 6)
            } else {
                Text(Tagesplan.uhr(block.start)).font(.zahlKlein).monospacedDigit().foregroundStyle(Farbe.text).padding(.trailing, 16)
            }
        }
        .frame(minHeight: Mass.zeile)
    }

    private var symbol: String {
        if let g = speicher.zustand.ziel(block.zielID) { return g.symbol }
        switch block.art { case .termin: return "calendar"; case .aufgabe: return "checkmark"; case .habit: return "repeat" }
    }

    private var unter: String {
        let T = speicher.heute
        var teile: [String] = []
        if block.tag != T { teile.append(block.tag == T.plus(tage: 1) ? "morgen" : block.tag.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))) }
        if block.art != .termin { teile.append(Tagesplan.uhr(block.start)) }
        if let g = speicher.zustand.ziel(block.zielID) { teile.append(g.titel) } else if block.art == .habit { teile.append("Habit") } else if block.art == .termin { teile.append("\(block.dauer) Min") }
        return teile.joined(separator: " · ")
    }
}

/// Zeichen im Rosé-Kreis (40 pt), Weinrot – für Zeilen (Blattwerk)
struct ZeichenKreis: View {
    var symbol: String
    var gruen = false
    var body: some View {
        Image(systemName: symbol).font(.system(size: 16, weight: .bold))
            .foregroundStyle(gruen ? Farbe.text : Farbe.wort)
            .frame(width: 40, height: 40)
            .background(gruen ? Farbe.akzentWeich : Farbe.buehne, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Habit ohne Uhrzeit auf Home: Zeichen · Titel · Stand · Haken; Tipp = Menge eintragen.
private struct HomeHabitZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        HStack(spacing: 12) {
            ZeichenKreis(symbol: habit.symbol, gruen: true).padding(.leading, 12)
            Button {
                if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: T.text) } else { nav.oeffneHabit(habit.id) }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text("Habit · \(HabitRechnung.mengenText(habit, am: T))").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Haken(an: habit.voll(am: T), farbe: Farbe.handlung, beschriftung: habit.titel) { speicher.aendern { $0.habitUmschalten(habit.id, am: T) } }
                .padding(.trailing, 6)
        }
        .frame(minHeight: Mass.zeile)
    }
}
