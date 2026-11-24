import EventKit
import Foundation
import Observation

/// Apple-Kalender (EventKit): lesen, und – seit 24.11.2026 – in Kompass verschieben, bearbeiten, anlegen und löschen.
/// Google-Kalender kommen über das Google-Konto in den iOS-Einstellungen mit (werden als „Google“ erkannt).
/// Nur nach Zustimmung; Änderungen gehen in den Kalender des Geräts, nichts an Kompass-Server.
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
            let quelle: Termin.Quelle = Self.istGoogle(quelle: e.calendar.source?.title ?? "", kalender: e.calendar.title) ? .google : .apple
            if e.isAllDay {
                var d = Tag(e.startDate, kalender: k)
                let letzter = Tag(e.endDate.addingTimeInterval(-1), kalender: k)
                while d <= letzter { if d >= von && d <= bis { out[d, default: []].append(Termin(quelle: quelle, schluessel: id, titel: e.title ?? "Termin", tag: d, kalenderFarbe: farbe, wiederkehrend: e.hasRecurrenceRules)) }; d = d.plus(tage: 1) }
                continue
            }
            // Mehrtägige Termine: je Tag der passende Abschnitt
            var d = Tag(e.startDate, kalender: k)
            let letzter = Tag(e.endDate.addingTimeInterval(-1), kalender: k)
            while d <= letzter {
                let s = d == Tag(e.startDate, kalender: k) ? Self.minuten(e.startDate, k) : 0
                let en = d == letzter ? max(s + 5, Self.minuten(e.endDate, k) == 0 ? 24 * 60 - 1 : Self.minuten(e.endDate, k)) : 24 * 60 - 1
                if d >= von && d <= bis {
                    out[d, default: []].append(Termin(quelle: quelle, schluessel: id, titel: e.title ?? "Termin", tag: d, start: s, ende: min(en, 24 * 60 - 1), kalenderFarbe: farbe, wiederkehrend: e.hasRecurrenceRules))
                }
                d = d.plus(tage: 1)
            }
        }
        return out
    }

    // MARK: Erkennen

    /// Google-Kalender, die über das Google-Konto auf dem iPhone kommen.
    nonisolated static func istGoogle(quelle: String, kalender: String) -> Bool {
        let q = quelle.lowercased(), c = kalender.lowercased()
        return q.contains("google") || q.contains("gmail") || c.hasSuffix("@gmail.com") || c.contains("@group.calendar.google.com")
    }

    // MARK: Live aktualisieren

    private var beobachter: NSObjectProtocol?

    /// Ruft `aenderung` auf, sobald sich der Kalender ändert (in Kompass, in der Kalender-App oder durch Sync mit iCloud/Google).
    func beobachten(_ aenderung: @escaping @MainActor () -> Void) {
        guard beobachter == nil else { return }
        beobachter = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { _ in
            Task { @MainActor in aenderung() }
        }
    }

    // MARK: Schreiben

    struct Kalender: Identifiable, Hashable, Sendable {
        var id: String
        var titel: String
        var google: Bool
    }

    enum Fehler: Error { case keinZugriff, nichtGefunden, nurLesen }

    /// Kalender, in die Kompass schreiben darf (Standard zuerst).
    func beschreibbareKalender() -> [Kalender] {
        guard status == .erlaubt else { return [] }
        let standard = store.defaultCalendarForNewEvents?.calendarIdentifier
        return store.calendars(for: .event).filter(\.allowsContentModifications)
            .sorted { ($0.calendarIdentifier == standard ? 0 : 1, $0.title) < ($1.calendarIdentifier == standard ? 0 : 1, $1.title) }
            .map { Kalender(id: $0.calendarIdentifier, titel: $0.title,
                            google: Self.istGoogle(quelle: $0.source?.title ?? "", kalender: $0.title)) }
    }

    /// Das Vorkommen eines Termins an einem Tag (bei Serien das richtige Datum).
    private func vorkommen(_ id: String, am tag: Tag, kalender k: Calendar) -> EKEvent? {
        guard status == .erlaubt else { return nil }
        let p = store.predicateForEvents(withStart: tag.plus(tage: -1).datum(kalender: k), end: tag.plus(tage: 2).datum(kalender: k), calendars: nil)
        return store.events(matching: p).first { $0.eventIdentifier == id && Tag($0.startDate, kalender: k) <= tag && Tag($0.endDate.addingTimeInterval(-1), kalender: k) >= tag }
            ?? store.event(withIdentifier: id)
    }

    /// Darf dieser Termin in Kompass geändert werden?
    func bearbeitbar(_ id: String, am tag: Tag, kalender k: Calendar) -> Bool {
        vorkommen(id, am: tag, kalender: k)?.calendar.allowsContentModifications ?? false
    }

    /// Alle Eigenschaften eines Termins, wie die Kalender-App sie kennt.
    struct Details: Equatable, Sendable {
        enum Wiederholung: String, CaseIterable, Sendable {
            case nie, taeglich, woechentlich, zweiwoechentlich, monatlich, jaehrlich
            var name: String {
                switch self {
                case .nie: "Nie"
                case .taeglich: "Täglich"
                case .woechentlich: "Wöchentlich"
                case .zweiwoechentlich: "Alle 2 Wochen"
                case .monatlich: "Monatlich"
                case .jaehrlich: "Jährlich"
                }
            }
        }
        var titel = ""
        var ort = ""
        var ganztaegig = false
        var start = Date()
        var ende = Date()
        var wiederholung: Wiederholung = .nie
        /// Erinnerungen in Minuten vor Beginn (0 = zum Termin)
        var erinnerungen: [Int] = []
        var url = ""
        var notizen = ""
        var kalenderID = ""
        var kalenderName = ""
        var teilnehmer: [String] = []
        var serie: Bool { wiederholung != .nie }
    }

    /// Liest alle Eigenschaften eines Vorkommens.
    func details(_ id: String, am tag: Tag, kalender k: Calendar) -> Details? {
        guard let e = vorkommen(id, am: tag, kalender: k), let s = e.startDate, let en = e.endDate else { return nil }
        var d = Details()
        d.titel = e.title ?? ""; d.ort = e.location ?? ""; d.ganztaegig = e.isAllDay
        d.start = s; d.ende = en
        d.wiederholung = Self.wiederholung(e.recurrenceRules?.first)
        d.erinnerungen = (e.alarms ?? []).compactMap { a in a.absoluteDate == nil ? Int((-a.relativeOffset / 60).rounded()) : nil }.sorted()
        d.url = e.url?.absoluteString ?? ""; d.notizen = e.notes ?? ""
        d.kalenderID = e.calendar.calendarIdentifier; d.kalenderName = e.calendar.title
        d.teilnehmer = (e.attendees ?? []).compactMap { $0.name }
        return d
    }

    /// Speichert alle Eigenschaften; `alle` = dieses und alle folgenden Vorkommen (wie in der Kalender-App).
    func speichern(_ id: String, am tag: Tag, details d: Details, alle: Bool, kalender k: Calendar) throws {
        guard let e = vorkommen(id, am: tag, kalender: k) else { throw Fehler.nichtGefunden }
        guard e.calendar.allowsContentModifications else { throw Fehler.nurLesen }
        e.title = d.titel
        e.location = d.ort.isEmpty ? nil : d.ort
        e.isAllDay = d.ganztaegig
        e.startDate = d.start
        e.endDate = max(d.ende, d.start.addingTimeInterval(d.ganztaegig ? 0 : 5 * 60))
        e.notes = d.notizen.isEmpty ? nil : d.notizen
        e.url = URL(string: d.url.trimmingCharacters(in: .whitespaces))
        e.alarms = d.erinnerungen.map { EKAlarm(relativeOffset: TimeInterval(-$0 * 60)) }
        if let c = store.calendar(withIdentifier: d.kalenderID), c.allowsContentModifications { e.calendar = c }
        let alt = Self.wiederholung(e.recurrenceRules?.first)
        if d.wiederholung != alt {
            e.recurrenceRules = Self.regel(d.wiederholung).map { [$0] }
        }
        try store.save(e, span: alle ? .futureEvents : .thisEvent, commit: true)
    }

    nonisolated static func wiederholung(_ r: EKRecurrenceRule?) -> Details.Wiederholung {
        guard let r else { return .nie }
        switch r.frequency {
        case .daily: return .taeglich
        case .weekly: return r.interval == 2 ? .zweiwoechentlich : .woechentlich
        case .monthly: return .monatlich
        case .yearly: return .jaehrlich
        @unknown default: return .nie
        }
    }

    nonisolated static func regel(_ w: Details.Wiederholung) -> EKRecurrenceRule? {
        switch w {
        case .nie: nil
        case .taeglich: EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
        case .woechentlich: EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)
        case .zweiwoechentlich: EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: nil)
        case .monatlich: EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)
        case .jaehrlich: EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil)
        }
    }

    /// Angaben eines Termins fürs Bearbeiten.
    func angaben(_ id: String, am tag: Tag, kalender k: Calendar) -> (titel: String, start: Date, ende: Date, kalender: String, serie: Bool)? {
        guard let e = vorkommen(id, am: tag, kalender: k) else { return nil }
        guard let s = e.startDate, let en = e.endDate else { return nil }
        return (e.title ?? "", s, en, e.calendar.title, e.hasRecurrenceRules)
    }

    /// Verschiebt dieses Vorkommen (Dauer bleibt) auf Tag und Uhrzeit.
    func verschieben(_ id: String, von alt: Tag, nach neu: Tag, start: Int, alle: Bool = false, kalender k: Calendar) throws {
        guard let e = vorkommen(id, am: alt, kalender: k) else { throw Fehler.nichtGefunden }
        guard e.calendar.allowsContentModifications else { throw Fehler.nurLesen }
        guard let alterStart = e.startDate, let altesEnde = e.endDate else { throw Fehler.nichtGefunden }
        let dauer = altesEnde.timeIntervalSince(alterStart)
        let beginn = k.date(byAdding: .minute, value: start, to: neu.datum(kalender: k)) ?? alterStart
        e.startDate = beginn
        e.endDate = beginn.addingTimeInterval(dauer)
        try store.save(e, span: alle ? .futureEvents : .thisEvent, commit: true)
    }

    /// Ändert Titel und Zeit (dieses Vorkommen) oder legt einen neuen Termin an. Gibt die Kennung zurück.
    @discardableResult
    func speichern(id: String?, am tag: Tag, titel: String, start: Date, ende: Date, kalenderID: String?, kalender k: Calendar) throws -> String {
        guard status == .erlaubt else { throw Fehler.keinZugriff }
        let e: EKEvent
        if let id {
            guard let x = vorkommen(id, am: tag, kalender: k) else { throw Fehler.nichtGefunden }
            guard x.calendar.allowsContentModifications else { throw Fehler.nurLesen }
            e = x
        } else {
            e = EKEvent(eventStore: store)
            e.calendar = kalenderID.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewEvents
        }
        e.title = titel
        e.startDate = start
        e.endDate = max(ende, start.addingTimeInterval(5 * 60))
        try store.save(e, span: .thisEvent, commit: true)
        return e.eventIdentifier ?? ""
    }

    /// Löscht dieses Vorkommen.
    func loeschen(_ id: String, am tag: Tag, alle: Bool = false, kalender k: Calendar) throws {
        guard let e = vorkommen(id, am: tag, kalender: k) else { throw Fehler.nichtGefunden }
        guard e.calendar.allowsContentModifications else { throw Fehler.nurLesen }
        try store.remove(e, span: alle ? .futureEvents : .thisEvent, commit: true)
    }

    private static func minuten(_ d: Date, _ k: Calendar) -> Int {
        let c = k.dateComponents([.hour, .minute], from: d); return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private static func hex(_ c: CGColor) -> String? {
        guard let comp = c.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?.components, comp.count >= 3 else { return nil }
        return String(format: "#%02X%02X%02X", Int(comp[0] * 255), Int(comp[1] * 255), Int(comp[2] * 255))
    }
}
