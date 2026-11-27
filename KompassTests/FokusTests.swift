import Testing
@testable import Kompass

/// Fokus-Timer: Startdauer, Ergebnis und Uhr-Anzeige.
struct FokusTests {
    @Test func festeDauerBeiZeitHabits() {
        #expect(Fokus.festeSekunden(einheit: .minuten, ziel: 45, wert: 0) == 45 * 60)     // genau die Zeit des Habits
        #expect(Fokus.festeSekunden(einheit: .minuten, ziel: 30, wert: 21) == 9 * 60)     // nur was noch fehlt
        #expect(Fokus.festeSekunden(einheit: .minuten, ziel: 30, wert: 30) == 30 * 60)    // schon erledigt → ganzes Ziel
        #expect(Fokus.festeSekunden(einheit: .stunden, ziel: 1.5, wert: 0) == 90 * 60)
        #expect(Fokus.festeSekunden(einheit: .sekunden, ziel: 90, wert: 0) == 90)
    }

    @Test func freieDauerOhneZeit() {
        #expect(Fokus.festeSekunden(einheit: .seiten, ziel: 20, wert: 5) == nil)
        #expect(Fokus.festeSekunden(einheit: .keine, ziel: 1, wert: 0) == nil)
        #expect(Fokus.freieMinuten == 30)
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
