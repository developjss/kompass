import SwiftUI

/// Home (Nachtblau, Hick’s Law): Bühne „Jetzt dran“, Karte vorn mit genau einer Sache (Fokus · Erledigt),
/// darunter „Wichtig“ (höchstens drei Signale, §12), der Rückblick als Karten zum Wischen (§14) und „Als Nächstes“ (3 + alle). Abends der Tagesabschluss.
struct HeuteAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var serieOffen = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let jetzt = speicher.jetztMinuten
        let naechste = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:), anzahl: 6)
        let fokus = HomeRechnung.fokus(zustand: z, heute: T, jetzt: jetzt, naechste: naechste)
        let signale = Signale.oben(Signale.alle(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:)),
                                   stumm: z.lernen.signaleStumm, heute: T)
        let ohne = Tagesplan.ohneZeit(am: T, zustand: z)
        let offenH = ohne.habits.filter { !$0.voll(am: T) && $0.id != fokus.habit?.id }
        let zeilen = HomeRechnung.alsNaechstes(bloecke: naechste, habits: offenH, fokus: fokus, anzahl: 3)
        let gesamt = naechste.count + offenH.count

        let serie = KompassSerie.laenge(z, heute: T)
        let muster = Muster.befunde(z, heute: T).first

        ScrollView {
            VStack(spacing: 14) {
                // Kopf wie im Vorbild: Marke links, rechts Serie (Flamme), Pro, Profil
                HStack(spacing: 12) {
                    Text("Kompass").font(.system(size: 30, weight: .semibold)).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    Button { serieOffen = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill").foregroundStyle(LinearGradient(colors: [Color(0xFFD27A), Color(0xFF8A3D)], startPoint: .top, endPoint: .bottom))
                            Text("\(serie)").font(.system(.body, weight: .semibold)).foregroundStyle(Color(0xFFC766))
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Serie \(serie) Tage")
                    if z.einstellungen.pro { Plakette(text: "PRO") }
                    Button { nav.blatt = .einstellungen } label: {
                        Image(systemName: "person.fill").font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DFarbe.akzent)
                            .frame(width: 36, height: 40)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(DFarbe.akzent.opacity(0.8), lineWidth: 1) }
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profil und Einstellungen")
                }
                .padding(.horizontal, Dunkel.rand_)

                HomeBuehne(erfolg: HomeRechnung.geschafft(fokus))

                // Aussage und drei Werte (§19 Tageswert, §17 Ablenkung, Habits heute)
                VStack(spacing: 16) {
                    (Text(HomeRechnung.wort(fokus, heute: T, jetzt: jetzt).zeilen.joined(separator: " ") + " " + HomeRechnung.wort(fokus, heute: T, jetzt: jetzt).akzent).font(.system(.body, weight: .semibold))
                     + Text("  " + HomeRechnung.datumText(T)).font(.system(.body)).foregroundStyle(DFarbe.zweitrangig))
                    HStack(alignment: .top, spacing: 0) {
                        HomeWert(titel: "Tageswert", wert: "\(Tageswert.wert(z, am: T))")
                        HomeWert(titel: "Ablenkung", wert: Bildschirm.ablenkung(z.bildschirmzeit, am: T).map { Zahl.dauer(Double($0) * 60) } ?? "–")
                        HomeWert(titel: "Geschafft", wert: "\(fokus.geschafft)/\(fokus.gesamt)")
                    }
                }
                .padding(.top, -18)
                .padding(.bottom, 8)

                JetztKarte(fokus: fokus).padding(.horizontal, Dunkel.rand_)

                // Wichtig (§12): höchstens drei Signale, jedes mit genau einer Handlung
                if !signale.isEmpty {
                    GlasKarte {
                        Text("Wichtig").font(DSchrift.zeileFett).foregroundStyle(DFarbe.zweitrangig)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18).padding(.top, 16)
                        ForEach(signale) { SignalZeile(signal: $0) }
                    }
                    .padding(.horizontal, Dunkel.rand_)
                }

                // Erkenntnisse (§15): das stärkste Muster, sonst der Hinweis, dass Daten fehlen
                GlasKarte {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Erkenntnisse").font(DSchrift.zeileFett).foregroundStyle(DFarbe.zweitrangig)
                        if let m = muster {
                            Text(m.text).font(.system(.title3, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                            Text("Zusammenhang, keine Ursache · \(m.tage) Tage verglichen").font(DSchrift.unterzeile).foregroundStyle(DFarbe.zweitrangig)
                        } else {
                            Text("Deine ersten Erkenntnisse brauchen 14 Tage mit Journal.").font(DSchrift.zeile).foregroundStyle(DFarbe.text)
                                .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.vertical, 28)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                }
                .padding(.horizontal, Dunkel.rand_)

                // Rückblick (§14): Karten zum Wischen, das Auffälligste vorn
                RueckblickReihe()

                AbschnittKopf(titel: "Als Nächstes") {
                    if gesamt > zeilen.count {
                        Button("alle \(gesamt) ›") { nav.oeffneKalender(T) }
                    }
                }
                .padding(.horizontal, Dunkel.rand_)
                GlasKarte {
                    if zeilen.isEmpty {
                        LeerZeile(text: "Nichts mehr mit Uhrzeit.")
                    }
                    ForEach(zeilen) { e in
                        switch e {
                        case .block(let b): NaechsteZeile(block: b)
                        case .habit(let h): HomeHabitZeile(habit: h)
                        }
                    }
                }
                .padding(.horizontal, Dunkel.rand_)
                HinzufuegenKarte(titel: "Hinzufügen", unter: "Aufgabe · Habit · Ziel") { nav.blatt = .neu(nil) }
                    .padding(.horizontal, Dunkel.rand_)

                if jetzt >= 18 * 60 || z.reflexionen["tag:\(T.text)"] != nil {
                    PfeilZeile(symbol: "moon", text: z.reflexionen["tag:\(T.text)"] == nil ? "Tagesabschluss · 2 Min." : "Tagesabschluss ✓") {
                        nav.blatt = .reflexion(woche: false)
                    }
                    .padding(.horizontal, Dunkel.rand_)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 110)
        }
        .dunkelGrund()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $serieOffen) { SerieBlatt(serie: serie) }
    }
}

