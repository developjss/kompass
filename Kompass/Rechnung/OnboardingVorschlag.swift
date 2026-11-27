import Foundation

// rechenregeln.md §20: erste Vorschläge aus dem Onboarding. Feste Tabelle, keine Erfolgsquoten anderer Nutzer.

enum OnboardingVorschlag {

    enum Art: Equatable, Sendable { case habit, fokusMitSperre }

    struct Vorschlag: Identifiable, Equatable, Sendable {
        var id: String
        var titel: String
        var art: Art
        /// Dauer in Minuten
        var minuten: Int
        /// Rhythmus als Text („täglich“, „werktags“, „3× je Woche“)
        var rhythmus: String
        /// Start in Minuten ab Mitternacht
        var start: Int
        var grund: String
    }

    /// Uhrzeit je Lebenslage (Start in Minuten).
    static func start(_ l: Lebenslage?) -> Int {
        switch l {
        case .schule, .ausbildung: 15 * 60
        case .studium: 9 * 60
        case .job, .selbststaendig: 18 * 60
        default: 10 * 60
        }
    }

    static func name(_ v: Verbessern) -> String {
        switch v {
        case .ziele: "Ziele erreichen"
        case .gewohnheiten: "Gewohnheiten aufbauen"
        case .wenigerHandy: "Weniger am Handy"
        case .schlafen: "Besser schlafen"
        case .ruhe: "Mehr Ruhe"
        case .anderes: "Anderes"
        }
    }

    /// Höchstens 4 Vorschläge in der Reihenfolge der Antworten; ohne Antwort „Gewohnheiten“.
    static func vorschlaege(_ p: Profil) -> [Vorschlag] {
        let wahl = p.verbessern.isEmpty ? [.gewohnheiten] : p.verbessern
        let s = start(p.lebenslage)
        var gesehen = Set<Verbessern>()
        return wahl.filter { gesehen.insert($0).inserted }.prefix(4).map { v in
            let grund = "Weil du „\(name(v))“ gewählt hast"
            switch v {
            case .ziele: return Vorschlag(id: "ziel-fokus", titel: "Fokus für dein Ziel", art: .habit, minuten: 30, rhythmus: "werktags", start: s, grund: grund)
            case .gewohnheiten: return Vorschlag(id: "lesen", titel: "Lesen", art: .habit, minuten: 20, rhythmus: "täglich", start: s, grund: grund)
            case .wenigerHandy: return Vorschlag(id: "handyfreier-morgen", titel: "Handyfreier Morgen", art: .fokusMitSperre, minuten: 120, rhythmus: "täglich", start: 7 * 60, grund: grund)
            case .schlafen: return Vorschlag(id: "handy-weg", titel: "Handy weg ab 22 Uhr", art: .habit, minuten: 0, rhythmus: "täglich", start: 22 * 60, grund: grund)
            case .ruhe: return Vorschlag(id: "atmen", titel: "Atmen", art: .habit, minuten: 5, rhythmus: "täglich", start: s, grund: grund)
            case .anderes: return Vorschlag(id: "spaziergang", titel: "Spaziergang", art: .habit, minuten: 20, rhythmus: "3× je Woche", start: s, grund: grund)
            }
        }
    }
}
