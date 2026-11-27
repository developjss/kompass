import Foundation

/// Art einer Einheit: Menge (zählen) oder Zeit (schaltet später den Timer frei).
enum EinheitArt: String, CaseIterable, Sendable {
    case menge = "Menge"
    case zeit = "Zeit"
}

/// Womit das Ziel eingestellt wird – je nach Einheit eine andere Auswahl im Opal-Stil.
enum ZielAuswahl: Sendable, Equatable {
    /// Nur erledigt / nicht erledigt
    case keine
    /// Waagrechtes Lineal mit Schnellwahl (Zeit, große Zahlen)
    case lineal
    /// Senkrechtes Rad mit heller Mittel-Kapsel (kleine ganze Zahlen)
    case rad
    /// Zwei Spalten: ganze Zahl und Nachkomma (km, l)
    case zweiSpalten
    /// Füllbalken wie Aufladen (ml)
    case fuellen
}

/// Eine Einheit mit fester Spanne, Schrittweite und Standardwert. Alle Werte stehen fest im Code (keine KI, kein Rechnen außerhalb).
struct Einheit: Identifiable, Hashable, Sendable {
    let id: String
    /// Name in der Liste und Mehrzahl hinter der Zahl („Schritte“)
    let name: String
    /// Einzahl hinter der 1 („Schritt“)
    let einzahl: String
    /// Kurzzeichen hinter der Zahl, falls anders als der Name („km“)
    let zeichen: String?
    let art: EinheitArt
    let auswahl: ZielAuswahl
    let von: Double
    let bis: Double
    let schritt: Double
    let standard: Double
    /// Schnellwahl-Kapseln über dem Lineal
    let schnellwahl: [Double]
    /// Beschriftung am Lineal alle n Striche
    let markeAlle: Int

    init(_ id: String, _ name: String, einzahl: String? = nil, zeichen: String? = nil, art: EinheitArt = .menge,
         auswahl: ZielAuswahl, von: Double, bis: Double, schritt: Double, standard: Double,
         schnellwahl: [Double] = [], markeAlle: Int = 5) {
        self.id = id; self.name = name; self.einzahl = einzahl ?? name; self.zeichen = zeichen
        self.art = art; self.auswahl = auswahl; self.von = von; self.bis = bis; self.schritt = schritt
        self.standard = standard; self.schnellwahl = schnellwahl; self.markeAlle = markeAlle
    }

    // MARK: Feste Liste

    static let keine = Einheit("keine", "Keine Einheit", auswahl: .keine, von: 1, bis: 1, schritt: 1, standard: 1)
    static let mal = Einheit("mal", "Mal", auswahl: .rad, von: 1, bis: 50, schritt: 1, standard: 1)
    static let schritte = Einheit("schritte", "Schritte", einzahl: "Schritt", auswahl: .lineal, von: 500, bis: 30_000, schritt: 500,
                                  standard: 10_000, schnellwahl: [5_000, 8_000, 10_000], markeAlle: 10)
    static let wiederholungen = Einheit("wiederholungen", "Wiederholungen", einzahl: "Wiederholung", auswahl: .rad, von: 1, bis: 200, schritt: 1, standard: 20)
    static let seiten = Einheit("seiten", "Seiten", einzahl: "Seite", auswahl: .rad, von: 1, bis: 200, schritt: 1, standard: 10)
    static let glaeser = Einheit("glaeser", "Gläser", einzahl: "Glas", auswahl: .rad, von: 1, bis: 20, schritt: 1, standard: 8)
    static let ml = Einheit("ml", "Milliliter", zeichen: "ml", auswahl: .fuellen, von: 250, bis: 3_000, schritt: 250, standard: 1_500)
    static let liter = Einheit("l", "Liter", zeichen: "l", auswahl: .zweiSpalten, von: 0.1, bis: 10, schritt: 0.1, standard: 2)
    static let meter = Einheit("m", "Meter", zeichen: "m", auswahl: .lineal, von: 100, bis: 20_000, schritt: 100,
                               standard: 1_000, schnellwahl: [500, 1_000, 5_000], markeAlle: 10)
    static let km = Einheit("km", "Kilometer", zeichen: "km", auswahl: .zweiSpalten, von: 0.1, bis: 100, schritt: 0.1, standard: 5)
    static let kcal = Einheit("kcal", "Kalorien", zeichen: "kcal", auswahl: .lineal, von: 50, bis: 3_000, schritt: 50,
                              standard: 500, schnellwahl: [250, 500, 1_000], markeAlle: 10)
    static let gramm = Einheit("g", "Gramm", zeichen: "g", auswahl: .lineal, von: 10, bis: 1_000, schritt: 10,
                               standard: 100, schnellwahl: [50, 100, 250], markeAlle: 10)

