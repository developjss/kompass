import Foundation

// rechenregeln.md §19: Tageswert 0–100 aus Habits, Fokus, Ablenkung, Journal. Reine Funktionen.

enum Tageswert {

    /// Fokusziel in Minuten aus der Lebenslage (änderbar später).
    static func fokusZiel(_ p: Profil) -> Int {
        switch p.lebenslage {
        case .schule, .ausbildung, .studium: 90
        case .job, .selbststaendig: 60
        default: 45
        }
    }

    struct Teile: Equatable, Sendable {
        var habits: Double?
        var fokus: Double
        var ablenkung: Double?
        var journal: Double
    }

    static let gewichte = (habits: 40.0, fokus: 25.0, ablenkung: 25.0, journal: 10.0)

    static func teile(_ z: Zustand, am tag: Tag) -> Teile {
        let geplant = z.habits.filter { $0.angelegt <= tag && HabitRechnung.geplant($0, am: tag) }
        let habits = geplant.isEmpty ? nil : geplant.reduce(0) { $0 + min(1, $1.anteil(am: tag)) } / Double(geplant.count)
        let minuten = z.sitzungen.filter { $0.tag == tag }.reduce(0) { $0 + $1.sekunden } / 60
        let fokus = min(1, minuten / Double(fokusZiel(z.profil)))
        var ablenkung: Double?
        if let m = Bildschirm.ablenkung(z.bildschirmzeit, am: tag), let ziel = Bildschirm.zielMinuten(z.bildschirmzeit, spanne: z.profil.spanne) {
            ablenkung = Bildschirm.ablenkungsWert(minuten: m, ziel: ziel)
        }
        let e = z.journal[tag.text]
        let journal = (e?.stimmung != nil || !(e?.satz ?? "").isEmpty) ? 1.0 : 0.0
        return Teile(habits: habits, fokus: fokus, ablenkung: ablenkung, journal: journal)
    }

    /// Wert 0–100; fehlende Teile werden anteilig aus den übrigen Gewichten hochgerechnet.
    static func wert(_ t: Teile) -> Int {
        var summe = t.fokus * gewichte.fokus + t.journal * gewichte.journal
        var gewicht = gewichte.fokus + gewichte.journal
        if let h = t.habits { summe += h * gewichte.habits; gewicht += gewichte.habits }
        if let a = t.ablenkung { summe += a * gewichte.ablenkung; gewicht += gewichte.ablenkung }
        return Int((summe / gewicht * 100).rounded())
    }

    static func wert(_ z: Zustand, am tag: Tag) -> Int { wert(teile(z, am: tag)) }

    /// Ø der gespeicherten Tageswerte einer Woche (Mo–So), nil ohne Werte.
    static func wochenSchnitt(_ z: Zustand, montag: Tag) -> Int? {
        let werte = (0..<7).compactMap { z.tageswerte[montag.plus(tage: $0).text] }
        guard !werte.isEmpty else { return nil }
        return Int((Double(werte.reduce(0, +)) / Double(werte.count)).rounded())
    }
}
