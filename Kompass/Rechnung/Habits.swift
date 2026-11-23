import Foundation

// rechenregeln.md §6 (Fassung 2, Habits v2). Serie, Quote, Wochen – aus Rhythmus, Einträgen (Anteile) und Anlage.
// Anteil eines Tages = eingetragene Menge ÷ Soll (0…1); halb geschafft zählt halb. Abhaken ohne Soll = 1.

enum HabitRechnung {

    /// Ist der Tag geplant? Täglich/Wochentage nach Plan; „n-mal pro Woche“: jeder Tag, solange die Woche nicht voll ist
    /// (ein Tag mit Eintrag gilt immer als geplant).
    static func geplant(_ h: Habit, am d: Tag) -> Bool {
        switch h.rhythmus {
        case .taeglich: return true
        case .wochentage(let t): return t.contains(d.wochentag)
        case .proWoche(let n):
            if h.eintraege[d] != nil { return true }
            return summe(h, von: d.montag, bis: d.plus(tage: -1)) < Double(n)
        }
    }

    /// Summe der Tagesanteile in einem Zeitraum (beide Tage eingeschlossen).
    static func summe(_ h: Habit, von: Tag, bis: Tag) -> Double {
        guard von <= bis else { return 0 }
        return h.eintraege.keys.filter { $0 >= von && $0 <= bis }.reduce(0) { $0 + h.anteil(am: $1) }
    }

    /// Stand einer Woche: Soll (geplante Tage bzw. n), Ist (Summe der Anteile, höchstens Soll), erfüllt.
    static func woche(_ h: Habit, montag: Tag, seit: Tag, heute: Tag) -> (geplant: Int, erledigt: Double, erfuellt: Bool) {
        let sonntag = montag.plus(tage: 6)
        let ab = max(montag, seit)
        switch h.rhythmus {
        case .proWoche(let n):
            guard sonntag >= seit else { return (0, 0, false) }
            let ist = min(Double(n), summe(h, von: ab, bis: min(sonntag, heute)))
            return (n, ist, ist >= Double(n))
        default:
            var g = 0, voll = 0
            var e = 0.0
            var d = ab
            while d <= sonntag {
                if geplant(h, am: d) {
                    g += 1
                    if d <= heute { e += h.anteil(am: d); if h.voll(am: d) { voll += 1 } }
                }
                d = d.plus(tage: 1)
            }
            return (g, e, g > 0 && voll >= g)
        }
    }

    /// Erfüllte Wochen seit `seit` (für Meilenstein „Wochen“). Die laufende Woche zählt erst, wenn sie erfüllt ist.
    static func erfuellteWochen(_ h: Habit, seit: Tag, heute: Tag) -> Int {
        var n = 0
        var m = seit.montag
        while m <= heute {
            if woche(h, montag: m, seit: seit, heute: heute).erfuellt { n += 1 }
            m = m.plus(tage: 7)
        }
        return n
    }

    /// Serie: Tages-Habits – geplante Tage rückwärts bis zum ersten nicht vollen (heute zählt erst, wenn voll);
    /// „n-mal pro Woche“ – erfüllte Wochen rückwärts (laufende Woche zählt, sobald erfüllt).
    static func serie(_ h: Habit, heute: Tag) -> Int {
        if case .proWoche = h.rhythmus {
            var n = 0
            var m = heute.montag
            if !woche(h, montag: m, seit: h.angelegt, heute: heute).erfuellt { m = m.plus(tage: -7) }
            while m >= h.angelegt.montag {
                if woche(h, montag: m, seit: h.angelegt, heute: heute).erfuellt { n += 1 } else { break }
                m = m.plus(tage: -7)
            }
            return n
        }
        var s = 0
        var d = h.voll(am: heute) ? heute : heute.plus(tage: -1)
        while d >= h.angelegt {
            if geplant(h, am: d) {
                if h.voll(am: d) { s += 1 } else { break }
            }
            d = d.plus(tage: -1)
        }
        return s
    }

