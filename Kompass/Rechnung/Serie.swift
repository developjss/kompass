import Foundation

// rechenregeln.md §18: Kompass-Serie (Flamme) und Meilensteine. Reine Funktionen.

enum KompassSerie {

    /// Liegt der Tag in einem Urlaub?
    static func imUrlaub(_ tag: Tag, _ urlaub: [Urlaub]) -> Bool {
        urlaub.contains { tag.text >= $0.von && tag.text <= $0.bis }
    }

    /// Zählt der Tag für die Serie? Fokus-Sitzung ≥ 10 Min · alle geplanten Habits erledigt (≥ 1 geplant) · Journal-Eintrag.
    static func zaehlt(_ z: Zustand, am tag: Tag) -> Bool {
        if z.sitzungen.contains(where: { $0.tag == tag && $0.sekunden >= 600 }) { return true }
        let geplant = z.habits.filter { $0.angelegt <= tag && HabitRechnung.geplant($0, am: tag) }
        if !geplant.isEmpty && geplant.allSatisfy({ $0.anteil(am: tag) >= 1 }) { return true }
        if let e = z.journal[tag.text], e.stimmung != nil || !e.satz.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        return false
    }

    /// Serie: Tage in Folge, die zählen. Heute zählt erst, wenn erfüllt; Urlaubstage zählen nicht und brechen nicht.
    static func laenge(_ z: Zustand, heute: Tag) -> Int {
        var n = 0
        var d = zaehlt(z, am: heute) ? heute : heute.plus(tage: -1)
        var schritte = 0
        while schritte < 3660 {
            schritte += 1
            if imUrlaub(d, z.urlaub) { d = d.plus(tage: -1); continue }
            guard zaehlt(z, am: d) else { break }
            n += 1
            d = d.plus(tage: -1)
        }
        return n
    }

    struct Meilenstein: Identifiable, Equatable, Sendable {
        enum Art: Sendable { case serie, fokusStunden }
        var id: String
        var art: Art
        var schwelle: Int
        var wert: Double
        var erreicht: Bool
        var anteil: Double { min(1, max(0, wert / Double(schwelle))) }
    }

    static let serienSchwellen = [7, 30, 100, 150, 300]
    static let fokusSchwellen = [10, 50, 100, 500, 1000, 2000]

    /// Alle Meilensteine mit Stand. Einmal erreicht (in `z.meilensteine` gemerkt) bleibt erreicht.
    static func meilensteine(_ z: Zustand, heute: Tag) -> [Meilenstein] {
        let serie = Double(laenge(z, heute: heute))
        let stunden = z.sitzungen.reduce(0) { $0 + $1.sekunden } / 3600
        let s = serienSchwellen.map { k -> Meilenstein in
            let id = "serie-\(k)"
            return Meilenstein(id: id, art: .serie, schwelle: k, wert: serie, erreicht: z.meilensteine[id] != nil || serie >= Double(k))
        }
        let f = fokusSchwellen.map { k -> Meilenstein in
            let id = "fokus-\(k)"
            return Meilenstein(id: id, art: .fokusStunden, schwelle: k, wert: stunden, erreicht: z.meilensteine[id] != nil || stunden >= Double(k))
        }
        return s + f
    }

    /// Neu erreichte Meilensteine merken; gibt die neuen Kennungen zurück (für die Feier).
    @discardableResult
    static func merken(_ z: inout Zustand, heute: Tag, jetzt: Date) -> [String] {
        let neu = meilensteine(z, heute: heute).filter { $0.erreicht && z.meilensteine[$0.id] == nil }.map(\.id)
        for id in neu { z.meilensteine[id] = jetzt }
        return neu
    }
}
