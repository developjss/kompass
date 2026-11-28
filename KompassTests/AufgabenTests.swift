import Foundation
import Testing
@testable import Kompass

/// Aufgaben: Ring-Anteil, Schritte, Abhaken, Reihenfolge und Fälligkeit.
struct AufgabenTests {
    private let heute: Date = {
        var k = DateComponents(); k.year = 2026; k.month = 11; k.day = 28; k.hour = 10
        return Calendar(identifier: .gregorian).date(from: k)!
    }()

    private func tag(_ n: Int) -> Date { Calendar(identifier: .gregorian).date(byAdding: .day, value: n, to: heute)! }

    @Test func anteil() {
        let demo = Aufgabe.demo(heute: heute)
        #expect(AufgabenRegel.anteil(demo[0]) == 0)          // ohne Schritte, offen
        #expect(AufgabenRegel.anteil(demo[1]) == 0.25)       // 1 von 4
        var fertig = demo[0]; fertig.erledigt = true
        #expect(AufgabenRegel.anteil(fertig) == 1)
    }

    @Test func letzterSchrittErledigtDieAufgabe() {
        var a = Aufgabe.demo(heute: heute)[3]                 // Lernplan, 3 Schritte
        AufgabenRegel.umschalten("l1", in: &a)
        AufgabenRegel.umschalten("l2", in: &a)
        #expect(!a.erledigt)
        AufgabenRegel.umschalten("l3", in: &a)
        #expect(a.erledigt)
        AufgabenRegel.umschalten("l2", in: &a)                // wieder geöffnet
        #expect(!a.erledigt)
        AufgabenRegel.umschalten("gibt-es-nicht", in: &a)
        #expect(a.schritte.filter(\.erledigt).count == 2)
    }

    @Test func ganzeAufgabeHaktAlleSchritteAb() {
        var a = Aufgabe.demo(heute: heute)[1]
        AufgabenRegel.setzeErledigt(true, in: &a)
        #expect(a.erledigt && a.schritte.allSatisfy(\.erledigt))
        AufgabenRegel.setzeErledigt(false, in: &a)
        #expect(!a.erledigt && a.schritte.allSatisfy { !$0.erledigt })
    }

    @Test func erledigteAnsEnde() {
        var liste = Aufgabe.demo(heute: heute)
        liste[0].erledigt = true
        #expect(AufgabenRegel.sortiert(liste).map(\.id) == ["einkaufen", "anrufen", "lernplan", "steuer", "emails"])
    }

    @Test func faelligkeit() {
        #expect(AufgabenRegel.faelligText(nil, heute: heute) == nil)
        #expect(AufgabenRegel.faelligText(tag(0), heute: heute) == "Heute fällig")
        #expect(AufgabenRegel.faelligText(tag(1), heute: heute) == "Morgen fällig")
        #expect(AufgabenRegel.faelligText(tag(-2), heute: heute) == "Überfällig")
        #expect(AufgabenRegel.faelligText(tag(17), heute: heute) == "Fällig am 15. Dez.")
    }

    @Test func zeile() {
        let demo = Aufgabe.demo(heute: heute)
        #expect(AufgabenRegel.zeile(demo[1], heute: heute) == "Heute fällig · 1 von 4 Schritten")
        #expect(AufgabenRegel.zeile(demo[2], heute: heute) == "0 von 2 Schritten")
        #expect(AufgabenRegel.zeile(demo[0], heute: heute) == "Heute fällig")
        var fertig = demo[2]; fertig.erledigt = true
        #expect(AufgabenRegel.zeile(fertig, heute: heute) == "Erledigt")
    }
}