    static let sekunden = Einheit("sek", "Sekunden", einzahl: "Sekunde", art: .zeit, auswahl: .lineal, von: 5, bis: 600, schritt: 5,
                                  standard: 60, schnellwahl: [30, 60, 120], markeAlle: 6)
    static let minuten = Einheit("min", "Minuten", einzahl: "Minute", art: .zeit, auswahl: .lineal, von: 5, bis: 240, schritt: 5,
                                 standard: 30, schnellwahl: [15, 30, 60], markeAlle: 6)
    static let stunden = Einheit("std", "Stunden", einzahl: "Stunde", art: .zeit, auswahl: .lineal, von: 0.25, bis: 12, schritt: 0.25,
                                 standard: 1, schnellwahl: [1, 2, 4], markeAlle: 4)

    static let mengen: [Einheit] = [.keine, .mal, .schritte, .wiederholungen, .seiten, .glaeser, .ml, .liter, .meter, .km, .kcal, .gramm]
    static let zeiten: [Einheit] = [.sekunden, .minuten, .stunden]
    static let alle: [Einheit] = mengen + zeiten

    /// Eigene Einheit: Name frei, ganze Zahlen 1–100 im Rad.
    static func eigene(_ name: String) -> Einheit {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Einheit("eigen-\(n.lowercased())", n, auswahl: .rad, von: 1, bis: 100, schritt: 1, standard: 1)
    }

    var istEigene: Bool { id.hasPrefix("eigen-") }

    // MARK: Werte

    /// Alle wählbaren Werte von `von` bis `bis` in festen Schritten (ganzzahlig gezählt, ohne Rundungsfehler).
    var werte: [Double] {
        let anzahl = Int(((bis - von) / schritt).rounded())
        return (0...anzahl).map { gerundet(von + Double($0) * schritt) }
    }

    /// Nächster gültiger Wert (in der Spanne, auf dem Raster).
    func eingerastet(_ wert: Double) -> Double {
        let i = ((wert - von) / schritt).rounded()
        let max = ((bis - von) / schritt).rounded()
        return gerundet(von + Swift.min(Swift.max(i, 0), max) * schritt)
    }

    func index(von wert: Double) -> Int { Int(((eingerastet(wert) - von) / schritt).rounded()) }

    private func gerundet(_ x: Double) -> Double { (x * 100).rounded() / 100 }

    // MARK: Text

    private static let ort = Locale(identifier: "de_DE")

    /// Zahl ohne Einheit („10.000“, „2,5“).
    static func zahl(_ wert: Double) -> String {
        wert.formatted(.number.locale(ort).precision(.fractionLength(0...1)))
    }

    /// Zeit kompakt wie im Vorbild: „1h 25m“, „45m“, „1m 30s“, „30s“.
    static func zeit(sekunden: Int) -> String {
        let h = sekunden / 3600, m = (sekunden % 3600) / 60, s = sekunden % 60
        var teile: [String] = []
        if h > 0 { teile.append("\(h)h") }
        if m > 0 { teile.append("\(m)m") }
        if s > 0 || teile.isEmpty { teile.append("\(s)s") }
        return teile.joined(separator: " ")
    }

    /// Wert in Sekunden (nur Zeit-Einheiten).
    func sekunden(_ wert: Double) -> Int {
        switch id {
        case "sek": Int(wert.rounded())
        case "min": Int((wert * 60).rounded())
        case "std": Int((wert * 3600).rounded())
        default: 0
        }
    }

    /// Ganzer Ziel-Text: „10.000 Schritte“, „1 Glas“, „2,5 km“, „1h 25m“, „Einmal am Tag“.
    func text(_ wert: Double) -> String {
        switch art {
        case .zeit: return Einheit.zeit(sekunden: sekunden(wert))
        case .menge:
            if auswahl == .keine { return "Einmal am Tag" }
            return "\(Einheit.zahl(wert)) \(wort(wert))"
        }
    }

    /// Wort hinter der Zahl: Zeichen, sonst Einzahl bei 1, sonst Mehrzahl.
    func wort(_ wert: Double) -> String { zeichen ?? (wert == 1 ? einzahl : name) }

    /// Kurze Beschriftung am Lineal („30m“, „2h“, „5.000“).
    func marke(_ wert: Double) -> String {
        art == .zeit ? Einheit.zeit(sekunden: sekunden(wert)) : Einheit.zahl(wert)
    }

    /// Hilfstext unter Milliliter: in Gläsern zu 250 ml („6 Gläser à 250 ml“).
    static func glaeserText(ml: Double) -> String {
        let n = Int((ml / 250).rounded(.down))
        return "\(n) \(n == 1 ? "Glas" : "Gläser") à 250 ml"
    }

    /// Text der Schnellwahl-Kapseln („15m“, „1h“, „5.000“).
    func kapsel(_ wert: Double) -> String { marke(wert) }
}
