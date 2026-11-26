import Foundation
import Testing
@testable import Kompass

// Rechenregel §13: Rückblick konkret – Listen, Fokus, Auslastung, Vorschläge, Erkenntnis.

@Suite("Rückblick · konkret")
struct RueckschauTests {
    private let T = Tag(2026, 11, 25)              // Mittwoch
    private var montag: Tag { T.montag }
    private let ziel = UUID()

    @Test func erledigtUndOffenSortiert() {
        var z = Zustand()
        z.aufgaben = [
            Aufgabe(titel: "B ohne Ziel", datum: montag, erledigt: true),
            Aufgabe(titel: "A mit Ziel", datum: montag, zielID: ziel, erledigt: true),
            Aufgabe(titel: "Offen normal", datum: montag),
            Aufgabe(titel: "Offen wichtig", datum: T, prio: .hoch),
            Aufgabe(titel: "Morgen", datum: T.plus(tage: 1)),          // nach heute: zählt nicht
            Aufgabe(titel: "Letzte Woche", datum: montag.plus(tage: -1), erledigt: true),
            Aufgabe(titel: "Ohne Datum"),
        ]
        let l = Rueckschau.aufgaben(zustand: z, von: montag, bis: montag.plus(tage: 6), heute: T)
        #expect(l.erledigt.map(\.titel) == ["A mit Ziel", "B ohne Ziel"])
        #expect(l.offen.map(\.titel) == ["Offen wichtig", "Offen normal"])
    }

    @Test func fokusJeAufgabeUndOhneTimer() {
        var z = Zustand()
        let a = Aufgabe(titel: "Lernen", datum: montag, erledigt: true), b = Aufgabe(titel: "Mail", datum: montag, erledigt: true), c = Aufgabe(titel: "Lesen", datum: T)
        z.aufgaben = [a, b, c]
        z.sitzungen = [FokusSitzung(aufgabeID: a.id, tag: montag, sekunden: 1800), FokusSitzung(aufgabeID: a.id, tag: T, sekunden: 600),
                       FokusSitzung(aufgabeID: c.id, tag: T, sekunden: 3000), FokusSitzung(aufgabeID: nil, tag: T, sekunden: 300),
                       FokusSitzung(aufgabeID: a.id, tag: montag.plus(tage: -1), sekunden: 9999)]
        let f = Rueckschau.fokus(zustand: z, von: montag, bis: montag.plus(tage: 6), heute: T)
        #expect(f.posten.map(\.titel) == ["Lesen", "Lernen", "Ohne Aufgabe"])
        #expect(f.posten.map(\.sekunden) == [3000, 2400, 300])
        #expect(f.summe == 5700)
        #expect(f.ohneTimer.map(\.titel) == ["Mail"])     // erledigt, aber nie gemessen
    }

    @Test func auslastungMittelUndArten() {
        var z = Zustand()
        // Montag 450 Min (50 % von 900), Dienstag 90 Min
        z.aufgaben = [Aufgabe(titel: "Lang", datum: montag, uhrzeit: 8 * 60, dauer: 450), Aufgabe(titel: "Kurz", datum: montag.plus(tage: 1), uhrzeit: 9 * 60, dauer: 90)]
        let a = Rueckschau.auslastung(zustand: z, montag: montag, termine: { _ in [] })
        #expect(a.aufgaben == 540 && a.termine == 0 && a.habits == 0)
        #expect(abs(a.mittel - (0.5 + 0.1) / 7) < 0.0001)
        #expect(a.vollster == 0)
        #expect(a.volleTage == 0)
    }

    @Test func vorschlagEntlastenUndLuftNutzen() {
        var z = Zustand()
        let lang = Aufgabe(titel: "Großes", datum: T.plus(tage: 1), uhrzeit: 7 * 60, dauer: 400)
        let kurz = Aufgabe(titel: "Kleines", datum: T.plus(tage: 1), uhrzeit: 14 * 60, dauer: 300)
        let frei = Aufgabe(titel: "Irgendwann", prio: .hoch)
        z.aufgaben = [lang, kurz, frei, Aufgabe(titel: "Später")]
        let v = Rueckschau.vorschlaege(zustand: z, heute: T, jetzt: 12 * 60, termine: { _ in [] })
        #expect(v.map(\.art) == [.entlasten, .luftNutzen])
        #expect(v[0].aufgabeID == lang.id)                  // die längste Aufgabe des vollen Tages
        #expect(v[0].nach == T.plus(tage: 2))               // der leerste Tag ab morgen
        #expect(v[0].titel == "Morgen entlasten")
        #expect(v[1].aufgabeID == frei.id)                  // hohe Priorität zuerst
        #expect(v[1].text == "„Irgendwann“ einplanen · 2 ohne Datum")
    }

    @Test func keinVorschlagOhneAnlass() {
        var z = Zustand()
        z.aufgaben = [Aufgabe(titel: "Normal", datum: T.plus(tage: 1), uhrzeit: 9 * 60, dauer: 120)]
        #expect(Rueckschau.vorschlaege(zustand: z, heute: T, jetzt: 12 * 60, termine: { _ in [] }).isEmpty)
    }

