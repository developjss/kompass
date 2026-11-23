import Foundation
import Testing
@testable import Kompass

// Habits v2: Mengen und Teilerfüllung, n-mal pro Woche, Migration alter Daten, Vorschläge (habits-v2.md §4–§6).

@Suite("Habits v2 · Mengen")
struct HabitMengenTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    @Test func teilmengeZaehltAnteilig() {
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", rhythmus: .taeglich, menge: 20, einheit: .minuten, angelegt: heute.plus(tage: -3))
        h.eintragen(10, am: heute.plus(tage: -1))
        h.eintragen(20, am: heute.plus(tage: -2))
        h.eintragen(30, am: heute.plus(tage: -3)) // mehr als Soll → 1
        #expect(h.anteil(am: heute.plus(tage: -1)) == 0.5)
        #expect(h.anteil(am: heute.plus(tage: -3)) == 1)
        #expect(!h.voll(am: heute.plus(tage: -1)) && h.voll(am: heute.plus(tage: -2)))
        // Quote: (1 + 1 + 0,5) ÷ 3 geplante Tage (heute ohne Eintrag zählt nicht)
        #expect(abs(HabitRechnung.quote(h, heute: heute) - 2.5 / 3) < 1e-12)
        // Serie: gestern nur halb → Serie 0; nach Nachtrag auf 20 → 3
        #expect(HabitRechnung.serie(h, heute: heute) == 0)
        h.eintragen(20, am: heute.plus(tage: -1))
        #expect(HabitRechnung.serie(h, heute: heute) == 3)
        #expect(HabitRechnung.mengenText(h, am: heute.plus(tage: -1)) == "20 von 20 min")
    }

    @Test func umschaltenSetztGanzeMenge() {
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", menge: 20, einheit: .minuten, angelegt: heute)
        h.eintragen(5, am: heute)
        h.umschalten(am: heute)
        #expect(h.eintraege[heute] == 20)
        h.umschalten(am: heute)
        #expect(h.eintraege[heute] == nil)
        var ohne = Habit(titel: "Kein Handy", farbe: "#000000", symbol: "x", angelegt: heute)
        ohne.umschalten(am: heute)
        #expect(ohne.anteil(am: heute) == 1 && HabitRechnung.mengenText(ohne, am: heute) == "erledigt")
    }

    @Test func meilensteinZaehltAnteile() {
        var z = Zustand()
        var h = Habit(titel: "Fragen", farbe: "#000000", symbol: "x", menge: 30, einheit: .mal, angelegt: heute.plus(tage: -10))
        for i in 1...4 { h.eintragen(i % 2 == 0 ? 30 : 15, am: heute.plus(tage: -i)) } // 1 + 0,5 + 1 + 0,5 = 3
        z.habits = [h]
        let s = Schritt(titel: "Üben", art: .habit, seit: heute.plus(tage: -10), soll: 6, habitID: h.id)
        #expect(Fortschritt.habitWert(von: s, in: z, heute: heute) == 3)
        #expect(Fortschritt.stand(s, in: z, heute: heute).anteil == 0.5)
    }
}

@Suite("Habits v2 · n-mal pro Woche")
struct HabitProWocheTests {
    let heute = Tag(2027, 5, 5) // Mittwoch, Woche ab Mo 3.5.

    @Test func wocheUndSerie() {
        var h = Habit(titel: "Sport", farbe: "#000000", symbol: "x", rhythmus: .proWoche(3), menge: 45, einheit: .minuten, angelegt: Tag(2027, 4, 12))
        // Vorwoche (26.4.–2.5.): 3 Einheiten → erfüllt; Woche davor: 2 → nicht; diese Woche: Mo + Di
        for d in [Tag(2027, 4, 26), Tag(2027, 4, 28), Tag(2027, 5, 1), Tag(2027, 4, 19), Tag(2027, 4, 21), Tag(2027, 5, 3), Tag(2027, 5, 4)] { h.eintragen(45, am: d) }
        let w = HabitRechnung.woche(h, montag: heute.montag, seit: h.angelegt, heute: heute)
        #expect(w.geplant == 3 && w.erledigt == 2 && !w.erfuellt)
        #expect(HabitRechnung.geplant(h, am: heute)) // noch nicht voll → heute geplant
        #expect(HabitRechnung.serie(h, heute: heute) == 1) // nur die Vorwoche
        h.eintragen(45, am: heute)
        #expect(HabitRechnung.woche(h, montag: heute.montag, seit: h.angelegt, heute: heute).erfuellt)
        #expect(HabitRechnung.serie(h, heute: heute) == 2)
        #expect(!HabitRechnung.geplant(h, am: heute.plus(tage: 1))) // Woche voll → morgen nicht mehr geplant
        #expect(HabitRechnung.haeufigkeit(h) == "3× pro Woche" && HabitRechnung.sollText(h) == "3× pro Woche · 45 min")
    }

