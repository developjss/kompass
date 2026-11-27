import Foundation

// Werkzeuge des Lotsen: alles, was er wissen oder tun kann, geht über ein Werkzeug.
// Ein Sprachmodell wählt höchstens das Werkzeug und seine Parameter – gerechnet und geändert wird hier, deterministisch.
// Neues Werkzeug = ein Eintrag in `Werkzeuge.alle` + ein Fall in `Werkzeuge.ausfuehren` + Regeln in `Verstehen`.

struct Werkzeug: Sendable, Hashable {
    enum Name: String, CaseIterable, Sendable {
        case heute, naechstes, tagesplan, woche, freieZeit, aufgabeAnlegen, terminAnlegen, ziele, ziel, fortschrittErklaeren, habits, analyse, hilfe, empfehlen, merken, signale
    }

    let name: Name
    let beschreibung: String
    /// Parameter: Name → Beschreibung
    let parameter: [String: String]
    /// Beispielfragen – auch die Vorschläge im leeren Chat
    let beispiele: [String]
}

/// Aufruf eines Werkzeugs mit erkannten Parametern
struct WerkzeugAufruf: Sendable, Hashable {
    var name: Werkzeug.Name
    var parameter: [String: String] = [:]
}

/// Antwort des Lotsen
struct LotseAntwort: Sendable, Hashable {
    var text: String
    var werkzeug: Werkzeug.Name?
    var aktion: ChatNachricht.Aktion?
    /// Frage hat kein Werkzeug getroffen → fürs Lernen merken
    var unbeantwortet = false
}

enum Werkzeuge {

    static let alle: [Werkzeug] = [
        Werkzeug(name: .heute, beschreibung: "Was heute ansteht: offene Aufgaben (wichtig/weitere), fällige Habits, Termine, Fokuszeit.",
                 parameter: [:], beispiele: ["Was steht heute an?", "Was ist jetzt dran?"]),
        Werkzeug(name: .naechstes, beschreibung: "Die nächsten drei Einträge mit Uhrzeit (Termine, Aufgaben, Habits) ab jetzt, bis 7 Tage voraus.",
                 parameter: [:], beispiele: ["Was steht als Nächstes an?", "Was kommt als Nächstes?"]),
        Werkzeug(name: .tagesplan, beschreibung: "Wie voll ein Tag ist: verplant, frei, längste Lücke, Hinweise (enger Tag, Überschneidung, zu wenig Zeit für Offenes).",
                 parameter: ["tag": "heute | morgen | Wochentag"], beispiele: ["Wie voll ist mein Tag?", "Ist morgen noch Platz für Sport?"]),
        Werkzeug(name: .woche, beschreibung: "Überblick über die Woche: Termine und Aufgaben je Tag.",
                 parameter: ["zeitraum": "diese | naechste"], beispiele: ["Wie sieht meine Woche aus?", "Was steht nächste Woche an?"]),
        Werkzeug(name: .freieZeit, beschreibung: "Freie Zeitfenster (8–20 Uhr, ab 30 Minuten) zwischen Terminen und Aufgaben mit Uhrzeit.",
                 parameter: ["zeitraum": "heute | morgen | woche"], beispiele: ["Wann habe ich diese Woche Zeit?", "Habe ich morgen Zeit?"]),
        Werkzeug(name: .aufgabeAnlegen, beschreibung: "Legt eine Aufgabe an. Fällt automatisch in den nächsten offenen Meilenstein, wenn ein Ziel genannt ist.",
                 parameter: ["titel": "Text", "datum": "heute | morgen | Wochentag | TT.MM. | leer = Eingang", "wichtig": "ja | nein", "ziel": "Name eines Ziels"],
                 beispiele: ["Erstelle Aufgabe: Flugschule anrufen morgen", "Neue Aufgabe für Führerschein: Fragebogen Kapitel 5"]),
        Werkzeug(name: .terminAnlegen, beschreibung: "Legt einen Termin in Kompass an (Titel, Tag, von–bis). Zählt für ein Ziel, wenn eins genannt ist.",
                 parameter: ["titel": "Text", "datum": "heute | morgen | Wochentag | TT.MM.", "start": "HH:MM", "ende": "HH:MM (optional, sonst 1 h)", "ziel": "Name eines Ziels (optional)"],
                 beispiele: ["Trag morgen 15 Uhr Zahnarzt ein", "Neuer Termin: Fahrstunde Freitag 17:00 bis 18:30"]),
        Werkzeug(name: .ziele, beschreibung: "Alle aktiven Ziele mit Prozent, Auf Kurs und Frist.",
                 parameter: [:], beispiele: ["Wie stehen meine Ziele?", "Welches Ziel hinkt?"]),
        Werkzeug(name: .ziel, beschreibung: "Ein Ziel im Detail: Meilensteine mit Stand, Prognose, Einsatz, offene Aufgaben.",
                 parameter: ["ziel": "Name eines Ziels"], beispiele: ["Wie läuft der Führerschein?", "Zeig mir das Ziel Fit"]),
        Werkzeug(name: .fortschrittErklaeren, beschreibung: "Erklärt kurz, woher die Prozent eines Ziels kommen (Beitrag je Meilenstein) und was als Nächstes am meisten bringt.",
                 parameter: ["ziel": "Name eines Ziels"], beispiele: ["Warum steht der Führerschein bei 54 %?", "Was bringt beim LAPL am meisten?"]),
        Werkzeug(name: .habits, beschreibung: "Habits mit Serie, Quote und ob sie heute geplant sind; optional ein Habit im Detail.",
                 parameter: ["habit": "Name eines Habits (optional)"], beispiele: ["Wie laufen meine Habits?", "Wie ist meine Lese-Serie?"]),
        Werkzeug(name: .analyse, beschreibung: "Analyse der Woche: Fokuszeit, Anteil für Ziele, Zeit je Ziel, Habit-Quote, erledigte Aufgaben.",
                 parameter: ["zeitraum": "diese | letzte"], beispiele: ["Wie lief meine Woche?", "Wie viel Fokuszeit hatte ich letzte Woche?"]),
        Werkzeug(name: .hilfe, beschreibung: "Erklärt die App: Bereiche, Fenster, Rechenregeln, erste Schritte.",
                 parameter: ["thema": "Begriff oder Frage"], beispiele: ["Wie fange ich an?", "Wie wird der Fortschritt gerechnet?", "Wo finde ich den Fokus-Timer?"]),
        Werkzeug(name: .empfehlen, beschreibung: "Empfiehlt, womit du anfangen solltest: Liegengebliebenes, Ziele hinterher, wichtige Aufgaben – mit Begründung.",
                 parameter: ["zeitraum": "heute | woche"], beispiele: ["Was soll ich diese Woche zuerst machen?", "Worauf soll ich mich konzentrieren?"]),
        Werkzeug(name: .signale, beschreibung: "Was gerade wichtig ist – dieselben Signale wie auf Home unter „Wichtig“ (Rechenregel §12): volle Tage, Überschneidungen, zu wenig Zeit, Liegengebliebenes, Ziele hinter Plan, nahe Fristen, Serien in Gefahr, freie Tage. Nach Rang sortiert.",
                 parameter: [:], beispiele: ["Was ist gerade wichtig?", "Wo wird es eng?"]),
        Werkzeug(name: .merken, beschreibung: "Merkt sich etwas Dauerhaftes über den Nutzer (Vorlieben, Gewohnheiten, Umstände, z. B. „trainiert lieber morgens“, „wohnt in Ulm“) – nur auf dem Gerät, der Nutzer kann es löschen. Nur nutzen, wenn der Nutzer es sagt oder es für künftige Antworten klar hilft; nichts Sensibles (Gesundheit, Geld, Dritte) ohne Bitte. „vergessen“ entfernt passende Einträge.",
                 parameter: ["notiz": "kurzer Satz in der dritten Person", "vergessen": "Stichwort eines Eintrags, der weg soll (optional)"],
                 beispiele: ["Merk dir: Ich trainiere lieber morgens.", "Vergiss, dass ich in Ulm wohne."]),
    ]

