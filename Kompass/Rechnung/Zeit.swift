import Foundation

// rechenregeln.md §7 (Lernen) und §8 (Fokus-Timer, Wiederholungen).

enum WiederholungRechnung {

    /// täglich +1; werktags nächster Mo–Fr; wöchentlich +7; monatlich gleicher Tag, sonst Monatsletzter (Anker-Tag).
    static func naechstesDatum(nach datum: Tag, regel: Wiederholung, ankerTag: Int?) -> Tag? {
        switch regel {
        case .nie: return nil
        case .taeglich: return datum.plus(tage: 1)
        case .werktags:
            var d = datum.plus(tage: 1)
            while d.wochentag > 5 { d = d.plus(tage: 1) }
            return d
        case .woechentlich: return datum.plus(tage: 7)
        case .monatlich: return datum.plus(monate: 1, ankerTag: ankerTag ?? datum.tag)
        }
    }
}

enum FokusRechnung {

    /// Mehr als 4 Stunden am Stück zählen nicht (vergessener Timer).
    static let hoechstens: TimeInterval = 4 * 3600

    struct Buchung: Equatable, Sendable {
        var proTag: [Tag: TimeInterval]
        var gesamt: TimeInterval
        var gekappt: Bool
    }

    /// Teilt [Start, Ende) an Mitternacht der Zeitzone des Kalenders.
    static func anMitternachtTeilen(_ a: Date, _ b: Date, kalender: Calendar) -> [(Tag, TimeInterval)] {
        var out: [(Tag, TimeInterval)] = []
        var a = a
        while a < b {
            let start = kalender.startOfDay(for: a)
            let naechste = kalender.date(byAdding: .day, value: 1, to: start) ?? b
            let e = min(b, naechste)
            out.append((Tag(a, kalender: kalender), e.timeIntervalSince(a)))
            a = e
        }
        return out
    }

    /// Bucht die Abschnitte einer Sitzung: erste 4 Stunden zählen, je Kalendertag aufgeteilt.
    static func buchen(_ abschnitte: [LaufenderTimer.Abschnitt], kalender: Calendar) -> Buchung {
        var rest = hoechstens, gesamt: TimeInterval = 0
        var proTag: [Tag: TimeInterval] = [:]
        let roh = abschnitte.reduce(0) { $0 + max(0, $1.ende.timeIntervalSince($1.start)) }
        for x in abschnitte {
            let schnitt = min(x.ende, x.start.addingTimeInterval(rest))
            if schnitt <= x.start { break }
            for (tag, s) in anMitternachtTeilen(x.start, schnitt, kalender: kalender) { proTag[tag, default: 0] += s }
            rest -= schnitt.timeIntervalSince(x.start)
            gesamt += schnitt.timeIntervalSince(x.start)
        }
        return Buchung(proTag: proTag, gesamt: gesamt, gekappt: roh > hoechstens)
    }
}

enum LernRechnung {

    /// r = (Σ tatsächlich÷geplant + 3) ÷ (Anzahl + 3) aus den letzten 30 Zeit-Schritten.
    static func zeitfaktor(_ verhaeltnisse: [Double]) -> Double {
        let l = verhaeltnisse.suffix(30)
        return (l.reduce(0, +) + 3) / (Double(l.count) + 3)
    }

    /// q = (übernommen + 1) ÷ (gezeigt + 2); vorausgewählt ab 40 %.
    static func uebernahmeQuote(gezeigt: Int, uebernommen: Int) -> Double {
        Double(uebernommen + 1) / Double(gezeigt + 2)
    }

    static func vorausgewaehlt(gezeigt: Int, uebernommen: Int) -> Bool {
        uebernahmeQuote(gezeigt: gezeigt, uebernommen: uebernommen) >= 0.4
    }
}
