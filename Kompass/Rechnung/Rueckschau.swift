import Foundation

// rechenregeln.md §13 – Rückblick konkret: was erledigt wurde und was nicht, was im Fokus lag,
// woraus die Auslastung besteht, was sich umplanen lässt und was man aus jeder Analyse mitnimmt.
// Nur Rechnung, keine KI. Gelernt wird allein über die Übernahme-Quote (§7).

enum Rueckschau {

    // MARK: Erledigt und offen

    struct Aufgabenliste: Equatable, Sendable {
        var erledigt: [Aufgabe]
        var offen: [Aufgabe]
    }

    /// Aufgaben mit Datum im Zeitraum (bis heute). Erledigt: erst mit Ziel, dann mehr Fokuszeit, dann neuer.
    /// Offen: erst hohe Priorität, dann mit Ziel, dann älter – das Dringendste steht oben.
    static func aufgaben(zustand z: Zustand, von: Tag, bis: Tag, heute T: Tag) -> Aufgabenliste {
        let ende = min(bis, T)
        let alle = z.aufgaben.filter { a in a.datum.map { $0 >= von && $0 <= ende } == true }
        let erledigt = alle.filter(\.erledigt).sorted { a, b in
            if (a.zielID != nil) != (b.zielID != nil) { return a.zielID != nil }
            if a.fokusSekunden != b.fokusSekunden { return a.fokusSekunden > b.fokusSekunden }
            if a.datum != b.datum { return (a.datum ?? von) > (b.datum ?? von) }
            return a.titel < b.titel
        }
        let offen = alle.filter { !$0.erledigt }.sorted { a, b in
            if (a.prio == .hoch) != (b.prio == .hoch) { return a.prio == .hoch }
            if (a.zielID != nil) != (b.zielID != nil) { return a.zielID != nil }
            if a.datum != b.datum { return (a.datum ?? von) < (b.datum ?? von) }
            return a.titel < b.titel
        }
        return Aufgabenliste(erledigt: erledigt, offen: offen)
    }

    // MARK: Fokus

    struct FokusPosten: Identifiable, Equatable, Sendable {
        var id: String
        var titel: String
        var zielID: UUID?
        var sekunden: TimeInterval
    }

    struct Fokus: Equatable, Sendable {
        /// Gemessene Fokuszeit je Aufgabe, längste zuerst
        var posten: [FokusPosten]
        /// Im Zeitraum erledigt, aber nie mit dem Timer gemessen
        var ohneTimer: [Aufgabe]
        var summe: TimeInterval
    }

    /// Fokuszeit = Sitzungen des Timers im Zeitraum, je Aufgabe zusammengezählt. Sitzungen ohne Aufgabe (oder gelöschte) laufen als „Ohne Aufgabe“.
    static func fokus(zustand z: Zustand, von: Tag, bis: Tag, heute T: Tag) -> Fokus {
        let sitzungen = z.sitzungen.filter { $0.tag >= von && $0.tag <= bis }
        var je: [UUID: TimeInterval] = [:], frei: TimeInterval = 0
        for s in sitzungen {
            if let id = s.aufgabeID, z.aufgaben.contains(where: { $0.id == id }) { je[id, default: 0] += s.sekunden } else { frei += s.sekunden }
        }
        var posten = je.compactMap { id, sek -> FokusPosten? in
            guard let a = z.aufgaben.first(where: { $0.id == id }) else { return nil }
            return FokusPosten(id: id.uuidString, titel: a.titel, zielID: a.zielID, sekunden: sek)
        }
        .sorted { $0.sekunden != $1.sekunden ? $0.sekunden > $1.sekunden : $0.titel < $1.titel }
        if frei > 0 { posten.append(FokusPosten(id: "frei", titel: "Ohne Aufgabe", zielID: nil, sekunden: frei)) }
        let ohne = aufgaben(zustand: z, von: von, bis: bis, heute: T).erledigt.filter { je[$0.id] == nil && $0.fokusSekunden <= 0 }
        return Fokus(posten: posten, ohneTimer: ohne, summe: sitzungen.reduce(0) { $0 + $1.sekunden })
    }

