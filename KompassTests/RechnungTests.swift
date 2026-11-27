import Foundation
import Testing
@testable import Kompass

typealias Tag = Kompass.Tag

// Randfälle (übernommen aus dem archivierten Klick-Dummy-Test) und weitere Fälle aus rechenregeln.md.

private let berlin: Calendar = {
    var k = Calendar.kompass
    k.timeZone = TimeZone(identifier: "Europe/Berlin")!
    return k
}()

private func zeit(_ j: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0) -> Date {
    berlin.date(from: DateComponents(year: j, month: m, day: d, hour: h, minute: min))!
}

@Suite("Tag und Kalenderwoche")
struct TagTests {
    @Test func tagnummerHinUndZurueck() {
        for n in stride(from: -800_000, through: 800_000, by: 997) { #expect(Tag(nummer: n).nummer == n) }
        #expect(Tag(1970, 1, 1).nummer == 0)
        #expect(Tag(2026, 11, 23).wochentag == 1)
    }

    @Test func text() {
        #expect(Tag(text: "2028-02-29") == Tag(2028, 2, 29))
        #expect(Tag(text: "2027-02-29") == nil)
        #expect(Tag(2027, 3, 5).text == "2027-03-05")
    }

    @Test("KW nach ISO 8601", arguments: [(Tag(2026, 12, 31), 53), (Tag(2027, 1, 4), 1), (Tag(2028, 1, 1), 52)])
    func kalenderwoche(_ t: Tag, _ kw: Int) { #expect(t.kalenderwoche == kw) }

    @Test func sommerzeitfest() {
        // 28.03.2027 Umstellung auf Sommerzeit: trotzdem genau 1 Tag Abstand
        #expect(Tag(2027, 3, 27).tage(bis: Tag(2027, 3, 28)) == 1)
        #expect(Tag(zeit(2027, 3, 28, 0, 30), kalender: berlin) == Tag(2027, 3, 28))
    }
}

@Suite("Wiederholung")
struct WiederholungTests {
    @Test func monatlichAb31Januar() {
        var d = Tag(2028, 1, 31)
        var folge: [Tag] = []
        for _ in 0..<4 {
            d = WiederholungRechnung.naechstesDatum(nach: d, regel: .monatlich, ankerTag: 31)!
            folge.append(d)
        }
        #expect(folge == [Tag(2028, 2, 29), Tag(2028, 3, 31), Tag(2028, 4, 30), Tag(2028, 5, 31)])
    }

    @Test func werktagsAbFreitag() {
        #expect(WiederholungRechnung.naechstesDatum(nach: Tag(2027, 1, 1), regel: .werktags, ankerTag: nil) == Tag(2027, 1, 4))
    }

    @Test func woechentlichUeberZeitumstellung() {
        #expect(WiederholungRechnung.naechstesDatum(nach: Tag(2027, 3, 25), regel: .woechentlich, ankerTag: nil) == Tag(2027, 4, 1))
    }

    @Test func nurEineOffeneFolgeJeSerie() {
        var z = Zustand()
        let a = z.aufgabeAnlegen("Joggen", datum: Tag(2027, 5, 3), heute: Tag(2027, 5, 3))
        z.aufgaben[0].wiederholung = .taeglich
        z.erledigen(a.id, jetzt: zeit(2027, 5, 3, 9), kalender: berlin)
        #expect(z.aufgaben.count == 2)
        #expect(z.aufgaben[1].datum == Tag(2027, 5, 4))
        // erneut abhaken und wieder öffnen erzeugt keine zweite Folge
        z.umschalten(a.id, jetzt: zeit(2027, 5, 3, 10), kalender: berlin)
        z.umschalten(a.id, jetzt: zeit(2027, 5, 3, 11), kalender: berlin)
        #expect(z.aufgaben.count == 2)
    }

    @Test func serieBeenden() {
        var z = Zustand()
        let a = z.aufgabeAnlegen("Lesen", datum: Tag(2027, 5, 3), heute: Tag(2027, 5, 3))
        z.aufgaben[0].wiederholung = .taeglich
        z.loeschen(a.id, heute: Tag(2027, 5, 3))
        #expect(z.aufgaben.count == 1 && z.aufgaben[0].datum == Tag(2027, 5, 4)) // nur diesen löschen: Serie läuft weiter
        z.loeschen(z.aufgaben[0].id, serieBeenden: true, heute: Tag(2027, 5, 3))
        #expect(z.aufgaben.isEmpty)
    }
}

@Suite("Fristen")
struct FristTests {
    let heute = Tag(2027, 3, 28)

    @Test(arguments: [
        (Tag(2027, 3, 28), "heute fällig"), (Tag(2027, 3, 29), "morgen fällig"), (Tag(2027, 3, 27), "seit gestern überfällig"),
        (Tag(2027, 4, 28), "noch 1 Monat"), (Tag(2027, 4, 27), "noch 30 Tage"), (Tag(2029, 6, 28), "noch 2 Jahre 3 Mon."),
        (Tag(2027, 3, 20), "seit 8 Tagen überfällig"),
    ])
    func bisText(_ d: Tag, _ erwartet: String) { #expect(Kurs.bisText(d, heute: heute) == erwartet) }
}

@Suite("Fokus-Timer")
struct FokusTests {
    @Test func nachtschichtUeberZeitumstellung() {
        // 30.10.2027 23:00 – 31.10.2027 01:30 (Nacht der Zeitumstellung): 60 + 90 Minuten
        let teile = FokusRechnung.anMitternachtTeilen(zeit(2027, 10, 30, 23), zeit(2027, 10, 31, 1, 30), kalender: berlin)
        #expect(teile.map(\.0) == [Tag(2027, 10, 30), Tag(2027, 10, 31)])
        #expect(teile.map { $0.1 / 60 } == [60, 90])
    }

    @Test func hoechstensVierStunden() {
        let b = FokusRechnung.buchen([.init(start: zeit(2027, 5, 3, 8), ende: zeit(2027, 5, 3, 14))], kalender: berlin)
        #expect(b.gesamt == 4 * 3600)
        #expect(b.gekappt)
        #expect(b.proTag[Tag(2027, 5, 3)] == TimeInterval(4 * 3600))
    }

    @Test func abschnitteMitPause() {
        var z = Zustand()
        let a = z.aufgabeAnlegen("Lernen", datum: Tag(2027, 5, 3), heute: Tag(2027, 5, 3))
        z.timerStarten(a.id, jetzt: zeit(2027, 5, 3, 9), kalender: berlin)
        z.timerPausieren(jetzt: zeit(2027, 5, 3, 9, 25))
        z.timerStarten(a.id, jetzt: zeit(2027, 5, 3, 10), kalender: berlin)
        let b = z.timerStoppen(jetzt: zeit(2027, 5, 3, 10, 20), kalender: berlin)
        #expect(b?.gesamt == TimeInterval(45 * 60))
        #expect(z.aufgaben[0].fokusSekunden == 45 * 60)
        #expect(z.sitzungen.count == 1 && z.timer == nil)
    }

    @Test func unter15SekundenWirdNichtGebucht() {
        var z = Zustand()
        let a = z.aufgabeAnlegen("Kurz", datum: Tag(2027, 5, 3), heute: Tag(2027, 5, 3))
        z.timerStarten(a.id, jetzt: zeit(2027, 5, 3, 9), kalender: berlin)
        z.timerStoppen(jetzt: zeit(2027, 5, 3, 9).addingTimeInterval(10), kalender: berlin)
        #expect(z.sitzungen.isEmpty)
    }
}

@Suite("Fortschritt")
struct FortschrittTests {
    let heute = Tag(2027, 5, 3)

    func zahlZiel(_ s: Double, _ c: Double, _ t: Double) -> Double {
        var g = Ziel(titel: "x", farbe: "#000000", symbol: "x", bereich: "", faellig: heute, angelegt: heute)
        g.schritte = [Schritt(titel: "Zahl", art: .zahl, soll: t, start: s, aktuell: c)]
        return Fortschritt.ziel(g, in: Zustand(), heute: heute)
    }

    @Test func zahlRandfaelle() {
        #expect(zahlZiel(-12000, -3000, 0) == 0.75) // Schulden abbauen
        #expect(zahlZiel(86, 90, 75) == 0)          // schlechter als Start
        #expect(zahlZiel(0, 120_000, 80000) == 1)   // übertroffen
        #expect(zahlZiel(5, 5, 5) == 1)             // Start = Ziel, erreicht
        #expect(zahlZiel(5, 4, 5) == 0)             // Start = Ziel, nicht erreicht
    }

    @Test func ohneSchritte() {
        let g = Ziel(titel: "x", farbe: "#000000", symbol: "x", bereich: "", faellig: heute, angelegt: heute)
        #expect(Fortschritt.ziel(g, in: Zustand(), heute: heute) == 0)
    }

    @Test func neunzigProzentRegelUndGewichte() {
        var z = Zustand()
        var g = Ziel(titel: "Führerschein", farbe: "#000000", symbol: "x", bereich: "", faellig: heute.plus(tage: 100), angelegt: heute)
        g.schritte = [Schritt(titel: "Theorie", gewicht: 1), Schritt(titel: "Fahrstunden", art: .zahl, gewicht: 3, soll: 30, start: 0, aktuell: 15)]
        z.ziele = [g]
        let a = z.aufgabeAnlegen("Bogen 1", datum: heute, zielID: g.id, heute: heute)
        #expect(a.schrittID == g.schritte[0].id) // fällt in den nächsten offenen Schritt
        z.erledigen(a.id, jetzt: zeit(2027, 5, 3, 9), kalender: berlin)
        let theorie = Fortschritt.stand(z.ziele[0].schritte[0], in: z, heute: heute)
        #expect(theorie.anteil == 0.9)
        #expect(theorie.hinweis != nil)
        // (1 × 0,9 + 3 × 0,5) ÷ 4 = 0,6
        #expect(abs(Fortschritt.ziel(z.ziele[0], in: z, heute: heute) - 0.6) < 1e-12)
        z.schrittUmschalten(ziel: g.id, schritt: g.schritte[0].id, heute: heute)
        #expect(abs(Fortschritt.ziel(z.ziele[0], in: z, heute: heute) - 0.625) < 1e-12)
    }

    @Test func ungueltigeWerte() {
        let z = Zustand()
        #expect(Fortschritt.stand(Schritt(titel: "t", art: .zeit, soll: 0), in: z, heute: heute).anteil == 0)
        #expect(Fortschritt.stand(Schritt(titel: "t", art: .habit, soll: 10), in: z, heute: heute).anteil == 0)
        #expect(Fortschritt.gewicht(Schritt(titel: "t", gewicht: 7)) == 1)
    }

    @Test func wiederkehrendeZaehlenNichtInErledigteDurchAlle() {
        var z = Zustand()
        var g = Ziel(titel: "x", farbe: "#000000", symbol: "x", bereich: "", faellig: heute.plus(tage: 9), angelegt: heute)
        g.schritte = [Schritt(titel: "s")]
        z.ziele = [g]
        let a = z.aufgabeAnlegen("täglich", datum: heute, zielID: g.id, heute: heute)
        z.aufgaben[0].wiederholung = .taeglich
        z.erledigen(a.id, jetzt: zeit(2027, 5, 3, 9), kalender: berlin)
        #expect(Fortschritt.stand(z.ziele[0].schritte[0], in: z, heute: heute).anteil == 0)
    }
}

@Suite("Auf Kurs und Prognose")
struct KursTests {
    let a = Tag(2027, 1, 1)

    @Test(arguments: [(0.16, Kurs.Lage.voraus), (0.10, .imPlan), (0.06, .imPlan), (0.01, .imPlan), (0.0, .hinterher)])
    func lage(_ p: Double, _ erwartet: Kurs.Lage) {
        // 10 von 100 Tagen verstrichen → erwartet 10 %
        let r = Kurs.aufKurs(fortschritt: p, angelegt: a, faellig: a.plus(tage: 100), erreicht: false, heute: a.plus(tage: 10))
        #expect(r.erwartet == 0.1)
        #expect(r.lage == erwartet)
    }

    @Test func ueberfaelligUndErreicht() {
        #expect(Kurs.aufKurs(fortschritt: 0.5, angelegt: a, faellig: a.plus(tage: 10), erreicht: false, heute: a.plus(tage: 11)).lage == .ueberfaellig)
        #expect(Kurs.aufKurs(fortschritt: 0.5, angelegt: a, faellig: a.plus(tage: 10), erreicht: true, heute: a.plus(tage: 11)).lage == .erreicht)
    }

    @Test func prognose() {
        let heute = Tag(2027, 3, 1)
        // Bezug: letzter Stand vor ≥ 28 Tagen (hier vor 32 Tagen 0 %), heute 50 % → Tempo 1/64 je Tag → noch 32 Tage
        let v = [VerlaufPunkt(tag: heute.plus(tage: -40), wert: 0), VerlaufPunkt(tag: heute.plus(tage: -32), wert: 0), VerlaufPunkt(tag: heute.plus(tage: -10), wert: 0.3)]
        #expect(Kurs.prognose(verlauf: v, fortschritt: 0.5, heute: heute) == .datum(heute.plus(tage: 32), restTage: 32, tempoProTag: 0.5 / 32))
        #expect(Kurs.prognose(verlauf: [VerlaufPunkt(tag: heute.plus(tage: -3), wert: 0), VerlaufPunkt(tag: heute, wert: 0.1)], fortschritt: 0.1, heute: heute) == .keine)
        #expect(Kurs.prognose(verlauf: v, fortschritt: 0, heute: heute) == .keinFortschritt(tage: 32))
        #expect(Kurs.prognose(verlauf: v, fortschritt: 1, heute: heute) == .keine)
    }

    @Test func verlaufEinWertProTag() {
        var l: [VerlaufPunkt] = []
        l = Kurs.verlaufFortschreiben(l, wert: 0.1, heute: a)
        l = Kurs.verlaufFortschreiben(l, wert: 0.2, heute: a)
        l = Kurs.verlaufFortschreiben(l, wert: 0.2, heute: a.plus(tage: 1))
        #expect(l == [VerlaufPunkt(tag: a, wert: 0.2)])
    }
}

@Suite("Habits")
struct HabitTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    func habit(_ tage: Set<Int>, _ erledigt: [Int], angelegt: Int = -60) -> Habit {
        Habit(titel: "h", farbe: "#000000", symbol: "x", rhythmus: .aus(tagen: tage), eintraege: Dictionary(uniqueKeysWithValues: erledigt.map { (heute.plus(tage: $0), 1.0) }), angelegt: heute.plus(tage: angelegt))
    }

    @Test func serieHeuteZaehltErstWennAbgehakt() {
        let alle: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        #expect(HabitRechnung.serie(habit(alle, [-1, -2, -3]), heute: heute) == 3)
        #expect(HabitRechnung.serie(habit(alle, [0, -1, -2, -3]), heute: heute) == 4)
        #expect(HabitRechnung.serie(habit(alle, [0, -2, -3]), heute: heute) == 1)
    }

    @Test func serieUeberspringtNichtGeplanteTage() {
        // Mo/Mi/Fr: Mi (heute, offen), Mo −2, Fr −5, Mi −7 erledigt
        #expect(HabitRechnung.serie(habit([1, 3, 5], [-2, -5, -7]), heute: heute) == 3)
    }

    @Test func besteSerieUndQuote() {
        let h = habit([1, 2, 3, 4, 5, 6, 7], [-10, -9, -8, -7, -5, -1], angelegt: -10)
        #expect(HabitRechnung.besteSerie(h, heute: heute) == 4)
        // 10 geplante Tage seit Anlage (heute offen zählt nicht), 6 erledigt
        #expect(HabitRechnung.quote(h, heute: heute) == 0.6)
    }
}

@Suite("Lernen")
struct LernTests {
    @Test func zeitfaktor() {
        #expect(LernRechnung.zeitfaktor([]) == 1)
        #expect(abs(LernRechnung.zeitfaktor([1.2, 1.35]) - (2.55 + 3) / 5) < 1e-12)
    }

    @Test func uebernahme() {
        #expect(LernRechnung.uebernahmeQuote(gezeigt: 0, uebernommen: 0) == 0.5)
        #expect(LernRechnung.vorausgewaehlt(gezeigt: 3, uebernommen: 1))
        #expect(!LernRechnung.vorausgewaehlt(gezeigt: 8, uebernommen: 1))
    }
}

@Suite("Demo-Daten")
struct DemoTests {
    @Test func gleicheDemoBeiGleichemStart() {
        let t = Tag(2026, 11, 23), j = zeit(2026, 11, 23, 12)
        let a = DemoDaten.zustand(heute: t, jetzt: j), b = DemoDaten.zustand(heute: t, jetzt: j)
        #expect(a.sitzungen.map(\.sekunden) == b.sitzungen.map(\.sekunden))
        #expect(a.habits.map(\.eintraege) == b.habits.map(\.eintraege))
    }

    @Test func alleZahlenImGueltigenBereich() throws {
        let t = Tag(2026, 11, 23)
        let z = DemoDaten.zustand(heute: t, jetzt: zeit(2026, 11, 23, 12))
        for g in z.ziele {
            let p = Fortschritt.ziel(g, in: z, heute: t)
            #expect((0...1).contains(p), "\(g.titel)")
            for s in g.schritte { #expect((0...1).contains(Fortschritt.stand(s, in: z, heute: t).anteil)) }
        }
        // Speichern und Laden ergibt denselben Zustand
        let wieder = try JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(z))
        #expect(wieder.ziele == z.ziele && wieder.habits == z.habits && wieder.aufgaben.count == z.aufgaben.count)
    }
}


// MARK: - Rechnung v2: Meilensteine, Termine, Habit-Wochen, Zwischenstände, Lernen

@Suite("Rechnung v2")
struct RechnungV2Tests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    func ziel(_ schritte: [Schritt]) -> Ziel {
        var g = Ziel(titel: "z", farbe: "#000000", symbol: "x", bereich: "", faellig: heute.plus(tage: 100), angelegt: heute.plus(tage: -100))
        g.schritte = schritte
        return g
    }

    @Test func termineZaehlenInZahlUndZeit() {
        var z = Zustand()
        let zahl = Schritt(titel: "Fahrstunden", art: .zahl, soll: 30, start: 0, aktuell: 6)
        let zeit = Schritt(titel: "Fliegen", art: .zeit, soll: 10)
        let g = ziel([zahl, zeit])
        z.ziele = [g]
        // Fahrstunde jeden Dienstag 90 min, Flug jeden Samstag 120 min
        let quelle: (Tag) -> [Termin] = { d in
            var out: [Termin] = []
            if d.wochentag == 2 { out.append(Termin(quelle: .google, schluessel: "fahr", titel: "Fahrstunde", tag: d, start: 960, ende: 1050)) }
            if d.wochentag == 6 { out.append(Termin(quelle: .google, schluessel: "flug", titel: "Flug", tag: d, start: 660, ende: 780)) }
            return out
        }
        z.terminVerknuepfen(serie: "google:fahr", titel: "Fahrstunde", ziel: g.id, schritt: zahl.id, seit: heute.plus(tage: -21))
        z.terminVerknuepfen(serie: "google:flug", titel: "Flug", ziel: g.id, schritt: zeit.id, seit: heute.plus(tage: -21))
        z.termineAbgleichen(heute: heute, quelle: quelle)
        z.termineAbgleichen(heute: heute, quelle: quelle) // zweimal = gleich (keine Doppelten)
        // Dienstage seit 14.04.: 20.04., 27.04., 04.05. → 3 Termine; Samstage: 17.04., 24.04., 01.05. → 3 × 2 h
        #expect(Fortschritt.ist(von: zahl, in: z, heute: heute) == 9)
        #expect(Fortschritt.stand(zahl, in: z, heute: heute).anteil == 0.3)
        #expect(Fortschritt.stunden(von: zeit, in: z, heute: heute) == 6)
        // Einsatz des Ziels: 3 × 1,5 h + 3 × 2 h
        #expect(Fortschritt.zeit(ziel: g.id, in: z) == 10.5 * 3600)
        // zukünftige Termine zählen nicht
        z.termineAbgleichen(heute: heute.plus(tage: 6), quelle: quelle) // bis Di 11.05.
        #expect(Fortschritt.ist(von: zahl, in: z, heute: heute.plus(tage: 6)) == 10)
        // Lösen: zählt nicht mehr
        z.terminLoesen(z.termine[0].id)
        #expect(Fortschritt.ist(von: zahl, in: z, heute: heute) == 6)
    }

    @Test func habitWochen() {
        // Mo/Mi/Fr geplant; seit Mo 12.04.: Woche 1 komplett, Woche 2 Fr fehlt, Woche 3 komplett, Woche 4 (laufend) Mo erledigt, Mi offen
        var h = Habit(titel: "Sport", farbe: "#000000", symbol: "x", wochentage: [1, 3, 5], angelegt: Tag(2027, 4, 1))
        let w1 = Tag(2027, 4, 12)
        for o in [0, 2, 4, 7, 9, 14, 16, 18, 21] { h.eintragen(1, am: w1.plus(tage: o)) }
        #expect(HabitRechnung.erfuellteWochen(h, seit: w1, heute: heute) == 2)
        h.eintragen(1, am: heute)
        #expect(HabitRechnung.erfuellteWochen(h, seit: w1, heute: heute) == 2) // Fr fehlt noch
        h.eintragen(1, am: heute.plus(tage: 2))
        #expect(HabitRechnung.erfuellteWochen(h, seit: w1, heute: heute.plus(tage: 2)) == 3)
        // Start mitten in der Woche: nur geplante Tage ab „seit“ zählen (Do 15.04. → Fr 16.04. reicht für Woche 1)
        #expect(HabitRechnung.erfuellteWochen(h, seit: Tag(2027, 4, 15), heute: heute) == 2)
    }

    @Test func gemischtesZiel() {
        // Fit: Gewicht 86 → 75 (jetzt 81, ×2) · Sport 8 Wochen (2 erfüllt) · 10 km (offen) · Halbmarathon (×2, offen)
        var z = Zustand()
        var h = Habit(titel: "Sport", farbe: "#000000", symbol: "x", wochentage: [1, 3, 5], angelegt: Tag(2027, 4, 1))
        let w1 = Tag(2027, 4, 12)
        for o in [0, 2, 4, 14, 16, 18] { h.eintragen(1, am: w1.plus(tage: o)) }
        z.habits = [h]
        let g = ziel([
            Schritt(titel: "Gewicht", art: .zahl, gewicht: 2, soll: 75, start: 86, aktuell: 81),
            Schritt(titel: "Sport", art: .habit, seit: w1, soll: 8, habitID: h.id, habitModus: .wochen),
            Schritt(titel: "10 km"),
            Schritt(titel: "Halbmarathon", gewicht: 2),
        ])
        z.ziele = [g]
        // (2 × 5/11 + 1 × 2/8 + 0 + 0) ÷ 6
        let erwartet = (2.0 * 5 / 11 + 2.0 / 8) / 6
        #expect(abs(Fortschritt.ziel(g, in: z, heute: heute) - erwartet) < 1e-12)
        // Beiträge ergeben zusammen den Fortschritt
        let summe = g.schritte.reduce(0) { $0 + Fortschritt.beitrag($1, in: g, z: z, heute: heute) }
        #expect(abs(summe - erwartet) < 1e-12)
    }

    @Test func zwischenstaende() {
        let z = Zustand()
        let auf = Schritt(titel: "Vermögen", art: .zahl, soll: 1_000_000, start: 0, aktuell: 118_500, schwellen: [10_000, 100_000, 500_000])
        #expect(Fortschritt.erreichteSchwellen(auf, in: z, heute: heute) == [10_000, 100_000])
        let ab = Schritt(titel: "Gewicht", art: .zahl, soll: 75, start: 86, aktuell: 81, schwellen: [84, 80, 78])
        #expect(Fortschritt.erreichteSchwellen(ab, in: z, heute: heute) == [84])
    }

    @Test func lernenAusZeitMeilenstein() {
        var z = Zustand()
        let s = Schritt(titel: "Theorie", art: .zeit, soll: 20)
        let g = ziel([s])
        z.ziele = [g]
        z.sitzungen = [FokusSitzung(schrittID: s.id, tag: heute, sekunden: 26 * 3600)]
        z.schrittUmschalten(ziel: g.id, schritt: s.id, heute: heute)
        #expect(z.lernen.zeitVerhaeltnisse == [1.3])
        // Prozent bleibt deterministisch (abgehakt = 100 %), Lernen ändert nur Vorschläge
        #expect(Fortschritt.ziel(z.ziele[0], in: z, heute: heute) == 1)
        #expect(LernRechnung.vorschlagStunden(20, verhaeltnisse: z.lernen.zeitVerhaeltnisse) == 22) // 20 × (1,3 + 3) ÷ 4 = 21,5 → 22
    }

    @Test func vorschlagHabit() {
        var h = Habit(titel: "Sport", farbe: "#000000", symbol: "x", wochentage: [1, 3, 5], angelegt: heute.plus(tage: -100))
        // keine Erfahrung (nichts erledigt): Anteil (0 + 1) ÷ 10 → 10 % der verbleibenden Wochen
        #expect(LernRechnung.vorschlagWochen(h, heute: heute, bis: heute.plus(tage: 70)) == 1)
        // alle 8 letzten Wochen erfüllt: (8 + 1) ÷ 10 = 90 % von 10 Wochen = 9
        var d = heute.montag.plus(tage: -56)
        while d < heute.montag { if HabitRechnung.geplant(h, am: d) { h.eintragen(1, am: d) }; d = d.plus(tage: 1) }
        #expect(LernRechnung.vorschlagWochen(h, heute: heute, bis: heute.plus(tage: 70)) == 9)
    }

    @Test func verknuepfenUndLoesen() {
        var z = Zustand()
        let h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", wochentage: [1, 2, 3, 4, 5, 6, 7], angelegt: heute)
        z.habits = [h]
        let g = ziel([])
        z.ziele = [g]
        z.habitVerknuepfen(h.id, ziel: g.id, alsMeilenstein: .anzahl, soll: 10, heute: heute)
        #expect(z.ziele[0].schritte.count == 1 && z.habits[0].zielID == g.id)
        z.habitLoesen(h.id, ziel: g.id)
        #expect(z.ziele[0].schritte.isEmpty && z.habits[0].zielID == nil)

        let a = z.aufgabeAnlegen("Buch kaufen", datum: nil, heute: heute)
        z.schrittSpeichern(Schritt(titel: "Erstes Buch"), ziel: g.id)
        z.aufgabeZuordnen(a.id, ziel: g.id, heute: heute)
        #expect(z.aufgaben[0].schrittID == z.ziele[0].schritte[0].id) // fällt in den nächsten offenen Meilenstein
        z.zielLoeschen(g.id)
        #expect(z.ziele.isEmpty && z.aufgaben[0].zielID == nil && z.aufgaben[0].schrittID == nil)
    }

    @Test func zahlEintragenEinWertProTag() {
        var z = Zustand()
        let s = Schritt(titel: "Gewicht", art: .zahl, soll: 75, start: 86, aktuell: 86)
        let g = ziel([s])
        z.ziele = [g]
        z.zahlEintragen(84, ziel: g.id, schritt: s.id, heute: heute)
        z.zahlEintragen(83.5, ziel: g.id, schritt: s.id, heute: heute)
        #expect(z.ziele[0].schritte[0].verlauf == [VerlaufPunkt(tag: heute, wert: 83.5)])
        #expect(abs(Fortschritt.ziel(z.ziele[0], in: z, heute: heute) - 2.5 / 11) < 1e-12)
    }

    @Test func alteDatenLesen() throws {
        // Version 1: Ziel mit „zahl“, ohne „termine“ – darf nicht zum Lesefehler führen
        let alt = """
        {"version":1,"ziele":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","titel":"Alt","farbe":"#000000","symbol":"x","bereich":"",
        "faellig":"2027-12-31","warum":"","status":"aktiv","angelegt":"2027-01-01","zahl":{"start":0,"aktuell":5,"ziel":10,"einheit":"","verlauf":[]},
        "schritte":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FE","titel":"S","art":"aufgaben","gewicht":1,"geschafft":true}]}],
        "habits":[],"aufgaben":[],"sitzungen":[],"verlauf":[],"lernen":{"zeitVerhaeltnisse":[],"vorschlaege":{}},
        "einstellungen":{"nurEineAufgabe":false,"weitereAusblenden":false,"googleBeispiel":false,"appleBeispiel":false},"reflexionen":{}}
        """
        let z = try JSONDecoder.kompass.decode(Zustand.self, from: Data(alt.utf8))
        #expect(z.version == 1 && z.ziele.count == 1 && z.termine.isEmpty)
        #expect(z.ziele[0].schritte[0].modus == .anzahl)
    }
}
