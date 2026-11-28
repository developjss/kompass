import Testing
@testable import Kompass

/// Einheiten und Ziel-Werte: feste Spannen, Raster und Texte.
struct EinheitTests {
    @Test func idsSindEindeutig() {
        let ids = Einheit.alle.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func listenStimmen() {
        #expect(Einheit.zeiten.map(\.id) == ["sek", "min", "std"])
        #expect(Einheit.mengen.first == .keine)
        #expect(Einheit.zeiten.allSatisfy { $0.art == .zeit && $0.auswahl == .lineal })
        #expect(Einheit.mengen.allSatisfy { $0.art == .menge })
    }

    @Test func standardUndSchnellwahlLiegenAufDemRaster() {
        for e in Einheit.alle {
            let w = e.werte
            #expect(w.first == e.von, "\(e.id)")
            #expect(w.last == e.bis, "\(e.id)")
            #expect(w.contains(e.standard), "\(e.id) Standard")
            for s in e.schnellwahl { #expect(w.contains(s), "\(e.id) Schnellwahl \(s)") }
        }
    }

    @Test func rasterOhneRundungsfehler() {
        #expect(Einheit.km.werte.count == 1000)
        #expect(Einheit.km.werte[24] == 2.5)
        #expect(Einheit.stunden.werte.count == 48)
        #expect(Einheit.ml.werte == [250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000])
    }

    @Test func einrastenBleibtInDerSpanne() {
        #expect(Einheit.schritte.eingerastet(10_240) == 10_000)
        #expect(Einheit.schritte.eingerastet(-5) == 500)
        #expect(Einheit.schritte.eingerastet(99_999) == 30_000)
        #expect(Einheit.km.eingerastet(2.54) == 2.5)
        #expect(Einheit.minuten.index(von: 85) == 16)
    }

    @Test func texte() {
        #expect(Einheit.minuten.text(85) == "1h 25m")
        #expect(Einheit.minuten.text(45) == "45m")
        #expect(Einheit.stunden.text(1.25) == "1h 15m")
        #expect(Einheit.sekunden.text(90) == "1m 30s")
        #expect(Einheit.sekunden.text(30) == "30s")
        #expect(Einheit.schritte.text(10_000) == "10.000 Schritte")
        #expect(Einheit.km.text(2.5) == "2,5 km")
        #expect(Einheit.km.text(5) == "5 km")
        #expect(Einheit.glaeser.text(1) == "1 Glas")
        #expect(Einheit.glaeser.text(8) == "8 Gläser")
        #expect(Einheit.ml.text(1_500) == "1.500 ml")
        #expect(Einheit.keine.text(1) == "Einmal am Tag")
        #expect(Einheit.minuten.marke(120) == "2h")
        #expect(Einheit.schritte.marke(5_000) == "5.000")
        #expect(Einheit.glaeserText(ml: 1_500) == "6 Gläser à 250 ml")
        #expect(Einheit.glaeserText(ml: 250) == "1 Glas à 250 ml")
    }

    @Test func eigeneEinheit() {
        let e = Einheit.eigene("  Liegestütze ")
        #expect(e.name == "Liegestütze")
        #expect(e.istEigene)
        #expect(e.auswahl == .rad)
        #expect(e.text(12) == "12 Liegestütze")
    }
}

/// Ziele von „Mein Weg“ und die Zeile „Gehört zu“.
struct ZielTests {
    @Test func zeilenText() {
        #expect(Ziel.zeilenText(nil) == "Kein Ziel")
        #expect(Ziel.zeilenText(Ziel.demo[0]) == "Pilotenschein")
    }

    @Test func demoZieleSindEindeutig() {
        #expect(Set(Ziel.demo.map(\.id)).count == Ziel.demo.count)
        #expect(Ziel.demo.map(\.titel) == ["Pilotenschein", "Erster Alleinflug"])
    }
}
