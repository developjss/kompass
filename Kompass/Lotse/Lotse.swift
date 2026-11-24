import Foundation

/// Steuerung des Assistenten: Frage annehmen → Claude mit Werkzeugschleife (falls Server da) oder Regeln → Antwort speichern → Lernen.
@MainActor
enum Lotse {
    /// Höchstens so viele Werkzeugrunden je Frage (der Server erzwingt danach eine Textantwort)
    static let maxSchritte = 6

    /// Beantwortet eine Frage und hängt Frage und Antwort an den Chat. Gibt die Antwort zurück.
    @discardableResult
    static func fragen(_ frage: String, speicher: Speicher, modell: (any Sprachmodell)? = Sprachmodelle.aktiv) async -> LotseAntwort {
        let text = frage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return LotseAntwort(text: "") }
        let jetzt = speicher.jetzt()
        speicher.aendern { $0.chat.append(ChatNachricht(rolle: .nutzer, text: text, zeit: jetzt)) }

        var antwort: LotseAntwort

        // Mit Server: Claude beantwortet jede Frage. Braucht es Daten oder soll etwas geändert werden, ruft es Werkzeuge;
        // die App führt sie aus (sie rechnet) und schickt die Ergebnisse zurück – bis Claude mit Text antwortet.
        if let modell {
            var anfrage = SprachmodellAnfrage(wissen: AppWissen.text(), kurzstand: kurzstand(speicher), werkzeuge: Werkzeuge.alle,
                                              verlauf: speicher.zustand.chat.suffix(13).dropLast().map { ($0.rolle, $0.text) }, frage: text)
            var aktion: ChatNachricht.Aktion?
            var genutzt: Werkzeug.Name?
            var geaendert = false
            LotseStand.geteilt.status = "Denkt nach …"
            defer { LotseStand.geteilt.status = nil }
            do {
                for _ in 0...maxSchritte {
                    switch try await modell.antworte(auf: anfrage) {
                    case .text(let t):
                        return abschliessen(LotseAntwort(text: t, werkzeug: genutzt, aktion: aktion), frage: text, speicher: speicher)
                    case .werkzeuge(let aufrufe, let inhalt):
                        if let n = aufrufe.first.flatMap({ Werkzeug.Name(rawValue: $0.name) }) { LotseStand.geteilt.status = statusText(n) }
                        var ergebnisse: [(id: String, text: String)] = []
                        for a in aufrufe {
                            guard let name = Werkzeug.Name(rawValue: a.name) else { ergebnisse.append((a.id, "Dieses Werkzeug gibt es nicht: \(a.name).")); continue }
                            let r = ausfuehren(WerkzeugAufruf(name: name, parameter: a.parameter), speicher: speicher)
                            ergebnisse.append((a.id, r.text))
                            genutzt = name
                            if let ak = r.aktion { aktion = ak }
                            if name == .aufgabeAnlegen || name == .terminAnlegen || name == .merken { geaendert = true }
                        }
                        anfrage.schritte.append(ModellSchritt(inhalt: inhalt, ergebnisse: ergebnisse))
                        LotseStand.geteilt.status = "Schreibt die Antwort …"
                    }
                }
                throw LotseFehler.antwort
            } catch LotseFehler.kontingentErschoepft(let limit, let pro) {
                let t = pro
                    ? "Du hast heute die Obergrenze von \(limit) Fragen erreicht. Morgen geht es weiter – bis dahin antworte ich mit Bordmitteln."
                    : "Deine \(limit) freien Fragen für heute sind aufgebraucht. Mit **Kompass Pro** fragst du unbegrenzt – oder morgen wieder kostenlos."
                return abschliessen(LotseAntwort(text: t, werkzeug: nil, aktion: pro ? nil : .pro), frage: text, speicher: speicher)
            } catch {
                LotseStand.geteilt.letzterFehler = "Server gerade nicht erreichbar – ich antworte mit Bordmitteln."
                // Wurde schon etwas geändert, nicht noch einmal über Regeln ausführen – stattdessen die Ergebnisse zeigen
                if geaendert, let letzte = anfrage.schritte.last {
                    return abschliessen(LotseAntwort(text: letzte.ergebnisse.map(\.text).joined(separator: "\n\n"), werkzeug: genutzt, aktion: aktion), frage: text, speicher: speicher)
                }
            }
        }

