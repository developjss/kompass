import Foundation
import Testing
@testable import Kompass

// Ziele-Übersicht: Filter, Sortierung, Gruppen nach Jahr/Bereich · Anteile der Meilensteine (rechenregeln.md §1).

@Suite("Ziele · Ordnung und Anteile")
struct ZielOrdnungTests {
    let heute = Tag(2027, 5, 5)

    func ziel(_ t: String, bis: Tag, bereich: String = "x", geschafft: [Bool], status: ZielStatus = .aktiv) -> Ziel {
        var g = Ziel(titel: t, farbe: "#000000", symbol: "x", bereich: bereich, faellig: bis, angelegt: Tag(2027, 1, 1))
        g.schritte = geschafft.map { Schritt(titel: "s", art: .aufgaben, geschafft: $0) }
        g.status = status
        return g
    }

    func zustand() -> Zustand {
        // Seit Anlage ~1/3 der Zeit bis Ende 2027 vorbei
        Zustand(ziele: [
            ziel("Bergtour", bis: Tag(2027, 12, 31), bereich: "Sport", geschafft: [true, true, false]),  // 67 % → voraus
            ziel("Anki", bis: Tag(2027, 12, 31), bereich: "Lernen", geschafft: [false, false, false]),   // 0 % → hinterher
            ziel("Ausland", bis: Tag(2028, 6, 30), bereich: "Lernen", geschafft: [true, false]),          // 50 % → voraus
            ziel("Alt", bis: Tag(2027, 3, 1), geschafft: [true], status: .erreicht),
        ])
    }

    @Test func filterUndAnzahl() {
        let z = zustand()
        #expect(ZielOrdnung.anzahl(.alle, in: z, heute: heute) == 3)
        #expect(ZielOrdnung.anzahl(.aufKurs, in: z, heute: heute) == 2)
        #expect(ZielOrdnung.anzahl(.hinterher, in: z, heute: heute) == 1)
        #expect(ZielOrdnung.anzahl(.erreicht, in: z, heute: heute) == 1)
    }

    @Test func sortierenUndGruppieren() {
        let z = zustand()
        func titel(_ s: ZielOrdnung.Sortierung) -> [[String]] { ZielOrdnung.gruppen(z, filter: .alle, sortierung: s, heute: heute).map { $0.ziele.map(\.titel) } }
        #expect(titel(.frist) == [["Anki", "Bergtour", "Ausland"]])          // gleiche Frist → Titel
        #expect(titel(.name) == [["Anki", "Ausland", "Bergtour"]])
        #expect(titel(.fortschritt) == [["Bergtour", "Ausland", "Anki"]])
        #expect(titel(.hinterherZuerst).first?.first == "Anki")
        let jahre = ZielOrdnung.gruppen(z, filter: .alle, sortierung: .jahr, heute: heute)
        #expect(jahre.map(\.titel) == ["2027", "2028"] && jahre[0].ziele.count == 2)
        #expect(ZielOrdnung.gruppen(z, filter: .alle, sortierung: .bereich, heute: heute).map(\.titel) == ["Lernen", "Sport"])
        #expect(ZielOrdnung.gruppen(Zustand(), filter: .alle, sortierung: .frist, heute: heute).isEmpty)
    }

    @Test func anteileDerMeilensteine() {
        #expect(Fortschritt.anteile([1, 1]) == [0.5, 0.5])
        #expect(Fortschritt.anteile([1, 3]) == [0.25, 0.75])
        #expect(Fortschritt.anteile([7]) == [1])          // ungültiges Gewicht zählt als 1
        #expect(Fortschritt.anteile([]).isEmpty)
        var g = ziel("x", bis: heute, geschafft: [false, false])
        g.schritte[0].gewicht = 2
        // neuer großer Meilenstein: 3 ÷ (2 + 1 + 3) = 50 %
        #expect(Fortschritt.anteilVorschau(g, gewicht: 3) == 0.5)
        // bestehenden ersetzen: 1 ÷ (1 + 1) = 50 %
        #expect(Fortschritt.anteilVorschau(g, gewicht: 1, ersetzt: g.schritte[0].id) == 0.5)
        // löschen: der Rest teilt sich 100 %
        #expect(Fortschritt.anteileOhne(g, ohne: g.schritte[0].id).map(\.1) == [1])
    }

    @Test func aehnlicheTitelWerdenNichtNochmalVorgeschlagen() {
        #expect(ZielVorschlag.aehnlich("Praxisprüfung bestanden", "Praktische Prüfung"))
        #expect(ZielVorschlag.aehnlich("Theorieprüfung bestanden", "Theorieprüfung"))
        #expect(ZielVorschlag.aehnlich("theorie lernen", "Theorie lernen"))
        #expect(!ZielVorschlag.aehnlich("Theorie lernen", "Fahrstunden"))
        #expect(!ZielVorschlag.aehnlich("Sehtest", "Erste-Hilfe-Kurs"))
    }
}