/// Bühne: die Figur auf dem Sockel im Fels. Bild „home-fels“ aus den Assets, sonst gezeichneter Fels.
private struct HomeBuehne: View {
    var erfolg: Bool
    var body: some View {
        ZStack(alignment: .bottom) {
            BildPlatz(name: "home-fels") { FelsZeichnung() }
                .frame(height: 330).frame(maxWidth: .infinity).clipped()
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22), .init(color: .black, location: 0.72), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
            VStack(spacing: -44) {
                Figur(zustand: erfolg ? .erfolg : .ruhig, groesse: 112)
                // Sockel
                Ellipse().fill(LinearGradient(colors: [Color(0x2A2D2B), Color(0x0C0D0C)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 92, height: 18)
                    .overlay { Ellipse().strokeBorder(Color.white.opacity(0.12), lineWidth: 1) }
            }
            .padding(.bottom, 62)
        }
        .frame(height: 330)
        .accessibilityHidden(true)
    }
}

/// Gezeichneter Fels (Ersatz, bis das erzeugte Bild in den Assets liegt): zwei dunkle Wände, ein Vorsprung, Sternenstaub.
private struct FelsZeichnung: View {
    var body: some View {
        Canvas { ctx, g in
            func wand(_ punkte: [CGPoint], _ farben: [Color]) {
                var p = Path(); p.addLines(punkte.map { CGPoint(x: $0.x * g.width, y: $0.y * g.height) }); p.closeSubpath()
                ctx.fill(p, with: .linearGradient(Gradient(colors: farben), startPoint: .zero, endPoint: CGPoint(x: g.width, y: g.height)))
            }
            // Sternenstaub
            var z = Zufall(27)
            for _ in 0..<70 {
                let r = CGRect(x: 0.3 * g.width + z.zahl() * 0.4 * g.width, y: z.zahl() * 0.5 * g.height, width: 1.4, height: 1.4)
                ctx.fill(Path(ellipseIn: r), with: .color(.white.opacity(0.15 + z.zahl() * 0.4)))
            }
            wand([.init(x: 0, y: 0), .init(x: 0.36, y: 0), .init(x: 0.3, y: 0.22), .init(x: 0.22, y: 0.48), .init(x: 0.28, y: 0.74), .init(x: 0.12, y: 1), .init(x: 0, y: 1)],
                 [Color(0x39413A), Color(0x151816), Color(0x050605)])
            wand([.init(x: 1, y: 0), .init(x: 0.68, y: 0), .init(x: 0.74, y: 0.2), .init(x: 0.82, y: 0.44), .init(x: 0.76, y: 0.7), .init(x: 0.9, y: 1), .init(x: 1, y: 1)],
                 [Color(0x1B1F1C), Color(0x2F362F), Color(0x070807)])
            // Vorsprung, auf dem der Sockel steht
            wand([.init(x: 0.16, y: 0.8), .init(x: 0.34, y: 0.72), .init(x: 0.7, y: 0.73), .init(x: 0.86, y: 0.82), .init(x: 0.8, y: 1), .init(x: 0.2, y: 1)],
                 [Color(0x3A403B), Color(0x1A1D1B), Color(0x050605)])
        }
    }
}

private struct HomeWert: View {
    var titel: String
    var wert: String
    var body: some View {
        VStack(spacing: 6) {
            Text(titel.uppercased()).font(.system(.caption, weight: .medium)).tracking(0.6).foregroundStyle(DFarbe.zweitrangig)
            Text(wert).font(.system(.title2, weight: .semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Glaskarte des Vorbilds: Radius 28, dunkles Glas mit grünem Schimmer oben, feiner heller Rand.
struct GlasKarte<Inhalt: View>: View {
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(spacing: 0) { inhalt }
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [Color(0x232B25), Color(0x141615)], startPoint: .top, endPoint: .bottom))
            }
            .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.03)], startPoint: .top, endPoint: .bottom), lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

/// Serie (§18): Flamme groß, Zahl, „Tage in Folge“ – als Glas-Blatt.
private struct SerieBlatt: View {
    var serie: Int
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 10) {
            HStack { RundKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }; Spacer() }
            Image(systemName: "flame.fill").font(.system(size: 76))
                .foregroundStyle(LinearGradient(colors: [Color(0xFFE29A), Color(0xFF8A3D)], startPoint: .top, endPoint: .bottom))
                .shadow(color: Color(0xFFB347).opacity(0.7), radius: 24)
            Text("\(serie)").font(.system(size: 52, weight: .heavy)).foregroundStyle(Color(0xFFD27A))
            Text(serie == 1 ? "TAG IN FOLGE" : "TAGE IN FOLGE").font(.system(.title3, weight: .bold)).foregroundStyle(Color(0xFFC766))
            Text("Ein Tag zählt mit Fokus, allen Habits oder einem Journal-Eintrag.").font(DSchrift.unterzeile).foregroundStyle(Color(0xFFC766).opacity(0.85)).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(16)
        .presentationDetents([.height(380)])
        .glasBlatt()
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
        GlasKarte {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: fokus.habit != nil ? "repeat" : fokus.block?.art == .termin ? "calendar" : "scope")
                        .font(.system(size: 20, weight: .semibold)).foregroundStyle(DFarbe.akzent)
                        .frame(width: 44, height: 44).background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(titel).font(DSchrift.zeileFett).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                        Text(label).font(DSchrift.unterzeile).foregroundStyle(DFarbe.zweitrangig)
                    }
                    Spacer(minLength: 0)
                }
                knoepfe
                if fokus.gesamt > 0 {
                    let sek = z.sitzungen.filter { $0.tag == T }.reduce(0) { $0 + $1.sekunden } + z.timerSekunden(jetzt: speicher.jetzt())
                    Balken(anteil: Double(fokus.geschafft) / Double(fokus.gesamt), farbe: Color(Dunkel.akzentA), spur: Color.white.opacity(0.1))
                    Text("\(fokus.geschafft) von \(fokus.gesamt) geschafft · \(Zahl.dauer(sek)) Fokus").font(.system(.footnote)).foregroundStyle(DFarbe.zweitrangig)
                }
            }
            .padding(18)
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

    private var titel: String { fokus.block?.titel ?? fokus.aufgabe?.titel ?? fokus.habit?.titel ?? "Nichts mehr offen." }

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

