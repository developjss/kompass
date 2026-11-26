import Foundation
import Testing
@testable import Kompass

// Rechenregel §12: Signale auf Home – feste Bedingungen, Rang = Gewicht ÷ (1 + Tage), je Art eines, höchstens drei.

@Suite("Home · Signale")
struct SignaleTests {
    private let T = Tag(2026, 11, 25)
    private let mittag = 12 * 60
    private let abend = 19 * 60

    private func signale(_ z: Zustand, jetzt: Int? = nil) -> [Signale.Signal] {
        Signale.alle(zustand: z, heute: T, jetzt: jetzt ?? mittag, termine: { _ in [] })
    }
    private func ziel(_ titel: String, vor: Int, bis: Int) -> Ziel {
        Ziel(titel: titel, farbe: "#33475F", symbol: "target", bereich: "Test", faellig: T.plus(tage: bis), angelegt: T.plus(tage: -vor))
    }
    private func habit(_ titel: String, tage: ClosedRange<Int>, rhythmus: Rhythmus = .taeglich) -> Habit {
        var e: [Tag: Double] = [:]
        for i in tage { e[T.plus(tage: -i)] = 1 }
        return Habit(titel: titel, farbe: "#33475F", symbol: "book", rhythmus: rhythmus, eintraege: e, angelegt: T.plus(tage: -200))
    }

    @Test func ohneDatenKeinSignal() {
        #expect(signale(Zustand()).isEmpty)
    }

    @Test func liegengeblieben() {
        var z = Zustand()
        z.aufgaben = [Aufgabe(titel: "Alt", datum: T.plus(tage: -1)), Aufgabe(titel: "Älter", datum: T.plus(tage: -3)),
                      Aufgabe(titel: "Erledigt", datum: T.plus(tage: -1), erledigt: true), Aufgabe(titel: "Heute", datum: T)]
        let s = signale(z).first { $0.art == .liegengeblieben }
        #expect(s?.titel == "2 Aufgaben liegen geblieben")
        #expect(s?.handlung == .aufHeute)
        #expect(s?.rang == 90)
    }

    @Test func vollerTagAb75Prozent() {
        var z = Zustand()
        // wach 7–22 Uhr = 900 Min; 75 % = 675 Min
        z.aufgaben = [Aufgabe(titel: "Lang", datum: T.plus(tage: 1), uhrzeit: 8 * 60, dauer: 675)]
        let s = signale(z).first { $0.art == .engpass }
        #expect(s?.titel == "Morgen ist voll")
        #expect(s?.text == "11 h 15 min verplant")
        #expect(s?.tage == 1)
        #expect(s?.rang == 40)
        #expect(s?.handlung == .kalender(T.plus(tage: 1)))
        z.aufgaben[0].dauer = 670
        #expect(!signale(z).contains { $0.art == .engpass })
    }

    @Test func luftNurMitAufgabenOhneDatum() {
        var z = Zustand()
        #expect(!signale(z).contains { $0.art == .luft })
        z.aufgaben = [Aufgabe(titel: "Irgendwann")]
        let s = signale(z).first { $0.art == .luft }
        #expect(s?.titel == "Morgen ist Luft")
        #expect(s?.text == "15 h frei · 1 Aufgabe ohne Datum")
        #expect(s?.rang == 20)
    }

    @Test func zielHinterPlanNimmtDenGroesstenRueckstand() {
        let z = Zustand(ziele: [ziel("Klein", vor: 20, bis: 80), ziel("Groß", vor: 100, bis: 100)])
        let s = signale(z).filter { $0.art == .zielKippt }
        #expect(s.count == 1)                                   // je Art höchstens eines
        #expect(s.first?.titel == "Ziel hinter Plan")
        #expect(s.first?.text == "Groß · 0 % statt 50 %")
        #expect(s.first?.rang == 70)
    }

