import Foundation

/// Rückblick (rechenregeln.md §11): Kennzahlen je Zeitraum, „dein Normal“, Reife, Tower-Muster, Lernen.
/// Rein und testbar; die Anzeige liegt in `RueckblickAnsicht`.
enum Rueckblick {

    enum Zeitraum: String, CaseIterable, Sendable { case woche, monat, jahr
        var name: String { switch self { case .woche: "Woche"; case .monat: "Monat"; case .jahr: "Jahr" } }
    }

    /// Anfang und Ende (einschließlich) des Zeitraums, um `versatz` Zeiträume verschoben (0 = laufend).
    static func spanne(_ z: Zeitraum, versatz: Int, heute: Tag) -> (von: Tag, bis: Tag) {
        switch z {
        case .woche:
            let m = heute.montag.plus(tage: 7 * versatz); return (m, m.plus(tage: 6))
        case .monat:
            var jahr = heute.jahr, monat = heute.monat + versatz
            while monat < 1 { monat += 12; jahr -= 1 }
            while monat > 12 { monat -= 12; jahr += 1 }
            let von = Tag(jahr, monat, 1)
            let naechster = monat == 12 ? Tag(jahr + 1, 1, 1) : Tag(jahr, monat + 1, 1)
            return (von, naechster.plus(tage: -1))
        case .jahr:
            return (Tag(heute.jahr + versatz, 1, 1), Tag(heute.jahr + versatz, 12, 31))
        }
    }

    // MARK: Kennzahlen

    struct Kennzahlen: Equatable, Sendable {
        var planGeplant = 0
        var planGeschafft = 0.0
        /// Sekunden
        var fokus: TimeInterval = 0
        var zeitFuerZiele: TimeInterval = 0
        var zeitErfasst: TimeInterval = 0
        var habitsGeplant = 0
        var habitsErledigt = 0.0
        var termine = 0
        /// Sekunden je Ziel (Fokus + Termine + Habit-Zeit mit Ziel)
        var jeZiel: [UUID: TimeInterval] = [:]
        /// Sekunden ohne Ziel je Quelle („Arbeit“ = Kalendername, sonst „Termine“, „Fokus“)
        var ohneZiel: [String: TimeInterval] = [:]

        var planQuote: Double { planGeplant > 0 ? planGeschafft / Double(planGeplant) : 0 }
        var zielAnteil: Double { zeitErfasst > 0 ? zeitFuerZiele / zeitErfasst : 0 }
    }

    /// Kennzahlen für `von…bis` (nur Tage bis heute zählen). Überlappende Zeitfenster zählen einmal (Vereinigung je Tag).
    static func kennzahlen(zustand z: Zustand, von: Tag, bis: Tag, heute: Tag, termine: (Tag) -> [Termin]) -> Kennzahlen {
        var k = Kennzahlen()
        var d = von
        while d <= bis && d <= heute {
            let te = termine(d).filter { $0.start != nil && $0.ende != nil }
            k.termine += te.count
            // Fenster mit Ziel / alle Fenster (Termine + Habits mit Uhrzeit), Minuten
            var mitZiel: [(Int, Int)] = [], alle: [(Int, Int)] = []
            for t in te {
                let iv = (t.start!, t.ende!)
                alle.append(iv)
                if let g = t.zielID { mitZiel.append(iv); k.jeZiel[g, default: 0] += Double(iv.1 - iv.0) * 60 }
                else { k.ohneZiel[t.quelle == .kompass ? "Termine" : (t.kalenderName ?? "\(t.quelle.name)-Kalender"), default: 0] += Double(iv.1 - iv.0) * 60 }
            }
            for h in z.habits where d >= h.angelegt && HabitRechnung.geplant(h, am: d) && h.anteil(am: d) > 0 {
                guard let u = h.zeit(am: d) else { continue }
                let iv = (u, u + h.dauerMinuten)
                alle.append(iv)
                if let g = h.zielID { mitZiel.append(iv); k.jeZiel[g, default: 0] += Double(h.dauerMinuten) * 60 }
            }
            let fZ = Tagesplan.vereinigt(mitZiel).reduce(0) { $0 + $1.1 - $1.0 }
            let fA = Tagesplan.vereinigt(alle).reduce(0) { $0 + $1.1 - $1.0 }
            k.zeitFuerZiele += Double(fZ) * 60
            k.zeitErfasst += Double(fA) * 60
            // Fokus (hat nur Tag und Dauer – zählt zusätzlich)
            for s in z.sitzungen where s.tag == d {
                k.fokus += s.sekunden; k.zeitErfasst += s.sekunden
                if let g = s.zielID { k.zeitFuerZiele += s.sekunden; k.jeZiel[g, default: 0] += s.sekunden } else { k.ohneZiel["Fokus", default: 0] += s.sekunden }
            }
            // Plan: Aufgaben mit Datum + Habit-Tage
            let au = z.aufgaben.filter { $0.datum == d }
            k.planGeplant += au.count; k.planGeschafft += Double(au.filter(\.erledigt).count)
            let hq = HabitRechnung.quote(alle: z.habits, von: d, bis: d, heute: heute)
            k.habitsGeplant += hq.geplant; k.habitsErledigt += hq.erledigt
            k.planGeplant += hq.geplant; k.planGeschafft += hq.erledigt
            d = d.plus(tage: 1)
        }
        return k
    }

