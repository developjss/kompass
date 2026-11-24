import Foundation

/// Meilenstein aus etwas Bestehendem (rechenregeln.md §3): Termin-Serien finden und zählen, was schon stattgefunden hat,
/// und was ein Habit bisher geschafft hat. Nur Zählen – die Prozente rechnet weiter `Fortschritt.stand`.
enum MeilensteinQuelle {

    struct Serie: Identifiable, Equatable, Sendable {
        /// „quelle:schlüssel“ wie in `TerminVerknuepfung.serie`
        var id: String
        var titel: String
        /// stattgefunden im Suchzeitraum (heute nur, was schon vorbei ist – wie der Abgleich)
        var bisher: Int
        var minutenBisher: Int
        /// erster stattgefundener Tag (Start fürs Mitzählen), nil = noch keiner
        var erster: Tag?
        /// noch geplant im Suchzeitraum (heute Kommendes eingeschlossen)
        var kommend: Int
    }

    /// Termin-Serien mit Uhrzeit, die es um heute herum gibt (`zurueck` Tage zurück, `voraus` Tage voraus).
    /// Bereits mit diesem Ziel verknüpfte Serien fehlen. Sortiert: meiste bisherige zuerst, dann Titel.
    static func serien(zustand z: Zustand, ziel zid: UUID, heute: Tag, jetzt: Int, termine: (Tag) -> [Termin],
                       zurueck: Int = 120, voraus: Int = 60) -> [Serie] {
        let verknuepft = Set(z.termine.filter { $0.zielID == zid }.map(\.serie))
        var liste: [String: Serie] = [:]
        for i in -zurueck...voraus {
            let d = heute.plus(tage: i)
            for t in termine(d) {
                guard let a = t.start, let e = t.ende else { continue }
                let key = "\(t.quelle.rawValue):\(t.schluessel)"
                guard !verknuepft.contains(key) else { continue }
                var s = liste[key] ?? Serie(id: key, titel: t.titel, bisher: 0, minutenBisher: 0, erster: nil, kommend: 0)
                // wie der Abgleich (`termineAbgleichen`): heutige Termine zählen erst, wenn sie vorbei sind
                let vorbei = d < heute || (d == heute && e <= jetzt)
                if vorbei {
                    s.bisher += 1
                    s.minutenBisher += max(0, e - a)
                    if s.erster == nil || d < s.erster! { s.erster = d }
                } else {
                    s.kommend += 1
                }
                liste[key] = s
            }
        }
        return liste.values.sorted { ($0.bisher, $1.titel) > ($1.bisher, $0.titel) }
    }

    /// Was ein Habit bisher geschafft hat: Summe der Tagesanteile bzw. erfüllte Wochen seit Anlage des Habits.
    static func habitBisher(_ h: Habit, modus: HabitModus, heute: Tag) -> Double {
        switch modus {
        case .anzahl: HabitRechnung.summe(h, von: h.angelegt, bis: heute)
        case .wochen: Double(HabitRechnung.erfuellteWochen(h, seit: h.angelegt, heute: heute))
        }
    }

    /// Vorschau: so weit wäre der Meilenstein schon (0…1), wenn `bisher` von `soll` mitzählt.
    static func vorschau(bisher: Double, soll: Double) -> Double {
        soll > 0 ? min(1, max(0, bisher / soll)) : 0
    }
}
