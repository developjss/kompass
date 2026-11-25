import Charts
import SwiftUI

/// Rückblick (Nachtblau, Hick): Bühne mit dem Wochenwort (§11), darunter genau vier Kacheln – Erledigt, Habits, Ziele, Zeit –
/// als Vorschau. Antippen öffnet die Statistik mit Zeitraum (Woche · Monat · Jahr) und Blättern. Unten die Wochenreflexion.
struct RueckblickAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let w = Statistik.werte(zustand: z, heute: T, wochen: 1, versatz: 0, termine: speicher.termine(am:))
        let (zeile, akzent) = Wochenwort.wort(w.lage)

        BuehnenSeite(wort: Wort(zeilen: [zeile], akzent: akzent), fuss: false, marke: {
            Spacer(minLength: 8)
            RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.rueckblick) }
            RahmenKnopf(symbol: "gearshape", beschriftung: "Einstellungen") { nav.blatt = .einstellungen }
        }) {
            // Vier Kacheln – die wichtigsten Dinge der App: Pläne, Habits, Ziele, Zeit
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Statistik.Art.allCases, id: \.self) { art in
                    NavigationLink(value: StatistikAuswahl(art: art)) { StatistikKachel(art: art, werte: w, heute: T.wochentag - 1) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(art.titel): \(art.zahl(w)). \(art.satz(w))")
                        .accessibilityHint("Öffnet die Statistik")
                }
            }
            .padding(.horizontal, Mass.rand)
            .padding(.top, Mass.karteVornVersatz)

            PfeilZeile(symbol: "moon", text: z.reflexionen["woche:\(T.montag.text)"] == nil ? "Wochenreflexion · 3 Fragen" : "Wochenreflexion ✓") {
                nav.blatt = .reflexion(woche: true)
            }
            .padding(.horizontal, Mass.rand).padding(.top, Mass.abschnitt)
        }
    }
}

/// Für NavigationLink(value:) auf eine Statistik
struct StatistikAuswahl: Hashable {
    var art: Statistik.Art
}

/// Die Zahlen des Rückblicks für einen Zeitraum (Wochen ab Montag, zurück um `versatz` Zeiträume). Nur Rechnung aus `Tagesplan`, `Kurs`, `Fortschritt`.
enum Statistik {
    enum Art: String, CaseIterable, Hashable, Sendable {
        case erledigt, habits, ziele, zeit
        var titel: String { switch self { case .erledigt: "Erledigt"; case .habits: "Habits"; case .ziele: "Ziele"; case .zeit: "Zeit" } }
        var symbol: String { switch self { case .erledigt: "checkmark.circle"; case .habits: "repeat"; case .ziele: "target"; case .zeit: "clock" } }

        func zahl(_ w: Werte) -> String {
            switch self {
            case .erledigt: Zahl.prozent(w.bilanz.quote)
            case .habits: w.bilanz.habitsGeplant > 0 ? Zahl.prozent(w.habitQuote) : "–"
            case .ziele: "\(w.zieleAufKurs) von \(w.zieleGesamt)"
            case .zeit: Zahl.dauer(w.fokus)
            }
        }
        /// Ein Satz in einfacher Sprache
        func satz(_ w: Werte) -> String {
            switch self {
            case .erledigt: "\(w.bilanz.aufgabenErledigt) von \(w.bilanz.aufgabenGeplant) Aufgaben geschafft"
            case .habits: w.bilanz.habitsGeplant > 0 ? "\(Zahl.text(w.bilanz.habitsErledigt, stellen: 0)) von \(w.bilanz.habitsGeplant) Habit-Tagen" : "keine Habits geplant"
            case .ziele: w.zieleGesamt > 0 ? "auf Kurs · Ø \(Zahl.prozent(w.fortschrittMittel)) Fortschritt" : "noch kein Ziel"
            case .zeit: "Fokus · \(w.volleTage == 0 ? "kein voller Tag" : "\(w.volleTage) volle Tage")"
            }
        }
        /// Das Wort auf der Bühne der Statistik-Seite
        func wort(_ w: Werte) -> Wort {
            switch self {
            case .erledigt: Wort(zeilen: [Zahl.prozent(w.bilanz.quote)], akzent: "erledigt.", groesse: Wort.kleinGroesse)
            case .habits: Wort(zeilen: ["Habits"], akzent: w.bilanz.habitsGeplant > 0 ? Zahl.prozent(w.habitQuote) + "." : "offen.", groesse: Wort.kleinGroesse)
            case .ziele: Wort(zeilen: ["\(w.zieleAufKurs) von \(w.zieleGesamt)"], akzent: "auf Kurs.", groesse: Wort.kleinGroesse)
            case .zeit: Wort(zeilen: [Zahl.dauer(w.fokus)], akzent: "Fokus.", groesse: Wort.kleinGroesse)
            }
        }
    }

