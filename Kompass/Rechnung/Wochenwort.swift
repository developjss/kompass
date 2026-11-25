import Foundation

/// Das Wort über dem Rückblick (rechenregeln.md §11): ein bis zwei Wörter, die die Lage der Woche beschreiben.
/// Deterministisch aus vier Zahlen – keine KI. Erste passende Regel gewinnt.
enum Wochenwort {
    struct Lage: Equatable, Sendable {
        /// Anteil der geschafften Pläne (Aufgaben + Habits), 0…1
        var quote: Double
        /// Anteil der geschafften Habit-Tage, 0…1
        var habitQuote: Double
        var zieleAufKurs: Int
        var zieleGesamt: Int
        /// höchste Tagesauslastung der Woche (verplant ÷ wach), 0…1
        var auslastung: Double
        /// Tage der Woche mit Daten (geplant oder verplant)
        var tageMitDaten: Int
    }

    /// (Zeile, Akzentwort) – zusammen höchstens zwei Wörter.
    static func wort(_ l: Lage) -> (String, String) {
        if l.tageMitDaten == 0 { return ("Neue", "Woche.") }
        if l.auslastung >= 0.75 { return ("Volle", "Woche.") }
        if l.quote >= 0.8 && (l.habitQuote >= 0.8 || l.habitQuote == 0) { return ("Starke", "Woche.") }
        if l.zieleGesamt > 0 && l.zieleAufKurs * 2 < l.zieleGesamt { return ("Kurs", "halten.") }
        if l.quote < 0.4 { return ("Luft", "holen.") }
        if l.habitQuote >= 0.8 { return ("Gut", "dabei.") }
        return ("Im", "Fluss.")
    }
}