    // MARK: Dein Normal

    struct Normal: Equatable, Sendable {
        var median: Double
        var unten: Double
        var oben: Double
        enum Lage: Sendable { case unter, drin, ueber }
        func lage(_ w: Double) -> Lage { w < unten ? .unter : w > oben ? .ueber : .drin }
    }

    /// Median der Werte ± 1,5 × mittlere Abweichung vom Median, Spanne mindestens ±10 % des Medians. nil bei < 4 Werten.
    static func normal(_ werte: [Double]) -> Normal? {
        guard werte.count >= 4 else { return nil }
        let m = median(werte)
        let mad = median(werte.map { abs($0 - m) })
        let s = max(1.5 * mad, abs(m) * 0.1)
        return Normal(median: m, unten: m - s, oben: m + s)
    }

    static func median(_ w: [Double]) -> Double {
        let s = w.sorted(); let n = s.count
        guard n > 0 else { return 0 }
        return n % 2 == 1 ? s[n / 2] : (s[n / 2 - 1] + s[n / 2]) / 2
    }

    /// Ganze Wochen seit der ersten Aktivität (Aufgabe, Habit, Ziel, Fokus) – die Reifestufe.
    static func reifeWochen(zustand z: Zustand, heute: Tag) -> Int {
        var erster: Tag? = nil
        func merk(_ t: Tag?) { if let t, erster == nil || t < erster! { erster = t } }
        z.ziele.forEach { merk($0.angelegt) }
        z.habits.forEach { merk($0.angelegt) }
        z.sitzungen.forEach { merk($0.tag) }
        z.aufgaben.compactMap(\.datum).forEach { merk($0) }
        guard let e = erster, e <= heute else { return 0 }
        return e.tage(bis: heute) / 7
    }

    /// Kennzahlen der letzten `n` abgeschlossenen Wochen (älteste zuerst), fürs Normal.
    static func wochenVerlauf(zustand z: Zustand, heute: Tag, n: Int = 8, termine: (Tag) -> [Termin]) -> [Kennzahlen] {
        (1...n).reversed().map { i in
            let m = heute.montag.plus(tage: -7 * i)
            return kennzahlen(zustand: z, von: m, bis: m.plus(tage: 6), heute: heute, termine: termine)
        }
    }

    // MARK: Flugbericht – ein Satz

    static func satz(_ k: Kennzahlen, planNormal: Normal?, zielNormal: Normal?, zeitraum: Zeitraum, laufend: Bool) -> String {
        let z = zeitraum == .woche ? "Woche" : zeitraum == .monat ? "Monat" : "Jahr"
        guard k.planGeplant > 0 || k.zeitErfasst > 0 else { return "Noch nichts geplant – \(laufend ? "die \(z) ist jung." : "eine leere \(z).")" }
        guard let pn = planNormal, let zn = zielNormal else { return laufend ? "\(z) läuft – Kompass lernt dein Normal noch." : "Kompass lernt dein Normal noch." }
        let p = pn.lage(k.planQuote), g = zn.lage(k.zielAnteil)
        switch (p, g) {
        case (.ueber, .ueber): return "Starke \(z). Mehr geschafft und mehr Zeit für Ziele als sonst."
        case (.ueber, _): return "Starke \(z). Mehr geschafft als sonst."
        case (_, .ueber): return "Gute \(z). Mehr Zeit für Ziele als sonst."
        case (.unter, .unter): return "Ruhige \(z). Weniger geschafft, weniger Zeit für Ziele."
        case (.unter, _): return "Ruhige \(z). Weniger geschafft als sonst."
        case (_, .unter): return "Ganz normale \(z) – nur die Ziele kamen kurz."
        default: return "Ganz normale \(z). Alles in deinem Normal."
        }
    }

    // MARK: Tower – Muster

