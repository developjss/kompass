import Foundation
import Testing
@testable import Kompass

// Kalender: Termin-Serien für ein Ziel zählen lassen (Termin-Seite, §3) und Kopf „Als Nächstes“.

@Suite("Kalender · Termin-Seite und Als Nächstes")
struct KalenderTests {
    let heute = Tag(2027, 3, 10)

    @Test func serieZaehlenWechselnUndLoesen() {
        var z = Zustand()
        let a = UUID(), b = UUID(), s1 = UUID(), s2 = UUID()
        z.terminSerieZaehlen(serie: "apple:fahr", titel: "Fahrstunde", ziel: a, schritt: s1, seit: Tag(2027, 3, 1))
        #expect(z.termine.count == 1 && z.termine[0].schrittID == s1)
        // gleicher Ziel, anderer Meilenstein: seit und Vorkommen bleiben
        z.termine[0].vorkommen = [TerminVorkommen(tag: Tag(2027, 3, 2), minuten: 90)]
        z.terminSerieZaehlen(serie: "apple:fahr", titel: "Fahrstunde", ziel: a, schritt: s2, seit: heute)
        #expect(z.termine.count == 1 && z.termine[0].schrittID == s2 && z.termine[0].seit == Tag(2027, 3, 1) && z.termine[0].vorkommen.count == 1)
        // anderes Ziel: ersetzt, neu ab `seit`
        z.terminSerieZaehlen(serie: "apple:fahr", titel: "Fahrstunde", ziel: b, schritt: nil, seit: heute)
        #expect(z.termine.count == 1 && z.termine[0].zielID == b && z.termine[0].seit == heute && z.termine[0].vorkommen.isEmpty)
        // kein Ziel: gelöst
        z.terminSerieZaehlen(serie: "apple:fahr", titel: "Fahrstunde", ziel: nil, schritt: nil, seit: heute)
        #expect(z.termine.isEmpty)
    }

    @Test func externeTermineTragenIhrZiel() {
        var z = Zustand()
        let g = UUID()
        let t = Termin(quelle: .apple, schluessel: "fahr", titel: "Fahrstunde", tag: heute, start: 600, ende: 690)
        #expect(Kalenderquelle.termine(am: heute, zustand: z, heute: heute, extern: [t]).first?.zielID == nil)
        z.terminSerieZaehlen(serie: Kalenderquelle.serie(t), titel: t.titel, ziel: g, schritt: nil, seit: heute)
        let mit = Kalenderquelle.termine(am: heute, zustand: z, heute: heute, extern: [t])
        #expect(mit.first?.zielID == g)
        #expect(Tagesplan.bloecke(am: heute, zustand: z, termine: mit).first?.serie == "apple:fahr")
    }

    @Test func kopfAlsNaechstes() {
        func b(_ tag: Tag, _ s: Int) -> Tagesplan.Block { Tagesplan.Block(id: "x", art: .termin, titel: "x", tag: tag, start: s, ende: s + 30, farbe: "#000000", unter: "") }
        #expect(NaechsteStapel.aussage(b(heute, 600), heute: heute, jetzt: 543) == "Nächstes in 57 Min")
        #expect(NaechsteStapel.aussage(b(heute, 720), heute: heute, jetzt: 600) == "Nächstes in 2 h")
        #expect(NaechsteStapel.aussage(b(heute, 735), heute: heute, jetzt: 600) == "Nächstes in 2 h 15 Min")
        #expect(NaechsteStapel.aussage(b(heute, 590), heute: heute, jetzt: 600) == "Läuft gerade")
        #expect(NaechsteStapel.aussage(b(heute.plus(tage: 1), 600), heute: heute, jetzt: 600) == "Nächstes morgen")
    }

    @Test func lotseKenntTerminSeite() {
        let t = AppWissen.text()
        #expect(t.contains("Termin-Seite") && t.contains("Was um 14:00?"))
    }
}
