import Foundation

// Änderungen am Zustand – deterministisch, ohne UI. `heute`/`jetzt` werden übergeben, damit Tests jede Lage nachstellen können.

extension Zustand {

    // MARK: Aufgaben

    @discardableResult
    mutating func aufgabeAnlegen(_ titel: String, datum: Tag?, prio: Prioritaet = .normal, zielID: UUID? = nil, heute: Tag) -> Aufgabe {
        let liste = aufgaben.filter { $0.datum == datum && $0.prio == prio }
        let schritt = Fortschritt.naechsterOffenerSchritt(ziel(zielID), in: self, heute: heute)
        let a = Aufgabe(titel: titel, datum: datum, prio: prio, reihenfolge: (liste.map(\.reihenfolge).max() ?? -1) + 1,
                        zielID: zielID, schrittID: schritt?.id)
        aufgaben.append(a)
        return a
    }

    /// Erledigt eine Aufgabe; bei Wiederholung entsteht der nächste Termin (genau einmal je Serie).
    mutating func erledigen(_ id: UUID, jetzt: Date, kalender: Calendar = .kompass) {
        guard let i = aufgaben.firstIndex(where: { $0.id == id }), !aufgaben[i].erledigt else { return }
        if timer?.aufgabeID == id { timerStoppen(jetzt: jetzt, kalender: kalender) }
        aufgaben[i].erledigt = true
        aufgaben[i].erledigtAm = jetzt
        wiederholungAnlegen(nach: aufgaben[i], heute: Tag(jetzt, kalender: kalender))
    }

    mutating func umschalten(_ id: UUID, jetzt: Date, kalender: Calendar = .kompass) {
        guard let i = aufgaben.firstIndex(where: { $0.id == id }) else { return }
        if aufgaben[i].erledigt {
            aufgaben[i].erledigt = false
            aufgaben[i].erledigtAm = nil
        } else {
            erledigen(id, jetzt: jetzt, kalender: kalender)
        }
    }

    @discardableResult
    mutating func wiederholungAnlegen(nach a: Aufgabe, heute: Tag) -> Aufgabe? {
        guard !a.einmalig, let i = aufgaben.firstIndex(where: { $0.id == a.id }) else { return nil }
        let serie = a.serie ?? a.id
        aufgaben[i].serie = serie
        let basis = a.datum ?? heute
        let schonOffen = aufgaben.contains { $0.id != a.id && $0.serie == serie && !$0.erledigt && ($0.datum ?? Tag(1, 1, 1)) > basis }
        guard !schonOffen, let neu = WiederholungRechnung.naechstesDatum(nach: basis, regel: a.wiederholung, ankerTag: a.ankerTag ?? basis.tag)
        else { return nil }
        aufgaben[i].ankerTag = a.ankerTag ?? basis.tag
        var n = aufgabeAnlegen(a.titel, datum: neu, prio: a.prio, zielID: a.zielID, heute: heute)
        n.uhrzeit = a.uhrzeit
        n.dauer = a.dauer
        n.wiederholung = a.wiederholung
        n.serie = serie
        n.notizen = a.notizen
        n.ankerTag = aufgaben[i].ankerTag
        n.schrittID = a.schrittID
        aufgaben[aufgaben.count - 1] = n
        return n
    }

    /// „Nur diesen löschen“ lässt die Serie weiterlaufen, „Serie beenden“ stoppt sie.
    mutating func loeschen(_ id: UUID, serieBeenden: Bool = false, heute: Tag) {
        guard let a = aufgabe(id) else { return }
        if timer?.aufgabeID == id { timer = nil }
        if serieBeenden {
            let k = a.serie ?? a.id
            aufgaben.removeAll { ($0.serie ?? $0.id) == k && !$0.erledigt }
            for i in aufgaben.indices where (aufgaben[i].serie ?? aufgaben[i].id) == k { aufgaben[i].wiederholung = .nie }
            return
        }
        if !a.einmalig && !a.erledigt { wiederholungAnlegen(nach: a, heute: heute) }
        aufgaben.removeAll { $0.id == id }
    }

    // MARK: Habits und Schritte

    mutating func habitUmschalten(_ id: UUID, am tag: Tag) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        if habits[i].erledigt.contains(tag) { habits[i].erledigt.remove(tag) } else { habits[i].erledigt.insert(tag) }
    }

    mutating func schrittUmschalten(ziel zid: UUID, schritt sid: UUID) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }),
              let s = ziele[g].schritte.firstIndex(where: { $0.id == sid }) else { return }
        ziele[g].schritte[s].geschafft.toggle()
    }

    /// Gelöschter Schritt: seine Aufgaben werden „Keiner – nur Einsatz“.
    mutating func schrittLoeschen(ziel zid: UUID, schritt sid: UUID) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }) else { return }
        ziele[g].schritte.removeAll { $0.id == sid }
        for i in aufgaben.indices where aufgaben[i].schrittID == sid { aufgaben[i].schrittID = nil }
    }

    // MARK: Fokus-Timer

    mutating func timerStarten(_ aufgabeID: UUID, jetzt: Date, kalender: Calendar = .kompass) {
        if let t = timer, t.aufgabeID != aufgabeID { timerStoppen(jetzt: jetzt, kalender: kalender) }
        if timer == nil { timer = LaufenderTimer(aufgabeID: aufgabeID, laeuftSeit: jetzt) }
        else if timer?.laeuftSeit == nil { timer?.laeuftSeit = jetzt }
    }

    mutating func timerPausieren(jetzt: Date) {
        guard let seit = timer?.laeuftSeit else { return }
        timer?.abschnitte.append(.init(start: seit, ende: max(seit, jetzt)))
        timer?.laeuftSeit = nil
    }

    /// Bucht die Zeit (ab 15 Sekunden) als Fokus-Sitzungen je Kalendertag. Gibt die Buchung zurück.
    @discardableResult
    mutating func timerStoppen(jetzt: Date, kalender: Calendar = .kompass) -> FokusRechnung.Buchung? {
        guard timer != nil else { return nil }
        timerPausieren(jetzt: jetzt)
        guard let t = timer else { return nil }
        timer = nil
        let b = FokusRechnung.buchen(t.abschnitte, kalender: kalender)
        if let i = aufgaben.firstIndex(where: { $0.id == t.aufgabeID }), b.gesamt > 15 {
            aufgaben[i].fokusSekunden += b.gesamt
            for (tag, s) in b.proTag.sorted(by: { $0.key < $1.key }) {
                sitzungen.append(FokusSitzung(aufgabeID: t.aufgabeID, zielID: aufgaben[i].zielID, schrittID: aufgaben[i].schrittID, tag: tag, sekunden: s))
            }
        }
        return b
    }

    /// Laufende Sekunden (höchstens 4 Stunden).
    func timerSekunden(jetzt: Date) -> TimeInterval {
        guard let t = timer else { return 0 }
        let fertig = t.abschnitte.reduce(0) { $0 + $1.ende.timeIntervalSince($1.start) }
        return min(FokusRechnung.hoechstens, fertig + (t.laeuftSeit.map { jetzt.timeIntervalSince($0) } ?? 0))
    }

    // MARK: Verlauf

    mutating func verlaufFortschreiben(heute: Tag) {
        for g in ziele {
            verlauf[g.id] = Kurs.verlaufFortschreiben(verlauf[g.id] ?? [], wert: Fortschritt.ziel(g, in: self, heute: heute), heute: heute)
        }
    }
}
