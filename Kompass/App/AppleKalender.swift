import EventKit
import Foundation
import Observation

/// Apple-Kalender lesen (EventKit, Struktur v3 §7): nur nach Zustimmung, nur lesen, nichts verlässt das Gerät.
/// Liefert Termine je Tag an den Speicher (`externeTermine`); gerechnet wird in `Tagesplan`.
@MainActor
@Observable
final class AppleKalender {
    static let aktiv = AppleKalender()

    enum Status: Equatable { case unbekannt, erlaubt, abgelehnt }
    private(set) var status: Status = .unbekannt
    private let store = EKEventStore()
    private init() { statusLesen() }

    func statusLesen() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: status = .erlaubt
        case .denied, .restricted, .writeOnly: status = .abgelehnt
        default: status = .unbekannt
        }
    }

    /// Fragt einmal um Erlaubnis (Systemdialog).
    func erlauben() async -> Bool {
        let ok = (try? await store.requestFullAccessToEvents()) ?? false
        statusLesen()
        return ok
    }

    /// Termine von `von` bis `bis` (beide Tage eingeschlossen) als Kompass-Termine je Tag.
    func termine(von: Tag, bis: Tag, kalender k: Calendar) -> [Tag: [Termin]] {
        guard status == .erlaubt else { return [:] }
        let start = von.datum(kalender: k)
        let ende = bis.plus(tage: 1).datum(kalender: k)
        let p = store.predicateForEvents(withStart: start, end: ende, calendars: nil)
        var out: [Tag: [Termin]] = [:]
        for e in store.events(matching: p) {
            let farbe = e.calendar.cgColor.flatMap(Self.hex)
            let id = e.eventIdentifier ?? UUID().uuidString
            if e.isAllDay {
                var d = Tag(e.startDate, kalender: k)
                let letzter = Tag(e.endDate.addingTimeInterval(-1), kalender: k)
                while d <= letzter { if d >= von && d <= bis { out[d, default: []].append(Termin(quelle: .apple, schluessel: id, titel: e.title ?? "Termin", tag: d, kalenderFarbe: farbe)) }; d = d.plus(tage: 1) }
                continue
            }
            // Mehrtägige Termine: je Tag der passende Abschnitt
            var d = Tag(e.startDate, kalender: k)
            let letzter = Tag(e.endDate.addingTimeInterval(-1), kalender: k)
            while d <= letzter {
                let s = d == Tag(e.startDate, kalender: k) ? Self.minuten(e.startDate, k) : 0
                let en = d == letzter ? max(s + 5, Self.minuten(e.endDate, k) == 0 ? 24 * 60 - 1 : Self.minuten(e.endDate, k)) : 24 * 60 - 1
                if d >= von && d <= bis {
                    out[d, default: []].append(Termin(quelle: .apple, schluessel: id, titel: e.title ?? "Termin", tag: d, start: s, ende: min(en, 24 * 60 - 1), kalenderFarbe: farbe))
                }
                d = d.plus(tage: 1)
            }
        }
        return out
    }

    private static func minuten(_ d: Date, _ k: Calendar) -> Int {
        let c = k.dateComponents([.hour, .minute], from: d); return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private static func hex(_ c: CGColor) -> String? {
        guard let comp = c.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components, comp.count >= 3 else { return nil }
        return String(format: "#%02X%02X%02X", Int(comp[0] * 255), Int(comp[1] * 255), Int(comp[2] * 255))
    }
}
