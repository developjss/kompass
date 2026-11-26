import Foundation
import Testing
@testable import Kompass

// Der Lotse: Verstehen (Regeln), Werkzeuge, freie Zeit, Vollständigkeit des App-Wissens.

@Suite("Lotse · Verstehen")
struct VerstehenTests {
    let heute = Tag(2026, 11, 23) // Montag
    let z = DemoDaten.zustand(heute: Tag(2026, 11, 23), jetzt: Date(timeIntervalSince1970: 1_795_000_000))

    func name(_ frage: String) -> Werkzeug.Name? { Verstehen.erkennen(frage, zustand: z, heute: heute)?.name }

    @Test(arguments: [
        ("Was steht heute an?", Werkzeug.Name.heute), ("Was ist jetzt dran?", .heute),
        ("Was soll ich diese Woche zuerst machen?", .empfehlen), ("Worauf soll ich mich konzentrieren?", .empfehlen), ("Was würdest du mir raten?", .empfehlen),
        ("Was ist gerade wichtig?", .signale), ("Wo wird es eng?", .signale), ("Gibt es Engpässe diese Woche?", .signale),
        ("Wie sieht meine Woche aus?", .woche), ("Was steht nächste Woche an?", .woche), ("Welche Termine habe ich?", .woche),
        ("Wann habe ich diese Woche Zeit?", .freieZeit), ("Habe ich morgen Zeit?", .freieZeit),
        ("Wie stehen meine Ziele?", .ziele), ("Welches Ziel hinkt?", .ziele),
        ("Wie läuft der Führerschein?", .ziel), ("Zeig mir das Ziel Fit", .ziel),
        ("Warum steht der Führerschein bei 54 %?", .fortschrittErklaeren), ("Was bringt beim LAPL am meisten?", .fortschrittErklaeren),
        ("Wie laufen meine Habits?", .habits), ("Wie ist meine Serie beim Lesen?", .habits),
        ("Wie lief meine Woche?", .analyse), ("Wie viel Fokuszeit hatte ich letzte Woche?", .analyse),
        ("Wie fange ich an?", .hilfe), ("Wie wird der Fortschritt gerechnet?", .hilfe), ("Wo finde ich den Fokus-Timer?", .hilfe), ("Was kannst du?", .hilfe),
        ("Wie kann ich eine Erinnerung für einen Habit einstellen?", .hilfe),
        ("Was steht als Nächstes an?", .naechstes), ("Wie voll ist mein Tag?", .tagesplan), ("Ist morgen noch Platz für Sport?", .tagesplan),
        ("Trag morgen 15 Uhr Zahnarzt ein", .terminAnlegen), ("Neuer Termin: Fahrstunde Freitag 17:00 bis 18:30", .terminAnlegen),
        ("Erstelle Aufgabe: Flugschule anrufen morgen", .aufgabeAnlegen), ("Neue Aufgabe für Führerschein: Fragebogen Kapitel 5", .aufgabeAnlegen),
        ("Erinnere mich daran, Oma anzurufen", .aufgabeAnlegen),
    ])
    func erkennt(_ frage: String, _ erwartet: Werkzeug.Name) {
        #expect(name(frage) == erwartet, "\(frage)")
    }

