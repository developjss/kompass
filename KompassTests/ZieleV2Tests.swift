import Foundation
import Testing
@testable import Kompass

// Ziele v2: Meilenstein-Vorlagen aus dem Titel, Satz „so wird gerechnet“ (habits-v2.md §9).

@Suite("Ziele v2 · Vorlagen")
struct ZielVorschlagTests {
    @Test(arguments: [
        ("Führerschein Klasse B", "Prüfung"), ("LAPL(A) bestehen", "Prüfung"), ("Fit: 75 kg & Halbmarathon", "Gewicht"),
        ("Millionär werden", "Geld als Zahl"), ("10.000 € sparen", "Geld als Zahl"), ("Halbmarathon laufen", "Ausdauer"),
        ("12 Bücher lesen", "Bücher"), ("Spanisch B1", "Sprache"), ("App veröffentlichen", "Projekt"), ("Besserer Mensch werden", "Drei Schritte"),
    ])
    func besteVorlage(_ titel: String, _ name: String) {
        #expect(ZielVorschlag.fuer(titel).first?.name == name, Comment(rawValue: titel))
    }

    @Test func zahlenAusDemTitel() {
        #expect(ZielVorschlag.zahlImTitel("75 kg") == 75)
        #expect(ZielVorschlag.zahlImTitel("10.000 € sparen") == 10000)
        #expect(ZielVorschlag.zahlImTitel("2,5 km") == 2.5)
        #expect(ZielVorschlag.zahlImTitel("Marathon 2027") == nil)
        let geld = ZielVorschlag.fuer("10.000 € sparen").first!
        #expect(geld.schritte.first?.soll == 10000 && geld.schritte.first?.einheit == "€")
        #expect(ZielVorschlag.fuer("Halbmarathon laufen").first?.schritte.first?.soll == 21)
        #expect(ZielVorschlag.fuer("Millionär werden").first?.schritte.first?.soll == 1_000_000)
    }

    @Test func dreiSchritteImmerDabeiUndKurztext() {
        let v = ZielVorschlag.fuer("Führerschein Klasse B")
        #expect(v.count == 2 && v.last == ZielVorschlag.dreiSchritte)
        #expect(v.first?.kurz == "Theorie lernen · Theorieprüfung bestanden ×2 · Praxisprüfung bestanden ×3")
        #expect(ZielVorschlag.fuer("75 kg").first?.kurz == "Gewicht 75 kg ×3")
        #expect(ZielVorschlag.fuer("irgendwas").count == 1)
    }
}

@Suite("Ziele v2 · Rechen-Satz")
struct ZielSatzTests {
    let heute = Tag(2027, 5, 5)

    @Test func satzNenntDurchschnittUndGroesstenRest() {
        var g = Ziel(titel: "Test", farbe: "#000000", symbol: "target", bereich: "x", faellig: Tag(2027, 12, 31), angelegt: Tag(2027, 1, 1))
        #expect(Fortschritt.satz(g, in: Zustand(), heute: heute) == "0 % – noch kein Meilenstein. Leg einen an, dann zählt er.")
        g.schritte = [Schritt(titel: "A", art: .aufgaben, gewicht: 1, geschafft: true), Schritt(titel: "B", art: .aufgaben, gewicht: 3)]
        #expect(Fortschritt.satz(g, in: Zustand(), heute: heute) == "25 % = gewichteter Durchschnitt von 2 Meilensteinen · am meisten fehlt bei „B“.")
        g.schritte = [Schritt(titel: "A", art: .aufgaben, geschafft: true)]
        #expect(Fortschritt.satz(g, in: Zustand(), heute: heute) == "100 % = Stand des einen Meilensteins.")
        g.status = .erreicht
        #expect(Fortschritt.satz(g, in: Zustand(), heute: heute) == "Erreicht – zählt als 100 %.")
    }
}

@Suite("Ziele · nächster Schritt")
struct NaechsterSchrittTests {
    let heute = Tag(2027, 5, 5)

    @Test func meilensteinMitDemGroesstenRest() {
        var g = Ziel(titel: "Test", farbe: "#000000", symbol: "x", bereich: "x", faellig: Tag(2027, 12, 31), angelegt: Tag(2027, 1, 1))
        let a = Schritt(titel: "A", art: .aufgaben, gewicht: 1)
        let b = Schritt(titel: "B", art: .aufgaben, gewicht: 3)
        let c = Schritt(titel: "C", art: .aufgaben, gewicht: 3, geschafft: true)
        g.schritte = [a, b, c]
        var z = Zustand(ziele: [g])
        z.aufgaben = [Aufgabe(titel: "später", datum: Tag(2027, 5, 9), zielID: g.id, schrittID: b.id),
                      Aufgabe(titel: "zuerst", datum: Tag(2027, 5, 6), zielID: g.id, schrittID: b.id)]
        let n = Fortschritt.naechsterSchritt(g, in: z, heute: heute)
        #expect(n?.schritt.id == b.id && n?.aufgabe?.titel == "zuerst")
        #expect(abs((n?.punkte ?? 0) - 3.0 / 7.0) < 1e-9)
        // alles geschafft → kein nächster Schritt; erreichtes Ziel auch nicht
        g.schritte = [c]
        #expect(Fortschritt.naechsterSchritt(g, in: Zustand(ziele: [g]), heute: heute) == nil)
        g.schritte = [a]; g.status = .erreicht
        #expect(Fortschritt.naechsterSchritt(g, in: Zustand(ziele: [g]), heute: heute) == nil)
    }
}
