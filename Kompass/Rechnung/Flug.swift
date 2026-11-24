import Foundation

/// Fokus als Flug (Gadget, design.md §7): nur Anzeige. Die Fokuszeit selbst zählt und bucht weiter `FokusRechnung`.
/// Flugdauer = geplante Dauer der Aufgabe; nach der Landung läuft der Timer normal weiter.
enum FlugRechnung {

    enum Phase: String, Sendable, Equatable {
        case boarding, steigflug, reiseflug, landeanflug, gelandet, warteschleife

        var text: String {
            switch self {
            case .boarding: "Boarding – bereit zum Start"
            case .steigflug: "Startlauf und Steigflug"
            case .reiseflug: "Reiseflughöhe – ruhig weiterarbeiten"
            case .landeanflug: "Landeanflug"
            case .gelandet: "Gelandet – geplante Zeit geschafft"
            case .warteschleife: "Warteschleife – Pause"
            }
        }
    }

    /// Anteil der Strecke 0…1 = Fokuszeit ÷ geplante Dauer (mindestens 5 Minuten).
    static func strecke(sekunden: TimeInterval, dauerMinuten: Int) -> Double {
        let d = Double(max(5, dauerMinuten)) * 60
        return min(1, max(0, sekunden / d))
    }

    static func phase(strecke p: Double, sekunden: TimeInterval, laeuft: Bool) -> Phase {
        if p >= 1 { return .gelandet }
        if sekunden <= 0 { return .boarding }
        if !laeuft { return .warteschleife }
        if p < 0.15 { return .steigflug }
        if p < 0.8 { return .reiseflug }
        return .landeanflug
    }

    /// Flugfläche wie im Cockpit: Sinusbogen bis FL350, auf 10 gerundet („FL240“).
    static func flugflaeche(strecke p: Double) -> Int {
        Int((sin(p * .pi) * 35).rounded()) * 10
    }

    /// Restminuten bis zur Landung (aufgerundet), 0 nach der Landung.
    static func restMinuten(sekunden: TimeInterval, dauerMinuten: Int) -> Int {
        let rest = Double(max(5, dauerMinuten)) * 60 - sekunden
        return rest <= 0 ? 0 : Int((rest / 60).rounded(.up))
    }

    /// Flughafen-Kürzel aus einem Titel: drei Buchstaben, Umlaute aufgelöst („Führerschein“ → „FUH“).
    static func kuerzel(_ titel: String) -> String {
        let s = titel.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE")).uppercased()
        let b = s.filter { $0.isLetter && $0.isASCII }
        return String((b + "XXX").prefix(3))
    }
}
