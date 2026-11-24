import Foundation

// Beispieltermine statt echter Kalender (wie im Klick-Dummy). Echte Anbindung: EventKit / Google, Aufgabe `s-eventkit`.

struct Termin: Identifiable, Hashable, Sendable {
    enum Quelle: String, Sendable { case google, apple, kompass
        var name: String {
            switch self {
            case .google: "Google"
            case .apple: "Apple"
            case .kompass: "Kompass"
            }
        }
        var farbe: String {
            switch self {
            case .google: "#4285F4"
            case .apple: "#FF5A5F"
            case .kompass: "#3B4CCA"
            }
        }
    }

    var id: String { "\(quelle.rawValue):\(schluessel):\(tag.text)" }
    var quelle: Quelle
    var schluessel: String
    var titel: String
    var tag: Tag
    /// Minuten seit Mitternacht; nil = ganztägig
    var start: Int?
    var ende: Int?
    /// Nur bei Kompass-Terminen bzw. Apple-Kalenderfarbe
    var eigenID: UUID? = nil
    var kategorie: Kategorie? = nil
    var zielID: UUID? = nil
    var habitID: UUID? = nil
    var kalenderFarbe: String? = nil
    /// Teil einer Serie (Apple/Google: Wiederholungsregel; Kompass: Wiederholung)
    var wiederkehrend = false
}

enum Beispieltermine {

    static func termine(am d: Tag, google: Bool, apple: Bool, heute: Tag) -> [Termin] {
        let w = d.wochentag
        let dieseWoche = d.montag == heute.montag
        var out: [Termin] = []
        func add(_ q: Termin.Quelle, _ k: String, _ t: String, _ s: Int?, _ e: Int?) {
            out.append(Termin(quelle: q, schluessel: k, titel: t, tag: d, start: s, ende: e))
        }
        if google {
            if w == 1 { add(.google, "team", "Team-Meeting", 9 * 60, 10 * 60) }
            if w == 3 { add(.google, "zahn", "Zahnarzt", 15 * 60, 15 * 60 + 45) }
            if w == 4 { add(.google, "fahr", "Fahrstunde", 17 * 60, 18 * 60 + 30) }
            if w == 2 { add(.google, "fahr2", "Fahrstunde", 16 * 60, 17 * 60 + 30) }
            if w == 5 && dieseWoche { add(.google, "bday1", "Geburtstag Lena", nil, nil) }
            if w == 6 { add(.google, "flug", "Schnupperflug Flugplatz", 11 * 60, 13 * 60) }
        }
        if apple {
            if w == 2 || w == 4 { add(.apple, "gym", "Fitnessstudio", 7 * 60, 8 * 60) }
            if w == 7 { add(.apple, "fam", "Abendessen Familie", 18 * 60, 20 * 60) }
            if w == 3 { add(.apple, "call", "Call mit Steuerberater", 12 * 60, 12 * 60 + 30) }
            if w == 1 && dieseWoche { add(.apple, "bday2", "Geburtstag Opa", nil, nil) }
            if w == 6 { add(.apple, "markt", "Wochenmarkt", 9 * 60, 10 * 60) }
        }
        return out.sorted { ($0.start ?? -1) < ($1.start ?? -1) }
    }

    /// Alle Serien der nächsten 14 Tage (für „Termin-Serie zuordnen“), ohne ganztägige.
    static func serien(google: Bool, apple: Bool, heute: Tag) -> [(serie: String, titel: String, wann: String)] {
        let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        var gesehen: [String: (String, String)] = [:]
        var reihenfolge: [String] = []
        for i in 0..<14 {
            let d = heute.plus(tage: i)
            for t in termine(am: d, google: google, apple: apple, heute: heute) where t.start != nil {
                let k = "\(t.quelle.rawValue):\(t.schluessel)"
                if gesehen[k] == nil {
                    gesehen[k] = (t.titel, "\(namen[d.wochentag - 1]) \(uhrzeit(t.start ?? 0))–\(uhrzeit(t.ende ?? 0)) · \(t.quelle.name)")
                    reihenfolge.append(k)
                }
            }
        }
        return reihenfolge.map { ($0, gesehen[$0]!.0, gesehen[$0]!.1) }
    }

    static func uhrzeit(_ m: Int) -> String { String(format: "%02d:%02d", m / 60, m % 60) }
}
