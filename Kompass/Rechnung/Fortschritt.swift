import Foundation

// rechenregeln.md §1–§3. Reine Funktionen: gleiche Eingabe → gleiche Zahl. Keine KI, keine Uhr – `heute` wird übergeben.
//
// Kurz: Ein Ziel besteht aus Meilensteinen. Fortschritt = gewichteter Durchschnitt ihrer Stände.
// Jeder Meilenstein misst sich auf genau eine Art (Abhaken, Zahl, Zeit, Habit). Aufgaben, Habits,
// Fokuszeit und Termine fließen nur über Meilensteine in die Prozente – alles andere ist „Einsatz“.

enum Fortschritt {

    struct SchrittStand: Equatable, Sendable {
        /// 0…1
        var anteil: Double
        /// eine Zeile, z. B. „3 von 5 Aufgaben“, „12 von 30 Fahrstunden“
        var text: String
        var hinweis: String?
        var gewicht: Int
    }

    static func gewicht(_ s: Schritt) -> Int { [1, 2, 3].contains(s.gewicht) ? s.gewicht : 1 }

    static func begrenzt(_ x: Double) -> Double { x.isFinite ? min(1, max(0, x)) : 0 }

    /// Einmalige Aufgaben dieses Meilensteins (wiederkehrende zählen nicht in „erledigte ÷ alle“, §3).
    static func aufgaben(von s: Schritt, in z: Zustand) -> [Aufgabe] {
        z.aufgaben.filter { $0.schrittID == s.id && $0.einmalig }
    }

    /// Termin-Vorkommen, die diesem Meilenstein zugeordnet sind (nur stattgefundene, bis heute).
    static func termine(von s: Schritt, in z: Zustand, heute: Tag) -> [TerminVorkommen] {
        z.termine.filter { $0.schrittID == s.id }.flatMap { l in l.vorkommen.filter { $0.tag >= l.seit && $0.tag <= heute } }
    }

    /// Stunden: Fokuszeit dieses Meilensteins + Dauer zugeordneter Termine.
    static func stunden(von s: Schritt, in z: Zustand, heute: Tag) -> Double {
        let fokus = z.sitzungen.filter { $0.schrittID == s.id }.reduce(0) { $0 + $1.sekunden } / 3600
        let termine = termine(von: s, in: z, heute: heute).reduce(0) { $0 + Double($1.minuten) } / 60
        return fokus + termine
    }

    /// Zahl: eingetragener Stand + 1 je zugeordnetem Termin.
    static func ist(von s: Schritt, in z: Zustand, heute: Tag) -> Double {
        (s.aktuell ?? s.start ?? 0) + Double(termine(von: s, in: z, heute: heute).count)
    }

    /// Habit: Summe der Tagesanteile (halb geschafft zählt halb) bzw. erfüllte Wochen seit Anlage des Meilensteins.
    static func habitWert(von s: Schritt, in z: Zustand, heute: Tag) -> Double {
        guard let h = z.habit(s.habitID) else { return 0 }
        let ab = max(s.seit ?? h.angelegt, h.angelegt)
        switch s.modus {
        case .anzahl: return HabitRechnung.summe(h, von: ab, bis: heute)
        case .wochen: return Double(HabitRechnung.erfuellteWochen(h, seit: ab, heute: heute))
        }
    }

