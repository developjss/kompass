import ActivityKit
import AudioToolbox
import Foundation
import UserNotifications

/// Steuert die Live-Aktivität und die Mitteilung zum Fokus-Ende.
/// Läuft der Timer ab, während die App offen ist: Handy vibriert zweimal.
/// Ist die App im Hintergrund oder das Handy gesperrt: Mitteilung „Geschafft“ (vibriert nach den iOS-Einstellungen).
@MainActor
enum FokusLive {
    /// Kennung der laufenden Aktivität (die Aktivität selbst wird je Aufruf frisch geholt – sicher für Swift 6)
    private static var aktivID: String?
    private static let mitteilungID = "fokus-ende"

    // MARK: Live-Aktivität

    static func starten(name: String, gesamt: Int, rest: Int) {
        // alte Aktivitäten beenden – nur die, die es vor diesem Start schon gab
        mitteilungAbsagen()
        let alte = Activity<FokusAktivitaet>.activities.map(\.id)
        Task.detached {
            for a in Activity<FokusAktivitaet>.activities where alte.contains(a.id) { await a.end(nil, dismissalPolicy: .immediate) }
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let stand = laufend(gesamt: gesamt, rest: rest)
        aktivID = (try? Activity.request(attributes: FokusAktivitaet(habitName: name),
                                         content: ActivityContent(state: stand, staleDate: stand.ende),
                                         pushType: nil))?.id
        mitteilungPlanen(name: name, inSekunden: rest)
    }

    static func pausieren(gesamt: Int, rest: Int) {
        let start = Date().addingTimeInterval(-TimeInterval(gesamt - rest))
        let stand = FokusAktivitaet.ContentState(start: start, ende: start.addingTimeInterval(TimeInterval(gesamt)), pausiert: true, restSekunden: rest)
        aktualisieren(stand, veraltet: nil)
        mitteilungAbsagen()
    }

    static func weiter(name: String, gesamt: Int, rest: Int) {
        let stand = laufend(gesamt: gesamt, rest: rest)
        aktualisieren(stand, veraltet: stand.ende)
        mitteilungPlanen(name: name, inSekunden: rest)
    }

    /// Timer abgelaufen: „Geschafft“ zeigen, nach kurzer Zeit ausblenden.
    static func fertig(gesamt: Int) {
        guard let id = aktivID else { return }
        let jetzt = Date()
        let stand = FokusAktivitaet.ContentState(start: jetzt.addingTimeInterval(-TimeInterval(gesamt)), ende: jetzt, pausiert: false, restSekunden: 0)
        let inhalt = ActivityContent(state: stand, staleDate: jetzt)
        Task.detached {
            for a in Activity<FokusAktivitaet>.activities where a.id == id {
                await a.end(inhalt, dismissalPolicy: .after(jetzt.addingTimeInterval(8)))
            }
        }
        aktivID = nil
        mitteilungAbsagen()
    }

    /// Früher beendet oder geschlossen: sofort weg.
    static func beendenSofort() {
        mitteilungAbsagen()
        aktivID = nil
        // auch übrig gebliebene Aktivitäten (z. B. nach Absturz) beenden
        Task.detached {
            for a in Activity<FokusAktivitaet>.activities { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private static func laufend(gesamt: Int, rest: Int) -> FokusAktivitaet.ContentState {
        let ende = Date().addingTimeInterval(TimeInterval(rest))
        return FokusAktivitaet.ContentState(start: ende.addingTimeInterval(-TimeInterval(gesamt)), ende: ende, pausiert: false, restSekunden: rest)
    }

    private static func aktualisieren(_ stand: FokusAktivitaet.ContentState, veraltet: Date?) {
        guard let id = aktivID else { return }
        let inhalt = ActivityContent(state: stand, staleDate: veraltet)
        Task.detached {
            for a in Activity<FokusAktivitaet>.activities where a.id == id { await a.update(inhalt) }
        }
    }

    // MARK: Vibrieren und Mitteilung

    /// Zweimal vibrieren (App im Vordergrund).
    static func doppeltVibrieren() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private static func mitteilungPlanen(name: String, inSekunden: Int) {
        guard inSekunden > 0 else { return }
        let zentrale = UNUserNotificationCenter.current()
        Task {
            // Beim ersten Fokus fragt iOS einmal nach Mitteilungen
            let erlaubt = (try? await zentrale.requestAuthorization(options: [.alert, .sound])) ?? false
            guard erlaubt else { return }
            let inhalt = UNMutableNotificationContent()
            inhalt.title = "Geschafft"
            inhalt.body = "Dein Fokus für \(name) ist abgelaufen."
            inhalt.sound = .default
            inhalt.interruptionLevel = .timeSensitive
            let ausloeser = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(inSekunden), repeats: false)
            try? await zentrale.add(UNNotificationRequest(identifier: mitteilungID, content: inhalt, trigger: ausloeser))
        }
    }

    private static func mitteilungAbsagen() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [mitteilungID])
    }
}