    static func werkzeug(_ n: Werkzeug.Name) -> Werkzeug { alle.first { $0.name == n }! }

    /// Beispielfragen für den leeren Chat (eine je Werkzeug, ohne Hilfe-Dopplung)
    static var vorschlaege: [String] { [Werkzeug.Name.naechstes, .tagesplan, .ziele, .fortschrittErklaeren, .terminAnlegen, .hilfe].map { werkzeug($0).beispiele[0] } }

    // MARK: Ausführen (nur lesen) – Änderungen laufen über `Lotse`, damit der Speicher sie sichert

    @MainActor
    static func ausfuehren(_ a: WerkzeugAufruf, z: Zustand, heute T: Tag, jetzt: Date, kalender: Calendar) -> LotseAntwort {
        switch a.name {
        case .heute: return heute(z, T, jetzt)
        case .naechstes: return naechstes(z, T, minuten(jetzt, kalender))
        case .tagesplan: return tagesplan(z, T, minuten(jetzt, kalender), tag: a.parameter["tag"].flatMap { Tag(text: $0) } ?? T)
        case .terminAnlegen: return LotseAntwort(text: "Dafür brauche ich Titel, Tag und Uhrzeit.", werkzeug: .terminAnlegen) // echte Anlage in Lotse
        case .woche: return woche(z, T, naechste: a.parameter["zeitraum"] == "naechste")
        case .freieZeit: return freieZeit(z, T, a.parameter["zeitraum"] ?? "woche")
        case .aufgabeAnlegen: return LotseAntwort(text: "Dafür brauche ich einen Titel.", werkzeug: .aufgabeAnlegen) // echte Anlage in Lotse
        case .ziele: return ziele(z, T)
        case .ziel: return ziel(z, T, name: a.parameter["ziel"])
        case .fortschrittErklaeren: return erklaeren(z, T, name: a.parameter["ziel"])
        case .habits: return habits(z, T, name: a.parameter["habit"])
        case .analyse: return analyse(z, T, kalender, letzte: a.parameter["zeitraum"] == "letzte")
        case .hilfe: return hilfe(a.parameter["thema"] ?? "")
        case .empfehlen: return empfehlen(z, T, woche: a.parameter["zeitraum"] == "woche", jetzt: minuten(jetzt, kalender))
        case .merken: return LotseAntwort(text: "Was soll ich mir merken?", werkzeug: .merken) // echtes Merken in Lotse
        case .signale: return signale(z, T, jetzt: minuten(jetzt, kalender))
        }
    }

