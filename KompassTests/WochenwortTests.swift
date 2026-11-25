import Foundation
import Testing
@testable import Kompass

// Rückblick §11: das Wort über der Woche – eine Regel nach der anderen, die erste passende gewinnt.

@Suite("Rückblick · Wochenwort")
struct WochenwortTests {
    private func lage(q: Double = 0.6, h: Double = 0.6, kurs: Int = 2, ziele: Int = 4, voll: Double = 0.4, tage: Int = 5) -> Wochenwort.Lage {
        Wochenwort.Lage(quote: q, habitQuote: h, zieleAufKurs: kurs, zieleGesamt: ziele, auslastung: voll, tageMitDaten: tage)
    }

    @Test func reihenfolgeDerRegeln() {
        #expect(Wochenwort.wort(lage(tage: 0)) == ("Neue", "Woche."))
        #expect(Wochenwort.wort(lage(voll: 0.8)) == ("Volle", "Woche."))
        #expect(Wochenwort.wort(lage(q: 0.9, h: 0.85)) == ("Starke", "Woche."))
        #expect(Wochenwort.wort(lage(q: 0.9, h: 0)) == ("Starke", "Woche."))        // keine Habits geplant
        #expect(Wochenwort.wort(lage(kurs: 1, ziele: 4)) == ("Kurs", "halten."))
        #expect(Wochenwort.wort(lage(q: 0.2)) == ("Luft", "holen."))
        #expect(Wochenwort.wort(lage(h: 0.9)) == ("Gut", "dabei."))
        #expect(Wochenwort.wort(lage()) == ("Im", "Fluss."))
    }

    @Test func hoechstensZweiWoerter() {
        let faelle = [lage(tage: 0), lage(voll: 0.9), lage(q: 0.9, h: 0.9), lage(kurs: 0), lage(q: 0.1), lage(h: 0.9), lage()]
        for f in faelle {
            let (a, b) = Wochenwort.wort(f)
            #expect((a + " " + b).split(separator: " ").count <= 2)
            #expect(b.hasSuffix("."))
        }
    }

    @Test func volleWocheSchlaegtStarkeWoche() {
        // Hick: die Lage, die das Handeln ändert (zu voll), steht vor dem Lob
        #expect(Wochenwort.wort(lage(q: 0.95, h: 0.95, voll: 0.8)) == ("Volle", "Woche."))
    }
}
