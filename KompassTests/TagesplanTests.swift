import Foundation
import Testing
@testable import Kompass

// Struktur v3: Tagesplan (rechenregeln.md §9) – Blöcke, Als Nächstes, Auslastung, Hinweise, eigene Termine, Einplanen.

@Suite("Tagesplan")
struct TagesplanTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    func zustand() -> Zustand {
        var z = Zustand()
        var a = Aufgabe(titel: "Bericht", datum: heute, uhrzeit: 10 * 60, dauer: 60)
        a.kategorie = .arbeit
        z.aufgaben = [a, Aufgabe(titel: "Einkaufen", datum: heute, dauer: 30)]
        var h = Habit(titel: "Lesen", farbe: "#7A4FD6", symbol: "book.fill", menge: 20, einheit: .minuten, angelegt: heute.plus(tage: -10))
        h.uhrzeit = 21 * 60
        z.habits = [h, Habit(titel: "Sport", farbe: "#15803D", symbol: "x", rhythmus: .proWoche(3), menge: 45, einheit: .minuten, angelegt: heute.plus(tage: -10))]
        z.eigeneTermine = [EigenerTermin(titel: "Uni", tag: heute.plus(tage: -7), start: 8 * 60, ende: 9 * 60 + 30, kategorie: .studium, wiederholung: .woechentlich)]
        return z
    }

    func quelle(_ z: Zustand) -> (Tag) -> [Termin] { { d in Kalenderquelle.termine(am: d, zustand: z, heute: heute) } }

    @Test func bloeckeAusAllenQuellen() {
        let z = zustand()
        let b = Tagesplan.bloecke(am: heute, zustand: z, termine: quelle(z)(heute))
        #expect(b.map(\.titel) == ["Uni", "Bericht", "Lesen"])
        #expect(b[0].farbe == Kategorie.studium.farbe && b[1].farbe == Kategorie.arbeit.farbe)
        #expect(b[2].dauer == 20 && b[2].art == .habit)
        let ohne = Tagesplan.ohneZeit(am: heute, zustand: z)
        #expect(ohne.aufgaben.map(\.titel) == ["Einkaufen"] && ohne.habits.map(\.titel) == ["Sport"])
        // Wöchentlich: nächste Woche wieder, Donnerstag nicht
        #expect(Kalenderquelle.termine(am: heute.plus(tage: 7), zustand: z, heute: heute).contains { $0.titel == "Uni" })
        #expect(!Kalenderquelle.termine(am: heute.plus(tage: 1), zustand: z, heute: heute).contains { $0.titel == "Uni" })
    }

    @Test func farbeNachZielOderKategorie() {
        var z = zustand()
        let g = Ziel(titel: "Job", farbe: "#123456", symbol: "x", bereich: "x", faellig: heute.plus(tage: 90), angelegt: heute)
        z.ziele = [g]
        z.aufgaben[0].zielID = g.id
        #expect(Tagesplan.bloecke(am: heute, zustand: z, termine: []).first { $0.titel == "Bericht" }?.farbe == "#123456")
        z.einstellungen.farbenNachKategorie = true
        #expect(Tagesplan.bloecke(am: heute, zustand: z, termine: []).first { $0.titel == "Bericht" }?.farbe == Kategorie.arbeit.farbe)
    }

    @Test func alsNaechstesAbJetzt() {
        let z = zustand()
        // 9:00 – Uni läuft noch, dann Bericht, dann Lesen
        let n = Tagesplan.naechste(zustand: z, heute: heute, jetzt: 9 * 60, termine: quelle(z))
        #expect(n.map(\.titel) == ["Uni", "Bericht", "Lesen"])
        #expect(Tagesplan.laeuft(n[0], heute: heute, jetzt: 9 * 60))
        #expect(Tagesplan.wannText(n[0], heute: heute, jetzt: 9 * 60) == "läuft · noch 30 Min")
        #expect(Tagesplan.wannText(n[1], heute: heute, jetzt: 9 * 60) == "heute 10:00")
        // 22:00 – nichts mehr heute → nächste Woche Uni (Lesen täglich morgen 21:00 kommt vorher)
        let spaet = Tagesplan.naechste(zustand: z, heute: heute, jetzt: 22 * 60, termine: quelle(z), anzahl: 1)
        #expect(spaet.first?.titel == "Lesen" && spaet.first?.tag == heute.plus(tage: 1))
        #expect(Tagesplan.wannText(spaet[0], heute: heute, jetzt: 22 * 60) == "morgen 21:00")
    }

    @Test func auslastungUndLuecke() {
        func b(_ s: Int, _ e: Int) -> Tagesplan.Block {
            Tagesplan.Block(id: "\(s)", art: .termin, titel: "x", tag: heute, start: s * 60, ende: e * 60, farbe: "#000000", unter: "")
        }
        let a = Tagesplan.auslastung([b(8, 12), b(11, 13), b(14, 20)])
        #expect(a.verplant == 11 * 60 && a.frei == 4 * 60 && a.laengsteLuecke == 2 * 60 && !a.eng)
        let voll = Tagesplan.auslastung([b(7, 19)])
        #expect(voll.eng && voll.frei == 180)
        #expect(Tagesplan.freiAb([b(8, 12), b(14, 20)], ab: 13 * 60) == 60 + 120)
    }

    @Test func hinweiseUeberschneidungUndKeinPlatz() {
        var z = zustand()
        z.eigeneTermine.append(EigenerTermin(titel: "Arzt", tag: heute, start: 10 * 60 + 30, ende: 11 * 60 + 30))
        // abends ist nur noch 30 Min frei: Termin 18–21:30, Lesen 21:00–21:20 überschneidet sich
        z.eigeneTermine.append(EigenerTermin(titel: "Kino", tag: heute, start: 18 * 60, ende: 21 * 60 + 30))
        let h = Tagesplan.hinweise(zustand: z, heute: heute, jetzt: 17 * 60 + 30, termine: quelle(z), tage: 1)
        #expect(h.contains { $0.art == .ueberschneidung && $0.text.contains("Kino") && $0.text.contains("Lesen") })
        #expect(!h.contains { $0.art == .ueberschneidung && $0.text.contains("Arzt") }) // vorbei
        // offen ohne Uhrzeit: Einkaufen 30 + Sport 45 = 75 Min; frei ab 17:30 = 30 Min (17:30–18:00) + 0 (bis 22 belegt? 21:30–22 = 30) = 60
        #expect(h.contains { $0.art == .keinPlatz && $0.text == "75 Min offen, frei sind noch 60 Min" })
    }

    @Test func eigenerTerminZaehltFuerZielUndHabit() {
        var z = zustand()
        var g = Ziel(titel: "Fit", farbe: "#15803D", symbol: "x", bereich: "x", faellig: heute.plus(tage: 90), angelegt: heute.plus(tage: -30))
        let s = Schritt(titel: "Training", art: .zeit, soll: 10)
        g.schritte = [s]
        z.ziele = [g]
        let sport = z.habits[1].id
        let t = EigenerTermin(titel: "Gym", tag: heute.plus(tage: -2), start: 18 * 60, ende: 19 * 60, zielID: g.id, schrittID: s.id, habitID: sport, wiederholung: .taeglich)
        z.terminSpeichern(t)
        #expect(z.termine.count == 1 && z.termine[0].serie == "kompass:\(t.id.uuidString)")
        let kopie = z
        z.termineAbgleichen(heute: heute) { d in Kalenderquelle.termine(am: d, zustand: kopie, heute: heute) }
        // zwei vergangene Tage + heute (zählt, sobald abgeglichen) → mindestens 2 h
        #expect(Fortschritt.stand(s, in: z, heute: heute).anteil >= 0.2)
        z.habitsAusTerminen(heute: heute, jetzt: 12 * 60)
        #expect(z.habits[1].voll(am: heute.plus(tage: -2)) && z.habits[1].voll(am: heute.plus(tage: -1)) && !z.habits[1].voll(am: heute))
        z.habitsAusTerminen(heute: heute, jetzt: 19 * 60)
        #expect(z.habits[1].voll(am: heute))
        z.terminLoeschen(t.id)
        #expect(z.termine.isEmpty && z.eigeneTermine.count == 1)
    }

    @Test func einplanenPerZiehen() {
        var z = zustand()
        let einkaufen = z.aufgaben[1].id
        z.aufgabeEinplanen(einkaufen, tag: heute, uhrzeit: 16 * 60)
        #expect(Tagesplan.bloecke(am: heute, zustand: z, termine: []).contains { $0.titel == "Einkaufen" && $0.start == 16 * 60 })
        z.aufgabeEinplanen(einkaufen, tag: nil, uhrzeit: 16 * 60)
        #expect(z.aufgabe(einkaufen)?.datum == nil && z.aufgabe(einkaufen)?.uhrzeit == nil)
        let sport = z.habits[1].id
        z.habitEinplanen(sport, tag: heute, uhrzeit: 7 * 60)
        #expect(z.habit(sport)?.zeit(am: heute) == 7 * 60 && z.habit(sport)?.zeit(am: heute.plus(tage: 1)) == nil)
        #expect(Tagesplan.bloecke(am: heute, zustand: z, termine: []).first { $0.titel == "Sport" }?.dauer == 45)
        // Speichern und Lesen behält Uhrzeiten
        let wieder = try? JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(z))
        #expect(wieder?.habit(sport)?.planZeiten[heute] == 7 * 60 && wieder?.eigeneTermine.count == 1)
    }
}

