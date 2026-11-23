import Foundation
import Testing
@testable import Kompass

// Anbindung an den Lotse-Server: Antworten lesen, Regeln zuerst (kostenlos), Kontingent-Fehler als Antwort.

@Suite("Lotse · Server-Anbindung")
struct ClaudeServerTests {
    @Test func werkzeugAntwortLesen() throws {
        let json = #"{"art":"werkzeug","name":"aufgabeAnlegen","parameter":{"titel":"Oma anrufen","datum":"2026-11-24"},"kontingent":{"frei":4,"limit":5,"pro":false}}"#
        let (a, k) = try ClaudeServer.lesen(Data(json.utf8), status: 200)
        guard case .werkzeug(let w, _) = a else { Issue.record("kein Werkzeug"); return }
        #expect(w.name == .aufgabeAnlegen && w.parameter["titel"] == "Oma anrufen")
        #expect(k == Kontingent(frei: 4, limit: 5, pro: false))
    }

    @Test func textAntwortUndFehler() throws {
        let (a, _) = try ClaudeServer.lesen(Data(#"{"art":"text","text":"Fang mit dem Führerschein an."}"#.utf8), status: 200)
        guard case .text(let t) = a else { Issue.record("kein Text"); return }
        #expect(t.hasPrefix("Fang"))
        #expect(throws: LotseFehler.kontingentErschoepft(limit: 5, pro: false)) {
            try ClaudeServer.lesen(Data(#"{"fehler":"kontingent","limit":5,"pro":false}"#.utf8), status: 429)
        }
        #expect(throws: LotseFehler.server(503)) { try ClaudeServer.lesen(Data(#"{"fehler":"modell"}"#.utf8), status: 503) }
        #expect(throws: LotseFehler.antwort) { try ClaudeServer.lesen(Data(#"{"art":"werkzeug","name":"gibtEsNicht"}"#.utf8), status: 200) }
    }

    @Test func kanalUndNutzerID() {
        #expect(Kanal.aktuell == .debug) // Tests laufen im Debug-Build
        let a = LotseKonfiguration.nutzerID
        #expect(a == LotseKonfiguration.nutzerID && UUID(uuidString: a) != nil)
    }
}

/// Ein Sprachmodell für Tests: zählt Aufrufe und antwortet fest.
final class ZaehlModell: Sprachmodell, @unchecked Sendable {
    var aufrufe = 0
    var antwort: SprachmodellAntwort
    var fehler: Error?
    init(antwort: SprachmodellAntwort, fehler: Error? = nil) { self.antwort = antwort; self.fehler = fehler }
    var name: String { "Test" }
    func antworte(auf anfrage: SprachmodellAnfrage) async throws -> SprachmodellAntwort {
        aufrufe += 1
        if let fehler { throw fehler }
        return antwort
    }
}

@Suite("Lotse · Stufen")
@MainActor
struct LotseStufenTests {
    func speicher() -> Speicher {
        let s = Speicher(datei: nil)
        s.jetzt = { Date(timeIntervalSince1970: 1_795_000_000) }
        s.zustand = DemoDaten.zustand(heute: s.heute, jetzt: s.jetzt())
        return s
    }

    @Test func regelTrefferFragtDenServerNicht() async {
        let m = ZaehlModell(antwort: .text("sollte nicht kommen"))
        let a = await Lotse.fragen("Was steht heute an?", speicher: speicher(), modell: m)
        #expect(m.aufrufe == 0 && a.werkzeug == .heute)
    }

    @Test func freieFormulierungGehtAnDenServerUndWerkzeugWirdAusgefuehrt() async {
        let m = ZaehlModell(antwort: .werkzeug(WerkzeugAufruf(name: .ziele), einleitung: "Schauen wir auf deine Ziele."))
        let a = await Lotse.fragen("blubb trallala", speicher: speicher(), modell: m)
        #expect(a.text.hasPrefix("Schauen wir auf deine Ziele."))
        #expect(m.aufrufe == 1 && a.werkzeug == .ziele && !a.unbeantwortet)
    }

    @Test func kontingentErschoepftZeigtPro() async {
        let m = ZaehlModell(antwort: .text(""), fehler: LotseFehler.kontingentErschoepft(limit: 5, pro: false))
        let a = await Lotse.fragen("blubb trallala", speicher: speicher(), modell: m)
        #expect(a.aktion == .pro && a.text.contains("5"))
    }

    @Test func beratungsfrageGehtAnDenServerUndFaelltLokalZurueck() async {
        let m = ZaehlModell(antwort: .text("Fang mit Fitness an."))
        let a = await Lotse.fragen("Was soll ich diese Woche zuerst machen?", speicher: speicher(), modell: m)
        #expect(m.aufrufe == 1 && a.text == "Fang mit Fitness an.")
        let b = await Lotse.fragen("Was soll ich diese Woche zuerst machen?", speicher: speicher(), modell: nil)
        #expect(b.werkzeug == .empfehlen && b.text.contains("Fit: 75 kg & Halbmarathon")) // liegt hinterher → zuerst
    }

    @Test func serverFehlerFaelltAufRegelnZurueck() async {
        let m = ZaehlModell(antwort: .text(""), fehler: LotseFehler.server(503))
        let a = await Lotse.fragen("blubb trallala", speicher: speicher(), modell: m)
        #expect(a.unbeantwortet && LotseStand.geteilt.letzterFehler != nil)
    }
}
