import Testing
@testable import Kompass

/// Fortschritt eines Habits: Teilwerte, Status und Texte.
struct FortschrittTests {
    @Test func teilwerteRastenEin() {
        #expect(Fortschritt.wert(anteil: 0.6, einheit: .seiten, ziel: 20) == 12)
        #expect(Fortschritt.wert(anteil: 0.7, einheit: .minuten, ziel: 30) == 21)
        #expect(Fortschritt.wert(anteil: 0.6, einheit: .ml, ziel: 2_000) == 1_250)   // 1.200 → 1.250 (250er-Schritt)
        #expect(Fortschritt.wert(anteil: 0.5, einheit: .stunden, ziel: 1) == 0.5)
        #expect(Fortschritt.wert(anteil: 0, einheit: .seiten, ziel: 20) == 0)
        #expect(Fortschritt.wert(anteil: -1, einheit: .seiten, ziel: 20) == 0)
    }

    @Test func nurGanzRechtsIstErledigt() {
        #expect(Fortschritt.wert(anteil: 1, einheit: .seiten, ziel: 20) == 20)
        #expect(Fortschritt.wert(anteil: 0.99, einheit: .seiten, ziel: 20) == 19)   // 19,8 würde auf 20 runden
        #expect(Fortschritt.wert(anteil: 0.95, einheit: .ml, ziel: 2_000) == 1_750)
        #expect(Fortschritt.wert(anteil: 2, einheit: .minuten, ziel: 30) == 30)
    }

    @Test func keineEinheitNurGanzOderGarNicht() {
        #expect(Fortschritt.wert(anteil: 0.8, einheit: .keine, ziel: 1) == 0)
        #expect(Fortschritt.wert(anteil: 1, einheit: .keine, ziel: 1) == 1)
    }

    @Test func status() {
        #expect(Fortschritt.status(wert: 0, ziel: 20) == .offen)
        #expect(Fortschritt.status(wert: 12, ziel: 20) == .teilweise)
        #expect(Fortschritt.status(wert: 20, ziel: 20) == .erledigt)
        #expect(Fortschritt.prozent(wert: 12, ziel: 20) == 60)
        #expect(Fortschritt.anteil(wert: 5, ziel: 0) == 0)
    }

    @Test func texte() {
        #expect(Fortschritt.text(wert: 12, einheit: .seiten, ziel: 20) == "12 / 20 Seiten")
        #expect(Fortschritt.text(wert: 21, einheit: .minuten, ziel: 30) == "21m / 30m")
        #expect(Fortschritt.text(wert: 0, einheit: .minuten, ziel: 30) == "0m / 30m")
        #expect(Fortschritt.text(wert: 1_250, einheit: .ml, ziel: 2_000) == "1.250 / 2.000 ml")
        #expect(Fortschritt.text(wert: 1, einheit: .keine, ziel: 1) == "Erledigt")
        #expect(Fortschritt.speichernText(wert: 12, einheit: .seiten, ziel: 20) == "12 von 20 Seiten speichern")
        #expect(Fortschritt.speichernText(wert: 21, einheit: .minuten, ziel: 30) == "21m von 30m speichern")
        #expect(Fortschritt.speichernText(wert: 0, einheit: .seiten, ziel: 20) == "Als offen markieren")
    }

    @Test func demoHabitsSindGueltig() {
        for h in Habit.demo {
            #expect(h.einheit.werte.contains(h.tagesziel), "\(h.id)")
            #expect(!h.tage.isEmpty)
        }
        #expect(Habit.demo.map(\.name) == ["Lesen", "Sport", "Meditieren", "Lernen", "Wasser"])
    }
}
