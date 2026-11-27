import Foundation

/// Wochentage eines Habits: 1 = Montag … 7 = Sonntag. Text fest gerechnet (keine KI).
enum Wochentage {
    static let buchstaben = ["M", "D", "M", "D", "F", "S", "S"]
    static let kurz = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    static let namen = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]

    /// Text rechts in der Zeile: „Täglich“, „Werktags“, „Wochenende“, „Nur Montag“ oder „Mo, Mi, Fr“.
    static func text(_ tage: Set<Int>) -> String {
        let t = tage.filter { (1...7).contains($0) }
        switch t {
        case Set(1...7): return "Täglich"
        case Set(1...5): return "Werktags"
        case [6, 7]: return "Wochenende"
        case []: return "Keine Tage"
        default:
            if t.count == 1, let tag = t.first { return "Nur \(namen[tag - 1])" }
            return t.sorted().map { kurz[$0 - 1] }.joined(separator: ", ")
        }
    }

    /// Tag umschalten; der letzte gewählte Tag bleibt an. Gibt `false` zurück, wenn nichts geändert wurde.
    @discardableResult
    static func umschalten(_ tag: Int, in tage: inout Set<Int>) -> Bool {
        guard (1...7).contains(tag) else { return false }
        if tage.contains(tag) {
            guard tage.count > 1 else { return false }
            tage.remove(tag)
        } else {
            tage.insert(tag)
        }
        return true
    }
}
