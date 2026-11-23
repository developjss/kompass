import Foundation

/// Meilenstein-Vorlagen aus dem Titel eines Ziels – Regeln, keine KI (habits-v2.md §9, Aufgabe z-v2).
/// „Führerschein Klasse B“ → Prüfung (Theorie · Theorieprüfung · Praxisprüfung); „75 kg“ → Zahl in kg; „10.000 € sparen“ → Zahl in €.
enum ZielVorschlag {

    struct Vorlage: Equatable, Sendable {
        var name: String
        var symbol: String
        var bereich: String
        var schritte: [Schritt]

        /// „Theorie lernen · Theorieprüfung ×2 · Praxisprüfung ×3“
        var kurz: String {
            schritte.map { s in
                var t = s.titel
                if s.art == .zahl, let soll = s.soll { t += " \(Zahl.text(soll))\(s.einheit.map { " " + $0 } ?? "")" }
                if s.gewicht > 1 { t += " ×\(s.gewicht)" }
                return t
            }.joined(separator: " · ")
        }

        static func == (a: Vorlage, b: Vorlage) -> Bool { a.name == b.name }
    }

    /// Vorlagen zum Titel, beste zuerst; „Drei Schritte“ ist immer dabei (als letzte, falls nicht beste).
    static func fuer(_ titel: String) -> [Vorlage] {
        let t = titel.lowercased()
        let zahl = zahlImTitel(t)
        var v: [Vorlage] = []
        func hat(_ w: String...) -> Bool { w.contains { t.contains($0) } }

        if hat("prüfung", "pruefung", "führerschein", "fuehrerschein", "lapl", "ppl", "examen", "klausur", "zertifikat", "abschluss", "bestehen", "bachelor", "master", "staatsexamen") {
            v.append(Vorlage(name: "Prüfung", symbol: "graduationcap.fill", bereich: "Lernen", schritte: [
                Schritt(titel: "Theorie lernen", art: .aufgaben, gewicht: 1),
                Schritt(titel: "Theorieprüfung bestanden", art: .aufgaben, gewicht: 2),
                Schritt(titel: "Praxisprüfung bestanden", art: .aufgaben, gewicht: 3),
            ]))
        }
        if hat("kg", "kilo", "abnehmen", "gewicht", "zunehmen") {
            v.append(Vorlage(name: "Gewicht", symbol: "figure.run", bereich: "Gesundheit", schritte: [
                Schritt(titel: "Gewicht", art: .zahl, gewicht: 3, soll: zahl ?? 75, start: nil, aktuell: nil, einheit: "kg"),
            ]))
        }
        if hat("€", "euro", "spar", "vermögen", "vermoegen", "geld", "rücklage", "ruecklage", "schulden", "millionär", "millionaer") {
            let soll = zahl ?? (hat("million") ? 1_000_000 : 10_000)
            v.append(Vorlage(name: "Geld als Zahl", symbol: "eurosign.circle.fill", bereich: "Finanzen", schritte: [
                Schritt(titel: hat("schulden") ? "Restschuld" : "Gespart", art: .zahl, gewicht: 3, soll: soll, start: hat("schulden") ? soll : 0, aktuell: hat("schulden") ? soll : 0, einheit: "€"),
            ]))
        }
        if hat("marathon", "laufen", "lauf ", "km", "kilometer", "rad", "schwimm", "triathlon", "wandern") {
            let strecke = zahl ?? (hat("halbmarathon") ? 21 : hat("marathon") ? 42 : 10)
            v.append(Vorlage(name: "Ausdauer", symbol: "figure.run", bereich: "Gesundheit", schritte: [
                Schritt(titel: "Längste Strecke", art: .zahl, gewicht: 2, soll: strecke, start: 0, aktuell: 0, einheit: "km"),
                Schritt(titel: "Wettkampf absolviert", art: .aufgaben, gewicht: 3),
            ]))
        }
        if hat("buch", "bücher", "buecher", "lesen") {
            v.append(Vorlage(name: "Bücher", symbol: "book.fill", bereich: "Lernen", schritte: [
                Schritt(titel: "Bücher gelesen", art: .zahl, gewicht: 3, soll: zahl ?? 12, start: 0, aktuell: 0, einheit: "Bücher"),
            ]))
        }
        if hat("sprache", "englisch", "spanisch", "französisch", "franzoesisch", "italienisch", "japanisch", "vokabel", "b1", "b2", "c1") {
            v.append(Vorlage(name: "Sprache", symbol: "character.book.closed.fill", bereich: "Lernen", schritte: [
                Schritt(titel: "Grundkurs abgeschlossen", art: .aufgaben, gewicht: 1),
                Schritt(titel: "Vokabeln", art: .zahl, gewicht: 2, soll: zahl ?? 1000, start: 0, aktuell: 0, einheit: "Wörter"),
                Schritt(titel: "Erstes Gespräch geführt", art: .aufgaben, gewicht: 2),
            ]))
        }
        if hat("projekt", "app", "website", "webseite", "launch", "veröffentlich", "veroeffentlich", "gründ", "gruend", "firma", "schreiben", "roman", "podcast") {
            v.append(Vorlage(name: "Projekt", symbol: "hammer.fill", bereich: "Arbeit", schritte: [
                Schritt(titel: "Geplant", art: .aufgaben, gewicht: 1),
                Schritt(titel: "Umgesetzt", art: .aufgaben, gewicht: 3),
                Schritt(titel: "Veröffentlicht", art: .aufgaben, gewicht: 2),
            ]))
        }
        v.append(dreiSchritte)
        return v
    }

    static let dreiSchritte = Vorlage(name: "Drei Schritte", symbol: "target", bereich: "Allgemein", schritte: [
        Schritt(titel: "Vorbereitet", art: .aufgaben, gewicht: 1),
        Schritt(titel: "Umgesetzt", art: .aufgaben, gewicht: 2),
        Schritt(titel: "Abgeschlossen", art: .aufgaben, gewicht: 1),
    ])

    /// Erste Zahl im Titel („75 kg“ → 75, „10.000 €“ → 10000, „2,5“ → 2.5); Jahreszahlen zählen nicht.
    static func zahlImTitel(_ t: String) -> Double? {
        guard let r = t.range(of: #"\d+([.,]\d+)*"#, options: .regularExpression) else { return nil }
        let roh = String(t[r])
        let tausender = roh.range(of: #"^\d{1,3}(\.\d{3})+$"#, options: .regularExpression) != nil
        let text = tausender ? roh.replacingOccurrences(of: ".", with: "") : roh.replacingOccurrences(of: ",", with: ".")
        guard let z = Double(text), z > 0 else { return nil }
        if (1990...2100).contains(z), roh.count == 4 { return nil }
        return z
    }
}
