import Foundation
import Testing
@testable import Kompass

// Fokus als Flug: Strecke, Phasen, Flugfläche, Restzeit, Kürzel. Nur Anzeige – gebucht wird wie bisher.

@Suite("Fokus · Flug")
struct FlugTests {
    @Test func streckeUndRest() {
        #expect(FlugRechnung.strecke(sekunden: 0, dauerMinuten: 60) == 0)
        #expect(FlugRechnung.strecke(sekunden: 1800, dauerMinuten: 60) == 0.5)
        #expect(FlugRechnung.strecke(sekunden: 9000, dauerMinuten: 60) == 1)
        #expect(FlugRechnung.strecke(sekunden: 150, dauerMinuten: 0) == 0.5)   // mindestens 5 Minuten
        #expect(FlugRechnung.restMinuten(sekunden: 1790, dauerMinuten: 30) == 1)
        #expect(FlugRechnung.restMinuten(sekunden: 1800, dauerMinuten: 30) == 0)
    }

    @Test func phasen() {
        #expect(FlugRechnung.phase(strecke: 0, sekunden: 0, laeuft: false) == .boarding)
        #expect(FlugRechnung.phase(strecke: 0.1, sekunden: 60, laeuft: true) == .steigflug)
        #expect(FlugRechnung.phase(strecke: 0.5, sekunden: 600, laeuft: true) == .reiseflug)
        #expect(FlugRechnung.phase(strecke: 0.5, sekunden: 600, laeuft: false) == .warteschleife)
        #expect(FlugRechnung.phase(strecke: 0.9, sekunden: 900, laeuft: true) == .landeanflug)
        #expect(FlugRechnung.phase(strecke: 1, sekunden: 3600, laeuft: false) == .gelandet)
    }

    @Test func flugflaecheUndKuerzel() {
        #expect(FlugRechnung.flugflaeche(strecke: 0) == 0)
        #expect(FlugRechnung.flugflaeche(strecke: 0.5) == 350)
        #expect(FlugRechnung.flugflaeche(strecke: 1) == 0)
        #expect(FlugRechnung.kuerzel("Führerschein Klasse B") == "FUH")
        #expect(FlugRechnung.kuerzel("LAPL(A) bestehen") == "LAP")
        #expect(FlugRechnung.kuerzel("Ö") == "OXX")
    }
}