    enum Zeitraum: String, CaseIterable, Sendable {
        case woche, monat, jahr
        var titel: String { switch self { case .woche: "Woche"; case .monat: "Monat"; case .jahr: "Jahr" } }
        var wochen: Int { switch self { case .woche: 1; case .monat: 4; case .jahr: 52 } }
    }

    struct Werte {
        var von: Tag
        var bis: Tag
        var bilanz: Tagesplan.Wochenbilanz
        var habitQuote: Double
        var zieleAufKurs: Int
        var zieleGesamt: Int
        var fortschrittMittel: Double
        var fokus: TimeInterval
        var fokusFuerZiele: TimeInterval
        var tage: Int
        var volleTage: Int
        /// Erledigt-Anteil je Tag der letzten Woche des Zeitraums (für die kleinen Säulen)
        var jeTag: [Double]
        var auslastungJeTag: [Double]
        /// Fortschritt je aktives Ziel (für die kleinen Säulen)
        var fortschrittJeZiel: [Double]
        var zieleFarben: [String]
        /// Fokusstunden je Woche, die letzten 12 Wochen bis zum Ende des Zeitraums
        var zwoelfWochen: [Double]
        var zeitraumText: String
        var lage: Wochenwort.Lage
    }

    /// Zeitraum: `wochen` Wochen, deren letzte um `versatz` Zeiträume zurückliegt.
    static func werte(zustand z: Zustand, heute T: Tag, wochen: Int, versatz: Int, termine: (Tag) -> [Termin]) -> Werte {
        let letzterMontag = T.montag.plus(tage: -7 * wochen * versatz)
        let von = letzterMontag.plus(tage: -7 * (wochen - 1)), bis = letzterMontag.plus(tage: 6)
        var bilanz = Tagesplan.Wochenbilanz(aufgabenGeplant: 0, aufgabenErledigt: 0, habitsGeplant: 0, habitsErledigt: 0, termine: 0,
                                            verplant: Array(repeating: 0, count: 7), geplantJeTag: Array(repeating: 0, count: 7), erledigtJeTag: Array(repeating: 0, count: 7))
        var letzte: Tagesplan.Wochenbilanz?
        var volle = 0
        let wach = Double(Tagesplan.wachBis - Tagesplan.wachVon)
        for k in 0..<wochen {
            let m = von.plus(tage: 7 * k)
            let b = Tagesplan.woche(zustand: z, montag: m, heute: T, termine: termine)
            bilanz.aufgabenGeplant += b.aufgabenGeplant; bilanz.aufgabenErledigt += b.aufgabenErledigt
            bilanz.habitsGeplant += b.habitsGeplant; bilanz.habitsErledigt += b.habitsErledigt; bilanz.termine += b.termine
            for i in 0..<7 { bilanz.verplant[i] = max(bilanz.verplant[i], b.verplant[i]); bilanz.geplantJeTag[i] += b.geplantJeTag[i]; bilanz.erledigtJeTag[i] += b.erledigtJeTag[i] }
            volle += b.verplant.filter { Double($0) / wach >= 0.75 }.count
            letzte = b
        }
        let sitzungen = z.sitzungen.filter { $0.tag >= von && $0.tag <= bis }
        let fokus = sitzungen.reduce(0) { $0 + $1.sekunden }
        let fuerZiele = sitzungen.filter { $0.zielID != nil }.reduce(0) { $0 + $1.sekunden }
        let aktiv = z.ziele.filter { $0.status == .aktiv }
        let kurse = aktiv.map { Kurs.aufKurs($0, in: z, heute: T) }
        let aufKurs = kurse.filter { $0.lage == .imPlan || $0.lage == .voraus }.count
        let mittel = kurse.isEmpty ? 0 : kurse.map(\.fortschritt).reduce(0, +) / Double(kurse.count)
        let tage = max(1, (0..<(7 * wochen)).filter { von.plus(tage: $0) <= T }.count)
        let habitQuote = bilanz.habitsGeplant > 0 ? bilanz.habitsErledigt / Double(bilanz.habitsGeplant) : 0
        let l = letzte ?? bilanz
        let jeTag = (0..<7).map { i in l.geplantJeTag[i] > 0 ? l.erledigtJeTag[i] / l.geplantJeTag[i] : 0 }
        let auslastung = (0..<7).map { min(1, Double(l.verplant[$0]) / wach) }
        let mitDaten = (0..<7).filter { l.geplantJeTag[$0] > 0 || l.verplant[$0] > 0 }.count
        let lage = Wochenwort.Lage(quote: bilanz.quote, habitQuote: habitQuote, zieleAufKurs: aufKurs, zieleGesamt: aktiv.count,
                                   auslastung: auslastung.max() ?? 0, tageMitDaten: mitDaten)
        let f = { (t: Tag) in t.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE"))) }
        return Werte(von: von, bis: bis, bilanz: bilanz, habitQuote: habitQuote, zieleAufKurs: aufKurs, zieleGesamt: aktiv.count, fortschrittMittel: mittel,
                     fokus: fokus, fokusFuerZiele: fuerZiele, tage: tage, volleTage: volle, jeTag: jeTag, auslastungJeTag: auslastung, fortschrittJeZiel: kurse.map(\.fortschritt), zieleFarben: aktiv.map(\.farbe),
                     zwoelfWochen: (0..<12).map { k -> Double in let a = bis.plus(tage: -7 * (11 - k) - 6); return z.sitzungen.filter { $0.tag >= a && $0.tag <= a.plus(tage: 6) }.reduce(0) { $0 + $1.sekunden } / 3600 },
                     zeitraumText: "\(f(von)) – \(f(bis))", lage: lage)
    }
}

/// Eine der vier Kacheln: Titel, Zahl, ein Satz, kleine Säulen – alles Vorschau, nichts zum Bedienen außer Antippen.
private struct StatistikKachel: View {
    var art: Statistik.Art
    var werte: Statistik.Werte
    var heute: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: art.symbol).font(.caption.weight(.heavy))
                Etikett(text: art.titel)
                Spacer()
                Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
            }
            .foregroundStyle(Farbe.zweitrangig)
            Text(art.zahl(werte)).font(.system(size: 32, weight: .regular, design: .serif)).foregroundStyle(Farbe.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            KachelGrafik(art: art, werte: werte, heute: heute)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Farbe.schatten.opacity(0.10), radius: 5, y: 4)
        .shadow(color: Farbe.schatten.opacity(0.22), radius: 20, y: 18)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Die Grafik je Kachel – sofort lesbar, ohne Beschriftung: Erledigt = sieben Tage, Habits = Ring, Ziele = ein Balken je Ziel, Zeit = Kurve der 12 Wochen.
