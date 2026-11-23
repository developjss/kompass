import Foundation

/// Schlägt aus dem Titel eines Habits Menge und Einheit vor – Regeln, keine KI (habits-v2.md §6).
/// „20 Minuten lesen“ → 20 min · „Erdnüsse“ → 300 g · „Kein Handy nach 22 Uhr“ → nur abhaken.
enum HabitVorschlag {

    struct Vorschlag: Equatable, Sendable {
        var menge: Double?
        var einheit: Einheit?
        /// true = Verzicht/Ja-Nein, keine Menge sinnvoll
        var nurAbhaken = false
        var symbol: String = "star.fill"
    }

    private static let regeln: [(woerter: [String], menge: Double, einheit: Einheit, symbol: String)] = [
        (["lesen", "buch"], 20, .minuten, "book.fill"),
        (["seite"], 20, .seiten, "book.fill"),
        (["lernen", "üben", "ueben", "theorie", "vokabel", "wiederhol", "hausaufgabe", "kurs"], 30, .minuten, "graduationcap.fill"),
        (["meditier", "atem", "achtsam", "journal", "tagebuch", "dankbar"], 10, .minuten, "leaf.fill"),
        (["dehn", "yoga", "mobil"], 15, .minuten, "figure.yoga"),
        (["lauf", "jogg", "rennen"], 5, .kilometer, "figure.run"),
        (["spazier", "gehen", "wandern"], 30, .minuten, "figure.walk"),
        (["rad", "fahrrad", "bike"], 10, .kilometer, "bicycle"),
        (["schwimm"], 1, .kilometer, "figure.pool.swim"),
        (["sport", "training", "trainier", "workout", "gym", "fitness", "krafttraining"], 45, .minuten, "dumbbell.fill"),
        (["liegestütz", "liegestuetz", "klimmz", "kniebeug", "sit-up", "situp", "crunch", "wiederholung", "sätze", "saetze"], 30, .mal, "figure.strengthtraining.traditional"),
        (["schritte"], 8000, .schritte, "figure.walk"),
        (["wasser", "trink"], 2, .liter, "drop.fill"),
        (["protein", "eiweiß", "eiweiss"], 120, .gramm, "fork.knife"),
        (["nüsse", "nuesse", "erdnüss", "erdnuess", "mandel", "gemüse", "gemuese", "obst", "salat", "haferflocken", "essen", "gramm"], 300, .gramm, "fork.knife"),
        (["schlaf"], 8, .stunden, "bed.double.fill"),
        (["musik", "üben", "gitarre", "klavier", "instrument"], 20, .minuten, "music.note"),
        (["schreib", "code", "programm", "projekt", "arbeit"], 60, .minuten, "pencil"),
        (["zähne", "zaehne", "zahnseide", "vitamin", "tablette", "medikament"], 1, .mal, "checkmark.seal.fill"),
    ]

    private static let verzicht = ["kein ", "keine ", "nicht ", "ohne ", "verzicht", "kein handy", "kein zucker", "kein alkohol", "rauchfrei"]

    static func fuer(_ titel: String) -> Vorschlag {
        let t = titel.lowercased().trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return Vorschlag() }
        if verzicht.contains(where: { t.hasPrefix($0) || t.contains(" " + $0) }) {
            return Vorschlag(nurAbhaken: true, symbol: "hand.raised.fill")
        }
        // Zahl + Einheit im Titel („20 Minuten“, „300 g“, „2 l“, „5 km“, „30×“)
        var v = Vorschlag()
        if let (m, e) = zahlUndEinheit(t) { v.menge = m; v.einheit = e }
        for r in regeln where r.woerter.contains(where: { t.contains($0) }) {
            v.symbol = r.symbol
            if v.einheit == nil { v.einheit = r.einheit; v.menge = r.menge }
            else if v.menge == nil { v.menge = r.menge }
            break
        }
        return v
    }

    private static let einheitWoerter: [(String, Einheit)] = [
        ("minuten", .minuten), ("minute", .minuten), ("min", .minuten), ("stunden", .stunden), ("stunde", .stunden), ("std", .stunden), ("h ", .stunden),
        ("sekunden", .sekunden), ("sek", .sekunden), ("kilogramm", .kilogramm), ("kg", .kilogramm), ("gramm", .gramm), ("g ", .gramm),
        ("milliliter", .milliliter), ("ml", .milliliter), ("liter", .liter), ("l ", .liter), ("seiten", .seiten), ("seite", .seiten),
        ("kilometer", .kilometer), ("km", .kilometer), ("schritte", .schritte), ("mal", .mal), ("×", .mal), ("x ", .mal), ("stück", .mal), ("stk", .mal),
    ]

    /// „300 g Erdnüsse“ → (300, gramm); „20 Minuten“ → (20, minuten); „3×“ → (3, mal)
    static func zahlUndEinheit(_ t: String) -> (Double, Einheit)? {
        guard let r = t.range(of: #"(\d+([.,]\d+)?)\s*([a-zäöü×]+)?"#, options: .regularExpression) else { return nil }
        let teil = String(t[r])
        let roh = String(teil.prefix { "0123456789.,".contains($0) })
        // deutsch: „10.000“ = zehntausend, „2,5“ = zweieinhalb
        let tausender = roh.range(of: #"^\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil
        let zahlText = tausender ? roh.replacingOccurrences(of: ".", with: "") : roh.replacingOccurrences(of: ",", with: ".")
        guard let zahl = Double(zahlText), zahl > 0 else { return nil }
        let rest = teil.dropFirst(roh.count).trimmingCharacters(in: .whitespaces) + " "
        for (w, e) in einheitWoerter where rest.hasPrefix(w) { return (zahl, e) }
        return nil
    }

    /// Schnellwahl beim Eintragen: halb, ganz, ganz + ein Viertel.
    static func schnellwahl(soll: Double) -> [Double] {
        let stufen = [0.25, 0.5, 0.75, 1, 1.25].map { ($0 * soll).rounded() }
        return Array(Set(stufen.filter { $0 > 0 })).sorted()
    }
}
