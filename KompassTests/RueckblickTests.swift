import Foundation
import Testing
@testable import Kompass

// Rückblick §11: Zeiträume, Kennzahlen (Überlappung zählt einmal), dein Normal, Satz, Tower-Muster, Lernen.

@Suite("Rückblick · Rechnung")
struct RueckblickTests {
    let heute = Tag(2027, 3, 10)   // Mittwoch

    @Test func zeitraeume() {
        #expect(Rueckblick.spanne(.woche, versatz: 0, heute: heute) == (Tag(2027, 3, 8), Tag(2027, 3, 14)))
        #expect(Rueckblick.spanne(.woche, versatz: -1, heute: heute) == (Tag(2027, 3, 1), Tag(2027, 3, 7)))
        #expect(Rueckblick.spanne(.monat, versatz: 0, heute: heute) == (Tag(2027, 3, 1), Tag(2027, 3, 31)))
        #expect(Rueckblick.spanne(.monat, versatz: -3, heute: heute) == (Tag(2026, 12, 1), Tag(2026, 12, 31)))
        #expect(Rueckblick.spanne(.jahr, versatz: -1, heute: heute) == (Tag(2026, 1, 1), Tag(2026, 12, 31)))
    }

    @Test func normal() {
        #expect(Rueckblick.normal([1, 2, 3]) == nil)
        let n = Rueckblick.normal([10, 12, 11, 13, 50])!   // Ausreißer 50 stört den Median kaum
        #expect(n.median == 12)
        #expect(n.unten == 10.5 && n.oben == 13.5)          // MAD = 1 → ±1,5
        #expect(n.lage(9) == .unter && n.lage(12) == .drin && n.lage(20) == .ueber)
        let flach = Rueckblick.normal([10, 10, 10, 10])!    // MAD 0 → mindestens ±10 %
        #expect(flach.unten == 9 && flach.oben == 11)
    }

    @Test func ueberlappungZaehltEinmal() {
        var z = Zustand()
        let g = Ziel(titel: "Z", farbe: "#1F7AC2", symbol: "x", bereich: "x", faellig: Tag(2027, 9, 1), angelegt: Tag(2027, 1, 1))
        z.ziele = [g]
        var h = Habit(titel: "H", farbe: "#1F7AC2", symbol: "x", zielID: g.id, angelegt: Tag(2027, 1, 1))
        h.uhrzeit = 600; h.dauer = 60; h.eintraege[heute] = 1
        z.habits = [h]
        let t = Termin(quelle: .apple, schluessel: "a", titel: "T", tag: heute, start: 630, ende: 690, zielID: g.id)
        let k = Rueckblick.kennzahlen(zustand: z, von: heute, bis: heute, heute: heute) { $0 == heute ? [t] : [] }
        #expect(k.zeitFuerZiele == 5400.0)      // 10:00–11:30 vereinigt, nicht 120 Min
        #expect(k.zeitErfasst == 5400.0)
        #expect((k.jeZiel[g.id] ?? 0) == 7200.0)      // je Ziel bleibt die Summe (Einsatz)
        #expect(k.planGeplant == 1 && k.planGeschafft == 1)
    }

    @Test func satzUndTower() {
        var k = Rueckblick.Kennzahlen(); k.planGeplant = 10; k.planGeschafft = 9; k.zeitErfasst = 3600; k.zeitFuerZiele = 2900
        let pn = Rueckblick.normal([0.6, 0.65, 0.7, 0.62, 0.68]), zn = Rueckblick.normal([0.4, 0.45, 0.5, 0.42, 0.48])
        #expect(Rueckblick.satz(k, planNormal: pn, zielNormal: zn, zeitraum: .woche, laufend: false).hasPrefix("Starke Woche. Mehr geschafft und mehr Zeit"))
        #expect(Rueckblick.satz(k, planNormal: nil, zielNormal: nil, zeitraum: .woche, laufend: true).contains("lernt dein Normal"))
        // Tower: Lernen senkt den Rang, Ausblenden entfernt
        var l = RueckblickLernen()
        let a = Rueckblick.Hinweis(muster: "zielRuht", familie: .ziele, titel: "", satz: "", handlung: nil, zahlen: [], rechnung: "", sicher: 3, staerke: 1, zielID: nil, habitID: nil)
        let b = Rueckblick.Hinweis(muster: "besterFokus", familie: .zeit, titel: "", satz: "", handlung: nil, zahlen: [], rechnung: "", sicher: 3, staerke: 1.2, zielID: nil, habitID: nil)
        #expect(Rueckblick.tower([a, b], lernen: l, heute: heute).map(\.muster) == ["zielRuht", "besterFokus"])
        l.gezeigt["zielRuht"] = 8; l.hilfreich["zielRuht"] = 0
        #expect(Rueckblick.tower([a, b], lernen: l, heute: heute).first?.muster == "besterFokus")
        l.ausgeblendet["besterFokus"] = heute.plus(tage: 10).text
        #expect(Rueckblick.tower([a, b], lernen: l, heute: heute).map(\.muster) == ["zielRuht"])
    }

    @Test func musterZielRuht() {
        var z = Zustand()
        let g = Ziel(titel: "Fit", farbe: "#15803D", symbol: "x", bereich: "x", faellig: Tag(2027, 9, 1), angelegt: Tag(2026, 12, 1))
        z.ziele = [g]
        z.sitzungen = [FokusSitzung(zielID: g.id, tag: Tag(2027, 2, 1), sekunden: 3600)]
        let m = Rueckblick.muster(zustand: z, heute: heute, woche: Rueckblick.Kennzahlen(), verlauf: [], reife: 12) { _ in [] }
        #expect(m.contains { $0.muster == "zielRuht" && $0.zielID == g.id })
        #expect(Rueckblick.muster(zustand: z, heute: heute, woche: Rueckblick.Kennzahlen(), verlauf: [], reife: 2) { _ in [] }.isEmpty)
    }
}