    // MARK: Auslastung

    struct Auslastung: Equatable, Sendable {
        /// Mittel der Tagesanteile (verplant ÷ wach 7–22 Uhr)
        var mittel: Double
        /// Index 0…6 des vollsten und leersten Tages
        var vollster: Int
        var leerster: Int
        var volleTage: Int
        /// Minuten je Art (Blöcke mit Uhrzeit in der wachen Zeit, Überschneidungen zählen doppelt)
        var termine: Int
        var aufgaben: Int
        var habits: Int
    }

    static let vollAb = 0.75
    static let wach = Tagesplan.wachBis - Tagesplan.wachVon

    static func auslastung(zustand z: Zustand, montag: Tag, termine: (Tag) -> [Termin]) -> Auslastung {
        var anteile: [Double] = [], t = 0, a = 0, h = 0
        for i in 0..<7 {
            let d = montag.plus(tage: i)
            let b = Tagesplan.bloecke(am: d, zustand: z, termine: termine(d))
            let iv = Tagesplan.vereinigt(b.map { (max($0.start, Tagesplan.wachVon), min($0.ende, Tagesplan.wachBis)) }.filter { $0.1 > $0.0 })
            anteile.append(Double(iv.reduce(0) { $0 + $1.1 - $1.0 }) / Double(wach))
            for x in b {
                let m = max(0, min(x.ende, Tagesplan.wachBis) - max(x.start, Tagesplan.wachVon))
                switch x.art { case .termin: t += m; case .aufgabe: a += m; case .habit: h += m }
            }
        }
        let voll = anteile.indices.max { anteile[$0] < anteile[$1] } ?? 0
        let leer = anteile.indices.min { anteile[$0] < anteile[$1] } ?? 0
        return Auslastung(mittel: anteile.reduce(0, +) / 7, vollster: voll, leerster: leer, volleTage: anteile.filter { $0 >= vollAb }.count,
                          termine: t, aufgaben: a, habits: h)
    }

    // MARK: Vorschläge zum Umplanen (nur ab heute)

    struct Vorschlag: Identifiable, Equatable, Sendable {
        enum Art: String, CaseIterable, Sendable { case entlasten, luftNutzen }
        var art: Art
        var aufgabeID: UUID
        var nach: Tag
        var titel: String
        var text: String
        var id: String { "\(art.rawValue):\(aufgabeID.uuidString)" }
        /// Schlüssel fürs Lernen (`lernen.vorschlaege`)
        var schluessel: String { Rueckschau.schluessel(art) }
    }

    static func schluessel(_ art: Vorschlag.Art) -> String { "auslastung.\(art.rawValue)" }
    static let luftBis = 0.25
    static let zielBis = 0.6
    /// Unter dieser Übernahme-Quote (§7) wird eine Vorschlags-Art nicht mehr gezeigt – nach drei Ablehnungen ohne Übernahme.
    static let zeigenAb = 0.25

