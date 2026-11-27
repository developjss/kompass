import Foundation

// rechenregeln.md §16 (Handy-Jahre) und §17 (Ablenkung, Ziel, Hinweise, Sperre). Reine Funktionen.

enum Bildschirm {

    /// §16: Stunden je Tag = Mitte der Spanne; „weiß nicht“ → nil (kein Zahlen-Bildschirm).
    static func stunden(_ s: BildschirmSpanne) -> Double? {
        switch s {
        case .unter1: 0.5
        case .eins3: 2
        case .drei4: 3.5
        case .vier5: 4.5
        case .fuenf7: 6
        case .ueber7: 8
        case .weissNicht: nil
        }
    }

    struct HandyJahre: Equatable, Sendable {
        /// Wache Tage je Jahr am Handy
        var tageJeJahr: Int
        /// Wache Jahre bis 80 (nil bei Alter außerhalb 10…79)
        var jahreBis80: Int?
        /// Mit 30 % weniger zurückgewonnen
        var jahreZurueck: Int?
        var tageZurueck: Int
    }

    /// §16: Wache Tage = Stunden × 365 ÷ 16; Jahre bis 80 = Tage × (80 − Alter) ÷ 365; zurück = 30 % davon.
    static func handyJahre(_ s: BildschirmSpanne, alter: Int?) -> HandyJahre? {
        guard let h = stunden(s) else { return nil }
        let tage = h * 365 / 16
        var jahre: Double?
        if let a = alter, (10...79).contains(a) { jahre = tage * Double(80 - a) / 365 }
        return HandyJahre(tageJeJahr: Int(tage.rounded()), jahreBis80: jahre.map { Int($0.rounded()) },
                          jahreZurueck: jahre.map { Int(($0 * 0.3).rounded()) }, tageZurueck: Int((tage * 0.3).rounded()))
    }

    /// §17: Ziel Ablenkung je Tag in Minuten – eigener Wert, sonst Stunden × 0,7 auf 15 Min gerundet, mindestens 15.
    static func zielMinuten(_ b: Bildschirmzeit, spanne: BildschirmSpanne?) -> Int? {
        if let eigen = b.zielMinuten { return max(15, eigen) }
        guard let s = spanne, let h = stunden(s) else { return nil }
        return max(15, Int((h * 60 * 0.7 / 15).rounded()) * 15)
    }

    /// §17: Schwellen, die Apple meldet (15 … 480 Min).
    static let schwellen = Array(stride(from: 15, through: 480, by: 15))

    /// §17: Ablenkung eines Tages – höchste gemeldete Schwelle; nil = keine Daten (nicht überwacht).
    static func ablenkung(_ b: Bildschirmzeit, am tag: Tag) -> Int? {
        guard b.ueberwacht.contains(tag.text) else { return nil }
        return b.ablenkung[tag.text] ?? 0
    }

    /// Neue Schwelle gemeldet: höchste erreichte bleibt.
    static func melden(_ b: inout Bildschirmzeit, minuten: Int, am tag: Tag) {
        b.ueberwacht.insert(tag.text)
        b.ablenkung[tag.text] = max(b.ablenkung[tag.text] ?? 0, minuten)
    }

    /// §17: Hinweis-Schwellen in Minuten je Häufigkeit (Anteile vom Ziel).
    static func hinweisSchwellen(_ h: HinweisHaeufigkeit, ziel: Int) -> [Int] {
        let anteile: [Double] = switch h {
        case .aus: []
        case .niedrig: [1]
        case .mittel: [0.5, 1]
        case .hoch: [0.25, 0.5, 0.75, 1]
        }
        // auf die nächste meldbare Schwelle (15 Min) aufrunden, ohne Doppel
        return Array(Set(anteile.map { a in max(15, Int((Double(ziel) * a / 15).rounded(.up)) * 15) })).sorted()
    }

    /// §17: Wartezeit vor dem vorzeitigen Beenden (Sekunden); nil = nicht möglich (Durchziehen).
    static func wartezeit(_ s: Schwierigkeit, abbruecheHeute: Int) -> Int? {
        switch s {
        case .leicht: 10
        case .steigend: 10 + 10 * max(0, abbruecheHeute)
        case .durchziehen: nil
        }
    }

    /// §17: Notfall-Pass einmal je Kalenderwoche (Mo–So).
    static func notfallPassFrei(_ b: Bildschirmzeit, heute: Tag, kalender: Calendar = .kompass) -> Bool {
        guard let zuletzt = b.notfallPass else { return true }
        return Tag(zuletzt, kalender: kalender).montag != heute.montag
    }

    /// §17/§19: Anteil Ablenkung für den Tageswert: 1 bei ≤ Ziel, 0 bei ≥ 2 × Ziel, dazwischen linear.
    static func ablenkungsWert(minuten: Int, ziel: Int) -> Double {
        guard ziel > 0 else { return 0 }
        if minuten <= ziel { return 1 }
        if minuten >= 2 * ziel { return 0 }
        return 1 - Double(minuten - ziel) / Double(ziel)
    }
}