    /// Terminquelle der App (mit Apple-Kalender); gesetzt von `Lotse`, sonst Kompass- und Beispieltermine.
    /// Nur auf dem Haupt-Thread gesetzt und gelesen (Lotse läuft dort).
    nonisolated(unsafe) static var quelle: ((Tag) -> [Termin])?

    private static func termine(_ z: Zustand, _ d: Tag, _ T: Tag) -> [Termin] {
        quelle?(d) ?? Kalenderquelle.termine(am: d, zustand: z, heute: T)
    }

    private static func minuten(_ d: Date, _ k: Calendar) -> Int {
        let c = k.dateComponents([.hour, .minute], from: d); return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func naechstes(_ z: Zustand, _ T: Tag, _ jetzt: Int) -> LotseAntwort {
        let n = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: { termine(z, $0, T) })
        guard !n.isEmpty else {
            return LotseAntwort(text: "In den nächsten 7 Tagen steht nichts mit Uhrzeit an. Im Kalender kannst du Aufgaben in einen Tag ziehen.", werkzeug: .naechstes, aktion: .bereich(Bereich.kalender.rawValue))
        }
        var zeilen = ["Als Nächstes:"]
        for b in n {
            var t = "• \(Tagesplan.wannText(b, heute: T, jetzt: jetzt)): \(b.titel)"
            if let g = z.ziel(b.zielID) { t += " (\(g.titel))" }
            zeilen.append(t)
        }
        let h = Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: { termine(z, $0, T) }, tage: 1)
        if let x = h.first { zeilen.append("Achtung: \(x.text).") }
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .naechstes, aktion: .bereich(Bereich.kalender.rawValue))
    }

    static func tagesplan(_ z: Zustand, _ T: Tag, _ jetzt: Int, tag d: Tag) -> LotseAntwort {
        let b = Tagesplan.bloecke(am: d, zustand: z, termine: termine(z, d, T))
        let a = Tagesplan.auslastung(b, ab: d == T ? jetzt : Tagesplan.wachVon)
        let frei = d == T ? Tagesplan.freiAb(b, ab: jetzt) : a.frei
        var zeilen = ["\(tagText(d, T)): \(Zahl.dauer(TimeInterval(a.verplant * 60))) verplant, \(Zahl.dauer(TimeInterval(frei * 60))) frei\(d == T ? " ab jetzt" : "") (7–22 Uhr)."]
        if a.laengsteLuecke >= 30 { zeilen.append("Längste Lücke: \(Zahl.dauer(TimeInterval(a.laengsteLuecke * 60))).") }
        let ohne = Tagesplan.ohneZeit(am: d, zustand: z)
        let offen = ohne.habits.filter { !$0.voll(am: d) }.map { "\($0.titel) (\($0.dauerMinuten) Min)" } + ohne.aufgaben.filter { !$0.erledigt }.map { "\($0.titel) (\($0.dauer) Min)" }
        if !offen.isEmpty { zeilen.append("Noch ohne Uhrzeit: " + Satz.liste(Array(offen.prefix(4))) + ".") }
        for h in Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: { termine(z, $0, T) }, tage: max(1, T.tage(bis: d) + 1)) where h.tag == d {
            zeilen.append(h.art == .eng ? "Das ist ein enger Tag – neue Termine besser auf einen anderen Tag legen." : "Achtung: \(h.text).")
        }
        if !a.eng && frei >= 60 { zeilen.append("Es ist noch Platz – im Kalender ziehst du etwas in eine Lücke.") }
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .tagesplan, aktion: .bereich(Bereich.kalender.rawValue))
    }

    private static let wochentage = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    private static func tagText(_ d: Tag, _ T: Tag) -> String {
        if d == T { return "Heute" }
        if d == T.plus(tage: 1) { return "Morgen" }
        return "\(wochentage[d.wochentag - 1]) \(d.tag).\(d.monat)."
    }

    static func heute(_ z: Zustand, _ T: Tag, _ jetzt: Date) -> LotseAntwort {
        let offen = z.aufgaben.filter { $0.datum == T && !$0.erledigt }.sorted { $0.reihenfolge < $1.reihenfolge }
        let wichtig = offen.filter { $0.prio == .hoch }, weitere = offen.filter { $0.prio != .hoch }
        let erledigt = z.aufgaben.filter { a in a.erledigt && a.erledigtAm.map { Tag($0) == T } == true }.count
        let habits = z.habits.filter { HabitRechnung.geplant($0, am: T) }
        let offeneHabits = habits.filter { !$0.voll(am: T) }
        let termine = termine(z, T, T).filter { $0.start != nil }
        let fokus = z.sitzungen.filter { $0.tag == T }.reduce(0) { $0 + $1.sekunden } + z.timerSekunden(jetzt: jetzt)
        var zeilen: [String] = []
        if let jetztDran = wichtig.first ?? weitere.first {
            zeilen.append("Als Nächstes ist „\(jetztDran.titel)“ dran" + (z.ziel(jetztDran.zielID).map { " – das zahlt auf \($0.titel) ein." } ?? "."))
        } else if offen.isEmpty && erledigt > 0 {
            zeilen.append("Für heute ist alles erledigt – \(erledigt) Aufgabe\(erledigt == 1 ? "" : "n") geschafft.")
        } else {
            zeilen.append("Heute steht noch keine Aufgabe an.")
        }
        let rest = max(0, wichtig.count - 1)
        if rest > 0 || !weitere.isEmpty {
            var teile: [String] = []
            if rest > 0 { teile.append("\(rest) weitere wichtige") }
            if !weitere.isEmpty { teile.append("\(weitere.count) kleinere") }
            zeilen.append("Danach warten " + teile.joined(separator: " und ") + " Aufgabe\(rest + weitere.count == 1 ? "" : "n")" + (erledigt > 0 ? "; \(erledigt) hast du schon geschafft." : "."))
        }
        if !offeneHabits.isEmpty { zeilen.append("Habits noch offen: " + Satz.liste(offeneHabits.map(\.titel)) + ".") }
        else if !habits.isEmpty { zeilen.append("Alle Habits für heute sind abgehakt.") }
        if !termine.isEmpty { zeilen.append("Termine: " + Satz.liste(termine.map { "\($0.titel) um \(Beispieltermine.uhrzeit($0.start!))" }) + ".") }
        if fokus > 0 { zeilen.append("Fokus bisher \(Zahl.dauer(fokus)).") }
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .heute, aktion: .bereich(Bereich.heute.rawValue))
    }

    static func woche(_ z: Zustand, _ T: Tag, naechste: Bool) -> LotseAntwort {
        let montag = T.montag.plus(tage: naechste ? 7 : 0)
        var zeilen: [String] = []
        for i in 0..<7 {
            let d = montag.plus(tage: i)
            if !naechste && d < T { continue }
            let te = termine(z, d, T).filter { $0.start != nil }.map { "\(Beispieltermine.uhrzeit($0.start!)) \($0.titel)" }
            let au = z.aufgaben.filter { $0.datum == d && !$0.erledigt }.map(\.titel)
            let teile = te + au.prefix(3).map { "Aufgabe: \($0)" } + (au.count > 3 ? ["+\(au.count - 3) Aufgaben"] : [])
            zeilen.append("\(tagText(d, T)): " + (teile.isEmpty ? "frei" : teile.joined(separator: " · ")))
        }
        let n = z.aufgaben.filter { a in a.datum.map { $0 >= montag && $0 <= montag.plus(tage: 6) } == true && !a.erledigt }.count
        return LotseAntwort(text: "\(naechste ? "Nächste" : "Diese") Woche \(n == 1 ? "steht eine offene Aufgabe" : "stehen \(n) offene Aufgaben") an.\n" + zeilen.joined(separator: "\n"),
                            werkzeug: .woche, aktion: .bereich(Bereich.kalender.rawValue))
    }

    static func freieZeit(_ z: Zustand, _ T: Tag, _ zeitraum: String) -> LotseAntwort {
        let tage: [Tag] = zeitraum == "heute" ? [T] : zeitraum == "morgen" ? [T.plus(tage: 1)] : (0..<7).map { T.plus(tage: $0) }
        var zeilen: [String] = []
        var gesamt = 0
        for d in tage {
            let f = Zeitfenster.frei(termine: termine(z, d, T), aufgaben: z.aufgaben.filter { $0.datum == d })
            gesamt += f.reduce(0) { $0 + $1.minuten }
            let groesste = f.sorted { $0.minuten > $1.minuten }.prefix(2).sorted { $0.start < $1.start }
            zeilen.append("\(tagText(d, T)): " + (groesste.isEmpty ? "voll" : groesste.map { "\(Zeitfenster.text($0)) (\(Zahl.dauer(Double($0.minuten) * 60)))" }.joined(separator: ", ")))
        }
        let kopf = tage.count == 1 ? "Zwischen 8 und 20 Uhr hast du \(Zahl.dauer(Double(gesamt) * 60)) frei." : "In den nächsten sieben Tagen hast du rund \(gesamt / 60) Stunden frei (8–20 Uhr, ohne Termine und geplante Aufgaben). Die größten Lücken:"
        return LotseAntwort(text: kopf + "\n" + zeilen.joined(separator: "\n"), werkzeug: .freieZeit, aktion: .bereich(Bereich.kalender.rawValue))
    }

    static func ziele(_ z: Zustand, _ T: Tag) -> LotseAntwort {
        let aktiv = z.ziele.filter { $0.status == .aktiv }.sorted { $0.faellig < $1.faellig }
        guard !aktiv.isEmpty else { return LotseAntwort(text: "Du hast noch kein Ziel. Leg eins an: Tab Ziele → „Ziel hinzufügen“.", werkzeug: .ziele, aktion: .bereich(Bereich.ziele.rawValue)) }
        let kurse = aktiv.map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
        let hinten = kurse.filter { [.hinterher, .ueberfaellig].contains($0.1.lage) }
        let kopf = hinten.isEmpty
            ? "Deine \(aktiv.count) Ziele liegen im Plan oder voraus."
            : (hinten.count == 1 ? "Ein Ziel braucht Aufmerksamkeit: \(hinten[0].0.titel) liegt \(hinten[0].1.lage.text)." : "\(hinten.count) Ziele liegen hinterher: " + Satz.liste(hinten.map(\.0.titel)) + ".")
        let zeilen = kurse.map { g, k in "• \(g.titel): \(Zahl.prozent(k.fortschritt)) · \(k.lage.text) · \(Kurs.bisText(g.faellig, heute: T))" }
        return LotseAntwort(text: ([kopf] + zeilen).joined(separator: "\n"), werkzeug: .ziele, aktion: .bereich(Bereich.ziele.rawValue))
    }

    /// Ziel nach Name finden: bestes Wort-Überlappen, mindestens ein Wort mit 4+ Zeichen
    static func findeZiel(_ name: String?, in z: Zustand) -> Ziel? {
        guard let name, !name.isEmpty else { return nil }
        let w = Verstehen.woerter(name)
        var bestes: (Ziel, Int)?
        for g in z.ziele {
            let treffer = Verstehen.woerter(g.titel).filter { wort in w.contains { $0.hasPrefix(wort) || wort.hasPrefix($0) } }.count
            if treffer > 0, treffer > (bestes?.1 ?? 0) { bestes = (g, treffer) }
        }
        return bestes?.0
    }

    static func findeHabit(_ name: String?, in z: Zustand) -> Habit? {
        guard let name, !name.isEmpty else { return nil }
        let w = Verstehen.woerter(name)
        return z.habits.max { a, b in
            Verstehen.woerter(a.titel).filter { x in w.contains { $0.hasPrefix(x) || x.hasPrefix($0) } }.count
                < Verstehen.woerter(b.titel).filter { x in w.contains { $0.hasPrefix(x) || x.hasPrefix($0) } }.count
        }.flatMap { h in Verstehen.woerter(h.titel).contains { x in w.contains { $0.hasPrefix(x) || x.hasPrefix($0) } } ? h : nil }
    }

    static func ziel(_ z: Zustand, _ T: Tag, name: String?) -> LotseAntwort {
        guard let g = findeZiel(name, in: z) else {
            let namen = z.ziele.filter { $0.status == .aktiv }.map(\.titel).joined(separator: ", ")
            return LotseAntwort(text: "Welches Ziel meinst du? Du hast: \(namen).", werkzeug: .ziel)
        }
        let k = Kurs.aufKurs(g, in: z, heute: T)
        var t = "\(g.titel): \(Zahl.prozent(k.fortschritt)) · \(k.lage.text) · \(Kurs.bisText(g.faellig, heute: T))."
        switch Kurs.prognose(verlauf: z.verlauf[g.id] ?? [], fortschritt: k.fortschritt, heute: T) {
        case .datum(let d, _, _): t += " Im jetzigen Tempo erreicht: \(d.monat).\(d.jahr)."
        case .keinFortschritt: t += " Zuletzt kein messbarer Fortschritt."
        case .keine: break
        }
        if g.schritte.isEmpty { t += "\nNoch keine Meilensteine – ohne sie bleibt das Ziel bei 0 %." }
        for s in g.schritte {
            let st = Fortschritt.stand(s, in: z, heute: T)
            t += "\n• \(s.titel): \(Zahl.prozent(st.anteil)) (\(st.text))"
        }
        let offen = z.aufgaben.filter { $0.zielID == g.id && !$0.erledigt }.count
        t += "\nEinsatz diese Woche: \(Zahl.dauer(Fortschritt.zeit(ziel: g.id, in: z, von: T.montag, bis: T))) · offene Aufgaben: \(offen)."
        return LotseAntwort(text: t, werkzeug: .ziel, aktion: .ziel(g.id))
    }

    static func erklaeren(_ z: Zustand, _ T: Tag, name: String?) -> LotseAntwort {
        guard let g = findeZiel(name, in: z) ?? (z.ziele.count == 1 ? z.ziele.first : nil) else {
            return LotseAntwort(text: "Für welches Ziel? Du hast: \(z.ziele.map(\.titel).joined(separator: ", ")).", werkzeug: .fortschrittErklaeren)
        }
        let p = Fortschritt.ziel(g, in: z, heute: T)
        var t = "\(g.titel) steht bei \(Zahl.prozent(p)), weil die Meilensteine im Schnitt so weit sind (mittel zählt doppelt, groß dreifach):"
        let beitraege = g.schritte.map { ($0, Fortschritt.beitrag($0, in: g, z: z, heute: T), Fortschritt.stand($0, in: z, heute: T)) }
        for (s, b, st) in beitraege { t += "\n• \(s.titel): \(Zahl.prozent(st.anteil))\(st.gewicht > 1 ? " ×\(st.gewicht)" : "") → +\(Zahl.text(b * 100, stellen: 1)) Punkte" }
        // Was bringt am meisten: dieselbe Rechnung wie „Dein nächster Schritt“ auf der Ziel-Seite (rechenregeln.md §10)
        if let n = Fortschritt.naechsterSchritt(g, in: z, heute: T) {
            t += "\nAm meisten bringt jetzt „\(n.schritt.titel)“ – bis zu \(Zahl.text(n.punkte * 100, stellen: 0)) Punkte, wenn du ihn abschließt."
            if let a = n.aufgabe { t += " Nächste Aufgabe dazu: „\(a.titel)“." }
        }
        return LotseAntwort(text: t, werkzeug: .fortschrittErklaeren, aktion: .ziel(g.id))
    }

    static func habits(_ z: Zustand, _ T: Tag, name: String?) -> LotseAntwort {
        if let h = findeHabit(name, in: z) {
            let t = "\(h.titel): Serie \(HabitRechnung.serie(h, heute: T)), beste \(HabitRechnung.besteSerie(h, heute: T)), Quote \(Zahl.prozent(HabitRechnung.quote(h, heute: T))) in 30 Tagen · \(HabitRechnung.haeufigkeit(h))"
                + (HabitRechnung.geplant(h, am: T) ? (h.voll(am: T) ? " · heute erledigt" : " · heute noch offen") : " · heute nicht geplant")
                + (z.ziel(h.zielID).map { " · Ziel: \($0.titel)" } ?? "")
            return LotseAntwort(text: t, werkzeug: .habits, aktion: .habit(h.id))
        }
        guard !z.habits.isEmpty else { return LotseAntwort(text: "Noch keine Habits. Leg einen an: Tab Habits → „Habit hinzufügen“.", werkzeug: .habits) }
        let offen = z.habits.filter { HabitRechnung.geplant($0, am: T) && !$0.voll(am: T) }
        let schwach = z.habits.filter { HabitRechnung.quote($0, heute: T) < 0.5 }
        let stark = z.habits.max { HabitRechnung.quote($0, heute: T) < HabitRechnung.quote($1, heute: T) }
        var zeilen: [String] = []
        zeilen.append(offen.isEmpty ? "Alle Habits für heute sind abgehakt." : "Heute noch offen: " + Satz.liste(offen.map(\.titel)) + ".")
        if let s = stark { zeilen.append("Am stabilsten läuft „\(s.titel)“ mit \(Zahl.prozent(HabitRechnung.quote(s, heute: T))) in 30 Tagen und Serie \(HabitRechnung.serie(s, heute: T)).") }
        zeilen += z.habits.map { h in "• \(h.titel): Serie \(HabitRechnung.serie(h, heute: T)) · \(Zahl.prozent(HabitRechnung.quote(h, heute: T)))" }
        if !schwach.isEmpty { zeilen.append((schwach.count == 1 ? "„\(schwach[0].titel)“ liegt unter 50 %" : Satz.liste(schwach.map(\.titel)) + " liegen unter 50 %") + " – kleiner machen oder Wochentage anpassen?") }
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .habits, aktion: .bereich(Bereich.habits.rawValue))
    }

    static func analyse(_ z: Zustand, _ T: Tag, _ kalender: Calendar, letzte: Bool) -> LotseAntwort {
        let von = T.montag.plus(tage: letzte ? -7 : 0), bis = von.plus(tage: 6)
        let woche = z.sitzungen.filter { $0.tag >= von && $0.tag <= bis }
        let gesamt = woche.reduce(0) { $0 + $1.sekunden }
        let fuerZiele = woche.filter { $0.zielID != nil }.reduce(0) { $0 + $1.sekunden }
        let jeZiel = z.ziele.map { ($0.titel, Fortschritt.zeit(ziel: $0.id, in: z, von: von, bis: bis)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        let h = HabitRechnung.quote(alle: z.habits, von: von, bis: bis, heute: T)
        let erledigt = z.aufgaben.filter { a in a.erledigtAm.map { let d = Tag($0, kalender: kalender); return d >= von && d <= bis } == true }.count
        let anteil = gesamt > 0 ? Int((fuerZiele / gesamt * 100).rounded()) : 0
        var t = "\(letzte ? "Letzte" : "Diese") Woche hast du \(Zahl.dauer(gesamt)) fokussiert gearbeitet, davon \(anteil) % für deine Ziele. \(erledigt) Aufgabe\(erledigt == 1 ? "" : "n") erledigt"
        t += h.geplant > 0 ? ", Habits zu \(Zahl.prozent(h.erledigt / Double(h.geplant))) (\(Zahl.text(h.erledigt, stellen: 1)) von \(h.geplant))." : "."
        if let erstes = jeZiel.first { t += "\nDie meiste Zeit ging in \(erstes.0) (\(Zahl.dauer(erstes.1)))" + (jeZiel.count > 1 ? ", dann " + Satz.liste(jeZiel.dropFirst().prefix(3).map { "\($0.0) (\(Zahl.dauer($0.1)))" }) + "." : ".") }
        if gesamt > 0 && fuerZiele / gesamt < 0.5 { t += "\nWeniger als die Hälfte zahlt auf Ziele ein – soll ich dir zeigen, welche Aufgaben noch kein Ziel haben?" }
        return LotseAntwort(text: t, werkzeug: .analyse, aktion: .bereich(Bereich.heute.rawValue))
    }

    static func hilfe(_ thema: String) -> LotseAntwort {
        let w = Verstehen.normal(thema)
        func treffer(_ s: String) -> Int { Verstehen.woerter(s).filter { w.contains($0) }.count }
        if w.contains("anfang") || w.contains("start") || w.contains("onboard") || w.contains("erste") || w.contains("loslegen") {
            return LotseAntwort(text: "So fängst du an:\n" + AppWissen.ersteSchritte.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"), werkzeug: .hilfe)
        }
        if w.contains("rechn") || w.contains("prozent") || w.contains("fortschritt") || w.contains("meilenstein") || w.contains("kurs") || w.contains("prognose") {
            let passend = AppWissen.regeln.filter { treffer($0) > 0 }
            return LotseAntwort(text: (passend.isEmpty ? Array(AppWissen.regeln.prefix(3)) : Array(passend.prefix(4))).joined(separator: "\n"), werkzeug: .hilfe)
        }
        // Bereich oder Fenster – was besser passt; bei Gleichstand der Bereich (Einstieg), ein Fenster nur, wenn es klar mehr trifft.
        let bereich = Bereich.allCases.max { treffer(AppWissen.bereiche[$0] ?? "") + treffer($0.titel) * 2 < treffer(AppWissen.bereiche[$1] ?? "") + treffer($1.titel) * 2 }
        let bereichPunkte = bereich.map { treffer(AppWissen.bereiche[$0] ?? "") + treffer($0.titel) * 2 } ?? 0
        // Gleichstand: der kürzere (genauere) Text gewinnt, dann der Name – feste Reihenfolge statt zufälliger Wörterbuch-Folge
        let fenster = AppWissen.fenster.sorted { $0.key < $1.key }.map(\.value).max { a, b in
            treffer(a) != treffer(b) ? treffer(a) < treffer(b) : a.count > b.count }
        let fensterPunkte = fenster.map(treffer) ?? 0
        // Fenster gegen Bereich: nur Treffer im Text vergleichen – der Tab-Titel („Habits“) darf ein genaueres Fenster nicht verdrängen.
        let bereichText = bereich.map { treffer(AppWissen.bereiche[$0] ?? "") } ?? 0
        if let f = fenster, fensterPunkte > bereichText { return LotseAntwort(text: f, werkzeug: .hilfe) }
        if let b = bereich, bereichPunkte > 0 { return LotseAntwort(text: AppWissen.bereiche[b] ?? "", werkzeug: .hilfe, aktion: .bereich(b.rawValue)) }
        return LotseAntwort(text: "Kompass hat fünf Bereiche:\n" + Bereich.allCases.map { "• \(AppWissen.bereiche[$0] ?? $0.titel)" }.joined(separator: "\n"), werkzeug: .hilfe)
    }

    /// Empfehlung ohne Sprachmodell: deterministische Reihenfolge – Liegengebliebenes, Ziel hinterher mit größtem Hebel, wichtigste Aufgabe heute, offene Habits.
    /// Was gerade wichtig ist: die Signale von Home (§12), nach Rang – der Assistent liest nur vor, er rechnet nicht.
    static func signale(_ z: Zustand, _ T: Tag, jetzt: Int = 8 * 60) -> LotseAntwort {
        let alle = Signale.alle(zustand: z, heute: T, jetzt: jetzt, termine: { termine(z, $0, T) })
        guard let erstes = alle.first else {
            return LotseAntwort(text: "Gerade drängt nichts: kein voller Tag, nichts liegen geblieben, alle Ziele im Plan.", werkzeug: .signale, aktion: .bereich(Bereich.heute.rawValue))
        }
        var zeilen = ["Am wichtigsten: \(erstes.titel) – \(erstes.text)."]
        for s in alle.dropFirst().prefix(4) { zeilen.append("– \(s.titel): \(s.text)") }
        zeilen.append("Die ersten drei stehen auf Home unter „Wichtig“.")
        let aktion: ChatNachricht.Aktion = { if case .ziel(let id) = erstes.handlung { return .ziel(id) }; return .bereich(Bereich.heute.rawValue) }()
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .signale, aktion: aktion)
    }

    static func empfehlen(_ z: Zustand, _ T: Tag, woche: Bool, jetzt: Int = 8 * 60) -> LotseAntwort {
        var zeilen: [String] = []
        let liegen = z.aufgaben.filter { a in a.datum.map { $0 < T } == true && !a.erledigt }
        let hinten = z.ziele.filter { $0.status == .aktiv }
            .map { ($0, Kurs.aufKurs($0, in: z, heute: T)) }
            .filter { [.hinterher, .ueberfaellig].contains($0.1.lage) }
            .sorted { $0.1.fortschritt - $0.1.erwartet < $1.1.fortschritt - $1.1.erwartet }
        let wichtig = z.aufgaben.filter { $0.datum == T && !$0.erledigt && $0.prio == .hoch }.sorted { $0.reihenfolge < $1.reihenfolge }
        let offeneHabits = z.habits.filter { HabitRechnung.geplant($0, am: T) && !$0.voll(am: T) }

        if let (g, k) = hinten.first {
            var t = "Fang bei \(g.titel) an: Das Ziel liegt \(k.lage.text) (\(Zahl.prozent(k.fortschritt)) statt erwarteter \(Zahl.prozent(k.erwartet)))."
            if let s = g.schritte.filter({ Fortschritt.stand($0, in: z, heute: T).anteil < 1 })
                .max(by: { (1 - Fortschritt.stand($0, in: z, heute: T).anteil) * Double(Fortschritt.gewicht($0)) < (1 - Fortschritt.stand($1, in: z, heute: T).anteil) * Double(Fortschritt.gewicht($1)) }) {
                t += " Am meisten bringt dort „\(s.titel)“."
            }
            zeilen.append(t)
        } else if !liegen.isEmpty {
            zeilen.append("Räum zuerst auf, was liegen geblieben ist: " + Satz.liste(liegen.prefix(3).map(\.titel)) + (liegen.count > 3 ? " und \(liegen.count - 3) weitere." : "."))
        } else if let a = wichtig.first {
            zeilen.append("Fang mit „\(a.titel)“ an" + (z.ziel(a.zielID).map { " – deine wichtigste Aufgabe heute, sie zahlt auf \($0.titel) ein." } ?? " – deine wichtigste Aufgabe heute."))
        } else {
            zeilen.append("Heute ist nichts Dringendes offen – ein guter Tag, um an einem Ziel weiterzukommen.")
        }
        if hinten.first != nil, !liegen.isEmpty { zeilen.append("Außerdem liegen \(liegen.count) Aufgabe\(liegen.count == 1 ? "" : "n") aus den letzten Tagen offen.") }
        if hinten.first != nil, let a = wichtig.first { zeilen.append("Heute konkret: „\(a.titel)“.") }
        if !offeneHabits.isEmpty { zeilen.append("Und die kleinen Dinge nicht vergessen: " + Satz.liste(offeneHabits.prefix(3).map(\.titel)) + ".") }
        if woche && hinten.count > 1 { zeilen.append("In der Woche danach: " + Satz.liste(hinten.dropFirst().map(\.0.titel)) + ".") }
        // Dieselben Vorschläge wie im Kalender unter „Empfehlung“ (rechenregeln.md §9.1)
        let b: Empfehlung.Bereich = woche ? .woche : .tag
        let plan = Empfehlung.fuer(b, tag: T, zustand: z, heute: T, jetzt: jetzt, termine: { termine(z, $0, T) }).prefix(2)
            .compactMap { v in Empfehlung.platzText(v, bereich: b, heute: T).map { "„\(v.titel)“ \(b == .tag && !v.verschoben ? "um" : "am") \($0)" } }
        if !plan.isEmpty { zeilen.append("Zum Einplanen passt: " + Satz.liste(plan) + " – im Kalender unter „Empfehlung“.") }
        let aktion: ChatNachricht.Aktion = hinten.first.map { .ziel($0.0.id) } ?? .bereich(Bereich.heute.rawValue)
        return LotseAntwort(text: zeilen.joined(separator: "\n"), werkzeug: .empfehlen, aktion: aktion)
    }
}

/// Kleine Sprachhelfer für lesbare Antworten.
enum Satz {
    /// „A, B und C“
    static func liste(_ teile: [String]) -> String {
        let t = Array(teile)
        switch t.count {
        case 0: return ""
        case 1: return t[0]
        default: return t.dropLast().joined(separator: ", ") + " und " + t[t.count - 1]
        }
    }
}
