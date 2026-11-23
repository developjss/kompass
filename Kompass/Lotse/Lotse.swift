import Foundation

/// Steuerung des Lotsen: Frage annehmen → Sprachmodell (falls da) oder Regeln → Werkzeug ausführen → Antwort speichern → Lernen.
@MainActor
enum Lotse {

    /// Beantwortet eine Frage und hängt Frage und Antwort an den Chat. Gibt die Antwort zurück.
    @discardableResult
    static func fragen(_ frage: String, speicher: Speicher, modell: (any Sprachmodell)? = Sprachmodelle.aktiv) async -> LotseAntwort {
        let text = frage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return LotseAntwort(text: "") }
        let jetzt = speicher.jetzt()
        speicher.aendern { $0.chat.append(ChatNachricht(rolle: .nutzer, text: text, zeit: jetzt)) }

        var antwort: LotseAntwort
        var aufruf = Verstehen.erkennen(text, zustand: speicher.zustand, heute: speicher.heute)

        // Stufe 0: Trifft eine Regel, kostet die Antwort nichts – der Server wird nur bei freien Formulierungen gefragt.
        // Beratungsfragen („was soll ich zuerst …“) gehen mit Server an Stufe 2, ohne Server an die lokale Empfehlung.
        var einleitung: String?
        if aufruf == nil || aufruf?.name == .empfehlen, let modell {
            do {
                let anfrage = SprachmodellAnfrage(wissen: AppWissen.text() + "\n\nStand:\n" + kurzstand(speicher), werkzeuge: Werkzeuge.alle.filter(\.fuerServer),
                                                  verlauf: speicher.zustand.chat.suffix(12).map { ($0.rolle, $0.text) }, frage: text)
                switch try await modell.antworte(auf: anfrage) {
                case .werkzeug(let a, let satz): aufruf = a; einleitung = satz
                case .text(let t):
                    antwort = LotseAntwort(text: t, werkzeug: nil)
                    return abschliessen(antwort, frage: text, speicher: speicher)
                }
            } catch LotseFehler.kontingentErschoepft(let limit, let pro) {
                let t = pro
                    ? "Du hast heute die Obergrenze von \(limit) Fragen erreicht. Morgen geht es weiter – oder frag mich etwas, das ich ohne Server beantworten kann."
                    : "Deine \(limit) freien Fragen für heute sind aufgebraucht. Mit Kompass Pro fragst du unbegrenzt – oder morgen wieder kostenlos."
                return abschliessen(LotseAntwort(text: t, werkzeug: nil, aktion: pro ? nil : .pro), frage: text, speicher: speicher)
            } catch {
                // Server nicht erreichbar → Regeln; der Nutzer sieht trotzdem eine Antwort
                LotseStand.geteilt.letzterFehler = "Server gerade nicht erreichbar – ich antworte mit Bordmitteln."
            }
        }

        if let a = aufruf {
            antwort = ausfuehren(a, speicher: speicher)
            if let e = einleitung?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty, a.name != .aufgabeAnlegen, a.name != .terminAnlegen { antwort.text = e + "\n" + antwort.text }
        } else {
            antwort = LotseAntwort(text: "Das habe ich noch nicht verstanden. Ich merke mir die Frage, damit der Lotse das lernt.\nVersuch zum Beispiel: „\(Werkzeuge.vorschlaege[0])“ oder „\(Werkzeuge.vorschlaege[2])“.", unbeantwortet: true)
        }
        return abschliessen(antwort, frage: text, speicher: speicher)
    }

    /// Führt ein Werkzeug aus – lesend über `Werkzeuge`, schreibend hier (Aufgabe anlegen).
    static func ausfuehren(_ a: WerkzeugAufruf, speicher: Speicher) -> LotseAntwort {
        let T = speicher.heute
        switch a.name {
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

    /// Kurzer Datenstand für das Sprachmodell (keine Rohdaten, nur Überschriften und Zahlen)
    static func kurzstand(_ speicher: Speicher) -> String {
        let z = speicher.zustand, T = speicher.heute
        var t = "Heute: \(T.text). Ziele: "
        t += z.ziele.filter { $0.status == .aktiv }.map { "\($0.titel) \(Zahl.prozent(Fortschritt.ziel($0, in: z, heute: T)))" }.joined(separator: ", ")
        t += ". Habits: " + z.habits.map(\.titel).joined(separator: ", ")
        t += ". Offene Aufgaben heute: \(z.aufgaben.filter { $0.datum == T && !$0.erledigt }.count)."
        return t
    }
}
