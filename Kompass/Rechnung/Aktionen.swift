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

    /// Abhaken = ganze Menge; bei vollem Tag wieder leeren.
    mutating func habitUmschalten(_ id: UUID, am tag: Tag) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[i].umschalten(am: tag)
    }

    /// Teilmenge eintragen (z. B. 12 von 20 Minuten).
    mutating func habitEintragen(_ id: UUID, menge: Double, am tag: Tag) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[i].eintragen(menge, am: tag)
    }

    mutating func habitSpeichern(_ h: Habit) {
        if let i = habits.firstIndex(where: { $0.id == h.id }) { habits[i] = h } else { habits.append(h) }
    }

    /// Abhaken / wieder öffnen. Ein abgehakter Zeit-Meilenstein wird gelernt: tatsächlich ÷ geplant (§7).
    mutating func schrittUmschalten(ziel zid: UUID, schritt sid: UUID, heute: Tag) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }),
              let s = ziele[g].schritte.firstIndex(where: { $0.id == sid }) else { return }
        ziele[g].schritte[s].geschafft.toggle()
        let x = ziele[g].schritte[s]
        if x.geschafft, x.art == .zeit, let soll = x.soll, soll > 0 {
            let h = Fortschritt.stunden(von: x, in: self, heute: heute)
            if h > 0 { lernen.zeitVerhaeltnisse = Array((lernen.zeitVerhaeltnisse + [(h / soll * 1000).rounded() / 1000]).suffix(30)) }
        }
    }

    /// Meilenstein anlegen oder ersetzen (gleiche id).
    mutating func schrittSpeichern(_ x: Schritt, ziel zid: UUID) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }) else { return }
        if let i = ziele[g].schritte.firstIndex(where: { $0.id == x.id }) { ziele[g].schritte[i] = x } else { ziele[g].schritte.append(x) }
    }

    mutating func schrittVerschieben(ziel zid: UUID, von: IndexSet, nach: Int) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }) else { return }
        ziele[g].schritte.move(fromOffsets: von, toOffset: nach)
    }

    /// Neuen Stand eines Zahl-Meilensteins eintragen (wird im Verlauf gespeichert; ein Wert pro Tag).
    mutating func zahlEintragen(_ wert: Double, ziel zid: UUID, schritt sid: UUID, heute: Tag) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }),
              let s = ziele[g].schritte.firstIndex(where: { $0.id == sid }), wert.isFinite else { return }
        ziele[g].schritte[s].aktuell = wert
        var v = ziele[g].schritte[s].verlauf ?? []
        v.removeAll { $0.tag == heute }
        v.append(VerlaufPunkt(tag: heute, wert: wert))
        ziele[g].schritte[s].verlauf = v.sorted { $0.tag < $1.tag }
    }

    // MARK: Verknüpfen mit Zielen

    /// Aufgabe einem Ziel (und optional einem Meilenstein) zuordnen. Ohne Meilenstein: nächster offener.
    mutating func aufgabeZuordnen(_ aid: UUID, ziel zid: UUID?, schritt sid: UUID? = nil, automatisch: Bool = true, heute: Tag) {
        guard let i = aufgaben.firstIndex(where: { $0.id == aid }) else { return }
        aufgaben[i].zielID = zid
        aufgaben[i].schrittID = zid == nil ? nil : (sid ?? (automatisch ? Fortschritt.naechsterOffenerSchritt(ziel(zid), in: self, heute: heute)?.id : nil))
    }

    /// Habit mit Ziel verbinden; optional zählt er als Meilenstein (Anzahl oder Wochen).
    mutating func habitVerknuepfen(_ hid: UUID, ziel zid: UUID, alsMeilenstein modus: HabitModus?, soll: Double, heute: Tag) {
        guard let i = habits.firstIndex(where: { $0.id == hid }) else { return }
        habits[i].zielID = zid
        if let modus {
            let x = Schritt(titel: habits[i].titel, art: .habit, seit: heute, soll: soll, habitID: hid, habitModus: modus)
            schrittSpeichern(x, ziel: zid)
        }
    }

    /// Habit vom Ziel lösen: Verbindung und seine Habit-Meilensteine in diesem Ziel fallen weg.
    mutating func habitLoesen(_ hid: UUID, ziel zid: UUID) {
        if let i = habits.firstIndex(where: { $0.id == hid }), habits[i].zielID == zid { habits[i].zielID = nil }
        if let g = ziele.firstIndex(where: { $0.id == zid }) {
            let weg = ziele[g].schritte.filter { $0.art == .habit && $0.habitID == hid }.map(\.id)
            for sid in weg { schrittLoeschen(ziel: zid, schritt: sid) }
        }
    }

    /// Habit löschen: auch aus allen Meilensteinen (die bleiben, zeigen „Habit wählen“).
    mutating func habitLoeschen(_ hid: UUID) {
        habits.removeAll { $0.id == hid }
    }

    /// Termin-Serie einem Ziel und optional einem Meilenstein zuordnen (ab heute, nur stattgefundene Termine zählen).
    mutating func terminVerknuepfen(serie: String, titel: String, ziel zid: UUID, schritt sid: UUID?, seit: Tag) {
        termine.removeAll { $0.serie == serie && $0.zielID == zid }
        termine.append(TerminVerknuepfung(serie: serie, titel: titel, zielID: zid, schrittID: sid, seit: seit))
    }

    mutating func terminLoesen(_ id: UUID) { termine.removeAll { $0.id == id } }

    /// Termin-Serie (Apple/Google) für ein Ziel zählen lassen oder lösen (Termin-Seite im Kalender).
    /// Wechselt das Ziel, wird die alte Verknüpfung ersetzt; bleibt es gleich, bleibt `seit` erhalten.
    mutating func terminSerieZaehlen(serie: String, titel: String, ziel zid: UUID?, schritt sid: UUID?, seit: Tag) {
        if let zid, let i = termine.firstIndex(where: { $0.serie == serie && $0.zielID == zid }) {
            termine[i].schrittID = sid
            termine.removeAll { $0.serie == serie && $0.zielID != zid }
            return
        }
        termine.removeAll { $0.serie == serie }
        guard let zid else { return }
        termine.append(TerminVerknuepfung(serie: serie, titel: titel, zielID: zid, schrittID: sid, seit: seit))
    }

    /// Stattgefundene Termine der verknüpften Serien übernehmen (nur Tag und Dauer). `quelle` liefert die Termine eines Tages.
    /// `jetzt` (Minuten seit Mitternacht): heutige Termine zählen erst, wenn sie vorbei sind. nil = der ganze Tag zählt (Tagesende).
    mutating func termineAbgleichen(heute: Tag, jetzt: Int? = nil, quelle: (Tag) -> [Termin]) {
        for i in termine.indices {
            let l = termine[i]
            // Heute wird jedes Mal neu geprüft (Termin kann noch dazukommen), frühere Tage nur einmal.
            var neu = l.vorkommen.filter { $0.tag >= l.seit && $0.tag < heute && $0.tag <= (l.abgeglichenBis ?? l.seit.plus(tage: -1)) }
            var d = max(l.seit, (l.abgeglichenBis ?? l.seit.plus(tage: -1)).plus(tage: 1))
            if d > heute { d = heute }
            while d <= heute {
                for t in quelle(d) where "\(t.quelle.rawValue):\(t.schluessel)" == l.serie {
                    guard let a = t.start, let e = t.ende else { continue }
                    if d == heute, let j = jetzt, e > j { continue } // heute noch nicht vorbei → zählt noch nicht
                    neu.append(TerminVorkommen(tag: d, minuten: max(0, e - a)))
                }
                d = d.plus(tage: 1)
            }
            termine[i].vorkommen = neu.sorted { $0.tag < $1.tag }
            termine[i].abgeglichenBis = heute.plus(tage: -1)
        }
    }

    /// Ziel löschen: Aufgaben, Habits und Termine bleiben, verlieren nur die Zuordnung.
    mutating func zielLoeschen(_ zid: UUID) {
        ziele.removeAll { $0.id == zid }
        for i in aufgaben.indices where aufgaben[i].zielID == zid { aufgaben[i].zielID = nil; aufgaben[i].schrittID = nil }
        for i in habits.indices where habits[i].zielID == zid { habits[i].zielID = nil }
        for i in sitzungen.indices where sitzungen[i].zielID == zid { sitzungen[i].zielID = nil; sitzungen[i].schrittID = nil }
        termine.removeAll { $0.zielID == zid }
        verlauf[zid] = nil
    }

    /// Gelöschter Schritt: seine Aufgaben werden „Keiner – nur Einsatz“.
    mutating func schrittLoeschen(ziel zid: UUID, schritt sid: UUID) {
        guard let g = ziele.firstIndex(where: { $0.id == zid }) else { return }
        ziele[g].schritte.removeAll { $0.id == sid }
        for i in aufgaben.indices where aufgaben[i].schrittID == sid { aufgaben[i].schrittID = nil }
        for i in sitzungen.indices where sitzungen[i].schrittID == sid { sitzungen[i].schrittID = nil }
        for i in termine.indices where termine[i].schrittID == sid { termine[i].schrittID = nil }
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

// MARK: Kalender (Struktur v3): einplanen, eigene Termine, Habits aus Terminen

extension Zustand {

    /// Aufgabe in den Kalender legen: Tag (und optional Uhrzeit). `uhrzeit: nil` = ganzer Tag ohne Uhrzeit.
    mutating func aufgabeEinplanen(_ id: UUID, tag: Tag?, uhrzeit: Int?) {
        guard let i = aufgaben.firstIndex(where: { $0.id == id }) else { return }
        aufgaben[i].datum = tag
        aufgaben[i].uhrzeit = tag == nil ? nil : uhrzeit.map { min(max($0, 0), 24 * 60 - 5) }
    }

    /// Habit an einem Tag zu einer Uhrzeit planen (nur dieser Tag); nil = an diesem Tag ohne Uhrzeit (auch wenn eine feste Uhrzeit gilt).
    mutating func habitEinplanen(_ id: UUID, tag: Tag, uhrzeit: Int?) {
        guard let i = habits.firstIndex(where: { $0.id == id }) else { return }
        if let u = uhrzeit { habits[i].planZeiten[tag] = min(max(u, 0), 24 * 60 - 5) }
        else { habits[i].planZeiten[tag] = habits[i].uhrzeit == nil ? nil : -1 }
    }

    /// Eigenen Termin anlegen oder ändern; zählt er für ein Ziel, wird die Serie verknüpft (Einsatz bzw. Meilenstein Zeit/Zahl).
    mutating func terminSpeichern(_ t: EigenerTermin) {
        if let i = eigeneTermine.firstIndex(where: { $0.id == t.id }) { eigeneTermine[i] = t } else { eigeneTermine.append(t) }
        let serie = "kompass:\(t.id.uuidString)"
        termine.removeAll { $0.serie == serie }
        if let z = t.zielID, ziel(z) != nil {
            termine.append(TerminVerknuepfung(serie: serie, titel: t.titel, zielID: z, schrittID: t.schrittID, seit: t.tag))
        }
    }

    mutating func terminLoeschen(_ id: UUID) {
        eigeneTermine.removeAll { $0.id == id }
        termine.removeAll { $0.serie == "kompass:\(id.uuidString)" }
    }

    /// Termine mit Habit: ist der Termin vorbei, ist der Habit an dem Tag erfüllt (nur wenn noch nichts eingetragen ist).
    mutating func habitsAusTerminen(heute: Tag, jetzt: Int) {
        for i in eigeneTermine.indices {
            let t = eigeneTermine[i]
            guard let hid = t.habitID, let h = habits.firstIndex(where: { $0.id == hid }) else { continue }
            var d = max(t.tag, (t.habitBis ?? t.tag.plus(tage: -1)).plus(tage: 1))
            var bis = t.habitBis
            while d <= heute {
                if d == heute && t.ende > jetzt { break }
                if t.findetStatt(am: d), habits[h].eintraege[d] == nil { habits[h].eintraege[d] = habits[h].menge ?? 1 }
                bis = d
                d = d.plus(tage: 1)
            }
            eigeneTermine[i].habitBis = bis
        }
    }
}
