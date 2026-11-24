import Foundation
import Testing
@testable import Kompass

// Anbindung an den Lotse-Server: Antworten lesen, Regeln zuerst (kostenlos), Kontingent-Fehler als Antwort.

@Suite("Lotse · Server-Anbindung")
struct ClaudeServerTests {
    @Test func werkzeugAntwortLesen() throws {
        let json = #"{"art":"werkzeuge","aufrufe":[{"id":"t1","name":"aufgabeAnlegen","parameter":{"titel":"Oma anrufen","datum":"2026-11-24"}}],"inhalt":[{"type":"tool_use","id":"t1","name":"aufgabeAnlegen","input":{"titel":"Oma anrufen"}}],"kontingent":{"frei":4,"limit":5,"pro":false}}"#
        let (a, k) = try ClaudeServer.lesen(Data(json.utf8), status: 200)
        guard case .werkzeuge(let w, let inhalt) = a else { Issue.record("kein Werkzeug"); return }
        #expect(w.first?.name == "aufgabeAnlegen" && w.first?.parameter["titel"] == "Oma anrufen" && w.first?.id == "t1")
        #expect(k == Kontingent(frei: 4, limit: 5, pro: false))
        // Inhalt geht unverändert zurück an den Server
        let zurueck = try JSONDecoder().decode(JSONWert.self, from: JSONEncoder().encode(inhalt))
        #expect(zurueck == inhalt)
    }

    @Test func textAntwortUndFehler() throws {
        let (a, _) = try ClaudeServer.lesen(Data(#"{"art":"text","text":"Fang mit dem **Führerschein** an."}"#.utf8), status: 200)
        guard case .text(let t) = a else { Issue.record("kein Text"); return }
        #expect(t.hasPrefix("Fang"))
        #expect(throws: LotseFehler.kontingentErschoepft(limit: 5, pro: false)) {
            try ClaudeServer.lesen(Data(#"{"fehler":"kontingent","limit":5,"pro":false}"#.utf8), status: 429)
        }
        #expect(throws: LotseFehler.server(503)) { try ClaudeServer.lesen(Data(#"{"fehler":"modell"}"#.utf8), status: 503) }
        #expect(throws: LotseFehler.antwort) { try ClaudeServer.lesen(Data(#"{"art":"werkzeuge","aufrufe":[]}"#.utf8), status: 200) }
    }

    @Test func antwortTextZerlegen() {
        let b = AntwortText.bloecke("**Etwa 1 Stunde.**\n\n- **Auto:** 95 km\n  - über die A8\n- Zug: 1 h\n\n1. Erst\n2) Dann\n---\n## Tipp\nZeile eins\nZeile zwei")
        #expect(b == [.absatz("**Etwa 1 Stunde.**"), .punkt("•", "**Auto:** 95 km", 0), .punkt("•", "über die A8", 1), .punkt("•", "Zug: 1 h", 0),
                      .punkt("1.", "Erst", 0), .punkt("2.", "Dann", 0), .trenner, .ueberschrift("Tipp"), .absatz("Zeile eins\nZeile zwei")])
        #expect(AntwortText.ohneZeichen("**fett** und normal") == "fett und normal")
    }

    @Test func kanalUndNutzerID() {
        #expect(Kanal.aktuell == .debug) // Tests laufen im Debug-Build
        let a = LotseKonfiguration.nutzerID
        #expect(a == LotseKonfiguration.nutzerID && UUID(uuidString: a) != nil)
    }
}

/// Ein Sprachmodell für Tests: spielt Antworten der Reihe nach ab und merkt sich die Anfragen.
final class ZaehlModell: Sprachmodell, @unchecked Sendable {
    var anfragen: [SprachmodellAnfrage] = []
    var antworten: [SprachmodellAntwort]
    var fehler: Error?
    var aufrufe: Int { anfragen.count }
    init(_ antworten: SprachmodellAntwort..., fehler: Error? = nil) { self.antworten = antworten; self.fehler = fehler }
    var name: String { "Test" }
    func antworte(auf anfrage: SprachmodellAnfrage) async throws -> SprachmodellAntwort {
        anfragen.append(anfrage)
        if let fehler, anfragen.count > antworten.count { throw fehler }
        return antworten[min(anfragen.count - 1, antworten.count - 1)]
    }
}

@Suite("Lotse · Claude mit Werkzeugschleife")
@MainActor
struct LotseStufenTests {
    func speicher() -> Speicher {
        let s = Speicher(datei: nil)
        s.jetzt = { Date(timeIntervalSince1970: 1_795_000_000) }
        s.zustand = DemoDaten.zustand(heute: s.heute, jetzt: s.jetzt())
        return s
    }

    @Test func mitServerAntwortetClaudeAuchAufRegelFragen() async {
        // Früher fing „Was steht heute an?“ eine Regel ab – jetzt antwortet Claude, mit Absätzen
        let m = ZaehlModell(.text("**Heute** ist ruhig.\n\n- 2 Termine"))
        let s = speicher()
        let a = await Lotse.fragen("Was steht heute an?", speicher: s, modell: m)
        #expect(m.aufrufe == 1 && a.text.hasPrefix("**Heute**"))
        // Claude bekommt Wissen, Stand mit Datum, alle Werkzeuge und die Frage – der Verlauf ohne die Frage selbst
        let anf = m.anfragen[0]
        #expect(anf.kurzstand.hasPrefix("Jetzt: ") && anf.kurzstand.contains("Ziele: ") && anf.wissen.contains("Rechenregeln"))
        #expect(anf.werkzeuge.count == Werkzeug.Name.allCases.count && anf.frage == "Was steht heute an?")
        #expect(!anf.verlauf.contains { $0.1 == "Was steht heute an?" })
    }

