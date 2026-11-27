import Foundation

// rechenregeln.md §15: Muster aus Journal (Stimmung), Habits, Fokus und Ablenkung. Reine Funktionen –
// die KI darf Muster in Worte fassen, nie selbst finden.

enum Muster {

    struct Befund: Identifiable, Equatable, Sendable {
        var id: String
        var text: String
        /// Unterschied in vergleichbaren Punkten (Stimmung × 20, Anteil × 100)
        var staerke: Double
        var tage: Int
    }

    static let fenster = 56
    static let mindestJeGruppe = 5
    static let mindestGesamt = 14

    static func zahl(_ x: Double) -> String { String(format: "%.1f", x).replacingOccurrences(of: ".", with: ",") }

    /// Alle Muster, stärkste zuerst (Gleichstand: mehr Tage), ohne stumm geschaltete.
    static func befunde(_ z: Zustand, heute: Tag, stumm: Set<String> = []) -> [Befund] {
        let tage = (1...fenster).map { heute.plus(tage: -$0) }
        let stimmung: [Tag: Double] = Dictionary(uniqueKeysWithValues: tage.compactMap { t in
            z.journal[t.text]?.stimmung.map { (t, Double($0)) } })
        var ergebnis: [Befund] = []

        // Habit und Stimmung
        for h in z.habits {
            let tageH = tage.filter { stimmung[$0] != nil && $0 >= h.angelegt && HabitRechnung.geplant(h, am: $0) }
            let a = tageH.filter { h.anteil(am: $0) >= 1 }.map { stimmung[$0]! }
            let b = tageH.filter { h.anteil(am: $0) < 1 }.map { stimmung[$0]! }
            if let f = vergleich(a, b, schwelle: 0.5, faktor: 20) {
                ergebnis.append(Befund(id: "habit-stimmung-\(h.id)", text: "An Tagen mit \(h.titel): Stimmung \(zahl(f.a)) statt \(zahl(f.b))", staerke: f.staerke, tage: a.count + b.count))
            }
        }

        // Fokus und Stimmung
        let minuten: (Tag) -> Double = { t in z.sitzungen.filter { $0.tag == t }.reduce(0) { $0 + $1.sekunden } / 60 }
        let tageS = tage.filter { stimmung[$0] != nil }
        if let f = vergleich(tageS.filter { minuten($0) >= 30 }.map { stimmung[$0]! }, tageS.filter { minuten($0) < 30 }.map { stimmung[$0]! }, schwelle: 0.5, faktor: 20) {
            ergebnis.append(Befund(id: "fokus-stimmung", text: "An Tagen mit 30 Min Fokus: Stimmung \(zahl(f.a)) statt \(zahl(f.b))", staerke: f.staerke, tage: f.n))
        }

        // Ablenkung und Stimmung / Habit
        if let ziel = Bildschirm.zielMinuten(z.bildschirmzeit, spanne: z.profil.spanne) {
            let mitDaten = tage.filter { Bildschirm.ablenkung(z.bildschirmzeit, am: $0) != nil }
            let ueber: (Tag) -> Bool = { (Bildschirm.ablenkung(z.bildschirmzeit, am: $0) ?? 0) > ziel }
            let tA = mitDaten.filter { stimmung[$0] != nil }
            if let f = vergleich(tA.filter(ueber).map { stimmung[$0]! }, tA.filter { !ueber($0) }.map { stimmung[$0]! }, schwelle: 0.5, faktor: 20) {
                ergebnis.append(Befund(id: "ablenkung-stimmung", text: "An Tagen über deinem Handy-Ziel: Stimmung \(zahl(f.a)) statt \(zahl(f.b))", staerke: f.staerke, tage: f.n))
            }
            for h in z.habits {
                let tH = mitDaten.filter { $0 >= h.angelegt && HabitRechnung.geplant(h, am: $0) }
                if let f = vergleich(tH.filter(ueber).map { min(1, h.anteil(am: $0)) }, tH.filter { !ueber($0) }.map { min(1, h.anteil(am: $0)) }, schwelle: 0.2, faktor: 100) {
                    ergebnis.append(Befund(id: "ablenkung-habit-\(h.id)", text: "Über deinem Handy-Ziel schaffst du \(h.titel) zu \(Int((f.a * 100).rounded())) % statt \(Int((f.b * 100).rounded())) %", staerke: f.staerke, tage: f.n))
                }
            }
        }
        // Auslastung und Stimmung (§15, gelesene Kalender) folgt mit dem Berater (Umbau Block N).

        return ergebnis.filter { !stumm.contains($0.id) }
            .sorted { $0.staerke != $1.staerke ? $0.staerke > $1.staerke : $0.tage > $1.tage }
    }

    /// Vergleich zweier Gruppen: je ≥ 5, zusammen ≥ 14, |Ø A − Ø B| ≥ Schwelle.
    static func vergleich(_ a: [Double], _ b: [Double], schwelle: Double, faktor: Double) -> (a: Double, b: Double, staerke: Double, n: Int)? {
        guard a.count >= mindestJeGruppe, b.count >= mindestJeGruppe, a.count + b.count >= mindestGesamt else { return nil }
        let ma = a.reduce(0, +) / Double(a.count), mb = b.reduce(0, +) / Double(b.count)
        guard abs(ma - mb) >= schwelle - 1e-9 else { return nil }
        return (ma, mb, abs(ma - mb) * faktor, a.count + b.count)
    }
}
