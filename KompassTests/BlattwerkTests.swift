import Foundation
import Testing
import UIKit
@testable import Kompass

// Blattwerk-Palette: bunte Farben (Ziele, Habits, Kalender) landen in Weinrot-, Rosé- oder Grüntönen; Dunkles, Helles, Graues bleibt.
// Kontraste nach WCAG, Bilder vorhanden, Platzierungen plausibel.

@Suite("Blattwerk · Palette")
struct BlattwerkTests {
    @Test func familienDerDemoFarben() {
        #expect(Farbe.tonArt("#1F7AC2") == .beere)       // Führerschein (Blau)
        #expect(Farbe.tonArt("#15803D") == .gruen)       // Fit (Grün)
        #expect(Farbe.tonArt("#9A6700") == .gruenTief)   // Millionär (Gold)
        #expect(Farbe.tonArt("#3B4CCA") == .weinrot)     // LAPL (Indigo)
        #expect(Farbe.tonArt("#7A4FD6") == .rosa)        // Lila
        #expect(Farbe.tonArt("#B8456E") == .wein)        // Rosa/Rot
    }

    @Test func dunkleHelleUndGraueBleiben() {
        #expect(Farbe.tonArt("#2E0816") == nil)
        #expect(Farbe.tonArt("#FBEDF1") == nil)
        #expect(Farbe.tonArt("#6B7285") == nil)
        #expect(Farbe.tonArt("kaputt") == nil)
    }

    @Test func auswahlDeckJedeFamilieGenauEinmal() {
        let arten = Farbe.ziele.compactMap { Farbe.tonArt($0) }
        #expect(arten.count == Farbe.ziele.count)
        #expect(Set(arten.map { "\($0)" }).count == Farbe.ziele.count)
    }

    @Test func kontrasteHell() {
        #expect(Blattwerk.kontrast(Blattwerk.weinrot, Blattwerk.roseHell) >= 7)        // Text auf Grund
        #expect(Blattwerk.kontrast(Blattwerk.weinrot, Blattwerk.rose) >= 7)            // Wort auf Bühne
        #expect(Blattwerk.kontrast(Blattwerk.zweitrangigHell, Blattwerk.roseHell) >= 4.5)
        #expect(Blattwerk.kontrast(Blattwerk.gruenTief, Blattwerk.roseHell) >= 4.5)    // Handlung als Text
        #expect(Blattwerk.kontrast(Blattwerk.weinrotTief, Blattwerk.gruen) >= 4.5)     // Schrift auf Grün
        #expect(Blattwerk.kontrast(Blattwerk.gruen, Blattwerk.rose) < 4.5)             // Grün nie als Text auf Rosé
    }

    @Test func kontrasteDunkel() {
        #expect(Blattwerk.kontrast(Blattwerk.rose, Blattwerk.weinrotTief) >= 7)
        #expect(Blattwerk.kontrast(Blattwerk.rose, Blattwerk.weinrotKarte) >= 7)
        #expect(Blattwerk.kontrast(Blattwerk.zweitrangigDunkel, Blattwerk.weinrotTief) >= 4.5)
        #expect(Blattwerk.kontrast(Blattwerk.gruen, Blattwerk.weinrotTief) >= 4.5)
    }

    @Test func kontrastFormel() {
        #expect(abs(Blattwerk.kontrast(0xFFFFFF, 0x000000) - 21) < 0.01)
        #expect(abs(Blattwerk.kontrast(0x808080, 0x808080) - 1) < 0.01)
    }
}

@Suite("Blattwerk · Bühne")
struct BuehneTests {
    @Test func jedesObjektHatEinBild() {
        for o in Objekt.allCases {
            #expect(UIImage(named: o.rawValue, in: Bundle(for: Speicher.self), with: nil) != nil, "Bild fehlt: \(o.rawValue)")
        }
    }

    @Test func platzierungenPassenAufDieBuehne() {
        let alle: [Platz] = [.home, .kalender, .neu, .assistent, .fortschritt, .ziel, .habits, .aufgabe, .analyseZiel, .analyseHabit, .einstellungen, .rueckblick]
        for p in alle {
            #expect(p.breite >= 120 && p.breite <= 460)
            #expect(p.oben >= 0 && p.oben < Mass.buehne)
            #expect(abs(p.drehung) <= 20)
            #expect(p.rechts >= -p.breite / 2, "Objekt ragt mehr als zur Hälfte hinaus")
        }
    }

    @Test func wortGroessen() {
        #expect(Wort.kleinGroesse < Wort.mittel && Wort.mittel < Wort.gross && Wort.gross < Wort.riesig)
        let w = Wort(zeilen: ["3 von 4"], akzent: "auf Kurs.")
        #expect(w.groesse == Wort.gross && w.klein == nil)
    }
}