    /// Für die nächsten 7 Tage ab heute, höchstens einer je Art:
    /// entlasten – die längste offene Aufgabe eines vollen Tages (≥ 75 %) auf den leersten Tag, wenn der danach ≤ 60 % hat;
    /// Luft nutzen – die wichtigste Aufgabe ohne Datum auf den ersten Tag ab morgen mit ≤ 25 %.
    static func vorschlaege(zustand z: Zustand, heute T: Tag, jetzt: Int, termine: (Tag) -> [Termin]) -> [Vorschlag] {
        var out: [Vorschlag] = []
        let tage = (0...6).map { T.plus(tage: $0) }
        let bloecke = tage.enumerated().map { i, d in
            Tagesplan.bloecke(am: d, zustand: z, termine: termine(d)).filter { !$0.erledigt && (i > 0 || $0.ende > jetzt) }
        }
        let anteile = bloecke.enumerated().map { i, b in Tagesplan.auslastung(b, ab: i == 0 ? max(jetzt, Tagesplan.wachVon) : Tagesplan.wachVon).anteil }

        if let voll = anteile.indices.first(where: { anteile[$0] >= vollAb }),
           let last = bloecke[voll].filter({ $0.art == .aufgabe && $0.aufgabeID != nil }).max(by: { ($0.dauer, $1.titel) < ($1.dauer, $0.titel) }),
           let ziel = anteile.indices.filter({ $0 != voll && $0 > 0 }).min(by: { (anteile[$0], $0) < (anteile[$1], $1) }),
           anteile[ziel] + Double(last.dauer) / Double(wach) <= zielBis, let id = last.aufgabeID {
            out.append(Vorschlag(art: .entlasten, aufgabeID: id, nach: tage[ziel],
                                 titel: "\(tagWort(tage[voll], heute: T)) entlasten",
                                 text: "„\(last.titel)“ (\(Zahl.dauer(Double(last.dauer) * 60))) auf \(tagWort(tage[ziel], heute: T))"))
        }
        let ohneDatum = z.aufgaben.filter { !$0.erledigt && $0.datum == nil }
            .sorted { a, b in
                if (a.prio == .hoch) != (b.prio == .hoch) { return a.prio == .hoch }
                if (a.zielID != nil) != (b.zielID != nil) { return a.zielID != nil }
                return (a.reihenfolge, a.titel) < (b.reihenfolge, b.titel)
            }
        if let a = ohneDatum.first, let frei = anteile.indices.first(where: { $0 > 0 && anteile[$0] <= luftBis }) {
            out.append(Vorschlag(art: .luftNutzen, aufgabeID: a.id, nach: tage[frei],
                                 titel: "\(tagWort(tage[frei], heute: T)) ist Luft",
                                 text: "„\(a.titel)“ einplanen · \(ohneDatum.count) ohne Datum"))
        }
        return out
    }

    /// Was gezeigt wird: Arten, deren Übernahme-Quote (§7) nicht unter 25 % liegt – die mit der höheren Quote zuerst.
    static func zeigen(_ v: [Vorschlag], lernen: Lernen) -> [Vorschlag] {
        func quote(_ x: Vorschlag) -> Double {
            let c = lernen.vorschlaege[x.schluessel] ?? Lernen.VorschlagZaehler()
            return LernRechnung.uebernahmeQuote(gezeigt: c.gezeigt, uebernommen: c.uebernommen)
        }
        return v.filter { quote($0) >= zeigenAb }.sorted { quote($0) > quote($1) }
    }

