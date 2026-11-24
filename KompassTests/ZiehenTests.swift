import Foundation
import Testing
@testable import Kompass

// Ziehen im Kalender: Raster auf 15 Minuten, Grenzen der Zeitleiste, über den Rand, Tage in der Woche; Termin verschieben.

@Suite("Kalender · Ziehen")
struct ZiehenTests {
    @Test func raster() {
        // 64 pt je Stunde, Zeitleiste ab 6 Uhr
        #expect(Zeitraster.minute(y: 0, hoehe: 64, von: 6) == 360)
        #expect(Zeitraster.minute(y: 70, hoehe: 64, von: 6) == 420)       // 6:00 + 65,6 Min → 7:00
        #expect(Zeitraster.verschoben(start: 600, dauer: 60, dy: 32, hoehe: 64, von: 6, bis: 24) == 630)
        #expect(Zeitraster.verschoben(start: 600, dauer: 60, dy: 10, hoehe: 64, von: 6, bis: 24) == 615)   // 9,4 Min → 15
        #expect(Zeitraster.verschoben(start: 400, dauer: 60, dy: -500, hoehe: 64, von: 6, bis: 24) == 360) // nicht vor 6:00
        #expect(Zeitraster.verschoben(start: 1320, dauer: 90, dy: 500, hoehe: 64, von: 6, bis: 24) == 1350) // endet spätestens 24:00
        #expect(Zeitraster.ueberRand(start: 400, dy: -100, hoehe: 64, von: 6))
        #expect(!Zeitraster.ueberRand(start: 400, dy: -20, hoehe: 64, von: 6))
        #expect(Zeitraster.tage(dx: 120, spalte: 116) == 1)
        #expect(Zeitraster.tage(dx: -50, spalte: 116) == 0)
        #expect(Zeitraster.tage(dx: -200, spalte: 116) == -2)
    }

    @Test func terminVerschieben() {
        var z = Zustand()
        let einmal = EigenerTermin(titel: "Zahnarzt", tag: Tag(2027, 3, 10), start: 600, ende: 660)
        var serie = EigenerTermin(titel: "Training", tag: Tag(2027, 3, 1), start: 1080, ende: 1170)
        serie.wiederholung = .woechentlich
        z.terminSpeichern(einmal); z.terminSpeichern(serie)
        z.terminVerschieben(einmal.id, tag: Tag(2027, 3, 11), start: 840)
        #expect(z.eigenerTermin(einmal.id)?.tag == Tag(2027, 3, 11))
        #expect(z.eigenerTermin(einmal.id)?.start == 840 && z.eigenerTermin(einmal.id)?.ende == 900)
        z.terminVerschieben(serie.id, tag: Tag(2027, 3, 9), start: 1110)
        #expect(z.eigenerTermin(serie.id)?.tag == Tag(2027, 3, 1))      // Serie: nur die Uhrzeit
        #expect(z.eigenerTermin(serie.id)?.start == 1110 && z.eigenerTermin(serie.id)?.ende == 1200)
    }
}