    @Test func zielImPlanKeinSignal() {
        // 5 von 100 Tagen: erwartet 5 %, Rückstand unter 10 Punkten (§4)
        let z = Zustand(ziele: [ziel("Frisch", vor: 5, bis: 95)])
        #expect(!signale(z).contains { $0.art == .zielKippt })
        #expect(!signale(z).contains { $0.art == .fristNah })
    }

    @Test func fristNahBisVierzehnTage() {
        var z = Zustand(ziele: [ziel("Prüfung", vor: 50, bis: 9)])
        let s = signale(z).first { $0.art == .fristNah }
        #expect(s?.titel == "Frist in 9 Tagen")
        #expect(s?.text == "Prüfung · 0 %")
        #expect(s?.rang == 6)
        z.ziele[0].faellig = T.plus(tage: 15)
        #expect(!signale(z).contains { $0.art == .fristNah })
        z.ziele[0].faellig = T
        #expect(signale(z).first { $0.art == .fristNah }?.titel == "Frist heute")
    }

    @Test func serieInGefahrErstAbends() {
        var z = Zustand()
        z.habits = [habit("Lesen", tage: 1...10)]
        #expect(!signale(z, jetzt: mittag).contains { $0.art == .serieGefahr })
        let s = signale(z, jetzt: abend).first { $0.art == .serieGefahr }
        #expect(s?.text == "Lesen · 10 Tage · heute offen")
        #expect(s?.rang == 100)
        #expect(s?.handlung == .habit(z.habits[0].id))
        z.habits = [habit("Kurz", tage: 1...6)]                 // Serie unter 7
        #expect(!signale(z, jetzt: abend).contains { $0.art == .serieGefahr })
        z.habits = [habit("Wochen", tage: 1...60, rhythmus: .proWoche(3))]
        #expect(!signale(z, jetzt: abend).contains { $0.art == .serieGefahr })
    }

    @Test func serieGeschafftNurAnDerMarke() {
        var z = Zustand()
        z.habits = [habit("Lesen", tage: 0...6)]                // 7 Tage, heute dabei
        #expect(signale(z).first { $0.art == .serieGeschafft }?.titel == "7 Tage Serie")
        z.habits = [habit("Lesen", tage: 0...7)]                // 8 Tage: keine Marke
        #expect(!signale(z).contains { $0.art == .serieGeschafft })
    }

    @Test func rangfolgeUndHoechstensDrei() {
        var z = Zustand(ziele: [ziel("Prüfung", vor: 50, bis: 9)])
        z.aufgaben = [Aufgabe(titel: "Alt", datum: T.plus(tage: -1)), Aufgabe(titel: "Irgendwann")]
        z.habits = [habit("Lesen", tage: 1...10)]
        let alle = signale(z, jetzt: abend)
        #expect(alle.map(\.art).prefix(3) == [.serieGefahr, .liegengeblieben, .zielKippt])
        #expect(alle == alle.sorted { $0.rang > $1.rang })
        #expect(Set(alle.map(\.art)).count == alle.count)
        let oben = Signale.oben(alle, stumm: [:], heute: T)
        #expect(oben.count == 3)
    }

    @Test func passtNichtStelltAchtWochenStumm() {
        var z = Zustand()
        z.aufgaben = [Aufgabe(titel: "Alt", datum: T.plus(tage: -1))]
        let alle = signale(z)
        let bis = Signale.stummBis(heute: T)
        #expect(bis == T.plus(tage: 56))
        #expect(Signale.oben(alle, stumm: ["liegengeblieben": bis], heute: T).isEmpty)
        #expect(Signale.oben(alle, stumm: ["liegengeblieben": bis], heute: bis.plus(tage: -1)).isEmpty)
        #expect(Signale.oben(alle, stumm: ["liegengeblieben": bis], heute: bis).count == 1)
    }

    @Test func gewichteSindEindeutigUndBekannt() {
        let g = Signale.Art.allCases.map(\.gewicht)
        #expect(Set(g).count == g.count)
        #expect(g == g.sorted(by: >))
    }
}