    @Test func quoteUeberWochen() {
        var h = Habit(titel: "Sport", farbe: "#000000", symbol: "x", rhythmus: .proWoche(2), angelegt: Tag(2027, 4, 5))
        // 4 volle Vorwochen: 2, 1, 2, 0 Einheiten → Anteile 1, 0,5, 1, 0 → Mittel 0,625 (laufende Woche leer, zählt nicht)
        for d in [Tag(2027, 4, 5), Tag(2027, 4, 7), Tag(2027, 4, 13), Tag(2027, 4, 19), Tag(2027, 4, 21)] { h.eintragen(1, am: d) }
        #expect(abs(HabitRechnung.quote(h, heute: heute) - 0.625) < 1e-12)
    }
}

@Suite("Habits v2 · Migration und Vorschläge")
struct HabitMigrationTests {
    @Test func alteHabitsWerdenGelesen() throws {
        let alt = """
        {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","titel":"Lesen","farbe":"#000000","symbol":"book","wochentage":[1,3,5],
         "erledigt":["2027-05-03","2027-05-05"],"angelegt":"2027-04-01"}
        """
        let h = try JSONDecoder.kompass.decode(Habit.self, from: Data(alt.utf8))
        #expect(h.rhythmus == .wochentage([1, 3, 5]))
        #expect(h.anteil(am: Tag(2027, 5, 3)) == 1 && h.menge == nil)
        // täglich, wenn alle sieben Tage
        let alt2 = ##"{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FE","titel":"x","farbe":"#000000","symbol":"x","wochentage":[1,2,3,4,5,6,7],"erledigt":[],"angelegt":"2027-04-01"}"##
        #expect(try JSONDecoder.kompass.decode(Habit.self, from: Data(alt2.utf8)).rhythmus == .taeglich)
        // Hin und zurück
        var neu = Habit(titel: "Sport", farbe: "#000000", symbol: "x", rhythmus: .proWoche(3), menge: 45, einheit: .minuten, erinnerung: 1050, angelegt: Tag(2027, 4, 1))
        neu.eintragen(20, am: Tag(2027, 4, 2))
        let wieder = try JSONDecoder.kompass.decode(Habit.self, from: JSONEncoder.kompass.encode(neu))
        #expect(wieder == neu)
    }

    @Test(arguments: [
        ("20 Minuten lesen", 20.0, Einheit.minuten), ("300 g Erdnüsse essen", 300, .gramm), ("Erdnüsse essen", 300, .gramm),
        ("5 km laufen", 5, .kilometer), ("Joggen", 5, .kilometer), ("2 Liter Wasser trinken", 2, .liter), ("30 Liegestütze", 30, .mal),
        ("Meditieren", 10, .minuten), ("10.000 Schritte", 10000, .schritte), ("Buch lesen", 20, .minuten),
    ])
    func vorschlaege(_ titel: String, _ menge: Double, _ einheit: Einheit) {
        let v = HabitVorschlag.fuer(titel)
        #expect(v.menge == menge && v.einheit == einheit, Comment(rawValue: titel))
    }

    @Test func verzichtNurAbhaken() {
        #expect(HabitVorschlag.fuer("Kein Handy nach 22 Uhr").nurAbhaken)
        #expect(HabitVorschlag.fuer("Nicht rauchen").nurAbhaken)
        #expect(!HabitVorschlag.fuer("Lesen").nurAbhaken)
        #expect(HabitVorschlag.schnellwahl(soll: 20) == [5, 10, 15, 20, 25])
    }
}
