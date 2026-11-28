import ActivityKit
import AppIntents
import Foundation
import UserNotifications

/// Pause und Weiter direkt auf dem Sperrbildschirm / in der Dynamic Island.
/// Die Befehle laufen im Prozess der App (LiveActivityIntent). Ist der Fokus-Bildschirm offen, übernimmt er
/// (Uhr, Mitteilung, Live-Aktivität bleiben gleich). Sonst wird die Live-Aktivität direkt umgestellt.
enum FokusBefehl: Sendable { case pause, weiter, zuruecksetzen }

@MainActor
enum FokusBefehle {
    /// Vom Fokus-Bildschirm gesetzt
    static var empfaenger: ((FokusBefehl) -> Void)?

    static func ausfuehren(_ befehl: FokusBefehl) async {
        if let empfaenger {
            empfaenger(befehl)
        } else if befehl == .zuruecksetzen {
            await zuruecksetzenDirekt()
        } else {
            await direkt(pausieren: befehl == .pause)
        }
    }

    /// Ohne offenen Fokus-Bildschirm: Live-Aktivität beenden, nichts gutschreiben.
    nonisolated static func zuruecksetzenDirekt() async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mitteilungID])
        for a in Activity<FokusAktivitaet>.activities { await a.end(nil, dismissalPolicy: .immediate) }
    }

    /// Ohne offenen Fokus-Bildschirm: Live-Aktivität selbst umstellen und die Mitteilung zum Ende anpassen.
    nonisolated static func direkt(pausieren: Bool) async {
        for a in Activity<FokusAktivitaet>.activities {
            let s = a.content.state
            let gesamt = Int(s.ende.timeIntervalSince(s.start).rounded())
            let jetzt = Date()
            if pausieren, !s.pausiert {
                let rest = max(Int(s.ende.timeIntervalSince(jetzt).rounded(.up)), 0)
                let start = jetzt.addingTimeInterval(-TimeInterval(gesamt - rest))
                let neu = FokusAktivitaet.ContentState(start: start, ende: start.addingTimeInterval(TimeInterval(gesamt)), pausiert: true, restSekunden: rest)
                await a.update(ActivityContent(state: neu, staleDate: nil))
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mitteilungID])
            } else if !pausieren, s.pausiert {
                let ende = jetzt.addingTimeInterval(TimeInterval(s.restSekunden))
                let neu = FokusAktivitaet.ContentState(start: ende.addingTimeInterval(-TimeInterval(gesamt)), ende: ende, pausiert: false, restSekunden: s.restSekunden)
                await a.update(ActivityContent(state: neu, staleDate: ende))
                await mitteilungPlanen(name: a.attributes.habitName, inSekunden: s.restSekunden)
            }
        }
    }

    nonisolated static let mitteilungID = "fokus-ende"

    nonisolated static func mitteilungPlanen(name: String, inSekunden: Int) async {
        guard inSekunden > 0 else { return }
        let zentrale = UNUserNotificationCenter.current()
        let einstellungen = await zentrale.notificationSettings()
        guard einstellungen.authorizationStatus == .authorized else { return }
        let inhalt = UNMutableNotificationContent()
        inhalt.title = "Geschafft"
        inhalt.body = "Dein Fokus für \(name) ist abgelaufen."
        inhalt.sound = .default
        inhalt.interruptionLevel = .timeSensitive
        let ausloeser = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(inSekunden), repeats: false)
        try? await zentrale.add(UNNotificationRequest(identifier: mitteilungID, content: inhalt, trigger: ausloeser))
    }
}

struct FokusPausierenIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Fokus pausieren"
    init() {}
    func perform() async throws -> some IntentResult {
        await FokusBefehle.ausfuehren(.pause)
        return .result()
    }
}

struct FokusWeiterIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Fokus fortsetzen"
    init() {}
    func perform() async throws -> some IntentResult {
        await FokusBefehle.ausfuehren(.weiter)
        return .result()
    }
}

struct FokusZuruecksetzenIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Fokus zurücksetzen"
    init() {}
    func perform() async throws -> some IntentResult {
        await FokusBefehle.ausfuehren(.zuruecksetzen)
        return .result()
    }
}