    /// Stand eines Meilensteins (§2). Abgehakt = 100 %, immer begrenzt auf 0–100 %, ungültiges Soll → 0 %.
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
            let h = stunden(von: s, in: z, heute: heute)
            let soll = s.soll ?? 0
            p = soll > 0 ? h / soll : 0
            text = "\(Zahl.text(h, stellen: 1)) von \(Zahl.text(max(soll, 0))) h"
            if !(soll > 0) { hinweis = "Soll-Stunden fehlen" }
        case .habit:
            let n = habitWert(von: s, in: z, heute: heute)
            let soll = s.soll ?? 0
            p = soll > 0 ? n / soll : 0
            if let h = z.habit(s.habitID) {
                let name = h.titel == s.titel ? "" : " · \(h.titel)"
                text = s.modus == .wochen
                    ? "\(Zahl.text(n)) von \(Zahl.text(max(soll, 0))) Wochen\(name)"
                    : "\(Zahl.text(n, stellen: 1)) von \(Zahl.text(max(soll, 0)))×\(name)"
            } else {
                text = "kein Habit gewählt"
                hinweis = "Habit wählen"
            }
            if !(soll > 0) { hinweis = hinweis ?? "Soll fehlt" }
        case .zahl:
            let a = s.start ?? 0, c = ist(von: s, in: z, heute: heute), t = s.soll ?? 0
            p = anteil(start: a, aktuell: c, ziel: t)
            let e = s.einheit.map { $0.isEmpty ? "" : " " + $0 } ?? ""
            // abnehmende Ziele (86 → 75 kg) lesen sich als „81 kg · Ziel 75 kg“
            text = t >= a ? "\(Zahl.text(c)) von \(Zahl.text(t))\(e)" : "\(Zahl.text(c))\(e) · Ziel \(Zahl.text(t))\(e)"
        }
        p = begrenzt(p)
        if s.geschafft { p = 1 }
        return SchrittStand(anteil: p, text: text, hinweis: hinweis, gewicht: gewicht(s))
    }

    /// (aktuell − Start) ÷ (Ziel − Start); Start = Ziel → 1, wenn erreicht, sonst 0. Begrenzt auf 0…1.
    /// Funktioniert in beide Richtungen (Abnehmen 86 → 75 kg, Schulden −12.000 → 0 €).
    static func anteil(start: Double, aktuell: Double, ziel: Double) -> Double {
        let spanne = ziel - start
        if spanne == 0 { return aktuell == ziel ? 1 : 0 }
        return begrenzt((aktuell - start) / spanne)
    }

    /// Zwischenstände eines Zahl-Meilensteins, die schon erreicht sind (in Richtung des Ziels).
    static func erreichteSchwellen(_ s: Schritt, in z: Zustand, heute: Tag) -> [Double] {
        guard s.art == .zahl, let schwellen = s.schwellen else { return [] }
        let a = s.start ?? 0, c = ist(von: s, in: z, heute: heute), t = s.soll ?? 0
        return schwellen.filter { x in t >= a ? c >= x : c <= x }
    }

    /// Ziel-Fortschritt 0…1 (§1): Σ(Gewicht × Stand) ÷ Σ Gewicht. Als erreicht markiert = 1. Ohne Meilensteine 0.
    static func ziel(_ g: Ziel, in z: Zustand, heute: Tag) -> Double {
        if g.status == .erreicht { return 1 }
        var summeGewicht = 0.0, summe = 0.0
        for s in g.schritte {
            let st = stand(s, in: z, heute: heute)
            summeGewicht += Double(st.gewicht)
            summe += Double(st.gewicht) * st.anteil
        }
        return summeGewicht > 0 ? summe / summeGewicht : 0
    }

    /// Wie viele Prozentpunkte ein Meilenstein zum Ziel beiträgt (für „So wird gerechnet“).
    static func beitrag(_ s: Schritt, in g: Ziel, z: Zustand, heute: Tag) -> Double {
        let summe = g.schritte.reduce(0) { $0 + Double(gewicht($1)) }
        guard summe > 0 else { return 0 }
        return Double(gewicht(s)) * stand(s, in: z, heute: heute).anteil / summe
    }

    /// Nächster offener Meilenstein (Art Abhaken oder Zeit, noch nicht 100 %), in den neue Aufgaben fallen (§3).
    static func naechsterOffenerSchritt(_ g: Ziel?, in z: Zustand, heute: Tag) -> Schritt? {
        g?.schritte.first { s in
            !s.geschafft && (s.art == .aufgaben || s.art == .zeit) && stand(s, in: z, heute: heute).anteil < 1
        }
    }

    /// Einsatz: Fokuszeit eines Ziels + zugeordnete Termine in Sekunden, optional in einem Zeitraum (beide Tage eingeschlossen).
    static func zeit(ziel id: UUID, in z: Zustand, von: Tag? = nil, bis: Tag? = nil) -> TimeInterval {
        let imZeitraum = { (t: Tag) in (von.map { t >= $0 } ?? true) && (bis.map { t <= $0 } ?? true) }
        let fokus = z.sitzungen.filter { $0.zielID == id && imZeitraum($0.tag) }.reduce(0) { $0 + $1.sekunden }
        let termine = z.termine.filter { $0.zielID == id }
            .flatMap { l in l.vorkommen.filter { $0.tag >= l.seit && imZeitraum($0.tag) } }
            .reduce(0) { $0 + TimeInterval($1.minuten * 60) }
        return fokus + termine
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
