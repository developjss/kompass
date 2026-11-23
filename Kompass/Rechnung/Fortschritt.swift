import Foundation

// rechenregeln.md §1–§3. Reine Funktionen: gleiche Eingabe → gleiche Zahl. Keine KI, keine Uhr – `heute` wird übergeben.

enum Fortschritt {

    struct SchrittStand: Equatable, Sendable {
        /// 0…1
        var anteil: Double
        var text: String
        var hinweis: String?
        var gewicht: Int
    }

    static func gewicht(_ s: Schritt) -> Int { [1, 2, 3].contains(s.gewicht) ? s.gewicht : 1 }

    static func begrenzt(_ x: Double) -> Double { x.isFinite ? min(1, max(0, x)) : 0 }

    /// Einmalige Aufgaben dieses Schritts (wiederkehrende zählen nicht in „erledigte ÷ alle“, §3).
    static func aufgaben(von s: Schritt, in z: Zustand) -> [Aufgabe] {
        z.aufgaben.filter { $0.schrittID == s.id && $0.einmalig }
    }

    static func stunden(von s: Schritt, in z: Zustand) -> Double {
        z.sitzungen.filter { $0.schrittID == s.id }.reduce(0) { $0 + $1.sekunden } / 3600
    }

    /// Erledigte Male des Habits seit Anlage des Schritts, bis heute.
    static func habitMale(von s: Schritt, in z: Zustand, heute: Tag) -> Int {
        guard let h = z.habit(s.habitID) else { return 0 }
        let ab = s.seit ?? Tag(1, 1, 1)
        return h.erledigt.filter { $0 >= ab && $0 <= heute }.count
    }

    /// Stand eines Schritts (§2). Abgehakt = 100 %, immer begrenzt auf 0–100 %, ungültiges Soll → 0 %.
    static func stand(_ s: Schritt, in z: Zustand, heute: Tag) -> SchrittStand {
        var p = 0.0
        var text = ""
        var hinweis: String?
        switch s.art {
        case .aufgaben:
            let alle = aufgaben(von: s, in: z)
            let fertig = alle.filter(\.erledigt).count
            p = alle.isEmpty ? 0 : 0.9 * Double(fertig) / Double(alle.count)
            text = alle.isEmpty ? (s.geschafft ? "abgehakt" : "noch offen") : "\(fertig) von \(alle.count) Aufgaben"
            if !alle.isEmpty && fertig == alle.count && !s.geschafft { hinweis = "Alle Aufgaben erledigt – zum Abschließen abhaken" }
        case .zeit:
            let h = stunden(von: s, in: z)
            let soll = s.soll ?? 0
            p = soll > 0 ? h / soll : 0
            text = "\(Zahl.text(h, stellen: 1)) von \(Zahl.text(max(soll, 0))) h"
            if !(soll > 0) { hinweis = "Soll-Stunden fehlen" }
        case .habit:
            let n = habitMale(von: s, in: z, heute: heute)
            let soll = s.soll ?? 0
            p = soll > 0 ? Double(n) / soll : 0
            if let h = z.habit(s.habitID) {
                text = "\(n) von \(Zahl.text(max(soll, 0)))× \(h.titel)"
            } else {
                text = "kein Habit gewählt"
                hinweis = "Habit wählen"
            }
        case .zahl:
            let a = s.start ?? 0, c = s.aktuell ?? 0, t = s.soll ?? 0
            p = anteil(start: a, aktuell: c, ziel: t)
            text = "\(Zahl.text(c)) von \(Zahl.text(t))\(s.einheit.map { " " + $0 } ?? "")"
        }
        p = begrenzt(p)
        if s.geschafft { p = 1 }
        return SchrittStand(anteil: p, text: text, hinweis: hinweis, gewicht: gewicht(s))
    }

    /// (aktuell − Start) ÷ (Ziel − Start); Start = Ziel → 1, wenn erreicht, sonst 0. Begrenzt auf 0…1.
    static func anteil(start: Double, aktuell: Double, ziel: Double) -> Double {
        let spanne = ziel - start
        if spanne == 0 { return aktuell == ziel ? 1 : 0 }
        return begrenzt((aktuell - start) / spanne)
    }

    /// Ziel-Fortschritt 0…1 (§1).
    static func ziel(_ g: Ziel, in z: Zustand, heute: Tag) -> Double {
        if g.status == .erreicht { return 1 }
        if let m = g.zahl { return anteil(start: m.start, aktuell: m.aktuell, ziel: m.ziel) }
        var summeGewicht = 0.0, summe = 0.0
        for s in g.schritte {
            let st = stand(s, in: z, heute: heute)
            summeGewicht += Double(st.gewicht)
            summe += Double(st.gewicht) * st.anteil
        }
        return summeGewicht > 0 ? summe / summeGewicht : 0
    }

    /// Nächster offener Schritt (Art Aufgaben oder Zeit, noch nicht 100 %), in den neue Aufgaben fallen (§3).
    static func naechsterOffenerSchritt(_ g: Ziel?, in z: Zustand, heute: Tag) -> Schritt? {
        g?.schritte.first { s in
            !s.geschafft && (s.art == .aufgaben || s.art == .zeit) && stand(s, in: z, heute: heute).anteil < 1
        }
    }

    /// Fokuszeit eines Ziels in Sekunden, optional begrenzt auf einen Zeitraum (beide Tage eingeschlossen).
    static func zeit(ziel id: UUID, in z: Zustand, von: Tag? = nil, bis: Tag? = nil) -> TimeInterval {
        z.sitzungen.filter { s in
            s.zielID == id && (von.map { s.tag >= $0 } ?? true) && (bis.map { s.tag <= $0 } ?? true)
        }.reduce(0) { $0 + $1.sekunden }
    }
}

/// Zahlen deutsch formatiert, deterministisch (keine Locale des Geräts).
enum Zahl {
    static func text(_ x: Double, stellen: Int = 0) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.numberStyle = .decimal
        f.maximumFractionDigits = stellen
        f.minimumFractionDigits = 0
        f.roundingMode = .halfUp
        return f.string(from: NSNumber(value: x)) ?? "\(x)"
    }

    static func prozent(_ anteil: Double) -> String { "\(Int((anteil * 100).rounded())) %" }

    /// 1 h 25 min · 45 min
    static func dauer(_ sekunden: TimeInterval) -> String {
        let m = Int((sekunden / 60).rounded())
        if m < 60 { return "\(m) min" }
        return m % 60 == 0 ? "\(m / 60) h" : "\(m / 60) h \(m % 60) min"
    }
}