private struct KachelGrafik: View {
    var art: Statistik.Art
    var werte: Statistik.Werte
    var heute: Int?
    var body: some View {
        switch art {
        case .erledigt:
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<7, id: \.self) { i in
                    let v = werte.jeTag[i]
                    let geplant = werte.bilanz.geplantJeTag[i] > 0
                    Capsule().fill(heute == i ? Farbe.jetzt : (geplant ? Farbe.buehne.opacity(0.35 + 0.65 * v) : Farbe.linie))
                        .frame(height: max(6, 34 * (geplant ? max(v, 0.18) : 0.18)))
                        .frame(maxWidth: .infinity, maxHeight: 34, alignment: .bottom)
                }
            }
            .frame(height: 34)
        case .habits:
            HStack(spacing: 10) {
                FortschrittRing(anteil: werte.habitQuote, text: "")
                    .scaleEffect(0.68).frame(width: 38, height: 38)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Circle().fill(werte.jeTag[i] >= 0.999 ? Farbe.buehne : werte.jeTag[i] > 0 ? Farbe.buehne.opacity(0.4) : Farbe.linie)
                            .frame(width: 7, height: 7)
                    }
                }
            }
            .frame(height: 34)
        case .ziele:
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(werte.zieleFarben.prefix(4).enumerated()), id: \.offset) { i, f in
                    Balken(anteil: werte.fortschrittJeZiel[i], farbe: Color(hex: f), spur: Farbe.linie, hoehe: 5)
                }
            }
            .frame(height: 34, alignment: .bottom)
        case .zeit:
            Kurve(werte: werte.zwoelfWochen, farbe: Farbe.buehne).frame(height: 34)
        }
    }
}