@Suite("Rückblick · Wochenbilanz")
struct WochenbilanzTests {
    @Test func quoteAusAufgabenUndHabits() {
        let heute = Tag(2027, 5, 5) // Mi
        var z = Zustand()
        z.aufgaben = [Aufgabe(titel: "a", datum: Tag(2027, 5, 3), erledigt: true), Aufgabe(titel: "b", datum: Tag(2027, 5, 4)),
                      Aufgabe(titel: "c", datum: Tag(2027, 5, 7))] // Freitag zählt noch nicht
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", menge: 20, einheit: .minuten, angelegt: Tag(2027, 5, 1))
        h.eintragen(20, am: Tag(2027, 5, 3)); h.eintragen(10, am: Tag(2027, 5, 4))
        z.habits = [h]
        z.eigeneTermine = [EigenerTermin(titel: "T", tag: Tag(2027, 5, 3), start: 9 * 60, ende: 12 * 60)]
        let w = Tagesplan.woche(zustand: z, montag: heute.montag, heute: heute) { Kalenderquelle.termine(am: $0, zustand: z, heute: heute) }
        // Aufgaben 1 von 2, Habits Mo 1 + Di 0,5 (Mi ohne Eintrag zählt nicht) = 1,5 von 2 → (1 + 1,5) / 4
        #expect(w.aufgabenGeplant == 2 && w.aufgabenErledigt == 1 && w.habitsGeplant == 2 && w.habitsErledigt == 1.5)
        #expect(abs(w.quote - 2.5 / 4) < 1e-9)
        #expect(w.termine == 1 && w.verplant[0] == 180 && w.geplantJeTag[4] == 0)
    }
}