    /// Beste Serie über die ganze Historie seit Anlage (oder dem ersten Eintrag, falls früher).
    static func besteSerie(_ h: Habit, heute: Tag) -> Int {
        if case .proWoche = h.rhythmus {
            var beste = 0, lauf = 0
            var m = h.angelegt.montag
            while m <= heute {
                if woche(h, montag: m, seit: h.angelegt, heute: heute).erfuellt { lauf += 1; beste = max(beste, lauf) }
                else if m.plus(tage: 6) < heute { lauf = 0 }
                m = m.plus(tage: 7)
            }
            return beste
        }
        var beste = 0, lauf = 0
        var d = ([h.angelegt] + h.eintraege.keys).min() ?? heute
        while d <= heute {
            if geplant(h, am: d) {
                if h.voll(am: d) {
                    lauf += 1
                    beste = max(beste, lauf)
                } else if d != heute {
                    lauf = 0
                }
            }
            d = d.plus(tage: 1)
        }
        return beste
    }

    /// Zählt ein Tag für Quoten? Vor der Anlage nicht; heute erst, wenn etwas eingetragen ist.
    static func zaehlt(_ h: Habit, am d: Tag, heute: Tag) -> Bool {
        geplant(h, am: d) && d >= h.angelegt && d <= heute && !(d == heute && h.anteil(am: d) == 0)
    }

    /// Quote der letzten `tage` Tage: Σ Anteile ÷ geplante Tage. „n-mal pro Woche“: Mittel der Wochen-Anteile
    /// (laufende Woche nur, wenn erfüllt).
    static func quote(_ h: Habit, heute: Tag, tage: Int = 30) -> Double {
        if case .proWoche(let n) = h.rhythmus {
            var summeQ = 0.0, wochen = 0
            var m = heute.plus(tage: -(tage - 1)).montag
            while m <= heute {
                let w = woche(h, montag: m, seit: h.angelegt, heute: heute)
                let laufend = m == heute.montag
                if w.geplant > 0 && (!laufend || w.erfuellt) { summeQ += w.erledigt / Double(n); wochen += 1 }
                m = m.plus(tage: 7)
            }
            return wochen > 0 ? summeQ / Double(wochen) : 0
        }
        var geplantN = 0
        var erledigtS = 0.0
        for i in 0..<tage {
            let d = heute.plus(tage: -i)
            if zaehlt(h, am: d, heute: heute) {
                geplantN += 1
                erledigtS += h.anteil(am: d)
            }
        }
        return geplantN > 0 ? erledigtS / Double(geplantN) : 0
    }

    /// Alle Habits in einem Zeitraum (z. B. eine Woche): geplante Tage und Σ Anteile. Tage nach heute zählen nicht.
    static func quote(alle habits: [Habit], von: Tag, bis: Tag, heute: Tag) -> (erledigt: Double, geplant: Int) {
        var g = 0
        var e = 0.0
        for h in habits {
            if case .proWoche = h.rhythmus {
                let w = woche(h, montag: von.montag, seit: h.angelegt, heute: heute)
                g += w.geplant
                e += w.erledigt
                continue
            }
            var d = von
            while d <= min(bis, heute) {
                if zaehlt(h, am: d, heute: heute) { g += 1; e += h.anteil(am: d) }
                d = d.plus(tage: 1)
            }
        }
        return (e, g)
    }

    /// „täglich“, „werktags“, „Mo, Mi, Fr“, „3× pro Woche“
    static func haeufigkeit(_ h: Habit) -> String {
        switch h.rhythmus {
        case .taeglich: return "täglich"
        case .proWoche(let n): return "\(n)× pro Woche"
        case .wochentage(let t):
            if t == [1, 2, 3, 4, 5] { return "werktags" }
            if t.count >= 7 { return "täglich" }
            let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
            return t.sorted().map { namen[$0 - 1] }.joined(separator: ", ")
        }
    }

    /// „12 von 20 min“, „erledigt“, „offen“
    static func mengenText(_ h: Habit, am tag: Tag) -> String {
        guard let soll = h.menge, soll > 0 else { return h.voll(am: tag) ? "erledigt" : "offen" }
        let ist = h.eintraege[tag] ?? 0
        let e = h.einheit.map { " " + $0.kurz } ?? ""
        return "\(Zahl.text(ist, stellen: 1)) von \(Zahl.text(soll, stellen: 1))\(e)"
    }

    /// Soll als Text: „20 min“, „3× pro Woche · 45 min“
    static func sollText(_ h: Habit) -> String {
        let menge = h.menge.map { "\(Zahl.text($0, stellen: 1))\(h.einheit.map { " " + $0.kurz } ?? "")" }
        switch (h.rhythmus, menge) {
        case (.proWoche, let m?): return haeufigkeit(h) + " · " + m
        case (_, let m?): return m + " · " + haeufigkeit(h)
        default: return haeufigkeit(h)
        }
    }
}
