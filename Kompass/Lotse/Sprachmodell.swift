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
    /// `AppWissen.text()` – bei allen Nutzern gleich (Cache auf dem Server)
    var wissen: String
    /// von der App berechneter Stand: Datum, Uhrzeit, Tag, Ziele, Habits
    var kurzstand: String = ""
    var werkzeuge: [Werkzeug]
    /// die letzten Nachrichten (Rolle, Text)
    var verlauf: [(ChatNachricht.Rolle, String)]
    var frage: String
    /// Werkzeugschritte dieser Frage (Anforderung des Modells + Ergebnisse der App)
    var schritte: [ModellSchritt] = []
}

/// Ein Werkzeugaufruf des Modells mit seiner id (für das Ergebnis).
struct ModellAufruf: Sendable, Hashable {
    var id: String
    var name: String
    var parameter: [String: String]
}

/// Ein Schritt der Werkzeugschleife: was das Modell angefordert hat (unverändert zurück) und was die App geliefert hat.
struct ModellSchritt: Sendable {
    var inhalt: JSONWert
    var ergebnisse: [(id: String, text: String)]
}

enum SprachmodellAntwort: Sendable {
    /// Das Modell braucht Daten oder will etwas ändern: die App führt die Werkzeuge aus und fragt erneut.
    case werkzeuge([ModellAufruf], inhalt: JSONWert)
    /// Fertige Antwort (Markdown: **fett**, Listen, Absätze)
    case text(String)
}

/// Beliebiges JSON, unverändert weitergereicht (Inhalt des Modells zwischen Server und App).
enum JSONWert: Codable, Sendable, Hashable {
    case null, bool(Bool), zahl(Double), text(String), liste([JSONWert]), objekt([String: JSONWert])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .zahl(n) }
        else if let t = try? c.decode(String.self) { self = .text(t) }
        else if let l = try? c.decode([JSONWert].self) { self = .liste(l) }
        else { self = .objekt(try c.decode([String: JSONWert].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .zahl(let n): try c.encode(n)
        case .text(let t): try c.encode(t)
        case .liste(let l): try c.encode(l)
        case .objekt(let o): try c.encode(o)
        }
    }
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
