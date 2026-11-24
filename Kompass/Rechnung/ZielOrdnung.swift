import Foundation

/// Ziele-Übersicht: filtern (Alle · Auf Kurs · Hinterher · Erreicht), sortieren und gruppieren – deterministisch, ohne Rechnen in der Ansicht.
enum ZielOrdnung {

    enum Filter: String, CaseIterable, Sendable {
        case alle, aufKurs, hinterher, erreicht
        var titel: String {
            switch self {
            case .alle: "Alle"
            case .aufKurs: "Auf Kurs"
            case .hinterher: "Hinterher"
            case .erreicht: "Erreicht"
            }
        }
    }

    enum Sortierung: String, CaseIterable, Sendable {
        case frist, jahr, fortschritt, hinterherZuerst, bereich, name
        var titel: String {
            switch self {
            case .frist: "Nach Frist"
            case .jahr: "Nach Jahr"
            case .fortschritt: "Nach Fortschritt"
            case .hinterherZuerst: "Hinterher zuerst"
            case .bereich: "Nach Bereich"
            case .name: "Nach Name"
            }
        }
        var symbol: String {
            switch self {
            case .frist: "calendar"
            case .jahr: "calendar.badge.clock"
            case .fortschritt: "chart.bar.fill"
            case .hinterherZuerst: "exclamationmark.triangle"
            case .bereich: "square.grid.2x2"
            case .name: "textformat"
            }
        }
    }

    struct Gruppe: Equatable, Sendable {
        /// nil = ohne Überschrift
        var titel: String?
        var ziele: [Ziel]
    }

    /// Gehört ein Ziel in den Filter? Erreicht zählt nur bei „Erreicht“; „Auf Kurs“ = im Plan oder voraus.
    static func passt(_ g: Ziel, _ f: Filter, in z: Zustand, heute: Tag) -> Bool {
        switch f {
        case .alle: return g.status == .aktiv
        case .erreicht: return g.status == .erreicht
        case .aufKurs, .hinterher:
            guard g.status == .aktiv else { return false }
            let l = Kurs.aufKurs(g, in: z, heute: heute).lage
            return f == .aufKurs ? (l == .imPlan || l == .voraus) : (l == .hinterher || l == .ueberfaellig)
        }
    }

    static func anzahl(_ f: Filter, in z: Zustand, heute: Tag) -> Int { z.ziele.filter { passt($0, f, in: z, heute: heute) }.count }

    /// Gefilterte Ziele, sortiert und – bei Jahr/Bereich – gruppiert. Gleichstand immer nach Frist, dann Titel.
    static func gruppen(_ z: Zustand, filter f: Filter, sortierung s: Sortierung, heute: Tag) -> [Gruppe] {
        let liste = z.ziele.filter { passt($0, f, in: z, heute: heute) }
        let fortschritt = Dictionary(uniqueKeysWithValues: liste.map { ($0.id, Kurs.aufKurs($0, in: z, heute: heute)) })
        func nachFrist(_ a: Ziel, _ b: Ziel) -> Bool { (a.faellig, a.titel) < (b.faellig, b.titel) }
        switch s {
        case .frist:
            return liste.isEmpty ? [] : [Gruppe(titel: nil, ziele: liste.sorted(by: nachFrist))]
        case .name:
            return liste.isEmpty ? [] : [Gruppe(titel: nil, ziele: liste.sorted { $0.titel.localizedStandardCompare($1.titel) == .orderedAscending })]
        case .fortschritt:
            return liste.isEmpty ? [] : [Gruppe(titel: nil, ziele: liste.sorted {
                let a = fortschritt[$0.id]!.fortschritt, b = fortschritt[$1.id]!.fortschritt
                return a != b ? a > b : nachFrist($0, $1)
            })]
        case .hinterherZuerst:
            // Abstand zum Plan: am weitesten hinten zuerst
            return liste.isEmpty ? [] : [Gruppe(titel: nil, ziele: liste.sorted {
                let a = fortschritt[$0.id]!, b = fortschritt[$1.id]!
                let da = a.fortschritt - a.erwartet, db = b.fortschritt - b.erwartet
                return da != db ? da < db : nachFrist($0, $1)
            })]
        case .jahr:
            return Dictionary(grouping: liste) { $0.faellig.jahr }.sorted { $0.key < $1.key }
                .map { Gruppe(titel: String($0.key), ziele: $0.value.sorted(by: nachFrist)) }
        case .bereich:
            return Dictionary(grouping: liste) { $0.bereich.isEmpty ? "Ohne Bereich" : $0.bereich }
                .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
                .map { Gruppe(titel: $0.key, ziele: $0.value.sorted(by: nachFrist)) }
        }
    }
}

extension Fortschritt {
    /// Anteil jedes Meilensteins am Ziel: Gewicht ÷ Σ Gewicht (rechenregeln.md §1). Leere Liste → leer.
    static func anteile(_ gewichte: [Int]) -> [Double] {
        let g = gewichte.map { [1, 2, 3].contains($0) ? $0 : 1 }
        let summe = g.reduce(0, +)
        return summe == 0 ? [] : g.map { Double($0) / Double(summe) }
    }

    /// Anteil eines neuen oder geänderten Meilensteins mit Gewicht `gewicht` (ersetzt `ersetzt`, falls gesetzt).
    static func anteilVorschau(_ g: Ziel, gewicht: Int, ersetzt: UUID? = nil) -> Double {
        let andere = g.schritte.filter { $0.id != ersetzt }.map(Fortschritt.gewicht)
        return anteile(andere + [gewicht]).last ?? 1
    }

    /// Anteile der übrigen Meilensteine, wenn einer wegfällt (für „Was passiert beim Löschen?“).
    static func anteileOhne(_ g: Ziel, ohne id: UUID) -> [(Schritt, Double)] {
        let rest = g.schritte.filter { $0.id != id }
        return Array(zip(rest, anteile(rest.map(Fortschritt.gewicht))))
    }
}
