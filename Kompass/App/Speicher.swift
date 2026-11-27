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
            // Start mit frischen Demo-Daten (UI-Tests, Vorführung): Startargument „-demoNeu“
            if ProcessInfo.processInfo.arguments.contains("-demoNeu") { try? FileManager.default.removeItem(at: datei) }
            if FileManager.default.fileExists(atPath: datei.path) {
                let daten = try Data(contentsOf: datei)
                zustand = try JSONDecoder.kompass.decode(Zustand.self, from: daten)
                if zustand.version == 2 {
                    // Version 2 → 3: neue Felder haben Standardwerte; wer schon Daten hat, braucht kein Onboarding.
                    zustand.version = 3
                    zustand.profil.onboardingFertig = true
                    speichernJetzt()
                }
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
            appleKalenderLesen()
            // Live: jede Änderung im Kalender (auch iCloud-/Google-Sync) sofort übernehmen
            AppleKalender.aktiv.beobachten { [weak self] in self?.appleKalenderLesen() }
            erinnerungenPlanen()
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
        erinnerungenPlanen()
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
        let T = heute
        let z = zustand
        let extern = externeTermine
        let k = kalender.dateComponents([.hour, .minute], from: jetzt())
        let minuten = (k.hour ?? 0) * 60 + (k.minute ?? 0)
        zustand.termineAbgleichen(heute: T, jetzt: minuten) { d in Kalenderquelle.termine(am: d, zustand: z, heute: T, extern: extern[d] ?? []) }
        zustand.habitsAusTerminen(heute: T, jetzt: minuten)
    }

    /// Termine aus dem Apple-Kalender (EventKit), je Tag – nur gelesen, nicht gespeichert.
    var externeTermine: [Tag: [Termin]] = [:]

    /// Apple-Kalender neu lesen (6 Wochen zurück, 1 Jahr voraus), wenn eingeschaltet und erlaubt.
    func appleKalenderLesen() {
        guard datei != nil, zustand.einstellungen.appleKalender else { externeTermine = [:]; return }
        AppleKalender.aktiv.statusLesen()
        externeTermine = AppleKalender.aktiv.termine(von: heute.plus(tage: -42), bis: heute.plus(tage: 366), kalender: kalender)
        termineAbgleichen()
    }

    /// Alle Termine eines Tages (Beispiel, eigene, Apple).
    func termine(am d: Tag) -> [Termin] {
        Kalenderquelle.termine(am: d, zustand: zustand, heute: heute, extern: externeTermine[d] ?? [])
    }

    /// Minuten seit Mitternacht jetzt
    var jetztMinuten: Int {
        let k = kalender.dateComponents([.hour, .minute], from: jetzt())
        return (k.hour ?? 0) * 60 + (k.minute ?? 0)
    }

    /// Habit-Mitteilungen neu planen (nur in der echten App, nicht in Vorschau und Tests).
    func erinnerungenPlanen() {
        guard datei != nil else { return }
        Erinnerungen.aktiv.planen(habits: zustand.habits, heute: heute, jetzt: jetzt(), kalender: kalender)
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
