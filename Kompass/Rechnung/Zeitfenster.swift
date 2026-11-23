import Foundation

/// Freie Zeit eines Tages: Lücken zwischen Terminen und Aufgaben mit Uhrzeit (rein, testbar). Der Lotse nutzt das für „Wann habe ich Zeit?“.
enum Zeitfenster {

    struct Fenster: Equatable, Sendable {
        /// Minuten seit Mitternacht
        var start: Int
        var ende: Int
        var minuten: Int { ende - start }
    }

    /// Belegt = Termine mit Uhrzeit + Aufgaben mit Uhrzeit (Dauer). Frei = Lücken im Rahmen [von, bis), mindestens `mindestens` Minuten.
    static func frei(termine: [Termin], aufgaben: [Aufgabe], von: Int = 8 * 60, bis: Int = 20 * 60, mindestens: Int = 30) -> [Fenster] {
        var belegt: [(Int, Int)] = termine.compactMap { t in
            guard let a = t.start, let e = t.ende, e > a else { return nil }
            return (a, e)
        }
        belegt += aufgaben.compactMap { a in
            guard let u = a.uhrzeit, !a.erledigt else { return nil }
            return (u, u + max(a.dauer, 15))
        }
        belegt.sort { $0.0 < $1.0 }
        var out: [Fenster] = []
        var cursor = von
        for (a, e) in belegt {
            if a > cursor, a - cursor >= mindestens { out.append(Fenster(start: cursor, ende: min(a, bis))) }
            cursor = max(cursor, e)
            if cursor >= bis { break }
        }
        if bis - cursor >= mindestens { out.append(Fenster(start: cursor, ende: bis)) }
        return out.filter { $0.minuten >= mindestens && $0.start < bis }
    }

    static func text(_ f: Fenster) -> String {
        "\(Beispieltermine.uhrzeit(f.start))–\(Beispieltermine.uhrzeit(f.ende))"
    }
}