        // Ohne Server (oder bei Fehler): Regeln auf dem Gerät
        let aufruf = Verstehen.erkennen(text, zustand: speicher.zustand, heute: speicher.heute)
        if let a = aufruf {
            antwort = ausfuehren(a, speicher: speicher)
        } else {
            antwort = LotseAntwort(text: "Das habe ich noch nicht verstanden. Ich merke mir die Frage, damit der Assistent das lernt.\nVersuch zum Beispiel: „\(Werkzeuge.vorschlaege[0])“ oder „\(Werkzeuge.vorschlaege[2])“.", unbeantwortet: true)
        }
        return abschliessen(antwort, frage: text, speicher: speicher)
    }

    /// Führt ein Werkzeug aus – lesend über `Werkzeuge`, schreibend hier (Aufgabe anlegen).
    static func ausfuehren(_ a: WerkzeugAufruf, speicher: Speicher) -> LotseAntwort {
        let T = speicher.heute
        // Werkzeuge sehen dieselben Termine wie die App (inkl. Apple-Kalender)
        Werkzeuge.quelle = { speicher.termine(am: $0) }
        defer { Werkzeuge.quelle = nil }
        switch a.name {
        case .merken:
            if let weg = a.parameter["vergessen"]?.trimmingCharacters(in: .whitespaces), !weg.isEmpty {
                let vorher = speicher.zustand.lernen.lotse.erinnerungen.count
                speicher.aendern { $0.lernen.lotse.erinnerungen.removeAll { $0.localizedCaseInsensitiveContains(weg) } }
                let n = vorher - speicher.zustand.lernen.lotse.erinnerungen.count
                return LotseAntwort(text: n == 0 ? "Dazu hatte ich mir nichts gemerkt." : "Vergessen (\(n) Eintrag\(n == 1 ? "" : "e")).", werkzeug: .merken)
            }
            let notiz = (a.parameter["notiz"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !notiz.isEmpty else { return LotseAntwort(text: "Was soll ich mir merken?", werkzeug: .merken) }
            speicher.aendern { z in
                var e = z.lernen.lotse.erinnerungen.filter { $0.caseInsensitiveCompare(notiz) != .orderedSame }
                e.append(String(notiz.prefix(200)))
                z.lernen.lotse.erinnerungen = Array(e.suffix(30))
            }
            return LotseAntwort(text: "Gemerkt: \(notiz) – du findest es unter Einstellungen › Assistent.", werkzeug: .merken)
        case .aufgabeAnlegen:
            let titel = a.parameter["titel"]?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !titel.isEmpty else { return LotseAntwort(text: "Wie soll die Aufgabe heißen? Zum Beispiel: „Erstelle Aufgabe: Flugschule anrufen morgen“.", werkzeug: .aufgabeAnlegen) }
            let datum = a.parameter["datum"].flatMap { Tag(text: $0) }
            let prio: Prioritaet = a.parameter["wichtig"] == "ja" ? .hoch : .normal
            let ziel = Werkzeuge.findeZiel(a.parameter["ziel"], in: speicher.zustand)
            var neu: Aufgabe?
            speicher.aendern { neu = $0.aufgabeAnlegen(titel, datum: datum, prio: prio, zielID: ziel?.id, heute: T) }
            guard let n = neu else { return LotseAntwort(text: "Das hat nicht geklappt.", werkzeug: .aufgabeAnlegen) }
            var t = "Angelegt: „\(n.titel)“"
            t += datum.map { $0 == T ? " für heute" : $0 == T.plus(tage: 1) ? " für morgen" : " für den \($0.tag).\($0.monat)." } ?? " im Eingang (ohne Datum)"
            if prio == .hoch { t += ", wichtig" }
            if let ziel { t += " · Ziel: \(ziel.titel)" + (n.schrittID != nil ? " (zählt im nächsten offenen Meilenstein)" : " (nur Einsatz – kein offener Meilenstein)") }
            return LotseAntwort(text: t + ".", werkzeug: .aufgabeAnlegen, aktion: .aufgabe(n.id))
        case .terminAnlegen:
            let titel = a.parameter["titel"]?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !titel.isEmpty else { return LotseAntwort(text: "Wie heißt der Termin? Zum Beispiel: „Trag morgen 15 Uhr Zahnarzt ein“.", werkzeug: .terminAnlegen) }
            guard let s = a.parameter["start"].flatMap(Lotse.minuten) else {
                return LotseAntwort(text: "Um wie viel Uhr? Zum Beispiel: „\(titel) morgen um 15 Uhr“.", werkzeug: .terminAnlegen)
            }
            let tag = a.parameter["datum"].flatMap { Tag(text: $0) } ?? T
            let e = a.parameter["ende"].flatMap(Lotse.minuten).flatMap { $0 > s ? $0 : nil } ?? min(24 * 60 - 1, s + 60)
            let ziel = Werkzeuge.findeZiel(a.parameter["ziel"], in: speicher.zustand)
            let schritt = ziel?.schritte.first { $0.art == .zeit || $0.art == .zahl }
            let neu = EigenerTermin(titel: titel, tag: tag, start: s, ende: e, zielID: ziel?.id, schrittID: schritt?.id)
            speicher.aendern { $0.terminSpeichern(neu) }
            var t = "Eingetragen: „\(titel)“ " + (tag == T ? "heute" : tag == T.plus(tage: 1) ? "morgen" : "am \(tag.tag).\(tag.monat).") + " \(Tagesplan.uhr(s))–\(Tagesplan.uhr(e))"
            if let ziel { t += " · zählt für \(ziel.titel)" + (schritt.map { " (\($0.titel))" } ?? " (Einsatz)") }
            let b = Tagesplan.bloecke(am: tag, zustand: speicher.zustand, termine: speicher.termine(am: tag))
            if let k = b.first(where: { $0.eigenID != neu.id && min($0.ende, e) - max($0.start, s) >= 5 }) { t += ". Achtung: überschneidet sich mit „\(k.titel)“" }
            return LotseAntwort(text: t + ".", werkzeug: .terminAnlegen, aktion: .bereich(Bereich.kalender.rawValue))
        default:
            return Werkzeuge.ausfuehren(a, z: speicher.zustand, heute: T, jetzt: speicher.jetzt(), kalender: speicher.kalender)
        }
    }

    /// Ladeanzeige: was der Assistent mit einem Werkzeug gerade tut.
    static func statusText(_ n: Werkzeug.Name) -> String {
        switch n {
        case .heute, .naechstes, .tagesplan, .woche, .freieZeit: "Schaut in deinen Kalender …"
        case .empfehlen: "Wägt ab, was zuerst kommt …"
        case .ziele, .ziel, .fortschrittErklaeren: "Prüft deine Ziele …"
        case .habits: "Schaut auf deine Habits …"
        case .analyse: "Wertet deine Woche aus …"
        case .aufgabeAnlegen, .terminAnlegen: "Trägt es ein …"
        case .hilfe: "Liest in der Anleitung …"
        case .merken: "Merkt es sich …"
        }
    }

    /// „15:30“ → 930
    static func minuten(_ s: String) -> Int? {
        let t = s.split(separator: ":").compactMap { Int($0) }
        guard t.count == 2, (0..<24).contains(t[0]), (0..<60).contains(t[1]) else { return nil }
        return t[0] * 60 + t[1]
    }

    private static func abschliessen(_ antwort: LotseAntwort, frage: String, speicher: Speicher) -> LotseAntwort {
        let jetzt = speicher.jetzt()
        speicher.aendern { z in
            z.chat.append(ChatNachricht(rolle: .lotse, text: antwort.text, zeit: jetzt, werkzeug: antwort.werkzeug?.rawValue, aktion: antwort.aktion))
            if z.chat.count > 200 { z.chat.removeFirst(z.chat.count - 200) }
            if antwort.unbeantwortet { z.lernen.lotse.unbeantwortet = Array((z.lernen.lotse.unbeantwortet + [frage]).suffix(50)) }
            if let w = antwort.werkzeug { z.lernen.lotse.genutzt[w.rawValue, default: 0] += 1 }
        }
        return antwort
    }

    /// Daumen hoch/runter zu einer Lotsen-Antwort. Lernen: Zähler und die zugehörige Frage.
    static func rueckmeldung(_ gut: Bool, nachricht id: UUID, speicher: Speicher) {
        speicher.aendern { z in
            guard let i = z.chat.firstIndex(where: { $0.id == id }) else { return }
            z.chat[i].rueckmeldung = gut
            if gut { z.lernen.lotse.gut += 1 }
            else if i > 0, z.chat[i - 1].rolle == .nutzer { z.lernen.lotse.schlecht = Array((z.lernen.lotse.schlecht + [z.chat[i - 1].text]).suffix(50)) }
        }
    }

    static func verlaufLoeschen(speicher: Speicher) { speicher.aendern { $0.chat.removeAll() } }

    /// Neuer Chat: der laufende wandert in den Verlauf (wenn er eine Frage enthält), höchstens 30 bleiben.
    static func neuerChat(speicher: Speicher) {
        guard speicher.zustand.chat.contains(where: { $0.rolle == .nutzer }) else { return }
        speicher.aendern { z in
            let start = z.chat.first?.zeit ?? speicher.jetzt()
            z.chatVerlauf.insert(Chat(start: start, nachrichten: z.chat), at: 0)
            if z.chatVerlauf.count > 30 { z.chatVerlauf.removeLast(z.chatVerlauf.count - 30) }
            z.chat.removeAll()
        }
    }

    /// Früheren Chat wieder öffnen (der laufende geht in den Verlauf).
    static func chatOeffnen(_ id: UUID, speicher: Speicher) {
        neuerChat(speicher: speicher)
        speicher.aendern { z in
            guard let i = z.chatVerlauf.firstIndex(where: { $0.id == id }) else { return }
            z.chat = z.chatVerlauf.remove(at: i).nachrichten
        }
    }

    static func chatLoeschen(_ id: UUID, speicher: Speicher) { speicher.aendern { $0.chatVerlauf.removeAll { $0.id == id } } }

    /// Datenstand für das Sprachmodell – von der App berechnet (Überschriften und Zahlen, keine Notizen).
    /// Damit beantwortet Claude einfache Fragen ohne Werkzeug; Genaueres holt es über Werkzeuge.
    static func kurzstand(_ speicher: Speicher) -> String {
        let z = speicher.zustand, T = speicher.heute, jetzt = speicher.jetztMinuten
        let de = Locale(identifier: "de_DE")
        var zeilen: [String] = []
        zeilen.append("Jetzt: \(T.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(de))), \(Tagesplan.uhr(jetzt)) Uhr (\(TimeZone.current.identifier)).")
        let n = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:))
        if !n.isEmpty { zeilen.append("Als Nächstes: " + n.map { "\($0.titel) (\(Tagesplan.wannText($0, heute: T, jetzt: jetzt)), \($0.art.rawValue))" }.joined(separator: "; ") + ".") }
        let ohne = Tagesplan.ohneZeit(am: T, zustand: z)
        let offen = ohne.aufgaben.filter { !$0.erledigt }
        zeilen.append("Heute ohne Uhrzeit offen: \(offen.count) Aufgaben" + (offen.isEmpty ? "" : " (" + offen.prefix(5).map(\.titel).joined(separator: ", ") + ")")
                      + ", \(ohne.habits.filter { !$0.voll(am: T) }.count) Habits.")
        let liegen = z.aufgaben.filter { !$0.erledigt && ($0.datum.map { $0 < T } ?? false) }
        if !liegen.isEmpty { zeilen.append("Überfällig: \(liegen.count) (" + liegen.prefix(5).map(\.titel).joined(separator: ", ") + ").") }
        let ziele = z.ziele.filter { $0.status == .aktiv }.map { g -> String in
            let k = Kurs.aufKurs(g, in: z, heute: T)
            return "\(g.titel) \(Zahl.prozent(k.fortschritt)) (\(k.lage.text), \(Kurs.bisText(g.faellig, heute: T)))"
        }
        if !ziele.isEmpty { zeilen.append("Ziele: " + ziele.joined(separator: "; ") + ".") }
        let habits = z.habits.filter { T >= $0.angelegt }.map { h -> String in
            let geplant = HabitRechnung.geplant(h, am: T)
            return "\(h.titel) (" + (geplant ? (h.voll(am: T) ? "heute erledigt" : "heute offen") : "heute nicht geplant") + ")"
        }
        if !habits.isEmpty { zeilen.append("Habits: " + habits.joined(separator: "; ") + ".") }
        if !z.lernen.lotse.erinnerungen.isEmpty { zeilen.append("Das weißt du über den Nutzer (mit „merken“ gespeichert): " + z.lernen.lotse.erinnerungen.joined(separator: " · ")) }
        return String(zeilen.joined(separator: "\n").prefix(3800))
    }
}
