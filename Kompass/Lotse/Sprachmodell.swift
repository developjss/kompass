import Foundation

/// Steckdose für ein Sprachmodell. Es bekommt das App-Wissen, die Werkzeuge und den Verlauf und antwortet
/// entweder mit einem Werkzeugaufruf (dann rechnet die App) oder mit Text (Erklärung, Gespräch, Rückfrage).
/// Es rechnet nie selbst und ändert nie Daten – das geht nur über Werkzeuge.
///
/// [OFFEN] Welcher Anbieter: Claude-API über einen eigenen Server (Schlüssel nie in der App), Apples On-Device-Modell
/// (nur auf Geräten mit Apple Intelligence) oder beides. Entscheidung des Gründers, Aufgabe `l-anbieter`.
protocol Sprachmodell: Sendable {
    var name: String { get }
    func antworte(auf anfrage: SprachmodellAnfrage) async throws -> SprachmodellAntwort
}

struct SprachmodellAnfrage: Sendable {
    /// `AppWissen.text()` + Zustand in Kurzform
    var wissen: String
    var werkzeuge: [Werkzeug]
    /// die letzten Nachrichten (Rolle, Text)
    var verlauf: [(ChatNachricht.Rolle, String)]
    var frage: String
}

enum SprachmodellAntwort: Sendable {
    /// Werkzeugaufruf, optional mit einem einleitenden Satz des Modells („Schauen wir auf deine Woche.“)
    case werkzeug(WerkzeugAufruf, einleitung: String? = nil)
    case text(String)
}

/// Zentrale Stelle, die sagt, ob ein Modell angeschlossen ist. Ohne Modell antwortet `Verstehen` (Regeln).
enum Sprachmodelle {
    /// Hier wird der Anbieter eingesteckt, sobald entschieden. nil = nur Regeln.
    nonisolated(unsafe) static var aktiv: (any Sprachmodell)?

    static var beschreibung: String { aktiv?.name ?? "Regeln auf dem Gerät (kein Server eingetragen)" }

    /// Beim Start und nach Änderungen in den Einstellungen: Server aus der Konfiguration einstecken.
    @MainActor
    static func einrichten(pro: Bool) {
        if let url = LotseKonfiguration.serverURL { aktiv = ClaudeServer(url: url, pro: pro) } else { aktiv = nil }
    }
}
