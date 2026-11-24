import Foundation
import Testing
@testable import Kompass

// Wiederkehrende Termine: nur dieser Termin (Ausnahme + Einzeltermin) oder die ganze Serie; Wiederholungsregeln Apple/Google.

@Suite("Kalender · Serien")
struct SerienTests {
    func serie() -> (Zustand, EigenerTermin) {
        var z = Zustand()
        var t = EigenerTermin(titel: "Training", tag: Tag(2027, 3, 1), start: 1080, ende: 1170)   // Mo 18:00–19:30, wöchentlich
        t.wiederholung = .woechentlich
        z.terminSpeichern(t)
        return (z, t)
    }

    @Test func nurDieserTermin() {
        var (z, t) = serie()
        z.terminVerschieben(t.id, von: Tag(2027, 3, 8), tag: Tag(2027, 3, 9), start: 1140, nurDieser: true)
        let s = z.eigenerTermin(t.id)!
        #expect(!s.findetStatt(am: Tag(2027, 3, 8)))           // Serie lässt den Tag aus
        #expect(s.findetStatt(am: Tag(2027, 3, 15)))           // sonst unverändert
        #expect(s.start == 1080)
        let einzel = z.eigeneTermine.first { $0.id != t.id }!
        #expect(einzel.tag == Tag(2027, 3, 9) && einzel.start == 1140 && einzel.ende == 1230 && einzel.wiederholung == .nie)
    }

    @Test func alleTermine() {
        var (z, t) = serie()
        z.terminVerschieben(t.id, von: Tag(2027, 3, 8), tag: Tag(2027, 3, 9), start: 1140, nurDieser: false)
        let s = z.eigenerTermin(t.id)!
        #expect(z.eigeneTermine.count == 1)
        #expect(s.tag == Tag(2027, 3, 2) && s.start == 1140)   // Serie wandert auf Dienstag
        #expect(s.findetStatt(am: Tag(2027, 3, 9)) && !s.findetStatt(am: Tag(2027, 3, 8)))
    }

    @Test func auslassen() {
        var (z, t) = serie()
        z.terminAuslassen(t.id, am: Tag(2027, 3, 15))
        z.terminAuslassen(t.id, am: Tag(2027, 3, 15))
        #expect(z.eigenerTermin(t.id)?.ausgelassen == [Tag(2027, 3, 15)])
        #expect(!(z.eigenerTermin(t.id)!.findetStatt(am: Tag(2027, 3, 15))))
    }

    @Test func wiederholungsregeln() {
        for w in AppleKalender.Details.Wiederholung.allCases {
            #expect(AppleKalender.wiederholung(AppleKalender.regel(w)) == w)
        }
    }
}
