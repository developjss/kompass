import ActivityKit
import Foundation

/// Live-Aktivität „Fokus“ – gemeinsam für App und Erweiterung „CompassLive“.
struct FokusAktivitaet: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        /// Beginn (für den Balken; nach einer Pause so verschoben, dass der Balken stimmt)
        var start: Date
        /// Ende, solange der Timer läuft
        var ende: Date
        /// Pausiert: Zeit steht still
        var pausiert: Bool
        /// Restzeit in Sekunden während der Pause
        var restSekunden: Int
    }

    /// Name des Habits, z. B. „Lernen“
    var habitName: String
}

enum FokusUhrText {
    /// „29:57“, ab einer Stunde „1:05:00“.
    static func text(_ sekunden: Int) -> String {
        let s = max(sekunden, 0)
        let h = s / 3600, m = (s % 3600) / 60, r = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, r) : String(format: "%02d:%02d", m, r)
    }
}