@Suite("Tagesplan · Befunde aus dem Personen-Test")
struct TagesplanBefundTests {
    /// Befund Ahmet/Mia: zwei gleich benannte Termine überschneiden sich mit demselben Block → nur ein Hinweis (eindeutige ids).
    @Test func gleicheTitelGebenEinenHinweis() {
        let heute = Tag(2027, 5, 5)
        var z = Zustand()
        z.eigeneTermine = [EigenerTermin(titel: "Training", tag: heute, start: 600, ende: 660), EigenerTermin(titel: "Training", tag: heute, start: 610, ende: 670),
                           EigenerTermin(titel: "Call", tag: heute, start: 620, ende: 640)]
        let h = Tagesplan.hinweise(zustand: z, heute: heute, jetzt: 0, termine: { Kalenderquelle.termine(am: $0, zustand: z, heute: heute) }, tage: 1)
        #expect(Set(h.map(\.id)).count == h.count)
        #expect(h.filter { $0.art == .ueberschneidung }.count == 2) // Training+Training, Training+Call
    }
}

@Suite("Kalender · Herausziehen")
struct HerausziehenTests {
    @Test func habitMitFesterUhrzeitEinenTagOhneUhrzeit() {
        let heute = Tag(2027, 5, 5)
        var z = Zustand()
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", angelegt: heute.plus(tage: -5))
        h.uhrzeit = 21 * 60
        z.habits = [h]
        z.habitEinplanen(h.id, tag: heute, uhrzeit: nil)          // aus dem Kalender gezogen
        #expect(z.habit(h.id)?.zeit(am: heute) == nil && z.habit(h.id)?.zeit(am: heute.plus(tage: 1)) == 21 * 60)
        #expect(Tagesplan.ohneZeit(am: heute, zustand: z).habits.count == 1)
        z.habitEinplanen(h.id, tag: heute, uhrzeit: 8 * 60)      // wieder hinein
        #expect(z.habit(h.id)?.zeit(am: heute) == 8 * 60)
        let wieder = try? JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(z))
        #expect(wieder?.habit(h.id)?.zeit(am: heute) == 8 * 60)
        // Aufgabe: aus der Zeitleiste zurück nach „Ohne Uhrzeit“, dann in den Eingang
        z.aufgaben = [Aufgabe(titel: "a", datum: heute, uhrzeit: 10 * 60)]
        let a = z.aufgaben[0].id
        z.aufgabeEinplanen(a, tag: heute, uhrzeit: nil)
        #expect(z.aufgabe(a)?.uhrzeit == nil && z.aufgabe(a)?.datum == heute)
        z.aufgabeEinplanen(a, tag: nil, uhrzeit: nil)
        #expect(z.aufgabe(a)?.datum == nil)
    }
}