    @Test func werkzeugSchleifeLiefertErgebnisseZurueck() async {
        let inhalt = JSONWert.liste([.objekt(["type": .text("tool_use"), "id": .text("t1")])])
        let m = ZaehlModell(.werkzeuge([ModellAufruf(id: "t1", name: "ziele", parameter: [:]), ModellAufruf(id: "t2", name: "gibtsNicht", parameter: [:])], inhalt: inhalt),
                            .text("Zwei deiner Ziele sind **auf Kurs**."))
        let a = await Lotse.fragen("Wie stehen meine Ziele?", speicher: speicher(), modell: m)
        #expect(m.aufrufe == 2 && a.text.contains("auf Kurs") && a.werkzeug == .ziele)
        let schritt = m.anfragen[1].schritte.first
        #expect(schritt?.inhalt == inhalt && schritt?.ergebnisse.map(\.id) == ["t1", "t2"])
        #expect(schritt?.ergebnisse[0].text.contains("Führerschein") == true && schritt?.ergebnisse[1].text.contains("gibt es nicht") == true)
    }

    @Test func anlegenUeberClaudeUndKeinDoppeltesAnlegenBeiFehler() async {
        let s = speicher()
        let vorher = s.zustand.aufgaben.count
        let m = ZaehlModell(.werkzeuge([ModellAufruf(id: "t1", name: "aufgabeAnlegen", parameter: ["titel": "Oma anrufen"])], inhalt: .liste([])),
                            fehler: LotseFehler.server(503))
        let a = await Lotse.fragen("Erstelle Aufgabe Oma anrufen", speicher: s, modell: m)
        #expect(s.zustand.aufgaben.count == vorher + 1 && a.text.contains("Oma anrufen"))
    }

    @Test func kontingentErschoepftZeigtPro() async {
        let m = ZaehlModell(fehler: LotseFehler.kontingentErschoepft(limit: 5, pro: false))
        let a = await Lotse.fragen("blubb trallala", speicher: speicher(), modell: m)
        #expect(a.aktion == .pro && a.text.contains("5"))
    }

    @Test func ohneServerOderBeiFehlerAntwortenDieRegeln() async {
        let b = await Lotse.fragen("Was soll ich diese Woche zuerst machen?", speicher: speicher(), modell: nil)
        #expect(b.werkzeug == .empfehlen && b.text.contains("Fit: 75 kg & Halbmarathon")) // liegt hinterher → zuerst
        let m = ZaehlModell(fehler: LotseFehler.server(503))
        let a = await Lotse.fragen("Was steht heute an?", speicher: speicher(), modell: m)
        #expect(a.werkzeug == .heute && LotseStand.geteilt.letzterFehler != nil)
    }
}

@Suite("Assistent · Gedächtnis und Kalender")
@MainActor
struct AssistentGedaechtnisTests {
    func speicher() -> Speicher {
        let s = Speicher(datei: nil)
        s.jetzt = { Date(timeIntervalSince1970: 1_795_000_000) }
        s.zustand = DemoDaten.zustand(heute: s.heute, jetzt: s.jetzt())
        return s
    }

    @Test func merkenVergessenUndImStand() {
        let s = speicher()
        _ = Lotse.ausfuehren(WerkzeugAufruf(name: .merken, parameter: ["notiz": "Wohnt in Ulm"]), speicher: s)
        _ = Lotse.ausfuehren(WerkzeugAufruf(name: .merken, parameter: ["notiz": "wohnt in ulm"]), speicher: s) // kein Doppel
        _ = Lotse.ausfuehren(WerkzeugAufruf(name: .merken, parameter: ["notiz": "Trainiert lieber morgens"]), speicher: s)
        #expect(s.zustand.lernen.lotse.erinnerungen == ["wohnt in ulm", "Trainiert lieber morgens"])
        #expect(Lotse.kurzstand(s).contains("Trainiert lieber morgens"))
        let a = Lotse.ausfuehren(WerkzeugAufruf(name: .merken, parameter: ["vergessen": "Ulm"]), speicher: s)
        #expect(a.text.hasPrefix("Vergessen") && s.zustand.lernen.lotse.erinnerungen == ["Trainiert lieber morgens"])
        // offline: „Merk dir …“ trifft das Werkzeug
        #expect(Verstehen.erkennen("Merk dir: Ich esse vegetarisch.", zustand: s.zustand, heute: s.heute)?.parameter["notiz"] == "Ich esse vegetarisch.")
        #expect(Verstehen.erkennen("Vergiss, dass ich in Ulm wohne", zustand: s.zustand, heute: s.heute)?.parameter["vergessen"] == "in Ulm wohne")
    }

    @Test func werkzeugeSehenDieselbenTermineWieDieApp() {
        let s = speicher()
        s.externeTermine = [s.heute: [Termin(quelle: .apple, schluessel: "x", titel: "Aus Apple", tag: s.heute, start: 23 * 60, ende: 23 * 60 + 30)]]
        let a = Lotse.ausfuehren(WerkzeugAufruf(name: .woche), speicher: s)
        #expect(a.text.contains("Aus Apple"))
        #expect(Werkzeuge.quelle == nil) // danach zurückgesetzt
    }
}
