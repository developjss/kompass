import Foundation
import Testing
@testable import Kompass

// Kalender-Empfehlungen (rechenregeln.md §9.1): Reihenfolge nach Punkten, Platz nach freier Zeit, je Ansicht.

@Suite("Kalender · Empfehlungen")
struct EmpfehlungTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    func leer() -> Zustand {
        var z = Zustand()
        z.einstellungen.googleBeispiel = false
        z.einstellungen.appleBeispiel = false
        return z
    }

    func quelle(_ z: Zustand) -> (Tag) -> [Termin] { { d in Kalenderquelle.termine(am: d, zustand: z, heute: heute) } }

    @Test func tagReihenfolgeUndErsteFreieLuecke() {
        var z = leer()
        z.aufgaben = [Aufgabe(titel: "Bericht", datum: heute, uhrzeit: 10 * 60, dauer: 60),
                      Aufgabe(titel: "Einkaufen", datum: heute, dauer: 30),
                      Aufgabe(titel: "Alt", datum: heute.plus(tage: -3), dauer: 60),
                      Aufgabe(titel: "Idee", dauer: 60),
                      Aufgabe(titel: "Später", datum: heute.plus(tage: 2), dauer: 30)]
        z.habits = [Habit(titel: "Sport", farbe: "#15803D", symbol: "x", rhythmus: .taeglich, menge: 45, einheit: .minuten, angelegt: heute.plus(tage: -10))]
        z.eigeneTermine = [EigenerTermin(titel: "Uni", tag: heute, start: 8 * 60, ende: 9 * 60 + 30, kategorie: .studium, wiederholung: .nie)]
        let v = Empfehlung.fuer(.tag, tag: heute, zustand: z, heute: heute, jetzt: 7 * 60, termine: quelle(z))
        #expect(v.map(\.titel) == ["Alt", "Einkaufen", "Sport", "Idee"])
        #expect(v[0].grund == "Überfällig seit 3 Tagen" && v[1].grund == "Heute fällig" && v[3].grund == "Aus dem Eingang")
        // Uni 8:00–9:30, Bericht 10–11 → Alt (60) erst um 11:00, Einkaufen (30) passt 9:30, Sport (45) ab 12:00, Idee danach
        #expect(v.map(\.uhrzeit) == [11 * 60, 9 * 60 + 30, 12 * 60, 12 * 60 + 45])
        #expect(Empfehlung.platzText(v[1], bereich: .tag, heute: heute) == "09:30")
        // Bericht hat eine Uhrzeit, „Später“ liegt an einem anderen Tag → nicht dabei
        #expect(!v.contains { $0.titel == "Bericht" || $0.titel == "Später" })
    }

    @Test func tagAbJetztUndErledigteHabitsFehlen() {
        var z = leer()
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", angelegt: heute.plus(tage: -1))
        h.eintraege[heute] = 1
        z.habits = [h]
        z.aufgaben = [Aufgabe(titel: "A", datum: heute, dauer: 30)]
        let v = Empfehlung.fuer(.tag, tag: heute, zustand: z, heute: heute, jetzt: 14 * 60 + 5, termine: quelle(z))
        #expect(v.map(\.titel) == ["A"] && v[0].uhrzeit == 14 * 60 + 15)
        // Vergangener Tag: Vorschläge ohne Uhrzeit; zu spät am Abend: kein Platz mehr
        #expect(Empfehlung.fuer(.tag, tag: heute.plus(tage: -1), zustand: z, heute: heute, jetzt: 600, termine: quelle(z)).allSatisfy { $0.uhrzeit == nil })
        let spaet = Empfehlung.fuer(.tag, tag: heute, zustand: z, heute: heute, jetzt: 21 * 60 + 50, termine: quelle(z))[0]
        #expect(spaet.uhrzeit == nil && spaet.verschoben && spaet.tag == heute.plus(tage: 1))
        #expect(Empfehlung.platzText(spaet, bereich: .tag, heute: heute) == "morgen")
    }

    @Test func wocheVerteiltAufFreiesteTageOhneHabits() {
        var z = leer()
        z.aufgaben = [Aufgabe(titel: "Fr fällig", datum: Tag(2027, 5, 7), dauer: 60),
                      Aufgabe(titel: "Eingang", dauer: 60),
                      Aufgabe(titel: "Nächste Woche", datum: Tag(2027, 5, 12), dauer: 60),
                      Aufgabe(titel: "Mit Zeit", datum: Tag(2027, 5, 6), uhrzeit: 9 * 60, dauer: 60)]
        z.habits = [Habit(titel: "Sport", farbe: "#000000", symbol: "x", angelegt: heute.plus(tage: -5))]
        let v = Empfehlung.fuer(.woche, tag: Tag(2027, 5, 3), zustand: z, heute: heute, jetzt: 7 * 60, termine: quelle(z))
        #expect(v.map(\.titel) == ["Fr fällig", "Eingang"])
        #expect(v[0].grund == "Fällig Fr")
        // Alle Tage gleich frei → heute zuerst, dann der nächste freieste (Donnerstag hat 1 h Termin, also Freitag)
        #expect(v[0].tag == heute && v[1].tag == Tag(2027, 5, 7))
        #expect(v.allSatisfy { $0.uhrzeit == nil })
        #expect(Empfehlung.platzText(v[1], bereich: .woche, heute: heute) == "Fr")
        // Vergangene Woche: nur Überfälliges/Eingang, kein Platz in der Vergangenheit
        let alt = Empfehlung.fuer(.woche, tag: Tag(2027, 4, 26), zustand: z, heute: heute, jetzt: 7 * 60, termine: quelle(z))
        #expect(alt.map(\.titel) == ["Eingang"] && alt[0].tag == Tag(2027, 4, 26))
    }

    @Test func nieNachDerFrist() {
        var z = leer()
        // Heute ist voll verplant, Donnerstag halb – trotzdem bleibt „heute fällig“ bei heute, „Do fällig“ spätestens Do
        z.eigeneTermine = [EigenerTermin(titel: "Voll", tag: heute, start: 7 * 60, ende: 21 * 60, kategorie: .arbeit, wiederholung: .nie),
                           EigenerTermin(titel: "Halb", tag: Tag(2027, 5, 6), start: 7 * 60, ende: 14 * 60, kategorie: .arbeit, wiederholung: .nie)]
        z.aufgaben = [Aufgabe(titel: "Heute", datum: heute, dauer: 30), Aufgabe(titel: "Do", datum: Tag(2027, 5, 6), dauer: 30),
                      Aufgabe(titel: "Offen", dauer: 30)]
        let v = Empfehlung.fuer(.woche, tag: heute, zustand: z, heute: heute, jetzt: 7 * 60, termine: quelle(z))
        let tag = Dictionary(uniqueKeysWithValues: v.map { ($0.titel, $0.tag) })
        #expect(tag["Heute"] == heute && tag["Do"] == Tag(2027, 5, 6) && tag["Offen"] == Tag(2027, 5, 7))
    }

    @Test func naechsterSchrittEinesZielsZuerst() {
        var z = leer()
        var g = Ziel(titel: "Job", farbe: "#123456", symbol: "x", bereich: "x", faellig: heute.plus(tage: 90), angelegt: heute)
        let s = Schritt(titel: "Bewerben", art: .aufgaben)
        g.schritte = [s]
        z.ziele = [g]
        z.aufgaben = [Aufgabe(titel: "Idee", dauer: 30),
                      Aufgabe(titel: "Lebenslauf", dauer: 30, zielID: g.id, schrittID: s.id)]
        let v = Empfehlung.fuer(.monat, tag: heute, zustand: z, heute: heute, jetzt: 7 * 60, termine: quelle(z))
        #expect(v.first?.titel == "Lebenslauf" && v.first?.grund == "Nächster Schritt für „Job“")
        #expect(Empfehlung.zeitraum(.monat, heute) == (Tag(2027, 5, 1), Tag(2027, 5, 31)))
    }

    @Test func assistentNenntDieselbenVorschlaege() {
        var z = leer()
        z.aufgaben = [Aufgabe(titel: "Einkaufen", datum: heute, dauer: 30)]
        let a = Werkzeuge.empfehlen(z, heute, woche: false, jetzt: 7 * 60)
        #expect(a.text.contains("„Einkaufen“ um 08:00") && a.text.contains("„Empfehlung“"))
    }
}
