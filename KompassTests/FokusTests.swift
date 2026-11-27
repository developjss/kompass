import Testing
@testable import Kompass

/// Fokus-Timer: Startdauer, Ergebnis und Uhr-Anzeige.
struct FokusTests {
    @Test func startdauer() {
        #expect(Fokus.startMinuten(einheit: .minuten, ziel: 30, wert: 0) == 30)
        #expect(Fokus.startMinuten(einheit: .minuten, ziel: 30, wert: 21) == 10)      // 9 fehlen → auf 10 aufgerundet
        #expect(Fokus.startMinuten(einheit: .minuten, ziel: 30, wert: 30) == 30)      // schon erledigt → ganzes Ziel
        #expect(Fokus.startMinuten(einheit: .minuten, ziel: 10, wert: 8) == 5)        // mindestens 5
        #expect(Fokus.startMinuten(einheit: .stunden, ziel: 12, wert: 0) == 240)      // höchstens 240
        #expect(Fokus.startMinuten(einheit: .sekunden, ziel: 90, wert: 0) == 5)
        #expect(Fokus.startMinuten(einheit: .seiten, ziel: 20, wert: 5) == 30)        // keine Zeit-Einheit
    }

    @Test func ergebnis() {
        #expect(Fokus.ergebnis(wert: 0, einheit: .seiten, ziel: 20, sekunden: 600, fertig: true) == 20)
        #expect(Fokus.ergebnis(wert: 5, einheit: .seiten, ziel: 20, sekunden: 600, fertig: false) == 5)
        #expect(Fokus.ergebnis(wert: 10, einheit: .minuten, ziel: 30, sekunden: 12 * 60 + 40, fertig: false) == 22)
        #expect(Fokus.ergebnis(wert: 25, einheit: .minuten, ziel: 30, sekunden: 600, fertig: false) == 30)
        #expect(Fokus.ergebnis(wert: 0, einheit: .stunden, ziel: 1, sekunden: 30 * 60, fertig: false) == 0.5)
        #expect(Fokus.ergebnis(wert: 0, einheit: .minuten, ziel: 30, sekunden: 59, fertig: false) == 0)
    }

    @Test func uhr() {
        #expect(Fokus.uhr(1797) == "29:57")
        #expect(Fokus.uhr(0) == "00:00")
        #expect(Fokus.uhr(3900) == "1:05:00")
        #expect(Fokus.uhr(-3) == "00:00")
    }
}