    enum Familie: String, Sendable { case ziele, planen, habits, zeit
        var gewicht: Double { switch self { case .ziele: 1.5; case .planen: 1.2; default: 1.0 } }
        var name: String { switch self { case .ziele: "Ziele"; case .planen: "Planen"; case .habits: "Habits"; case .zeit: "Zeit" } }
    }

    struct Hinweis: Identifiable, Equatable, Sendable {
        /// Muster-Kennung („zielRuht“) – fürs Lernen
        var muster: String
        var familie: Familie
        var titel: String
        var satz: String
        var handlung: String?
        /// Zahlen fürs Warum-Blatt
        var zahlen: [(String, String)]
        var rechnung: String
        /// 1 erster Hinweis · 2 ziemlich sicher · 3 sicher
        var sicher: Int
        var staerke: Double
        var zielID: UUID?
        var habitID: UUID?
        var id: String { muster + (zielID?.uuidString ?? habitID?.uuidString ?? "") }
        static func == (a: Hinweis, b: Hinweis) -> Bool { a.id == b.id }
    }

    /// Alle erkannten Muster (ungeordnet). Mindestdaten je Muster; Ausgeblendetes fehlt.
    static func muster(zustand z: Zustand, heute: Tag, woche k: Kennzahlen, verlauf: [Kennzahlen], reife: Int, termine: (Tag) -> [Termin]) -> [Hinweis] {
        var out: [Hinweis] = []
        guard reife >= 4 else { return out }
        // Dein Ziel ruht: aktiv, 14 Tage ohne Einsatz, Frist < 12 Monate, Ziel ≥ 21 Tage alt
        for g in z.ziele where g.status == .aktiv && g.angelegt.tage(bis: heute) >= 21 && heute.tage(bis: g.faellig) < 366 {
            let einsatz = Fortschritt.zeit(ziel: g.id, in: z, von: heute.plus(tage: -13), bis: heute)
            let habit = z.habits.contains { $0.zielID == g.id && HabitRechnung.summe($0, von: heute.plus(tage: -13), bis: heute) > 0 }
            guard einsatz == 0 && !habit else { continue }
            let ruht = tageOhneEinsatz(g, in: z, heute: heute)
            let kurs = Kurs.aufKurs(g, in: z, heute: heute)
            out.append(Hinweis(muster: "zielRuht", familie: .ziele, titel: "Dein Ziel ruht",
                               satz: "„\(g.titel)“ hatte \(ruht) Tage keinen Einsatz.", handlung: "30 Min einplanen",
                               zahlen: [("Einsatz 14 Tage", "0 h"), ("Frist", Kurs.bisText(g.faellig, heute: heute)), ("Lage", kurs.lage.text)],
                               rechnung: "Aktives Ziel, 14 Tage ohne Fokus, Termin oder Habit, Frist in weniger als 12 Monaten.",
                               sicher: 3, staerke: Double(ruht) / 14 * (kurs.lage == .hinterher ? 1.5 : 1), zielID: g.id, habitID: nil))
        }
        // Bester Fokus: über dem Normal und Höchstwert der letzten 8 Wochen
        if let n = normal(verlauf.map(\.fokus)), k.fokus > n.oben, k.fokus > (verlauf.map(\.fokus).max() ?? 0), k.fokus > 0 {
            out.append(Hinweis(muster: "besterFokus", familie: .zeit, titel: "Bester Fokus",
                               satz: "\(Zahl.dauer(k.fokus)) Fokus – deine stärkste Woche seit \(verlauf.count) Wochen.", handlung: nil,
                               zahlen: [("Fokus", Zahl.dauer(k.fokus)), ("Dein Normal", "\(Zahl.dauer(n.unten))–\(Zahl.dauer(n.oben))")],
                               rechnung: "Fokuszeit über der oberen Grenze deines Normals und Höchstwert der letzten \(verlauf.count) Wochen.",
                               sicher: 3, staerke: 0.8, zielID: nil, habitID: nil))
        }
        // Habit wackelt: 3 Wochen in Folge unter dem eigenen Normal (8 Wochen)
        for h in z.habits where h.angelegt.tage(bis: heute) >= 56 {
            let wochen = (1...8).reversed().map { i -> Double in
                let m = heute.montag.plus(tage: -7 * i)
                let q = HabitRechnung.quote(alle: [h], von: m, bis: m.plus(tage: 6), heute: heute)
                return q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0
            }
            guard let n = normal(Array(wochen.prefix(5))), wochen.suffix(3).allSatisfy({ $0 < n.unten }) else { continue }
            let q = wochen.last ?? 0
            out.append(Hinweis(muster: "habitWackelt", familie: .habits, titel: "Wackelt",
                               satz: "„\(h.titel)“ liegt 3 Wochen unter deinem Normal.", handlung: "Soll anpassen",
                               zahlen: [("Letzte Woche", Zahl.prozent(q)), ("Dein Normal", "\(Zahl.prozent(n.unten))–\(Zahl.prozent(n.oben))")],
                               rechnung: "Drei Wochen in Folge unter der unteren Grenze deines Normals (Median der 5 Wochen davor).",
                               sicher: 2, staerke: min(1.5, (n.unten - q) / max(0.01, n.unten) + 0.5), zielID: nil, habitID: h.id))
        }
        // Zu viel geplant: geplante Minuten > 110 % der freien Zeit (7–22 Uhr minus Termine) an ≥ 3 Tagen der Woche
        var volleTage = 0, geplantMin = 0, freiMin = 0
        for i in 0..<7 {
            let d = heute.montag.plus(tage: i)
            let te = termine(d).filter { $0.start != nil }
            let belegt = Tagesplan.vereinigt(te.map { (max($0.start!, Tagesplan.wachVon), min($0.ende!, Tagesplan.wachBis)) }.filter { $0.1 > $0.0 }).reduce(0) { $0 + $1.1 - $1.0 }
            let frei = max(0, Tagesplan.wachBis - Tagesplan.wachVon - belegt)
            let plan = z.aufgaben.filter { $0.datum == d && !$0.erledigt }.reduce(0) { $0 + $1.dauer }
                + z.habits.filter { d >= $0.angelegt && HabitRechnung.geplant($0, am: d) }.reduce(0) { $0 + $1.dauerMinuten }
            geplantMin += plan; freiMin += frei
            if Double(plan) > 1.1 * Double(frei) { volleTage += 1 }
        }
        if volleTage >= 3 {
            out.append(Hinweis(muster: "zuVielGeplant", familie: .planen, titel: "Zu viel geplant",
                               satz: "An \(volleTage) Tagen hast du mehr geplant, als Zeit ist.", handlung: "Weniger einplanen",
                               zahlen: [("Geplant", Zahl.dauer(TimeInterval(geplantMin * 60))), ("Frei (7–22 Uhr)", Zahl.dauer(TimeInterval(freiMin * 60))), ("Tage über 110 %", "\(volleTage)")],
                               rechnung: "Geplante Dauer von Aufgaben und Habits > 110 % der freien Zeit zwischen Terminen, an mindestens 3 Tagen.",
                               sicher: 2, staerke: Double(volleTage) / 7 + 0.5, zielID: nil, habitID: nil))
        }
        return out
    }

