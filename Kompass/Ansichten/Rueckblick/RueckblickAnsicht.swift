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
            VStack(spacing: 12) {
                ErkenntnisKarte(erkenntnis: erkenntnis(w: w, z: z, T: T))
                inhalt(w: w, z: z, T: T)
                WasZaehlt(text: Rueckschau.wasZaehlt(auswahl.art.rawValue))
            }
            .padding(.horizontal, Mass.rand).padding(.top, 12)
        }
    }

    /// Unterzeile einer Aufgabe: Ziel · Tag
    private func aufgabeUnter(_ a: Aufgabe, z: Zustand) -> String {
        var teile: [String] = []
        if let g = z.ziel(a.zielID) { teile.append(g.titel) }
        if let d = a.datum { teile.append(d.datum().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "de_DE")))) }
        return teile.joined(separator: " · ")
    }

    /// Der eine Satz zum Mitnehmen (§13) – je Analyse eine feste Regelfolge.
    private func erkenntnis(w: Statistik.Werte, z: Zustand, T: Tag) -> Rueckschau.Erkenntnis {
        switch auswahl.art {
        case .erledigt: Rueckschau.erkenntnisErledigt(geplantJeTag: w.bilanz.geplantJeTag, erledigtJeTag: w.bilanz.erledigtJeTag, tage: w.tage,
                                                         laufend: versatz == 0 && zeitraum == .woche ? T.wochentag - 1 : nil)
        case .habits: Rueckschau.erkenntnisHabits(zustand: z, von: w.von, bis: w.bis, heute: T)
        case .ziele: Rueckschau.erkenntnisZiele(zustand: z, von: w.von, bis: w.bis, heute: T)
        case .zeit: Rueckschau.erkenntnisZeit(fokus: w.fokus, fuerZiele: w.fokusFuerZiele)
        }
    }

    @ViewBuilder
    private func inhalt(w: Statistik.Werte, z: Zustand, T: Tag) -> some View {
        switch auswahl.art {
        case .erledigt:
            WeisseKarte(titel: "Pläne", wert: Zahl.prozent(w.bilanz.quote), unter: "\(w.bilanz.aufgabenErledigt) von \(w.bilanz.aufgabenGeplant) Aufgaben · Habits \(Zahl.prozent(w.habitQuote)) · \(w.bilanz.termine) Termine") {
                MiniSaeulen(werte: w.jeTag, hoehe: 56, farbe: Farbe.buehne, hervor: versatz == 0 && zeitraum == .woche ? T.wochentag - 1 : nil, gestreckt: true)
                HStack { ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { Text($0).frame(maxWidth: .infinity) } }.font(.caption2).foregroundStyle(Farbe.zweitrangig)
            }
            let liste = Rueckschau.aufgaben(zustand: z, von: w.von, bis: w.bis, heute: T)
            PostenListe(titel: "Noch offen", leer: "Nichts mehr offen.", posten: liste.offen.map { a in
                Posten(id: a.id.uuidString, symbol: a.prio == .hoch ? "exclamationmark" : "circle", titel: a.titel, unter: aufgabeUnter(a, z: z), wert: nil) { nav.blatt = .aufgabe(a.id) }
            })
            PostenListe(titel: "Erledigt", leer: "Noch nichts erledigt.", posten: liste.erledigt.map { a in
                Posten(id: a.id.uuidString, symbol: "checkmark", titel: a.titel, unter: aufgabeUnter(a, z: z), wert: a.fokusSekunden > 0 ? Zahl.dauer(a.fokusSekunden) : nil) { nav.blatt = .aufgabe(a.id) }
            })
        case .habits:
            AbschnittKopf(titel: "Je Habit") {
                Text("\(Zahl.text(w.bilanz.habitsErledigt, stellen: 0)) von \(w.bilanz.habitsGeplant) Tagen").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
            GruppierteListe {
                ForEach(z.habits) { h in
                    let q = HabitRechnung.quote(alle: [h], von: w.von, bis: w.bis, heute: T)
                    let anteil = q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0
                    StatistikZeile(symbol: h.symbol, farbe: Color(hex: h.farbe), titel: h.titel, anteil: anteil,
                                   wert: q.geplant > 0 ? Zahl.prozent(anteil) : "–") { nav.zeigeAnalyse(habit: h.id) }
                }
            }
        case .ziele:
            let aktiv = z.ziele.filter { $0.status == .aktiv }
            AbschnittKopf(titel: "Je Ziel") { EmptyView() }
            GruppierteListe {
                ForEach(aktiv) { g in
                    let k = Kurs.aufKurs(g, in: z, heute: T)
                    StatistikZeile(symbol: g.symbol, farbe: Color(hex: g.farbe), titel: g.titel, anteil: k.fortschritt,
                                   wert: "\(Zahl.prozent(k.fortschritt)) · \(k.lage.text)") { nav.zeigeAnalyse(ziel: g.id) }
                }
            }
            let jeZiel = z.ziele.map { ($0, Fortschritt.zeit(ziel: $0.id, in: z, von: w.von, bis: w.bis)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
            let ohne = max(0, w.fokus - w.fokusFuerZiele)
            let summe = jeZiel.reduce(0) { $0 + $1.1 } + ohne
            AbschnittKopf(titel: "Zeit je Ziel") {
                Text(summe > 0 ? Zahl.dauer(summe) : "–").font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.top, 8)
            if summe <= 0 {
                GruppierteListe { LeerZeile(text: "In diesem Zeitraum noch keine Zeit gebucht.") }
            } else {
                GruppierteListe {
                    // Ein Balken, aufgeteilt nach Zielen – die Verteilung auf einen Blick
                    AnteilsBalken(teile: jeZiel.map { (Color(hex: $0.0.farbe), $0.1) } + (ohne > 0 ? [(Farbe.linie, ohne)] : []))
                        .padding(16)
                    ForEach(jeZiel, id: \.0.id) { g, s in
                        StatistikZeile(symbol: g.symbol, farbe: Color(hex: g.farbe), titel: g.titel, anteil: s / summe,
                                       wert: "\(Zahl.dauer(s)) · \(Zahl.prozent(s / summe))") { nav.zeigeAnalyse(ziel: g.id) }
                    }
                    if ohne > 0 {
                        StatistikZeile(symbol: "circle.dashed", farbe: Farbe.zweitrangig, titel: "Ohne Ziel", anteil: ohne / summe,
                                       wert: "\(Zahl.dauer(ohne)) · \(Zahl.prozent(ohne / summe))", aktion: nil)
                    }
                }
            }
        case .zeit:
            WeisseKarte(titel: "Fokuszeit", wert: Zahl.dauer(w.fokus),
                        unter: "Ø \(Zahl.dauer(w.fokus / Double(w.tage))) pro Tag · \(w.fokus > 0 ? Int((w.fokusFuerZiele / w.fokus * 100).rounded()) : 0) % für Ziele") {
                Kurve(werte: w.zwoelfWochen, farbe: Farbe.akzent).frame(height: 64)
                HStack { Text("vor 12 Wochen"); Spacer(); Text("jetzt") }.font(.caption2).foregroundStyle(Farbe.zweitrangig)
            }
            let f = Rueckschau.fokus(zustand: z, von: w.von, bis: w.bis, heute: T)
            PostenListe(titel: "Im Fokus", leer: "Noch keine Zeit mit dem Timer gemessen.", posten: f.posten.map { p in
                Posten(id: p.id, symbol: "timer", titel: p.titel, unter: z.ziel(p.zielID)?.titel ?? "Ohne Ziel", wert: Zahl.dauer(p.sekunden),
                       aktion: UUID(uuidString: p.id).map { id in { nav.blatt = .aufgabe(id) } })
            })
            PostenListe(titel: "Ohne Timer erledigt", leer: "Alles Erledigte wurde gemessen.", posten: f.ohneTimer.map { a in
                Posten(id: a.id.uuidString, symbol: "checkmark", titel: a.titel, unter: aufgabeUnter(a, z: z), wert: nil) { nav.blatt = .aufgabe(a.id) }
            })

            let last = Rueckschau.auslastung(zustand: z, montag: w.bis.plus(tage: -6), termine: speicher.termine(am:))
            WeisseKarte(titel: "Auslastung", wert: "Ø \(Zahl.prozent(last.mittel))",
                        unter: "von 7–22 Uhr verplant · Linie = voll (75 %)", pfeil: { nav.oeffneKalender(w.bis, modus: .woche) }) {
                AuslastungsBalken(verplant: w.bilanz.verplant, heute: versatz == 0 && zeitraum == .woche ? T.wochentag - 1 : nil)
                Text("Termine \(Zahl.dauer(Double(last.termine) * 60)) · Aufgaben \(Zahl.dauer(Double(last.aufgaben) * 60)) · Habits \(Zahl.dauer(Double(last.habits) * 60))")
                    .font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.top, 4)
                Text(last.volleTage > 0 ? "Voll: \(Rueckschau.tagNamen[last.vollster]) · am meisten Luft: \(Rueckschau.tagNamen[last.leerster])"
                     : "Kein voller Tag · am meisten Luft: \(Rueckschau.tagNamen[last.leerster])")
                    .font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
            // Umplanen geht nur nach vorn: Vorschläge für die nächsten 7 Tage, nur in der laufenden Woche
            if versatz == 0 && zeitraum == .woche {
                let vor = Rueckschau.zeigen(Rueckschau.vorschlaege(zustand: z, heute: T, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:)), lernen: z.lernen)
                if !vor.isEmpty {
                    AbschnittKopf(titel: "Vorschläge").padding(.top, 4)
                    GruppierteListe { ForEach(vor) { VorschlagZeile(vorschlag: $0) } }
                }
            }
        }
    }
}

/// Das nimmst du mit: eine Aussage, ein Fakt, höchstens ein Weg (§13).
private struct ErkenntnisKarte: View {
    var erkenntnis: Rueckschau.Erkenntnis
    @Environment(Navigation.self) private var nav

    var body: some View {
        let tippbar = erkenntnis.ziel != .keins
        Button(action: oeffnen) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Etikett(text: "Das nimmst du mit")
                    Text(erkenntnis.titel).font(.kompass(.headline, .heavy)).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                    Text(erkenntnis.text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
                if tippbar { Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.akzentWeich, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(tippbar)
        .accessibilityIdentifier("rueckblick.erkenntnis")
    }

    private func oeffnen() {
        switch erkenntnis.ziel {
        case .keins: break
        case .kalender: nav.oeffneKalender(nil, modus: .woche)
        case .zielSeite(let id): nav.oeffneZiel(id)
        case .habitSeite(let id): nav.oeffneHabit(id)
        }
    }
}

/// Ein Eintrag einer konkreten Liste (Aufgabe, Fokus-Posten)
private struct Posten: Identifiable {
    var id: String
    var symbol: String
    var titel: String
    var unter: String
    var wert: String?
    var aktion: (() -> Void)?
}

/// Konkrete Liste mit Anzahl: zeigt die ersten drei, der Rest klappt auf (Hick).
private struct PostenListe: View {
    var titel: String
    var leer: String
    var posten: [Posten]
    @State private var alle = false

    var body: some View {
        AbschnittKopf(titel: titel) { Text("\(posten.count)").font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig) }
            .padding(.top, 4)
        GruppierteListe {
            if posten.isEmpty { LeerZeile(text: leer) }
            ForEach(alle ? posten : Array(posten.prefix(3))) { p in
                Button { p.aktion?() } label: {
                    HStack(spacing: 12) {
                        Image(systemName: p.symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(Farbe.akzent)
                            .frame(width: 30, height: 30).background(Farbe.akzentWeich, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                            if !p.unter.isEmpty { Text(p.unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1) }
                        }
                        Spacer(minLength: 4)
                        if let w = p.wert { Text(w).font(.unterzeile).monospacedDigit().foregroundStyle(Farbe.text) }
                    }
                    .padding(.horizontal, 14).frame(minHeight: Mass.zeile)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .allowsHitTesting(p.aktion != nil)
            }
            if posten.count > 3 {
                Button(alle ? "Weniger" : "Alle \(posten.count) zeigen") { withAnimation(.snappy(duration: 0.2)) { alle.toggle() } }
                    .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent).frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }
}

/// Vorschlag zum Umplanen: Übernehmen verschiebt die Aufgabe, „Passt nicht“ zählt als Ablehnung – beides lernt (§7).
private struct VorschlagZeile: View {
    var vorschlag: Rueckschau.Vorschlag
    @Environment(Speicher.self) private var speicher

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vorschlag.titel).font(.zeile).foregroundStyle(Farbe.text)
                Text(vorschlag.text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                Button("Übernehmen") { entscheiden(true) }.buttonStyle(.hauptKlein)
                Button("Passt nicht") { entscheiden(false) }.buttonStyle(.leiseKlein)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func entscheiden(_ ja: Bool) {
        let v = vorschlag
        speicher.aendern { s in
            var c = s.lernen.vorschlaege[v.schluessel] ?? Lernen.VorschlagZaehler()
            c.gezeigt += 1
            if ja {
                c.uebernommen += 1
                if let i = s.aufgaben.firstIndex(where: { $0.id == v.aufgabeID }) { s.aufgaben[i].datum = v.nach; s.aufgaben[i].uhrzeit = nil }
            }
            s.lernen.vorschlaege[v.schluessel] = c
        }
    }
}

/// „Was zählt hier?“ – ein Satz, erst auf Wunsch.
private struct WasZaehlt: View {
    var text: String
    @State private var offen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation(.snappy(duration: 0.2)) { offen.toggle() } } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Was zählt hier?")
                    Image(systemName: offen ? "chevron.up" : "chevron.down").font(.caption2.weight(.bold))
                }
                .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent).frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            if offen { Text(text).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Tippbare Zeile der Statistik: Zeichen im Farbkreis, Name und Wert, darunter der Balken, rechts der Pfeil.
/// Beim Drücken färbt sich die Zeile (`ZeilenDruck`) – man sieht, dass sie sich öffnen lässt.
private struct StatistikZeile: View {
    var symbol: String
    var farbe: Color
    var titel: String
    var anteil: Double
    var wert: String
    var aktion: (() -> Void)?

    var body: some View {
        if let aktion {
            Button(action: aktion) { inhalt(pfeil: true) }
                .buttonStyle(ZeilenDruck())
                .accessibilityLabel("\(titel), \(wert)")
                .accessibilityHint("Analyse öffnen")
        } else {
            inhalt(pfeil: false).accessibilityElement(children: .combine)
        }
    }

    private func inhalt(pfeil: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(Farbe.aufTon)
                .frame(width: 36, height: 36).background(farbe, in: Circle())
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(wert).font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                Balken(anteil: anteil, farbe: farbe, spur: Farbe.linie, hoehe: 6)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil).opacity(pfeil ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 66)
        .contentShape(Rectangle())
    }
}

/// Druckzustand für Listenzeilen: weich hinterlegt und minimal kleiner.
private struct ZeilenDruck: ButtonStyle {
    func makeBody(configuration c: Configuration) -> some View {
        c.label
            .background(Farbe.akzentWeich.opacity(c.isPressed ? 1 : 0))
            .scaleEffect(c.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: c.isPressed)
    }
}

/// Ein Balken, in Teile nach Anteil aufgeteilt (Zeit je Ziel).
private struct AnteilsBalken: View {
    var teile: [(Color, Double)]
    var body: some View {
        let summe = max(teile.reduce(0) { $0 + $1.1 }, 0.0001)
        GeometryReader { g in
            HStack(spacing: 2) {
                ForEach(Array(teile.enumerated()), id: \.offset) { _, t in
                    RoundedRectangle(cornerRadius: 3, style: .continuous).fill(t.0)
                        .frame(width: max(3, (g.size.width - CGFloat(teile.count - 1) * 2) * t.1 / summe))
                }
            }
        }
        .frame(height: 14)
        .clipShape(Capsule())
        .accessibilityHidden(true)
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