/// Die Statistik-Seite: Bühne mit dem Wort, Karte vorn mit Zeitraum und Blättern, darunter die Karten der Statistik.
struct StatistikSeite: View {
    var auswahl: StatistikAuswahl
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var zeitraum: Statistik.Zeitraum = .woche
    @State private var versatz = 0

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let w = Statistik.werte(zustand: z, heute: T, wochen: zeitraum.wochen, versatz: versatz, termine: speicher.termine(am:))
        BuehnenSeite(hoehe: Mass.buehneKurz, wort: auswahl.art.wort(w), fuss: false, marke: {
            RahmenKnopf(symbol: "chevron.left", beschriftung: "Zurück") { dismiss() }
            MarkenTitel(text: auswahl.art.titel)
            Spacer(minLength: 8)
            MarkenHinweis(text: w.zeitraumText)
        }) {
            VornKarte(abstand: 10) {
                Picker("Zeitraum", selection: $zeitraum) {
                    ForEach(Statistik.Zeitraum.allCases, id: \.self) { Text($0.titel).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: zeitraum) { _, _ in versatz = 0 }
                HStack {
                    Button { versatz += 1 } label: { Label("Zurück", systemImage: "chevron.left") }.buttonStyle(.leiseKlein)
                    Spacer()
                    if versatz != 0 { Button("Jetzt") { versatz = 0 }.buttonStyle(.leiseKlein) }
                    Spacer()
                    Button { versatz = max(0, versatz - 1) } label: { Label("Vor", systemImage: "chevron.right") }.buttonStyle(.leiseKlein).disabled(versatz == 0)
                }
            }
            VStack(spacing: 12) { inhalt(w: w, z: z, T: T) }
                .padding(.horizontal, Mass.rand).padding(.top, 12)
        }
    }

