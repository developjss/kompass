import Foundation
import Observation
import UserNotifications

/// Habit-Erinnerungen als lokale Mitteilungen (UserNotifications, keine neue Abhängigkeit).
/// Was wann ansteht, rechnet `ErinnerungRechnung`; hier wird nur geplant, gefragt und geöffnet.
@MainActor
@Observable
final class Erinnerungen {
    static let aktiv = Erinnerungen()

    enum Status: Equatable { case unbekannt, erlaubt, abgelehnt }
    private(set) var status: Status = .unbekannt
    /// Wird gesetzt von der App: Tipp auf eine Mitteilung öffnet den Habit.
    var oeffnen: ((UUID) -> Void)?

    private let weiche = Weiche()
    private init() {}

    func starten() {
        UNUserNotificationCenter.current().delegate = weiche
        Task { await statusLesen() }
    }

    func statusLesen() async {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        switch s.authorizationStatus {
        case .authorized, .provisional, .ephemeral: status = .erlaubt
        case .denied: status = .abgelehnt
        default: status = .unbekannt
        }
    }

    /// Fragt beim ersten Einschalten einer Erinnerung um Erlaubnis.
    @discardableResult
    func erlaubnis() async -> Bool {
        if status == .erlaubt { return true }
        let ok = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        status = ok ? .erlaubt : .abgelehnt
        return ok
    }

    /// Plant alle Habit-Mitteilungen neu (nächste 7 Tage). Eigene alte werden entfernt; ohne Erlaubnis bleibt es leer.
    func planen(habits: [Habit], heute: Tag, jetzt: Date, kalender: Calendar) {
        let k = kalender.dateComponents([.hour, .minute], from: jetzt)
        let termine = ErinnerungRechnung.termine(habits: habits, heute: heute, jetztMinuten: (k.hour ?? 0) * 60 + (k.minute ?? 0))
        let inhalte = termine.compactMap { t -> (String, UNMutableNotificationContent, DateComponents)? in
            guard let h = habits.first(where: { $0.id == t.habitID }) else { return nil }
            let c = UNMutableNotificationContent()
            c.title = h.titel
            c.body = ErinnerungRechnung.text(h)
            c.sound = .default
            c.threadIdentifier = "habits"
            c.userInfo = ["habit": h.id.uuidString]
            var d = DateComponents()
            d.year = t.tag.jahr; d.month = t.tag.monat; d.day = t.tag.tag
            d.hour = t.minuten / 60; d.minute = t.minuten % 60
            return (t.id, c, d)
        }
        let erlaubt = status == .erlaubt
        Task {
            let center = UNUserNotificationCenter.current()
            let alt = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("habit-") }
            center.removePendingNotificationRequests(withIdentifiers: alt)
            guard erlaubt else { return }
            for (id, inhalt, datum) in inhalte {
                let anfrage = UNNotificationRequest(identifier: id, content: inhalt, trigger: UNCalendarNotificationTrigger(dateMatching: datum, repeats: false))
                try? await center.add(anfrage)
            }
        }
    }
}

/// Nimmt Mitteilungen entgegen: im Vordergrund als Banner zeigen, Tipp öffnet den Habit.
private final class Weiche: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = (response.notification.request.content.userInfo["habit"] as? String).flatMap(UUID.init)
        if let id { Task { @MainActor in Erinnerungen.aktiv.oeffnen?(id) } }
        completionHandler()
    }
}
