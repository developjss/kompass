import Foundation

/// Welche Habit-Mitteilungen anstehen (habits-v2.md §8). Reine Rechnung – kein System-Aufruf, keine KI.
/// Geplant wird je Habit mit Erinnerungszeit jeder geplante, noch nicht volle Tag der nächsten 7 Tage;
/// heute nur, wenn die Uhrzeit noch vor uns liegt. Nach jeder Änderung wird neu geplant.
enum ErinnerungRechnung {

    struct Termin: Hashable, Sendable {
        var habitID: UUID
        var tag: Tag
        /// Minuten seit Mitternacht
        var minuten: Int
        /// Kennung der Mitteilung (Präfix „habit-“, damit nur eigene gelöscht werden)
        var id: String { "habit-\(habitID.uuidString)-\(tag.text)" }
    }

    /// iOS hält höchstens 64 anstehende Mitteilungen; wir bleiben darunter.
    static let hoechstens = 60

    static func termine(habits: [Habit], heute: Tag, jetztMinuten: Int, tage: Int = 7, hoechstens limit: Int = hoechstens) -> [Termin] {
        var t: [Termin] = []
        for h in habits {
            guard let m = h.erinnerung, (0..<1440).contains(m) else { continue }
            for i in 0..<tage {
                let d = heute.plus(tage: i)
                if i == 0, m <= jetztMinuten { continue }
                guard d >= h.angelegt, HabitRechnung.geplant(h, am: d), !h.voll(am: d) else { continue }
                t.append(Termin(habitID: h.id, tag: d, minuten: m))
            }
        }
        return Array(t.sorted { ($0.tag, $0.minuten, $0.habitID.uuidString) < ($1.tag, $1.minuten, $1.habitID.uuidString) }.prefix(limit))
    }

    /// Text der Mitteilung: „Heute noch offen: 20 min.“ bzw. „Heute noch offen.“
    static func text(_ h: Habit) -> String {
        if let m = h.menge, m > 0 {
            return "Heute noch offen: \(Zahl.text(m, stellen: 1))\(h.einheit.map { " " + $0.kurz } ?? "")."
        }
        return "Heute noch offen."
    }
}