    @ViewBuilder
    private func inhalt(w: Statistik.Werte, z: Zustand, T: Tag) -> some View {
        switch auswahl.art {
        case .erledigt:
            WeisseKarte(titel: "Pläne", wert: Zahl.prozent(w.bilanz.quote), unter: "\(w.bilanz.aufgabenErledigt) von \(w.bilanz.aufgabenGeplant) Aufgaben · Habits \(Zahl.prozent(w.habitQuote)) · \(w.bilanz.termine) Termine") {
                MiniSaeulen(werte: w.jeTag, hoehe: 56, farbe: Farbe.buehne, hervor: versatz == 0 && zeitraum == .woche ? T.wochentag - 1 : nil)
                HStack { ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { Text($0).frame(maxWidth: .infinity) } }.font(.caption2).foregroundStyle(Farbe.zweitrangig)
            }
        case .habits:
            WeisseKarte(titel: "Habits", wert: w.bilanz.habitsGeplant > 0 ? Zahl.prozent(w.habitQuote) : "–",
                        unter: "\(Zahl.text(w.bilanz.habitsErledigt, stellen: 1)) von \(w.bilanz.habitsGeplant) geplanten Tagen", pfeil: { nav.zeige(.habits) }) {
                VStack(spacing: 8) {
                    ForEach(z.habits) { h in
                        let q = HabitRechnung.quote(alle: [h], von: w.von, bis: w.bis, heute: T)
                        Button { nav.zeigeAnalyse(habit: h.id) } label: { HStack(spacing: 8) {
                            Text(h.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(width: 120, alignment: .leading)
                            Balken(anteil: q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0, farbe: Color(hex: h.farbe), spur: Farbe.linie, hoehe: 6)
                            Text(q.geplant > 0 ? Zahl.prozent(q.erledigt / Double(q.geplant)) : "–").font(.klein).monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.8).foregroundStyle(Farbe.zweitrangig).frame(width: 50, alignment: .trailing)
                            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .frame(minHeight: 32).contentShape(Rectangle()) }
                        .buttonStyle(.plain)
                        .accessibilityHint("Analyse öffnen")
                    }
                }
            }
        case .ziele:
            let aktiv = z.ziele.filter { $0.status == .aktiv }
            WeisseKarte(titel: "Ziele", wert: "\(w.zieleAufKurs) von \(w.zieleGesamt)", unter: "auf Kurs · Antippen für Verlauf, Prognose und Einsatz") {
                VStack(spacing: 8) {
                    ForEach(aktiv) { g in
                        let k = Kurs.aufKurs(g, in: z, heute: T)
                        Button { nav.zeigeAnalyse(ziel: g.id) } label: {
                            HStack(spacing: 8) {
                                Text(g.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(width: 120, alignment: .leading)
                                Balken(anteil: k.fortschritt, farbe: Color(hex: g.farbe), spur: Farbe.linie, hoehe: 6)
                                Text(k.lage.text).font(.klein).foregroundStyle(Farbe.zweitrangig).frame(width: 74, alignment: .trailing)
                                Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
                            }
                            .frame(minHeight: 32).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(g.titel), \(Zahl.prozent(k.fortschritt)), \(k.lage.text)")
                    }
                }
            }
            let jeZiel = z.ziele.map { ($0, Fortschritt.zeit(ziel: $0.id, in: z, von: w.von, bis: w.bis)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
            WeisseKarte(titel: "Zeit je Ziel", wert: jeZiel.isEmpty ? "–" : Zahl.dauer(jeZiel.reduce(0) { $0 + $1.1 }),
                        unter: jeZiel.isEmpty ? "Noch keine Zeit für Ziele in diesem Zeitraum." : "Fokus und zugeordnete Termine") {
                if !jeZiel.isEmpty {
                    HStack(spacing: 16) {
                        Chart(jeZiel, id: \.0.id) { g, s in
                            SectorMark(angle: .value("Zeit", s), innerRadius: .ratio(0.62), angularInset: 1.5).foregroundStyle(Color(hex: g.farbe))
                        }
                        .frame(width: 84, height: 84).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(jeZiel.prefix(4), id: \.0.id) { g, s in
                                HStack(spacing: 6) {
                                    Circle().fill(Color(hex: g.farbe)).frame(width: 8, height: 8)
                                    Text(g.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1)
                                    Spacer(minLength: 4)
                                    Text(Zahl.dauer(s)).font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig)
                                }
                            }
                        }
                    }
                }
            }
        case .zeit:
            WeisseKarte(titel: "Fokuszeit", wert: Zahl.dauer(w.fokus),
                        unter: "Ø \(Zahl.dauer(w.fokus / Double(w.tage))) pro Tag · \(w.fokus > 0 ? Int((w.fokusFuerZiele / w.fokus * 100).rounded()) : 0) % für Ziele") {
                Kurve(werte: w.zwoelfWochen, farbe: Farbe.akzent).frame(height: 64)
                HStack { Text("vor 12 Wochen"); Spacer(); Text("jetzt") }.font(.caption2).foregroundStyle(Farbe.zweitrangig)
            }
            WeisseKarte(titel: "Auslastung", wert: Zahl.dauer(TimeInterval(w.bilanz.verplant.reduce(0, +) * 60)),
                        unter: "verplant (7–22 Uhr) · Linie = voller Tag", pfeil: { nav.oeffneKalender(w.bis, modus: .woche) }) {
                AuslastungsBalken(verplant: w.bilanz.verplant, heute: versatz == 0 && zeitraum == .woche ? T.wochentag - 1 : nil)
            }
        }
    }
}

/// Weiße Karte im Gapless-Stil: Titel (fett) + Pfeil, große Zahl, eine Unterzeile, Inhalt.
struct WeisseKarte<Inhalt: View>: View {
    var titel: String
    var wert: String
    var unter: String
    var pfeil: (() -> Void)? = nil
    @ViewBuilder var inhalt: Inhalt

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titel).font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                Spacer()
                if let pfeil {
                    Button(action: pfeil) { Image(systemName: "chevron.right").font(.body.weight(.semibold)).foregroundStyle(Farbe.pfeil).frame(width: 44, height: 32) }
                        .accessibilityLabel("\(titel) öffnen")
                }
            }
            Text(wert).font(.kompass(.title, .heavy)).foregroundStyle(Farbe.text).monospacedDigit().contentTransition(.numericText())
            Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            inhalt.padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
    }
}