    @Test func dreiAblehnungenBlendenDieArtAus() {
        let v = [Rueckschau.Vorschlag(art: .entlasten, aufgabeID: UUID(), nach: T, titel: "a", text: "b"),
                 Rueckschau.Vorschlag(art: .luftNutzen, aufgabeID: UUID(), nach: T, titel: "c", text: "d")]
        var l = Lernen()
        #expect(Rueckschau.zeigen(v, lernen: l).count == 2)
        l.vorschlaege["auslastung.entlasten"] = .init(gezeigt: 2, uebernommen: 0)   // (0+1)/(2+2) = 25 % → bleibt
        #expect(Rueckschau.zeigen(v, lernen: l).count == 2)
        l.vorschlaege["auslastung.entlasten"] = .init(gezeigt: 3, uebernommen: 0)   // 20 % → weg
        #expect(Rueckschau.zeigen(v, lernen: l).map(\.art) == [.luftNutzen])
        l.vorschlaege["auslastung.entlasten"] = .init(gezeigt: 4, uebernommen: 4)   // oft übernommen → zuerst
        #expect(Rueckschau.zeigen(v, lernen: l).map(\.art) == [.entlasten, .luftNutzen])
    }

    @Test func erkenntnisErledigtRegeln() {
        let leer = Rueckschau.erkenntnisErledigt(geplantJeTag: Array(repeating: 0, count: 7), erledigtJeTag: Array(repeating: 0, count: 7), tage: 3)
        #expect(leer.titel == "Noch nichts geplant")
        let zuViel = Rueckschau.erkenntnisErledigt(geplantJeTag: [4, 4, 2, 0, 0, 0, 0], erledigtJeTag: [2, 1, 1, 0, 0, 0, 0], tage: 2)
        #expect(zuViel.titel == "Mehr geplant als geschafft")
        #expect(zuViel.text.contains("5") && zuViel.text.contains("2"))
        let schwach = Rueckschau.erkenntnisErledigt(geplantJeTag: [4, 4, 0, 0, 0, 0, 0], erledigtJeTag: [4, 2, 0, 0, 0, 0, 0], tage: 2)
        #expect(schwach.titel == "Dienstag ist dein schwächster Tag")
        // heute (Dienstag) läuft noch → kann nicht der schwächste sein
        #expect(Rueckschau.erkenntnisErledigt(geplantJeTag: [4, 4, 0, 0, 0, 0, 0], erledigtJeTag: [4, 2, 0, 0, 0, 0, 0], tage: 2, laufend: 1).titel != "Dienstag ist dein schwächster Tag")
        let stark = Rueckschau.erkenntnisErledigt(geplantJeTag: [4, 4, 0, 0, 0, 0, 0], erledigtJeTag: [4, 3.5, 0, 0, 0, 0, 0], tage: 2)
        #expect(stark.titel == "Fast alles geschafft")
        let solide = Rueckschau.erkenntnisErledigt(geplantJeTag: [4, 4, 0, 0, 0, 0, 0], erledigtJeTag: [3, 2.5, 0, 0, 0, 0, 0], tage: 2)
        #expect(solide.titel == "Solide")
    }

    @Test func erkenntnisHabitsUndZiele() {
        var z = Zustand()
        #expect(Rueckschau.erkenntnisHabits(zustand: z, von: montag, bis: T, heute: T).titel == "Noch kein Habit geplant")
        #expect(Rueckschau.erkenntnisZiele(zustand: z, von: montag, bis: T, heute: T).titel == "Noch kein Ziel")
        z.habits = [Habit(titel: "Lesen", farbe: "#33475F", symbol: "book", eintraege: [montag: 1], angelegt: montag.plus(tage: -30))]
        let h = Rueckschau.erkenntnisHabits(zustand: z, von: montag, bis: T, heute: T)   // 1 von 3 Tagen
        #expect(h.titel == "„Lesen“ fällt zurück")
        #expect(h.ziel == .habitSeite(z.habits[0].id))
        z.habits[0].eintraege = [montag: 1, montag.plus(tage: 1): 1, T: 1]
        #expect(Rueckschau.erkenntnisHabits(zustand: z, von: montag, bis: T, heute: T).titel == "Alle Habits stabil")
        z.ziele = [Ziel(titel: "Fit", farbe: "#33475F", symbol: "figure.run", bereich: "Test", faellig: T.plus(tage: 100), angelegt: T.plus(tage: -100))]
        let g = Rueckschau.erkenntnisZiele(zustand: z, von: montag, bis: T, heute: T)     // 0 % statt 50 %
        #expect(g.titel == "„Fit“ braucht dich")
        #expect(g.ziel == .zielSeite(z.ziele[0].id))
        z.ziele[0].angelegt = T.plus(tage: -2)                                           // frisch → im Plan, aber keine Zeit
        #expect(Rueckschau.erkenntnisZiele(zustand: z, von: montag, bis: T, heute: T).titel == "Keine Zeit für „Fit“")
    }

    @Test func erkenntnisZeit() {
        #expect(Rueckschau.erkenntnisZeit(fokus: 0, fuerZiele: 0).titel == "Noch kein Fokus gemessen")
        #expect(Rueckschau.erkenntnisZeit(fokus: 3600, fuerZiele: 900).titel == "Wenig Fokus für Ziele")
        #expect(Rueckschau.erkenntnisZeit(fokus: 3600, fuerZiele: 1800).titel == "Fokus zahlt auf Ziele ein")
    }
}