    static func tageOhneEinsatz(_ g: Ziel, in z: Zustand, heute: Tag) -> Int {
        for i in 14...365 {
            let d = heute.plus(tage: -i)
            if Fortschritt.zeit(ziel: g.id, in: z, von: d, bis: d) > 0 { return i }
            if z.habits.contains(where: { $0.zielID == g.id && $0.anteil(am: d) > 0 }) { return i }
            if d <= g.angelegt { return i }
        }
        return 365
    }

    // MARK: Lernen und Rang

    /// Nutzen je Muster: (hilfreich + 1) ÷ (gezeigt + 2).
    static func nutzen(_ l: RueckblickLernen, muster: String) -> Double {
        Double((l.hilfreich[muster] ?? 0) + 1) / Double((l.gezeigt[muster] ?? 0) + 2)
    }

    /// Rang = Stärke × Familien-Gewicht × Nutzen; Ausgeblendetes fehlt; höchstens `anzahl`.
    static func tower(_ hinweise: [Hinweis], lernen l: RueckblickLernen, heute: Tag, anzahl: Int = 2) -> [Hinweis] {
        hinweise
            .filter { h in l.ausgeblendet[h.muster].flatMap { Tag(text: $0) }.map { $0 < heute } ?? true }
            .sorted { a, b in
                a.staerke * a.familie.gewicht * nutzen(l, muster: a.muster) > b.staerke * b.familie.gewicht * nutzen(l, muster: b.muster)
            }
            .prefix(anzahl).map { $0 }
    }
}

extension Zustand {
    /// „Hilfreich“ / „Passt nicht“ zu einem Tower-Hinweis.
    mutating func rueckblickRueckmeldung(muster: String, hilfreich: Bool, heute: Tag) {
        if hilfreich { lernen.rueckblick.hilfreich[muster, default: 0] += 1 }
        else { lernen.rueckblick.ausgeblendet[muster] = heute.plus(tage: 56).text }
    }

    mutating func rueckblickGezeigt(_ muster: [String]) {
        for m in muster { lernen.rueckblick.gezeigt[m, default: 0] += 1 }
    }
}
