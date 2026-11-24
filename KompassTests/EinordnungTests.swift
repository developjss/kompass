import Foundation
import Testing
@testable import Kompass

// Wie zählt eine Aufgabe fürs Ziel? Erklärt die bestehende Regel §3 (keine neue Rechnung).

@Suite("Aufgaben · Einordnung ins Ziel")
struct EinordnungTests {
    func zustand() -> (Zustand, Ziel) {
        var g = Ziel(titel: "Führerschein", farbe: "#1F7AC2", symbol: "car", bereich: "x", faellig: Tag(2027, 6, 1), angelegt: Tag(2027, 1, 1))
        g.schritte = [Schritt(titel: "Theorie", art: .aufgaben, gewicht: 1), Schritt(titel: "Fahrstunden", art: .zeit, gewicht: 1, soll: 20)]
        var z = Zustand(ziele: [g])
        let a = z.aufgabeAnlegen("Kapitel 1", datum: nil, prio: .normal, zielID: g.id, heute: Tag(2027, 1, 2))
        z.aufgabeZuordnen(a.id, ziel: g.id, schritt: g.schritte[0].id, automatisch: false, heute: Tag(2027, 1, 2))
        return (z, g)
    }

    @Test func faelle() {
        let (z, g) = zustand()
        #expect(Einordnung.fuer(zielID: nil, schrittID: nil, einmalig: true, aufgabeID: nil, in: z) == .keinZiel)
        #expect(Einordnung.fuer(zielID: g.id, schrittID: nil, einmalig: true, aufgabeID: nil, in: z) == .nurEinsatz(ziel: "Führerschein", passenderMeilenstein: true))
        #expect(Einordnung.fuer(zielID: g.id, schrittID: g.schritte[0].id, einmalig: false, aufgabeID: nil, in: z)
                == .wiederkehrendZaehltNicht(ziel: "Führerschein", meilenstein: "Theorie"))
        // neue Aufgabe: 2 Aufgaben im Meilenstein, Meilenstein = 50 % des Ziels → 0,5 × 0,9 ÷ 2 = 22,5 Punkte
        #expect(Einordnung.fuer(zielID: g.id, schrittID: g.schritte[0].id, einmalig: true, aufgabeID: nil, in: z)
                == .aufgaben(ziel: "Führerschein", meilenstein: "Theorie", anzahl: 2, punkte: 0.5 * 0.9 / 2))
        // bestehende Aufgabe zählt sich nicht doppelt
        let a = z.aufgaben[0]
        #expect(Einordnung.fuer(zielID: g.id, schrittID: g.schritte[0].id, einmalig: true, aufgabeID: a.id, in: z)
                == .aufgaben(ziel: "Führerschein", meilenstein: "Theorie", anzahl: 1, punkte: 0.5 * 0.9 / 1))
        #expect(Einordnung.fuer(zielID: g.id, schrittID: g.schritte[1].id, einmalig: true, aufgabeID: nil, in: z)
                == .fokuszeit(ziel: "Führerschein", meilenstein: "Fahrstunden", sollStunden: 20))
    }

    @Test func ohnePassendenMeilenstein() {
        var g = Ziel(titel: "Fit", farbe: "#15803D", symbol: "x", bereich: "x", faellig: Tag(2027, 6, 1), angelegt: Tag(2027, 1, 1))
        g.schritte = [Schritt(titel: "Gewicht", art: .zahl)]
        let z = Zustand(ziele: [g])
        let e = Einordnung.fuer(zielID: g.id, schrittID: nil, einmalig: true, aufgabeID: nil, in: z)
        #expect(e == .nurEinsatz(ziel: "Fit", passenderMeilenstein: false) && !e.zaehlt)
        #expect(e.satz.contains("Meilenstein „Aufgaben“"))
    }
}
