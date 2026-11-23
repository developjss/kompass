import Foundation

/// Was der Lotse über die App weiß – aus dem Code erzeugt, nicht von Hand gepflegt.
/// Quellen: `Bereich` (Tabs), `InfoThema` (Erklärtexte), `SchrittArt` (Rechenregeln), `Werkzeuge` (was er tun kann).
/// Ein Test (`LotseTests`) prüft, dass jeder Tab, jedes Fenster und jede Meilenstein-Art beschrieben ist –
/// wer etwas Neues baut, muss den Lotsen mitziehen, sonst wird der Test rot.
enum AppWissen {

    /// Kurzbeschreibung je Tab – auch Antwort auf „Wo finde ich …?“
    static let bereiche: [Bereich: String] = [
        .heute: "Home (erster Tab): Jetzt-Karte mit dem, was läuft oder als Nächstes kommt (Termin, Aufgabe oder Habit) – Fokus starten, Erledigt, Menge; Hinweise (enger Tag, Überschneidung, zu wenig Zeit); Als Nächstes; Heute offen (Aufgaben und Habits ohne Uhrzeit); Liegen geblieben; Ziele; Tagesabschluss.",
        .kalender: "Kalender: oben die nächsten drei Einträge; Umschalter Tag (Zeitleiste, Tipp auf eine Stunde = neuer Termin), Woche (7 Spalten), Monat (Raster mit farbigen Einträgen), Jahr (Auslastung); darunter „Ohne Uhrzeit“ und Eingang – Aufgaben und Habits per Ziehen in den Tag legen. Farben nach Ziel oder Kategorie (Einstellungen). Termine aus Apple (EventKit), Google als Beispiel, eigene Kompass-Termine.",
        .fortschritt: "Fortschritt: oben umschalten zwischen Zielen (Kopfkarte „x von y auf Kurs“, je Ziel Prozent, Auf Kurs, Frist; Ziel-Seite mit Satz „so wird gerechnet“, Meilensteinen, Aufgaben, Habits, Terminen, Einsatz und Fakten-Zeilen zum Bearbeiten) und Habits (Heute abhaken oder Menge eintragen, Diese Woche, Alle Habits mit Soll, Rhythmus, Erinnerung, Quote, Serie).",
        .lotse: "Lotse: dieser Chat. Fragen zur App, zu Zielen, Habits, Aufgaben, Terminen und zur Analyse; Aufgaben anlegen. Klare Fragen beantwortet er auf dem Gerät, freie Formulierungen über Claude (Kontingent, Pro).",
        .rueckblick: "Rückblick: Fokuszeit der Woche mit Kurve über 12 Wochen, Zeit pro Ziel, Habit-Quote, Wochenreflexion.",
    ]

    /// Fenster (Sheets) und was man dort tut – Schlüssel = Präfix der `Navigation.Blatt`-id
    static let fenster: [String: String] = [
        "neu": "+ Neu: Aufgabe (mit Datum, Uhrzeit, Dauer, Kategorie), Termin, Habit (mit fester Uhrzeit) oder Ziel anlegen. Beim Ziel schlägt die App Meilenstein-Vorlagen aus dem Titel vor (Prüfung, Gewicht, Geld, Ausdauer, Bücher, Sprache, Projekt, Drei Schritte).",
        "info": "(i): kurze Erklärung der Seite.",
        "einstellungen": "Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo-Daten neu laden.",
        "aufgabe": "Aufgabe: Titel, erledigt, wichtig, Datum, Wiederholung, Ziel, Notizen, löschen oder Serie beenden.",
        "habit": "Habit-Seite (im Tab Fortschritt): Kopfkarte mit Stand heute und Serie; Heute abhaken oder Menge eintragen; Stand (Serie, beste Serie, Quote 30 Tage); Fakten-Zeilen Titel, Menge, Rhythmus, Erinnerung, Ziel, Aussehen – jede Zeile antippen öffnet ihren Editor; letzte 14 Tage; „Zählt in“ (Meilensteine); löschen.",
        "habitbearbeiten": "Habit bearbeiten (einstellen, ändern): eine Zeile antippen – Titel, Menge mit Einheit (oder nur abhaken), Rhythmus (täglich, werktags, Wochentage, n-mal pro Woche), Erinnerung (aus oder Uhrzeit; beim ersten Mal fragt die App nach Erlaubnis für Mitteilungen), Ziel, Farbe und Symbol.",
        "fokus": "Fokus-Timer: läuft zur Aufgabe, Pause/Weiter, Fertig bucht die Zeit (an Mitternacht geteilt, höchstens 4 h am Stück).",
        "rechnung": "So wird gerechnet: ein Satz und je Meilenstein der Beitrag in Prozentpunkten.",
        "reflexion": "Tagesabschluss (3 Fragen) bzw. Wochenreflexion (3 Fragen).",
        "meilenstein": "Meilenstein: Titel, Messart (Abhaken, Zahl, Zeit, Habit), Soll, Gewicht klein/mittel/groß, geschafft, Zwischenstände, Stand eintragen, löschen.",
        "habitzuziel": "Habit zum Ziel: bestehenden oder neuen Habit verbinden; zählt in die Prozente (Anzahl oder Wochen) oder nur als Einsatz.",
        "aufgabezuziel": "Aufgaben zum Ziel: bestehende Aufgaben einem Ziel und Meilenstein zuordnen.",
        "terminzuziel": "Termine zum Ziel: eine Termin-Serie zuordnen; zählt in Zahl (je 1) oder Zeit (Dauer) oder nur als Einsatz.",
        "zielbearbeiten": "Ziel bearbeiten (ändern): eine Fakten-Zeile der Ziel-Seite antippen – Titel, Bis wann, Bereich, Warum, Aussehen (Farbe, Symbol).",
        "habitmenge": "Menge eintragen: wie viel vom Habit heute geschafft ist (z. B. 12 von 20 Minuten) – große Zahl, Schnellwahl halb/ganz.",
        "termin": "Termin anlegen oder ändern: Titel, Tag, von–bis (Chips 30 Min, 1 h, 2 h), Kategorie (Farbe), zählt für ein Ziel (Meilenstein Zeit/Zahl) oder erfüllt einen Habit, Wiederholung; löschen.",
        "pro": "Kompass Pro: unbegrenzte Lotse-Fragen und Gespräche; ohne Pro einige freie Fragen pro Tag (Regeln auf dem Gerät immer kostenlos).",
    ]

