import Foundation

/// Regelbasiertes Verstehen: ordnet eine deutsche Frage einem Werkzeug zu – ohne Sprachmodell, offline, deterministisch.
/// Das ist die Grundversorgung des Lotsen und der Rückfall, wenn kein Sprachmodell da ist oder es nicht antwortet.
enum Verstehen {

    /// Kleinbuchstaben, Umlaute vereinfacht, Satzzeichen raus
    static func normal(_ s: String) -> String {
        var t = s.lowercased()
        for (a, b) in [("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")] { t = t.replacingOccurrences(of: a, with: b) }
        return t.replacingOccurrences(of: "[^a-z0-9%.: ]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    static let fuellwoerter: Set<String> = ["der", "die", "das", "den", "dem", "ein", "eine", "einen", "mein", "meine", "meinen", "fuer", "und", "oder", "mit", "von", "zum", "zur", "wie", "was", "wann", "ist", "sind", "ich", "mir", "mich", "bitte", "mal", "noch", "auch", "bei", "beim", "auf", "im", "in", "an", "zu", "es", "ziel", "ziele", "habit", "habits", "aufgabe", "aufgaben", "steht", "laeuft", "geht"]

    /// Bedeutungstragende Wörter (ab 3 Zeichen, ohne Füllwörter)
    static func woerter(_ s: String) -> [String] {
        normal(s).split(separator: " ").map(String.init).filter { $0.count >= 3 && !fuellwoerter.contains($0) }
    }

    private static func hat(_ t: String, _ teile: String...) -> Bool { teile.contains { t.contains($0) } }

    /// Frage → Werkzeugaufruf. nil = nichts erkannt.
    static func erkennen(_ frage: String, zustand z: Zustand, heute T: Tag) -> WerkzeugAufruf? {
        let t = normal(frage)
        guard !t.isEmpty else { return nil }

        // 1. Aufgabe anlegen (vor allem anderen, sonst fängt „heute“ die Frage)
        if hat(t, "erstell", "leg ", "lege ", "anleg", "neue aufgabe", "aufgabe:", "erinnere mich", "notier", "fuege", "fueg ", "hinzu", "todo:", "to do:"),
           hat(t, "aufgabe", "erinnere", "notier", "todo", "to do") || t.hasPrefix("erstelle") || t.hasPrefix("lege") {
            return aufgabe(aus: frage, t: t, z: z, T: T)
        }
        // 2. „Jetzt dran“ vor den Hilfe-Mustern („was ist …“)
        if hat(t, "jetzt dran", "was soll ich", "als naechstes", "womit anfang", "womit fange") { return WerkzeugAufruf(name: .heute) }
        // 3. Hilfe / App-Fragen
        if hat(t, "wie funktioniert", "wie fange", "wie starte", "wie beginne", "was ist ", "was bedeutet", "wo finde", "wo ist", "wo kann", "wie kann ich", "wie wird", "wie rechnet", "wie berechn", "wie zaehl", "erklaer", "hilfe", "onboarding", "anleitung", "was kann die app", "was kannst du") {
            // „wie steht/läuft Ziel X“ ist keine Hilfe – prüfen, ob ein Ziel gemeint ist
            if hat(t, "warum") || Werkzeuge.findeZiel(frage, in: z) == nil || hat(t, "wie wird", "wie rechnet", "wie berechn", "wie funktioniert", "wo ") {
                if hat(t, "warum"), Werkzeuge.findeZiel(frage, in: z) != nil { return WerkzeugAufruf(name: .fortschrittErklaeren, parameter: ["ziel": frage]) }
                return WerkzeugAufruf(name: .hilfe, parameter: ["thema": frage])
            }
        }
        // 3. Warum/woher Prozent eines Ziels · was bringt am meisten
        if hat(t, "warum", "woher", "wieso", "weshalb", "am meisten", "was bringt", "naechster schritt", "worauf konzentr") {
            if hat(t, "%", "prozent", "fortschritt", "steht", "bringt", "schritt", "konzentr", "hinterher", "voraus") || Werkzeuge.findeZiel(frage, in: z) != nil {
                return WerkzeugAufruf(name: .fortschrittErklaeren, parameter: ["ziel": frage])
            }
        }
        // 4. Freie Zeit
        if (hat(t, "frei", "luecke", "passt ") || (hat(t, "zeit") && hat(t, "hab", "haett", "wann", "kann"))) && !hat(t, "fokuszeit", "wie viel zeit", "wieviel zeit") {
            let zeitraum = hat(t, "morgen") ? "morgen" : hat(t, "heute") ? "heute" : "woche"
            return WerkzeugAufruf(name: .freieZeit, parameter: ["zeitraum": zeitraum])
        }
        // 5. Analyse / Rückblick
        if hat(t, "analyse", "rueckblick", "wie lief", "wie war", "statistik", "fokuszeit", "wie viel zeit", "wieviel zeit", "auswertung", "bilanz", "produktiv") {
            return WerkzeugAufruf(name: .analyse, parameter: ["zeitraum": hat(t, "letzte", "vergangene", "vorige") ? "letzte" : "diese"])
        }
        // 6. Woche
        if hat(t, "woche") && hat(t, "aussieht", "sieht", "ansteh", "steht", "termine", "kalender", "plan", "los", "vor mir", "kommt") {
            return WerkzeugAufruf(name: .woche, parameter: ["zeitraum": hat(t, "naechste", "kommende") ? "naechste" : "diese"])
        }
        // 7. Heute
        if hat(t, "heute", "jetzt dran", "als naechstes", "was soll ich", "womit anfang", "tag aus") && !hat(t, "habit") {
            return WerkzeugAufruf(name: .heute)
        }
        // 8. Habits ausdrücklich
        if hat(t, "habit", "gewohnheit", "serie", "streak", "quote") {
            if let h = Werkzeuge.findeHabit(frage, in: z), !hat(t, "alle", "meine habits", "laufen meine") { return WerkzeugAufruf(name: .habits, parameter: ["habit": h.titel]) }
            return WerkzeugAufruf(name: .habits)
        }
        // 9. Ein Ziel im Detail, sonst ein Habit mit Namen
        if let g = Werkzeuge.findeZiel(frage, in: z) { return WerkzeugAufruf(name: .ziel, parameter: ["ziel": g.titel]) }
        if let h = Werkzeuge.findeHabit(frage, in: z) { return WerkzeugAufruf(name: .habits, parameter: ["habit": h.titel]) }
        // 10. Alle Ziele
        if hat(t, "ziel", "fortschritt", "stehe ich", "wie weit", "hinkt", "hinterher", "voraus", "im plan") { return WerkzeugAufruf(name: .ziele) }
        // 11. Termine / Kalender → Woche
        if hat(t, "termin", "kalender", "wochenende") { return WerkzeugAufruf(name: .woche) }
        return nil
    }

    // MARK: Aufgabe aus Text

    static let tage = ["montag": 1, "dienstag": 2, "mittwoch": 3, "donnerstag": 4, "freitag": 5, "samstag": 6, "sonntag": 7]

    /// Datum aus Wörtern: heute, morgen, übermorgen, Wochentag (nächster), TT.MM.(JJJJ)
    static func datum(aus t: String, heute T: Tag) -> (Tag?, String?) {
        if t.contains("uebermorgen") { return (T.plus(tage: 2), "uebermorgen") }
        if t.contains("morgen") { return (T.plus(tage: 1), "morgen") }
        if t.contains("heute") { return (T, "heute") }
        for (name, w) in tage where t.contains(name) {
            var d = T.plus(tage: 1)
            while d.wochentag != w { d = d.plus(tage: 1) }
            return (d, name)
        }
        if let m = t.range(of: #"\b(\d{1,2})\.(\d{1,2})\.(\d{4})?"#, options: .regularExpression) {
            let teile = t[m].split(separator: ".").compactMap { Int($0) }
            if teile.count >= 2 {
                let jahr = teile.count == 3 ? teile[2] : (teile[1] < T.monat || (teile[1] == T.monat && teile[0] < T.tag) ? T.jahr + 1 : T.jahr)
                if let d = Tag(text: String(format: "%04d-%02d-%02d", jahr, teile[1], teile[0])) { return (d, String(t[m])) }
            }
        }
        return (nil, nil)
    }

    static func aufgabe(aus frage: String, t: String, z: Zustand, T: Tag) -> WerkzeugAufruf {
        var titel = frage
        // Titel: nach Doppelpunkt, sonst Rest nach Befehlswörtern
        if let i = frage.firstIndex(of: ":") { titel = String(frage[frage.index(after: i)...]) }
        else {
            let muster = #"(?i)^(bitte )?(erstelle|erstell|lege|leg|notiere|notier|fuege|fuege|füge|erinnere mich( an| daran)?)( mir)?( bitte)?( eine| die| einen)?( neue| wichtige)?( aufgabe| todo)?( an| hinzu)?( fuer| für)?( heute| morgen)?:?\s*"#
            titel = frage.replacingOccurrences(of: muster, with: "", options: .regularExpression)
        }
        let (datum, datumWort) = datum(aus: t, heute: T)
        let wichtig = t.contains("wichtig") || t.contains("dringend")
        var zielName: String?
        if let g = Werkzeuge.findeZiel(titel, in: z) ?? Werkzeuge.findeZiel(frage, in: z) {
            zielName = g.titel
            // „für Führerschein:“ aus dem Titel entfernen, wenn Ziel sauber genannt
            for w in woerter(g.titel) where normal(titel).contains(w) && !woerter(titel).filter({ !woerter(g.titel).contains($0) }).isEmpty {
                titel = titel.replacingOccurrences(of: #"(?i)\b(fuer|für|zum|zu|beim|bei)\s+[^\s]*"# + NSRegularExpression.escapedPattern(for: w) + #"[^\s]*\s*"#, with: "", options: .regularExpression)
            }
        }
        if let w = datumWort {
            let muster = NSRegularExpression.escapedPattern(for: w).replacingOccurrences(of: "ue", with: "[uü]e?")
            titel = titel.replacingOccurrences(of: #"(?i)(\b(am|fuer|für|bis|zum)\s+)?"# + muster + #"\.?"#, with: "", options: .regularExpression)
        }
        if wichtig { titel = titel.replacingOccurrences(of: #"(?i)\b(wichtig|dringend)\b"#, with: "", options: .regularExpression) }
        titel = titel.replacingOccurrences(of: #"(?i)\b(an|hinzu|anlegen|erstellen|bitte)\b\.?$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " .,:;!-"))
        if !titel.isEmpty { titel = titel.prefix(1).uppercased() + titel.dropFirst() }
        var p = ["titel": titel, "wichtig": wichtig ? "ja" : "nein"]
        if let datum { p["datum"] = datum.text }
        if let zielName { p["ziel"] = zielName }
        return WerkzeugAufruf(name: .aufgabeAnlegen, parameter: p)
    }
}
