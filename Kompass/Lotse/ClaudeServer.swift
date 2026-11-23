import Foundation
import Observation

// Anbindung an den Lotse-Server (supabase/functions/lotse). Die App kennt weder Schlüssel noch Modellnamen:
// sie schickt Frage, App-Wissen, Werkzeuge und Kurzstand; der Server wählt Modell und Stufe.

/// Woher die App kommt – entscheidet auf dem Server über das Kontingent (Tester sind frei, solange LOTSE_TESTER_FREI gilt).
enum Kanal: String, Sendable {
    case debug, beta, testflight, store

    static var aktuell: Kanal {
        #if DEBUG
        return .debug
        #elseif BETA
        return .beta
        #else
        // App-Store-Build: TestFlight erkennt man am Sandbox-Beleg
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? .testflight : .store
        #endif
    }
}

/// Einstellungen für den Server: URL je Kanal, im Debug/Beta überschreibbar. Kein Schlüssel.
enum LotseKonfiguration {
    /// Server-URL je Kanal. Leer = kein Sprachmodell, nur Regeln. [OFFEN] Nach dem Deploy hier eintragen (docs/technik/lotse-server.md).
    static let standardURL: [Kanal: String] = [
        .debug: "",
        .beta: "",
        .testflight: "",
        .store: "",
    ]
    /// Gemeinsamer App-Schlüssel (hält zufällige Aufrufer fern; kein Geheimnis im strengen Sinn). Muss zu LOTSE_APP_SCHLUESSEL auf dem Server passen.
    static let appSchluessel = ""

    private static let urlSchluessel = "lotse.serverURL"
    private static let nutzerSchluessel = "lotse.nutzer"

    static var serverURL: URL? {
        let text = ueberschriebeneURL ?? standardURL[Kanal.aktuell] ?? ""
        return text.isEmpty ? nil : URL(string: text)
    }

    /// Nur Debug/Beta: eigene URL eintragen (z. B. lokaler `supabase functions serve`).
    static var ueberschriebeneURL: String? {
        get { Kanal.aktuell == .store ? nil : UserDefaults.standard.string(forKey: urlSchluessel).flatMap { $0.isEmpty ? nil : $0 } }
        set { UserDefaults.standard.set(newValue, forKey: urlSchluessel) }
    }

    /// Anonyme Geräte-ID für das Kontingent – kein Konto, kein Name. Neu bei Neuinstallation.
    static var nutzerID: String {
        if let id = UserDefaults.standard.string(forKey: nutzerSchluessel) { return id }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: nutzerSchluessel)
        return id
    }
}

/// Was der Server zum Kontingent zurückmeldet – für die Anzeige „3 freie Fragen heute“.
struct Kontingent: Codable, Sendable, Hashable {
    var frei: Int
    var limit: Int
    var pro: Bool
}

/// Sichtbarer Zustand der Anbindung (Kontingent, letzter Fehler) – vom Chat beobachtet.
@MainActor
@Observable
final class LotseStand {
    static let geteilt = LotseStand()
    var kontingent: Kontingent?
    var letzterFehler: String?
}

enum LotseFehler: Error, Equatable {
    case kontingentErschoepft(limit: Int, pro: Bool)
    case server(Int)
    case antwort
}

struct ClaudeServer: Sprachmodell {
    let url: URL
    var pro: Bool
    var name: String { "Claude über den Kompass-Server" }

    private struct Anfrage: Encodable {
        struct Werkzeug: Encodable { var name: String; var beschreibung: String; var parameter: [String: String] }
        struct Zeile: Encodable { var rolle: String; var text: String }
        var frage: String
        var wissen: String
        var kurzstand: String
        var werkzeuge: [Werkzeug]
        var verlauf: [Zeile]
        var nutzer: String
        var kanal: String
        var pro: Bool
        var zeitzone: String
    }

    private struct Antwort: Decodable {
        var art: String?
        var name: String?
        var parameter: [String: String]?
        var text: String?
        var kontingent: Kontingent?
        var fehler: String?
        var limit: Int?
        var pro: Bool?
    }

    func antworte(auf a: SprachmodellAnfrage) async throws -> SprachmodellAntwort {
        // Wissen und Kurzstand kommen getrennt: Wissen ist bei allen gleich (Cache), der Stand nicht.
        let teile = a.wissen.components(separatedBy: "\n\nStand:\n")
        let anfrage = Anfrage(
            frage: a.frage, wissen: teile[0], kurzstand: teile.count > 1 ? teile[1] : "",
            werkzeuge: a.werkzeuge.map { .init(name: $0.name.rawValue, beschreibung: $0.beschreibung, parameter: $0.parameter) },
            verlauf: a.verlauf.map { .init(rolle: $0.0.rawValue, text: $0.1) },
            nutzer: LotseKonfiguration.nutzerID, kanal: Kanal.aktuell.rawValue, pro: pro,
            zeitzone: TimeZone.current.identifier)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !LotseKonfiguration.appSchluessel.isEmpty { req.setValue(LotseKonfiguration.appSchluessel, forHTTPHeaderField: "X-Kompass-App") }
        req.httpBody = try JSONEncoder().encode(anfrage)

        let (daten, antwort) = try await URLSession.shared.data(for: req)
        let status = (antwort as? HTTPURLResponse)?.statusCode ?? 0
        let geparst = try? JSONDecoder().decode(Antwort.self, from: daten)
        if status == 429, let g = geparst, g.fehler == "kontingent" {
            await MainActor.run { LotseStand.geteilt.kontingent = Kontingent(frei: 0, limit: g.limit ?? 0, pro: g.pro ?? false) }
            throw LotseFehler.kontingentErschoepft(limit: g.limit ?? 0, pro: g.pro ?? false)
        }
        guard status == 200, let g = geparst else { throw LotseFehler.server(status) }
        if let k = g.kontingent { await MainActor.run { LotseStand.geteilt.kontingent = k } }
        switch g.art {
        case "werkzeug":
            guard let n = g.name, let werkzeug = Werkzeug.Name(rawValue: n) else { throw LotseFehler.antwort }
            return .werkzeug(WerkzeugAufruf(name: werkzeug, parameter: g.parameter ?? [:]))
        case "text":
            guard let t = g.text, !t.isEmpty else { throw LotseFehler.antwort }
            return .text(t)
        default:
            throw LotseFehler.antwort
        }
    }

    /// Antwort des Servers lesen – getrennt testbar.
    static func lesen(_ daten: Data, status: Int) throws -> (SprachmodellAntwort, Kontingent?) {
        let g = try JSONDecoder().decode(Antwort.self, from: daten)
        if status == 429 { throw LotseFehler.kontingentErschoepft(limit: g.limit ?? 0, pro: g.pro ?? false) }
        guard status == 200 else { throw LotseFehler.server(status) }
        switch g.art {
        case "werkzeug":
            guard let n = g.name, let w = Werkzeug.Name(rawValue: n) else { throw LotseFehler.antwort }
            return (.werkzeug(WerkzeugAufruf(name: w, parameter: g.parameter ?? [:])), g.kontingent)
        case "text":
            guard let t = g.text, !t.isEmpty else { throw LotseFehler.antwort }
            return (.text(t), g.kontingent)
        default: throw LotseFehler.antwort
        }
    }
}
