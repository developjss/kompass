import Foundation

// rechenregeln.md §6. Serie, beste Serie und Quote – nur aus Plan (Wochentage), Protokoll und Anlage.

enum HabitRechnung {

    static func geplant(_ h: Habit, am d: Tag) -> Bool { h.wochentage.contains(d.wochentag) }

    /// Geplante Tage rückwärts bis zum ersten verpassten; der heutige Tag zählt erst, wenn abgehakt.
    static func serie(_ h: Habit, heute: Tag) -> Int {
        var s = 0
        var d = h.erledigt.contains(heute) ? heute : heute.plus(tage: -1)
        while d >= h.angelegt {
            if geplant(h, am: d) {
                if h.erledigt.contains(d) { s += 1 } else { break }
            }
            d = d.plus(tage: -1)
        }
        return s
    }

    /// Beste Serie über die ganze Historie seit Anlage (oder dem ersten Eintrag, falls früher).
    static func besteSerie(_ h: Habit, heute: Tag) -> Int {
        var beste = 0, lauf = 0
        var d = ([h.angelegt] + h.erledigt).min() ?? heute
        while d <= heute {
            if geplant(h, am: d) {
                if h.erledigt.contains(d) {
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

    /// Zählt ein Tag für Quoten? Vor der Anlage nicht, heute erst wenn erledigt.
    static func zaehlt(_ h: Habit, am d: Tag, heute: Tag) -> Bool {
        geplant(h, am: d) && d >= h.angelegt && !(d == heute && !h.erledigt.contains(d))
    }

    /// erledigte ÷ geplante Tage der letzten `tage` Tage (heute eingeschlossen).
    static func quote(_ h: Habit, heute: Tag, tage: Int = 30) -> Double {
        var geplantN = 0, erledigtN = 0
        for i in 0..<tage {
            let d = heute.plus(tage: -i)
            if zaehlt(h, am: d, heute: heute) {
                geplantN += 1
                if h.erledigt.contains(d) { erledigtN += 1 }
            }
        }
        return geplantN > 0 ? Double(erledigtN) / Double(geplantN) : 0
    }

    /// Quote aller Habits in einem Zeitraum (z. B. eine Woche); Tage nach heute zählen nicht.
    static func quote(alle habits: [Habit], von: Tag, bis: Tag, heute: Tag) -> (erledigt: Int, geplant: Int) {
        var g = 0, e = 0
        var d = von
        while d <= min(bis, heute) {
            for h in habits where zaehlt(h, am: d, heute: heute) {
                g += 1
                if h.erledigt.contains(d) { e += 1 }
            }
            d = d.plus(tage: 1)
        }
        return (e, g)
    }

    static func haeufigkeit(_ h: Habit) -> String {
        if h.wochentage.count == 7 { return "täglich" }
        if h.wochentage == [1, 2, 3, 4, 5] { return "werktags" }
        let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        return h.wochentage.sorted().map { namen[$0 - 1] }.joined(separator: ", ")
    }
}
