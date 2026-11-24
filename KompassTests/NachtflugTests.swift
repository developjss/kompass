import Foundation
import Testing
@testable import Kompass

// Nachtflug-Palette: bunte Farben (Ziele, Habits, Kalender) landen in Indigo, Seladon oder Gold; Dunkles, Helles, Graues bleibt.

@Suite("Nachtflug · Palette")
struct NachtflugTests {
    @Test func familienDerDemoFarben() {
        #expect(Farbe.tonArt("#1F7AC2") == .seladon)      // Führerschein (Blau)
        #expect(Farbe.tonArt("#15803D") == .seladonTief)  // Fit (Grün)
        #expect(Farbe.tonArt("#9A6700") == .gold)         // Millionär (Gold)
        #expect(Farbe.tonArt("#3B4CCA") == .indigoHell)   // LAPL (Indigo)
        #expect(Farbe.tonArt("#7A4FD6") == .goldHell)     // Lila
        #expect(Farbe.tonArt("#B8456E") == .goldTief)     // Rosa
    }

    @Test func dunkleHelleUndGraueBleiben() {
        #expect(Farbe.tonArt("#0B1325") == nil)
        #expect(Farbe.tonArt("#F3F6F4") == nil)
        #expect(Farbe.tonArt("#6B7285") == nil)
        #expect(Farbe.tonArt("kaputt") == nil)
    }

    @Test func auswahlDeckJedeFamilieGenauEinmal() {
        let arten = Farbe.ziele.compactMap { Farbe.tonArt($0) }
        #expect(arten.count == Farbe.ziele.count)
        #expect(Set(arten.map { "\($0)" }).count == Farbe.ziele.count)
    }
}