/// Säulen je Wochentag: verplante Stunden, gestrichelte Linie bei 75 % (voller Tag).
private struct AuslastungsBalken: View {
    var verplant: [Int]
    var heute: Int?
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let wach = Double(Tagesplan.wachBis - Tagesplan.wachVon)

    var body: some View {
        let h: CGFloat = 90
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<7, id: \.self) { i in
                    let a = min(1, Double(verplant[i]) / wach)
                    VStack(spacing: 4) {
                        Capsule().fill(a >= 0.75 ? Farbe.warnung : (heute == i ? Farbe.akzent : Farbe.akzent.opacity(0.45)))
                            .frame(height: max(4, h * a))
                            .frame(height: h, alignment: .bottom)
                        Text(namen[i]).font(.caption2.weight(.semibold)).foregroundStyle(heute == i ? Farbe.akzent : Farbe.zweitrangig)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(namen[i]): \(verplant[i] / 60) Stunden verplant")
                }
            }
            Rectangle().fill(Farbe.warnung.opacity(0.6)).frame(height: 1)
                .offset(y: -(h * 0.75) - 18)
                .accessibilityHidden(true)
        }
    }
}

/// Tagesabschluss oder Wochenreflexion: drei Fragen, gespeichert je Tag bzw. Woche.
struct ReflexionBlatt: View {
    var woche: Bool
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var antworten: [String: String] = [:]

    private var fragen: [(String, String)] {
        woche ? [("fortschritt", "Wo bin ich meinen Zielen nähergekommen?"), ("lernen", "Was würde ich anders machen?"), ("fokus", "Worauf lege ich nächste Woche den Fokus?")]
              : [("gut", "Was lief heute gut?"), ("ablenkung", "Was hat mich abgelenkt?"), ("morgen", "Was ist morgen das Wichtigste?")]
    }

    private var schluessel: String { woche ? "woche:\(speicher.heute.montag.text)" : "tag:\(speicher.heute.text)" }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(fragen, id: \.0) { k, frage in
                    Section(frage) {
                        TextField("Antwort", text: Binding(get: { antworten[k] ?? "" }, set: { antworten[k] = $0 }), axis: .vertical)
                    }
                }
            }
            .navigationTitle(woche ? "Wochenreflexion" : "Tagesabschluss")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let k = schluessel, a = antworten
                        speicher.aendern { $0.reflexionen[k] = Reflexion(antworten: a) }
                        dismiss()
                    }
                }
            }
            .onAppear { antworten = speicher.zustand.reflexionen[schluessel]?.antworten ?? [:] }
        }
    }
}
