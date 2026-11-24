import Foundation
import Testing
@testable import Kompass

// Meilenstein aus Bestehendem (rechenregeln.md §3): Termin-Serien finden und zählen, Habit-Bisheriges, Vorschau.

@Suite("Meilenstein · aus Bestehendem")
struct MeilensteinQuelleTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    func zustand() -> Zustand {
        var z = Zustand()
        z.einstellungen.googleBeispiel = false
        z.einstellungen.appleBeispiel = false
        // wöchentlich mittwochs 17–18:30, seit 3 Wochen
        z.eigeneTermine = [EigenerTermin(titel: "Fahrstunde", tag: heute.plus(tage: -21), start: 17 * 60, ende: 18 * 60 + 30, kategorie: .freizeit, wiederholung: .woechentlich)]
        return z
    }

    func quelle(_ z: Zustand) -> (Tag) -> [Termin] { { d in Kalenderquelle.termine(am: d, zustand: z, heute: heute) } }

    @Test func serienZaehlenVergangeneUndKommende() {
        let z = zustand()
        let g = UUID()
        // heute zählt schon mit – genau wie beim Abgleich der Termine
        let s = MeilensteinQuelle.serien(zustand: z, ziel: g, heute: heute, jetzt: 10 * 60, termine: quelle(z), zurueck: 30, voraus: 14)
        #expect(s.count == 1 && s[0].titel == "Fahrstunde")
        #expect(s[0].bisher == 4 && s[0].minutenBisher == 360 && s[0].erster == heute.plus(tage: -21))
        #expect(s[0].kommend == 2) // +7, +14
    }

    @Test func schonVerknuepfteSerienFehlen() {
        var z = zustand()
        let g = UUID()
        let key = MeilensteinQuelle.serien(zustand: z, ziel: g, heute: heute, jetzt: 600, termine: quelle(z), zurueck: 30, voraus: 0)[0].id
        z.terminVerknuepfen(serie: key, titel: "Fahrstunde", ziel: g, schritt: nil, seit: heute)
        #expect(MeilensteinQuelle.serien(zustand: z, ziel: g, heute: heute, jetzt: 600, termine: quelle(z), zurueck: 30, voraus: 0).isEmpty)
    }

    @Test func bisherigeTermineZaehlenImMeilenstein() {
        var z = zustand()
        var g = Ziel(titel: "Führerschein", farbe: "#000000", symbol: "car", bereich: "x", faellig: heute.plus(tage: 200), angelegt: heute)
        let sr = MeilensteinQuelle.serien(zustand: z, ziel: g.id, heute: heute, jetzt: 600, termine: quelle(z), zurueck: 30, voraus: 0)[0]
        let schritt = Schritt(titel: "Fahrstunden", art: .zahl, soll: 10, start: 0, einheit: "Termine")
        g.schritte = [schritt]
        z.ziele = [g]
        // mitzählen ab dem ersten Termin → 4 von 10 = 40 % – Vorschau und Meilenstein zeigen dasselbe
        z.terminVerknuepfen(serie: sr.id, titel: sr.titel, ziel: g.id, schritt: schritt.id, seit: sr.erster!)
        z.termineAbgleichen(heute: heute, quelle: quelle(z))
        #expect(abs(Fortschritt.stand(schritt, in: z, heute: heute).anteil - MeilensteinQuelle.vorschau(bisher: Double(sr.bisher), soll: 10)) < 1e-9)
        #expect(MeilensteinQuelle.vorschau(bisher: 3, soll: 10) == 0.3 && MeilensteinQuelle.vorschau(bisher: 12, soll: 10) == 1)
    }

    @Test func habitBisherZaehltSeitAnlage() {
        var h = Habit(titel: "Laufen", farbe: "#000000", symbol: "x", angelegt: heute.plus(tage: -10))
        for i in 1...4 { h.eintraege[heute.plus(tage: -i)] = 1 }
        #expect(MeilensteinQuelle.habitBisher(h, modus: .anzahl, heute: heute) == 4)
        // Meilenstein mit seit = Anlage des Habits zählt das Bisherige
        let s = Schritt(titel: "Laufen", art: .habit, seit: h.angelegt, soll: 8, habitID: h.id)
        var z = Zustand()
        z.habits = [h]
        #expect(abs(Fortschritt.stand(s, in: z, heute: heute).anteil - 0.5) < 1e-9)
    }
}
