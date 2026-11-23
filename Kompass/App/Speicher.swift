import Foundation
import Observation
import SwiftUI

/// Hält den Zustand und speichert ihn lokal als JSON (Application Support). Offline vollständig.
/// [OFFEN] SwiftData statt JSON (Aufgabe `s-speicher`), danach Sync über einen Server.
@MainActor
@Observable
final class Speicher {

    enum Lage: Equatable {
        case laedt
        case bereit
        case fehler(String)
    }

    private(set) var lage: Lage = .laedt
    var zustand = Zustand()
    /// Für den Seitenfuß: „Lokal gespeichert“ oder Fehlermeldung
    private(set) var speicherText = "Lokal gespeichert"
    private(set) var speicherFehler = false

    /// Uhr ist austauschbar (Vorschauen, UI-Tests)
    var jetzt: () -> Date = { Date() }
    let kalender = Calendar.kompass
    var heute: Tag { Tag(jetzt(), kalender: kalender) }

    private let datei: URL?
    private var speichernAufgabe: Task<Void, Never>?

    init(datei: URL? = Speicher.standardDatei) {
        self.datei = datei
    }

    static var standardDatei: URL? {
        try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("kompass.json")
    }

    /// Nur für Vorschauen: sofort bereit mit Demo-Daten, ohne Datei.
    static func vorschau() -> Speicher {
        let s = Speicher(datei: nil)
        s.zustand = DemoDaten.zustand(heute: s.heute)
        s.lage = .bereit
        return s
    }

    func laden() async {
        lage = .laedt
        guard let datei else {
            zustand = DemoDaten.zustand(heute: heute, jetzt: jetzt())
            lage = .bereit
            return
        }
        do {
            if FileManager.default.fileExists(atPath: datei.path) {
                let daten = try Data(contentsOf: datei)
                zustand = try JSONDecoder.kompass.decode(Zustand.self, from: daten)
                if zustand.version < 2 {
                    // Version 1 kannte „Ziel als Zahl“ noch ohne Meilensteine; bisher gab es nur Demo-Daten → neu aufsetzen.
                    zustand = DemoDaten.zustand(heute: heute, jetzt: jetzt())
                    speichernJetzt()
                }
            } else {
                zustand = DemoDaten.zustand(heute: heute, jetzt: jetzt())
                speichernJetzt()
            }
            termineAbgleichen()
            zustand.verlaufFortschreiben(heute: heute)
            lage = .bereit
        } catch {
            lage = .fehler("Deine Daten konnten nicht gelesen werden.")
        }
    }

    /// Nach einem Lesefehler: mit Demo-Daten neu beginnen (alte Datei bleibt als Sicherung liegen).
    func neuBeginnen() {
        if let datei, FileManager.default.fileExists(atPath: datei.path) {
            let sicherung = datei.deletingPathExtension().appendingPathExtension("sicherung.json")
            try? FileManager.default.removeItem(at: sicherung)
            try? FileManager.default.moveItem(at: datei, to: sicherung)
        }
        zustand = DemoDaten.zustand(heute: heute, jetzt: jetzt())
        lage = .bereit
        speichernJetzt()
    }

    /// Ändert den Zustand und speichert gebündelt (viele Änderungen kurz hintereinander = ein Schreibvorgang).
    func aendern(_ aenderung: (inout Zustand) -> Void) {
        aenderung(&zustand)
        termineAbgleichen()
        zustand.verlaufFortschreiben(heute: heute)
        speichernAufgabe?.cancel()
        speichernAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.speichernJetzt()
        }
    }

    func speichernJetzt() {
        guard let datei else { return }
        do {
            let daten = try JSONEncoder.kompass.encode(zustand)
            try daten.write(to: datei, options: [.atomic, .completeFileProtection])
            speicherText = "Lokal gespeichert"
            speicherFehler = false
        } catch {
            speicherText = "Nicht gespeichert"
            speicherFehler = true
        }
    }

    /// Stattgefundene Termine verknüpfter Serien übernehmen (Beispielkalender; später EventKit/Google).
    func termineAbgleichen() {
        let e = zustand.einstellungen, T = heute
        guard e.googleBeispiel || e.appleBeispiel else { return }
        zustand.termineAbgleichen(heute: T) { Beispieltermine.termine(am: $0, google: e.googleBeispiel, apple: e.appleBeispiel, heute: T) }
    }

    func demoZuruecksetzen() {
        zustand = DemoDaten.zustand(heute: heute, jetzt: jetzt())
        speichernJetzt()
    }
}

extension JSONEncoder {
    static var kompass: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var kompass: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
