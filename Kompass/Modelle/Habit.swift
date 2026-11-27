import Foundation

/// Ein Habit mit Einheit, Tagesziel, Tagen und optionalem Ziel von „Mein Weg“.
struct Habit: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var bild: String
    var einheit: Einheit
    var tagesziel: Double
    var tage: Set<Int>
    var zielID: String?
    /// Eigenes Foto (JPEG, verkleinert); nil = Bild aus den Assets (`bild`)
    var bildDaten: Data? = nil

    var ziel: Ziel? { Ziel.demo.first { $0.id == zielID } }

    /// Demo-Habits (bis Habits gespeichert werden).
    static let demo: [Habit] = [
        Habit(id: "lesen", name: "Lesen", bild: "habit-1", einheit: .seiten, tagesziel: 20, tage: Set(1...7), zielID: "pilotenschein"),
        Habit(id: "sport", name: "Sport", bild: "habit-2", einheit: .minuten, tagesziel: 45, tage: [1, 3, 5]),
        Habit(id: "meditieren", name: "Meditieren", bild: "habit-3", einheit: .minuten, tagesziel: 10, tage: Set(1...7)),
        Habit(id: "lernen", name: "Lernen", bild: "habit-4", einheit: .minuten, tagesziel: 30, tage: Set(1...5), zielID: "pilotenschein"),
        Habit(id: "wasser", name: "Wasser", bild: "habit-5", einheit: .ml, tagesziel: 2_000, tage: Set(1...7)),
    ]
}

/// Fortschritt eines Habits an einem Tag – fest gerechnet, mit Tests.
/// [ENTSCHEIDUNG – 27.11.2026, Gründer: „wie es am meisten Sinn macht“]
/// - Teilwert = Anteil × Tagesziel, eingerastet auf den Fortschritt-Schritt (Zeit: ganze Minuten bzw. Sekunden, sonst Schritt der Einheit).
/// - Nur ganz nach rechts (100 %) zählt als erledigt; ein Teilwert erreicht das Tagesziel nie durch Runden.
/// - „Keine Einheit“: nur ganz oder gar nicht.
enum Fortschritt {
    enum Status: Sendable, Equatable { case offen, teilweise, erledigt }

    /// Kleinster Schritt beim Eintragen.
    static func schritt(_ e: Einheit) -> Double {
        switch e.id {
        case "sek", "min": 1
        case "std": 1.0 / 60
        default: e.auswahl == .keine ? 1 : e.schritt
        }
    }

    /// Wert aus dem Anteil am Balken (0…1).
    static func wert(anteil: Double, einheit: Einheit, ziel: Double) -> Double {
        let a = min(max(anteil, 0), 1)
        if einheit.auswahl == .keine { return a >= 1 ? ziel : 0 }
        if a >= 1 { return ziel }
        let s = schritt(einheit)
        var w = (a * ziel / s).rounded() * s
        if w >= ziel { w = max(ziel - s, 0) }
        return runde(max(w, 0))
    }

    static func anteil(wert: Double, ziel: Double) -> Double {
        guard ziel > 0 else { return 0 }
        return min(max(wert / ziel, 0), 1)
    }

    static func status(wert: Double, ziel: Double) -> Status {
        if wert <= 0 { return .offen }
        return wert >= ziel ? .erledigt : .teilweise
    }

    /// „12 / 20 Seiten“, „21m / 30m“, „1.250 / 2.000 ml“, „Erledigt“ / „Offen“.
    static func text(wert: Double, einheit: Einheit, ziel: Double) -> String {
        switch einheit.art {
        case .zeit: return "\(zeit(wert, einheit)) / \(zeit(ziel, einheit))"
        case .menge:
            if einheit.auswahl == .keine { return wert >= ziel ? "Erledigt" : "Offen" }
            return "\(Einheit.zahl(wert)) / \(Einheit.zahl(ziel)) \(einheit.wort(ziel))"
        }
    }

    /// Text der Bestätigungs-Kapsel bei einem Teilwert.
    static func speichernText(wert: Double, einheit: Einheit, ziel: Double) -> String {
        if wert <= 0 { return "Als offen markieren" }
        switch einheit.art {
        case .zeit: return "\(zeit(wert, einheit)) von \(zeit(ziel, einheit)) speichern"
        case .menge: return "\(Einheit.zahl(wert)) von \(Einheit.zahl(ziel)) \(einheit.wort(ziel)) speichern"
        }
    }

    /// Prozent ganzzahlig abgerundet (für den Titel „60 % geschafft“).
    static func prozent(wert: Double, ziel: Double) -> Int { Int((anteil(wert: wert, ziel: ziel) * 100).rounded(.down)) }

    private static func zeit(_ w: Double, _ e: Einheit) -> String {
        w <= 0 ? (e.id == "sek" ? "0s" : "0m") : e.text(w)
    }

    private static func runde(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
}