    @Test func alleBeispieleTreffenIhrWerkzeug() {
        for w in Werkzeuge.alle {
            for b in w.beispiele { #expect(name(b) == w.name, "„\(b)“ sollte \(w.name) treffen, traf \(String(describing: name(b)))") }
        }
    }

    @Test func unverstaendlichesBleibtOffen() {
        #expect(name("blubb trallala") == nil)
        #expect(name("") == nil)
    }

    @Test func aufgabeMitDatumZielUndWichtig() {
        let a = Verstehen.erkennen("Erstelle wichtige Aufgabe für Führerschein: Fragebogen Kapitel 5 am Freitag", zustand: z, heute: heute)!
        #expect(a.name == .aufgabeAnlegen)
        #expect(a.parameter["titel"] == "Fragebogen Kapitel 5")
        #expect(a.parameter["datum"] == Tag(2026, 11, 27).text) // nächster Freitag
        #expect(a.parameter["wichtig"] == "ja")
        #expect(a.parameter["ziel"] == "Führerschein Klasse B")
    }

    @Test func terminAusText() {
        let a = Verstehen.erkennen("Trag morgen 15 Uhr Zahnarzt ein", zustand: z, heute: heute)!
        #expect(a.name == .terminAnlegen && a.parameter["titel"] == "Zahnarzt" && a.parameter["datum"] == Tag(2026, 11, 24).text && a.parameter["start"] == "15:00")
        let b = Verstehen.erkennen("Neuer Termin: Fahrstunde Freitag 17:00 bis 18:30", zustand: z, heute: heute)!
        #expect(b.parameter["titel"] == "Fahrstunde" && b.parameter["start"] == "17:00" && b.parameter["ende"] == "18:30" && b.parameter["datum"] == Tag(2026, 11, 27).text)
        #expect(Verstehen.uhrzeiten(aus: "steuer abgeben 3.1.") == [])
    }

    @Test func aufgabeOhneDatumUndDatumAlsZahl() {
        let a = Verstehen.erkennen("Erstelle Aufgabe: Paket abholen", zustand: z, heute: heute)!
        #expect(a.parameter["titel"] == "Paket abholen" && a.parameter["datum"] == nil)
        let b = Verstehen.erkennen("Lege Aufgabe an: Steuer abgeben 3.1.", zustand: z, heute: heute)!
        #expect(b.parameter["datum"] == Tag(2027, 1, 3).text) // 3.1. liegt vor heute im Jahr → nächstes Jahr
        #expect(b.parameter["titel"] == "Steuer abgeben")
    }

    @Test func zielFindenIstTolerant() {
        #expect(Werkzeuge.findeZiel("fuehrerschein", in: z)?.titel == "Führerschein Klasse B")
        #expect(Werkzeuge.findeZiel("Wie läuft das mit dem Millionär?", in: z)?.titel == "Millionär werden")
        #expect(Werkzeuge.findeZiel("Wetter", in: z) == nil)
    }
}

@Suite("Lotse · Werkzeuge und Lernen")
@MainActor
struct LotseWerkzeugTests {
    func speicher() -> Speicher {
        let s = Speicher(datei: nil)
        s.jetzt = { Date(timeIntervalSince1970: 1_795_000_000) } // 2026-11-23 vormittags (Europe/Berlin)
        s.zustand = DemoDaten.zustand(heute: s.heute, jetzt: s.jetzt())
        return s
    }

    @Test func aufgabeAnlegenLandetImNaechstenOffenenMeilenstein() async {
        let s = speicher()
        let vorher = s.zustand.aufgaben.count
        let a = await Lotse.fragen("Erstelle Aufgabe für Führerschein: Fragebogen Kapitel 5 morgen", speicher: s, modell: nil)
        #expect(s.zustand.aufgaben.count == vorher + 1)
        let neu = s.zustand.aufgaben.last!
        #expect(neu.titel == "Fragebogen Kapitel 5" && neu.datum == s.heute.plus(tage: 1))
        #expect(neu.zielID == s.zustand.ziele[0].id && neu.schrittID != nil)
        #expect(a.text.contains("Angelegt") && a.aktion == .aufgabe(neu.id))
        #expect(s.zustand.chat.count == 2 && s.zustand.lernen.lotse.genutzt["aufgabeAnlegen"] == 1)
    }

    @Test func erklaerenNenntBeitraegeUndNaechstenHebel() async {
        let s = speicher()
        let a = await Lotse.fragen("Warum steht der Führerschein bei 54 %?", speicher: s, modell: nil)
        #expect(a.werkzeug == .fortschrittErklaeren)
        #expect(a.text.contains("Punkte") && a.text.contains("Am meisten bringt"))
        let p = Fortschritt.ziel(s.zustand.ziele[0], in: s.zustand, heute: s.heute)
        #expect(a.text.contains(Zahl.prozent(p)))
    }