/// Ein Signal (§12): Symbol im Kreis, Aussage, ein Fakt; Tipp führt zur Handlung. Lange drücken: „Passt nicht“.
private struct SignalZeile: View {
    var signal: Signale.Signal
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(spacing: 12) {
            SymbolKachel(symbol: signal.art.symbol, farbe: gut ? Farbe.akzent : Farbe.warnung)
            Button(action: oeffnen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text(signal.text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if signal.handlung == .aufHeute {
                Button("Auf heute", action: aufHeute).buttonStyle(.hauptKlein)
            } else {
                Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .frame(minHeight: Mass.zeile)
        .contextMenu {
            Button("Passt nicht – 8 Wochen ausblenden", systemImage: "eye.slash", action: stumm)
        }
        .accessibilityAction(named: "Passt nicht", stumm)
        .accessibilityIdentifier("signal.\(signal.art.rawValue)")
    }

    /// Gute Nachricht (Luft, Serie geschafft) in Akzent, alles andere als Warnung
    private var gut: Bool { signal.art == .luft || signal.art == .serieGeschafft }

    private func oeffnen() {
        switch signal.handlung {
        case .kalender(let d): nav.oeffneKalender(d)
        case .ziel(let id): nav.oeffneZiel(id)
        case .habit(let id): nav.oeffneHabit(id)
        case .habitAnalyse(let id): nav.zeigeAnalyse(habit: id)
        case .aufHeute: nav.oeffneKalender(nil)
        }
    }

    private func aufHeute() {
        let T = speicher.heute
        speicher.aendern { s in for i in s.aufgaben.indices where !s.aufgaben[i].erledigt && s.aufgaben[i].datum.map({ $0 < T }) == true { s.aufgaben[i].datum = T } }
    }

    private func stumm() {
        let art = signal.art.rawValue, bis = Signale.stummBis(heute: speicher.heute)
        speicher.aendern { $0.lernen.signaleStumm[art] = bis }
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
