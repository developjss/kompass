import Foundation

/// Wie eine Aufgabe für ein Ziel zählt – und warum (nicht). Nur Erklärung der bestehenden Regel (rechenregeln.md §3):
/// Meilenstein „Aufgaben“ = erledigte einmalige ÷ alle einmaligen (bis 90 %, Abhaken macht 100 %),
/// Meilenstein „Zeit“ = Fokuszeit zählt. Ohne Meilenstein zählt die Aufgabe nur als Einsatz.
enum Einordnung: Equatable, Sendable {
    case keinZiel
    /// Ziel gewählt, aber kein Meilenstein, der Aufgaben zählt (oder „Nur Einsatz“ gewählt)
    case nurEinsatz(ziel: String, passenderMeilenstein: Bool)
    /// Wiederkehrende Aufgabe in einem „Aufgaben“-Meilenstein: zählt dort nicht
    case wiederkehrendZaehltNicht(ziel: String, meilenstein: String)
    /// Erledigen bringt `punkte` Prozentpunkte (0…1) am Ziel; `anzahl` Aufgaben im Meilenstein
    case aufgaben(ziel: String, meilenstein: String, anzahl: Int, punkte: Double)
    /// Fokuszeit zählt in einen „Zeit“-Meilenstein
    case fokuszeit(ziel: String, meilenstein: String, sollStunden: Double?)

    /// Einordnung einer Aufgabe. `neu` = die Aufgabe ist noch nicht angelegt (zählt dann zusätzlich mit).
    static func fuer(zielID: UUID?, schrittID: UUID?, einmalig: Bool, aufgabeID: UUID?, in z: Zustand) -> Einordnung {
        guard let g = z.ziel(zielID) else { return .keinZiel }
        let passend = g.schritte.contains { $0.art == .aufgaben || $0.art == .zeit }
        guard let i = g.schritte.firstIndex(where: { $0.id == schrittID }) else {
            return .nurEinsatz(ziel: g.titel, passenderMeilenstein: passend)
        }
        let s = g.schritte[i]
        switch s.art {
        case .aufgaben:
            guard einmalig else { return .wiederkehrendZaehltNicht(ziel: g.titel, meilenstein: s.titel) }
            var anzahl = Fortschritt.aufgaben(von: s, in: z).count
            if aufgabeID == nil || !Fortschritt.aufgaben(von: s, in: z).contains(where: { $0.id == aufgabeID }) { anzahl += 1 }
            let anteil = Fortschritt.anteile(g.schritte.map(Fortschritt.gewicht))[i]
            return .aufgaben(ziel: g.titel, meilenstein: s.titel, anzahl: anzahl, punkte: anteil * 0.9 / Double(max(1, anzahl)))
        case .zeit:
            return .fokuszeit(ziel: g.titel, meilenstein: s.titel, sollStunden: s.soll)
        default:
            return .nurEinsatz(ziel: g.titel, passenderMeilenstein: passend)
        }
    }

    /// Ein Satz für die Oberfläche.
    var satz: String {
        switch self {
        case .keinZiel:
            return "Zählt für kein Ziel. Wähle eins, wenn die Aufgabe dich einem Ziel näher bringt."
        case .nurEinsatz(let g, let passend):
            return passend
                ? "Zählt für „\(g)“ nur als Einsatz – die Prozente ändern sich nicht. Wähle einen Meilenstein, damit sie zählt."
                : "Zählt für „\(g)“ nur als Einsatz. Für Prozente braucht das Ziel einen Meilenstein „Aufgaben“ oder „Zeit“."
        case .wiederkehrendZaehltNicht(let g, let m):
            return "Wiederkehrende Aufgaben zählen in „\(m)“ (\(g)) nicht mit – dort zählen nur einmalige. Ihre Fokuszeit zählt als Einsatz."
        case .aufgaben(let g, let m, let n, let p):
            let pp = Zahl.text(p * 100, stellen: p * 100 < 10 ? 1 : 0)
            return n == 1
                ? "Erledigt bringt „\(g)“ rund \(pp) Prozentpunkte – die einzige Aufgabe in „\(m)“."
                : "Erledigt bringt „\(g)“ rund \(pp) Prozentpunkte – eine von \(n) Aufgaben in „\(m)“."
        case .fokuszeit(let g, let m, let soll):
            return "Jede Minute Fokus zählt in „\(m)“ (\(g))\(soll.map { ", Soll \(Zahl.text($0)) h" } ?? "")."
        }
    }

    /// Zählt sie in die Prozente?
    var zaehlt: Bool {
        switch self {
        case .aufgaben, .fokuszeit: true
        default: false
        }
    }
}