    @Test func unbeantwortetWirdGemerktUndRueckmeldungGezaehlt() async {
        let s = speicher()
        await Lotse.fragen("blubb trallala", speicher: s, modell: nil)
        #expect(s.zustand.lernen.lotse.unbeantwortet == ["blubb trallala"])
        let antwort = s.zustand.chat.last!
        Lotse.rueckmeldung(false, nachricht: antwort.id, speicher: s)
        #expect(s.zustand.lernen.lotse.schlecht == ["blubb trallala"])
        Lotse.rueckmeldung(true, nachricht: antwort.id, speicher: s)
        #expect(s.zustand.lernen.lotse.gut == 1 && s.zustand.chat.last?.rueckmeldung == true)
    }

    @Test func chatBleibtBegrenzt() async {
        let s = speicher()
        for i in 0..<110 { s.zustand.chat.append(ChatNachricht(rolle: .nutzer, text: "\(i)", zeit: s.jetzt())) }
        await Lotse.fragen("Was steht heute an?", speicher: s, modell: nil)
        #expect(s.zustand.chat.count <= 200)
    }
}

@Suite("Lotse · Freie Zeit")
struct ZeitfensterTests {
    @Test func lueckenZwischenTerminenUndAufgaben() {
        let d = Tag(2026, 11, 24)
        let termine = [Termin(quelle: .google, schluessel: "a", titel: "A", tag: d, start: 9 * 60, ende: 10 * 60),
                       Termin(quelle: .apple, schluessel: "b", titel: "B", tag: d, start: 9 * 60 + 30, ende: 11 * 60)] // überlappt A
        let aufgaben = [Aufgabe(titel: "x", datum: d, uhrzeit: 14 * 60, dauer: 90),
                        Aufgabe(titel: "fertig", datum: d, uhrzeit: 17 * 60, dauer: 60, erledigt: true)] // erledigt → frei
        let f = Zeitfenster.frei(termine: termine, aufgaben: aufgaben)
        #expect(f == [.init(start: 8 * 60, ende: 9 * 60), .init(start: 11 * 60, ende: 14 * 60), .init(start: 15 * 60 + 30, ende: 20 * 60)])
    }

    @Test func kurzeLueckenZaehlenNicht() {
        let d = Tag(2026, 11, 24)
        let t = [Termin(quelle: .google, schluessel: "a", titel: "A", tag: d, start: 8 * 60 + 20, ende: 19 * 60 + 40)]
        #expect(Zeitfenster.frei(termine: t, aufgaben: []).isEmpty)
        #expect(Zeitfenster.frei(termine: [], aufgaben: []) == [.init(start: 8 * 60, ende: 20 * 60)])
    }
}

@Suite("Lotse · App-Wissen vollständig")
@MainActor
struct AppWissenTests {
    @Test func jederTabIstBeschrieben() {
        for b in Bereich.allCases { #expect(!(AppWissen.bereiche[b] ?? "").isEmpty, "\(b)") }
    }

    @Test func rueckblickWissenNenntErkenntnisUndVorschlaege() {
        let t = AppWissen.bereiche[.rueckblick] ?? ""
        #expect(t.contains("Das nimmst du mit") && t.contains("Was zählt hier?") && t.contains("Übernehmen"))
    }

    @Test func hilfeZurErinnerungNenntDenEditor() {
        let a = Werkzeuge.hilfe("Wie kann ich eine Erinnerung für einen Habit einstellen?")
        #expect(a.text.contains("Erinnerung") && a.text.contains("Mitteilung"))
    }

    @Test func jedesFensterIstBeschrieben() {
        for p in AppWissen.blattPraefixe { #expect(!(AppWissen.fenster[p] ?? "").isEmpty, "Fenster „\(p)“ fehlt im App-Wissen") }
    }

    @Test func jedesWerkzeugHatBeschreibungUndBeispiele() {
        #expect(Set(Werkzeuge.alle.map(\.name)).count == Werkzeug.Name.allCases.count)
        for w in Werkzeuge.alle { #expect(!w.beschreibung.isEmpty && w.beispiele.count >= 1, "\(w.name)") }
    }

    @Test func jedeMeilensteinArtUndJedesInfoThemaImWissen() {
        let t = AppWissen.text()
        for a in SchrittArt.allCases { #expect(t.contains(a.erklaerung)) }
        for b in Bereich.allCases { #expect(t.contains(b.titel)) }
        #expect(InfoThema.allCases.count == 6)
    }
}