    /// „Heute“, „Morgen“, sonst der Wochentag
    static func tagWort(_ d: Tag, heute: Tag) -> String {
        if d == heute { return "Heute" }
        if d == heute.plus(tage: 1) { return "Morgen" }
        return d.datum().formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "de_DE")))
    }

    // MARK: Erkenntnis – ein Satz je Analyse

    struct Erkenntnis: Equatable, Sendable {
        enum Ziel: Equatable, Sendable { case keins, kalender, zielSeite(UUID), habitSeite(UUID) }
        var titel: String
        var text: String
        var ziel: Ziel = .keins
        /// Wie auffällig der Satz ist (§14) – bestimmt die Reihenfolge der Rückblick-Karten auf Home.
        var stufe: Stufe = .gut
    }

    /// §14: handeln (etwas läuft schief) vor hinweis (etwas fällt auf) vor gut vor leer (noch keine Daten).
    enum Stufe: Int, Comparable, Sendable {
        case leer, gut, hinweis, handeln
        static func < (a: Stufe, b: Stufe) -> Bool { a.rawValue < b.rawValue }
    }

    /// Eine Rückblick-Karte auf Home: Analyse, ihre Zahl der laufenden Woche und der Satz zum Mitnehmen.
    struct Reel: Equatable, Identifiable, Sendable {
        var art: Statistik.Art
        var zahl: String
        var erkenntnis: Erkenntnis
        var id: String { art.rawValue }
    }

    /// §14 Rückblick-Karten: je Analyse eine Karte für die laufende Woche; das Auffälligste steht vorn.
    /// Reihenfolge: Stufe absteigend, bei Gleichstand die feste Folge Erledigt · Habits · Ziele · Zeit.
    static func reels(werte w: Statistik.Werte, zustand z: Zustand, heute T: Tag) -> [Reel] {
        let alle = Statistik.Art.allCases.map { art -> Reel in
            let e: Erkenntnis = switch art {
            case .erledigt: erkenntnisErledigt(geplantJeTag: w.bilanz.geplantJeTag, erledigtJeTag: w.bilanz.erledigtJeTag, tage: w.tage, laufend: T.wochentag - 1)
            case .habits: erkenntnisHabits(zustand: z, von: w.von, bis: w.bis, heute: T)
            case .ziele: erkenntnisZiele(zustand: z, von: w.von, bis: w.bis, heute: T)
            case .zeit: erkenntnisZeit(fokus: w.fokus, fuerZiele: w.fokusFuerZiele)
            }
            return Reel(art: art, zahl: art.zahl(w), erkenntnis: e)
        }
        return ordnen(alle)
    }

    /// Stabil: gleiche Stufe behält die Reihenfolge der Eingabe.
    static func ordnen(_ reels: [Reel]) -> [Reel] {
        reels.enumerated().sorted { ($1.element.erkenntnis.stufe, $0.offset) < ($0.element.erkenntnis.stufe, $1.offset) }.map(\.element)
    }

    static let tagNamen = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]

    /// Erledigt: erste passende Regel – nichts geplant · zu viel geplant (< 60 %) · schwächster Tag (≥ 30 Punkte unter dem besten) · stark (≥ 80 %) · solide.
    /// `laufend` = Index des heutigen Tages: er ist noch nicht vorbei und kann nicht der schwächste sein.
    static func erkenntnisErledigt(geplantJeTag g: [Double], erledigtJeTag e: [Double], tage: Int, laufend: Int? = nil) -> Erkenntnis {
        let geplant = g.reduce(0, +), erledigt = e.reduce(0, +)
        guard geplant > 0 else { return Erkenntnis(titel: "Noch nichts geplant", text: "Aufgaben mit Datum und Habits zählen hier.", ziel: .kalender, stufe: .leer) }
        let quote = erledigt / geplant
        if quote < 0.6 {
            let n = Double(max(1, tage))
            return Erkenntnis(titel: "Mehr geplant als geschafft", text: "Je Tag \(Zahl.text(geplant / n, stellen: 1)) geplant, \(Zahl.text(erledigt / n, stellen: 1)) geschafft – plane weniger ein.", ziel: .kalender, stufe: .handeln)
        }
        let q = g.indices.filter { g[$0] > 0 && $0 != laufend }.map { ($0, e[$0] / g[$0]) }
        if let schwach = q.min(by: { ($0.1, $0.0) < ($1.1, $1.0) }), let stark = q.max(by: { $0.1 < $1.1 }), stark.1 - schwach.1 >= 0.3 {
            return Erkenntnis(titel: "\(tagNamen[schwach.0]) ist dein schwächster Tag", text: "\(Zahl.prozent(schwach.1)) geschafft, am \(tagNamen[stark.0]) \(Zahl.prozent(stark.1)).", ziel: .kalender, stufe: .hinweis)
        }
        if quote >= 0.8 { return Erkenntnis(titel: "Fast alles geschafft", text: "\(Zahl.prozent(quote)) deiner Pläne – das Maß passt.") }
        return Erkenntnis(titel: "Solide", text: "\(Zahl.prozent(quote)) deiner Pläne geschafft, gleichmäßig über die Tage.")
    }

    /// Habits: der schwächste Habit unter 60 % – sonst „alle stabil“.
    static func erkenntnisHabits(zustand z: Zustand, von: Tag, bis: Tag, heute T: Tag) -> Erkenntnis {
        let q = z.habits.compactMap { h -> (Habit, Double, Double, Int)? in
            let x = HabitRechnung.quote(alle: [h], von: von, bis: bis, heute: T)
            return x.geplant > 0 ? (h, x.erledigt / Double(x.geplant), x.erledigt, x.geplant) : nil
        }
        guard !q.isEmpty else { return Erkenntnis(titel: "Noch kein Habit geplant", text: "Geplante Habit-Tage zählen hier.", stufe: .leer) }
        if let s = q.min(by: { ($0.1, $0.0.titel) < ($1.1, $1.0.titel) }), s.1 < 0.6 {
            return Erkenntnis(titel: "„\(s.0.titel)“ fällt zurück", text: "\(Zahl.text(s.2, stellen: 1)) von \(s.3) geschafft – kleiner machen oder fest einplanen.", ziel: .habitSeite(s.0.id), stufe: .handeln)
        }
        return Erkenntnis(titel: "Alle Habits stabil", text: "Keiner unter 60 % in diesem Zeitraum.")
    }

    /// Ziele: größter Rückstand (§4) – sonst ein aktives Ziel ohne Zeit im Zeitraum – sonst „alle im Plan“.
    static func erkenntnisZiele(zustand z: Zustand, von: Tag, bis: Tag, heute T: Tag) -> Erkenntnis {
        let aktiv = z.ziele.filter { $0.status == .aktiv }
        guard !aktiv.isEmpty else { return Erkenntnis(titel: "Noch kein Ziel", text: "Aktive Ziele mit Meilensteinen zählen hier.", stufe: .leer) }
        let kurse = aktiv.map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
        let hinten = kurse.filter { $0.1.lage == .hinterher || $0.1.lage == .ueberfaellig }
            .max { ($0.1.erwartet - $0.1.fortschritt, $1.0.titel) < ($1.1.erwartet - $1.1.fortschritt, $0.0.titel) }
        if let (g, k) = hinten {
            return Erkenntnis(titel: "„\(g.titel)“ braucht dich", text: "\(Zahl.prozent(k.fortschritt)) statt \(Zahl.prozent(k.erwartet)) – dort bringt der nächste Schritt am meisten.", ziel: .zielSeite(g.id), stufe: .handeln)
        }
        if let g = aktiv.sorted(by: { ($0.faellig, $0.titel) < ($1.faellig, $1.titel) }).first(where: { Fortschritt.zeit(ziel: $0.id, in: z, von: von, bis: min(bis, T)) <= 0 }) {
            return Erkenntnis(titel: "Keine Zeit für „\(g.titel)“", text: "In diesem Zeitraum nichts gebucht – ein Block reicht für den Anfang.", ziel: .zielSeite(g.id), stufe: .hinweis)
        }
        return Erkenntnis(titel: "Alle Ziele im Plan", text: "Jedes Ziel hatte in diesem Zeitraum Zeit.")
    }

    /// Zeit: kein Fokus · unter der Hälfte für Ziele · sonst der Anteil.
    static func erkenntnisZeit(fokus: TimeInterval, fuerZiele: TimeInterval) -> Erkenntnis {
        guard fokus > 0 else { return Erkenntnis(titel: "Noch kein Fokus gemessen", text: "Fokuszeit entsteht nur mit dem Timer – starte ihn bei der nächsten Aufgabe.", stufe: .leer) }
        let a = fuerZiele / fokus
        if a < 0.5 { return Erkenntnis(titel: "Wenig Fokus für Ziele", text: "\(Zahl.prozent(a)) deiner Fokuszeit zahlt auf ein Ziel ein – ordne Aufgaben einem Ziel zu.", stufe: .hinweis) }
        return Erkenntnis(titel: "Fokus zahlt auf Ziele ein", text: "\(Zahl.prozent(a)) deiner Fokuszeit gehört zu einem Ziel.")
    }

    /// Was in jede Analyse hineinzählt – ein Satz, steht hinter „Was zählt hier?“.
    static func wasZaehlt(_ art: String) -> String {
        switch art {
        case "erledigt": "Aufgaben mit Datum im Zeitraum und geplante Habit-Tage. Termine zählen nicht – sie finden ohnehin statt."
        case "habits": "Jeder geplante Habit-Tag bis heute. Halb geschafft zählt halb, Tage vor der Anlage zählen nicht."
        case "ziele": "Aktive Ziele. Fortschritt kommt nur aus Meilensteinen; „auf Kurs“ vergleicht ihn mit der verstrichenen Zeit."
        default: "Fokus = gemessene Timer-Zeit. Auslastung = verplante Zeit zwischen 7 und 22 Uhr; ab 75 % gilt ein Tag als voll."
        }
    }
}