    /// Rechenregeln in Sätzen (Quelle: rechenregeln.md Fassung 2) – der Lotse erklärt, rechnet aber nie.
    static var regeln: [String] {
        [
            "Ein Ziel besteht aus Meilensteinen. Fortschritt = gewichteter Durchschnitt der Meilensteine; mittel zählt doppelt, groß dreifach.",
        ] + SchrittArt.allCases.map { "\($0.name): \($0.erklaerung)" } + [
            "Alles ohne Meilenstein (Aufgaben, Habits, Termine, Fokuszeit) zählt als Einsatz und ändert die Prozente nicht.",
            "Auf Kurs vergleicht Fortschritt mit der verstrichenen Zeit: 5 Punkte darüber = voraus, 10 darunter = hinterher.",
            "Prognose: Tempo der letzten 4 Wochen, ab 7 Tagen Verlauf.",
            "Habit: Tagesanteil = Menge ÷ Soll (halb geschafft zählt halb). Serie = geplante Tage rückwärts, nur volle Tage; bei „n-mal pro Woche“ erfüllte Wochen. Quote = Σ Anteile ÷ geplante Tage der letzten 30 Tage.",
            "Wiederkehrende Aufgaben zählen nicht in „erledigte ÷ alle“, sondern über Fokuszeit.",
            "Lernen ändert nie bestehende Prozente – nur Vorschläge (Soll-Stunden, Habit-Soll) und die Prognose.",
        ]
    }

    /// Erste Schritte – für Onboarding-Fragen
    static let ersteSchritte = [
        "Leg ein Ziel an (+ Neu → Ziel) und gib ihm ein Datum.",
        "Öffne das Ziel und füge Meilensteine hinzu – so weiß Kompass, was gemessen wird.",
        "Verbinde Habits und Aufgaben mit dem Ziel; sie zählen über Meilensteine.",
        "Verbinde deinen Kalender (Daten & Kalender), dann zählen Termine wie Fahrstunden automatisch.",
        "Jeden Tag: Heute abarbeiten, Habits abhaken, abends der Tagesabschluss.",
    ]

    /// Gesamtes Wissen als Text – wird einem Sprachmodell als Systemwissen mitgegeben.
    static func text() -> String {
        var t = "Kompass verbindet heute (Aufgaben, Termine), täglich (Habits) und morgen (Ziele). Bereiche:\n"
        for b in Bereich.allCases { t += "- \(bereiche[b] ?? b.titel)\n" }
        t += "\nFenster:\n" + fenster.keys.sorted().map { "- \(fenster[$0]!)" }.joined(separator: "\n")
        t += "\n\nRechenregeln:\n" + regeln.map { "- \($0)" }.joined(separator: "\n")
        t += "\n\nErste Schritte:\n" + ersteSchritte.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        t += "\n\nWerkzeuge (nur über sie entstehen Zahlen und Änderungen):\n" + Werkzeuge.alle.map { "- \($0.name): \($0.beschreibung)" }.joined(separator: "\n")
        return t
    }

    /// Alle `Navigation.Blatt`-Fälle als id-Präfix – damit der Test Vollständigkeit prüfen kann.
    @MainActor
    static var blattPraefixe: [String] {
        let id = UUID()
        let faelle: [Navigation.Blatt] = [.neu(nil), .info(.heute), .einstellungen, .aufgabe(id), .fokus(id), .rechnung(id),
                                          .reflexion(woche: false), .meilenstein(ziel: id, schritt: nil), .habitZuZiel(id), .aufgabeZuZiel(id),
                                          .terminZuZiel(id), .zielBearbeiten(id, .titel), .pro, .habitMenge(id, tag: "2026-01-01"), .habitBearbeiten(id, .menge), .termin(nil, tag: "2026-01-01", start: nil)]
        return faelle.map { String($0.id.split(separator: "-")[0]) }
    }
}
