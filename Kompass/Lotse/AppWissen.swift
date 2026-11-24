import Foundation

/// Was der Lotse über die App weiß – aus dem Code erzeugt, nicht von Hand gepflegt.
/// Quellen: `Bereich` (Tabs), `InfoThema` (Erklärtexte), `SchrittArt` (Rechenregeln), `Werkzeuge` (was er tun kann).
/// Ein Test (`LotseTests`) prüft, dass jeder Tab, jedes Fenster und jede Meilenstein-Art beschrieben ist –
/// wer etwas Neues baut, muss den Lotsen mitziehen, sonst wird der Test rot.
enum AppWissen {

    /// Kurzbeschreibung je Tab – auch Antwort auf „Wo finde ich …?“
    static let bereiche: [Bereich: String] = [
        .heute: "Home (erster Tab): Jetzt-Karte, darunter „Dein Tag im Blick“ als Reel (Slides: Jetzt, Danach, wie voll der Tag ist, Heute offen, Ziele, Los); dann mit dem, was läuft oder als Nächstes kommt (Termin, Aufgabe oder Habit) – Fokus starten, Erledigt, Menge; Hinweise (enger Tag, Überschneidung, zu wenig Zeit); Als Nächstes; Heute offen (Aufgaben und Habits ohne Uhrzeit); Liegen geblieben; Ziele; Tagesabschluss.",
        .kalender: "Kalender: oben „Als Nächstes“ als Kartenstapel (Alle ansehen fächert auf); Umschalter Tag (Zeitleiste, Tipp auf eine Stunde = neuer Termin), Woche (7 Spalten), Monat (Raster mit farbigen Einträgen), Jahr (Auslastung); darunter „Empfehlung“: Kartenstapel mit Vorschlägen passend zur Ansicht (Tag: Habits und Aufgaben mit freier Uhrzeit; Woche/Monat: Aufgaben mit dem freiesten Tag bis zur Frist), Grund je Karte; antippen zeigt, wie man zieht, und bietet „Um 14:00 einplanen“; halten und in den Kalender ziehen; zurück auf die Karte ziehen = ohne Uhrzeit. Farben nach Ziel oder Kategorie (Einstellungen). Termine aus Apple (EventKit), Google als Beispiel, eigene Kompass-Termine.",
        .fortschritt: "Fortschritt: oben umschalten zwischen Zielen (Kopfkarte „x von y auf Kurs“, je Ziel Prozent, Auf Kurs, Frist; Ziel-Seite: oben Stand (Ring, Prozent, Lage, Als Nächstes, „Analyse im Rückblick“), darunter Einstellungs-Kacheln Bis wann · Warum · Name · Verfeinern (Kacheln Aufgaben, Habits, Termine, Einsatz, Details, „Geschafft?“ = als erreicht markieren), darunter die Meilensteine als Karten mit Stand und „zählt x %“ – antippen zum Ändern, „Meilenstein hinzufügen“ geführt; Liste mit Filter-Kacheln Alle · Auf Kurs · Hinterher · Erreicht und Sortieren nach Frist, Jahr, Fortschritt, Hinterher zuerst, Bereich, Name) und Habits (Heute abhaken oder Menge eintragen, Diese Woche, Alle Habits mit Soll, Rhythmus, Erinnerung, Quote, Serie).",
        .lotse: "Assistent (Tab in der Mitte, früher „Lotse“): dieser Chat. Fragen zur App, zu Zielen, Habits, Aufgaben, Terminen und zur Analyse, dazu allgemeine Fragen und Aktuelles über die Websuche (mit Quellen); Aufgaben und Termine anlegen. Merkt sich auf Wunsch Vorlieben (Einstellungen › Assistent › „Das merkt sich der Assistent“, dort löschbar). Antwortet über Claude (Kontingent, Pro); ohne Netz mit Regeln auf dem Gerät.",
        .rueckblick: "Rückblick: Fokuszeit der Woche mit Kurve über 12 Wochen, Zeit pro Ziel, Habit-Quote, Wochenreflexion.",
    ]

    /// Fenster (Sheets) und was man dort tut – Schlüssel = Präfix der `Navigation.Blatt`-id
    static let fenster: [String: String] = [
        "neu": "+ Neu, geführt in Schritten: Was (Aufgabe, Termin, Habit, Ziel als Kacheln) → Titel (mit Vorschlag) → Wann → Details → Passt das so? → Anlegen. Beim Ziel schlägt die App Meilenstein-Vorlagen aus dem Titel vor (Prüfung, Gewicht, Geld, Ausdauer, Bücher, Sprache, Projekt, Drei Schritte).",
        "info": "(i): kurze Erklärung der Seite.",
        "einstellungen": "Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo-Daten neu laden.",
        "aufgabe": "Aufgabe: Titel, erledigt, wichtig, Datum, Wiederholung, Ziel, Notizen, löschen oder Serie beenden.",
        "habit": "Habit-Seite (im Tab Fortschritt): Kopfkarte mit Stand heute und Serie; Heute abhaken oder Menge eintragen; Stand (Serie, beste Serie, Quote 30 Tage); Fakten-Zeilen Titel, Menge, Rhythmus, Erinnerung, Ziel, Aussehen – jede Zeile antippen öffnet ihren Editor; letzte 14 Tage; „Zählt in“ (Meilensteine); löschen.",
        "habitbearbeiten": "Habit bearbeiten (einstellen, ändern): eine Zeile antippen – Titel, Menge mit Einheit (oder nur abhaken), Rhythmus (täglich, werktags, Wochentage, n-mal pro Woche), Erinnerung (aus oder Uhrzeit; beim ersten Mal fragt die App nach Erlaubnis für Mitteilungen), Ziel, Farbe und Symbol.",
        "fokus": "Fokus-Timer: läuft zur Aufgabe, Pause/Weiter, Fertig bucht die Zeit (an Mitternacht geteilt, höchstens 4 h am Stück).",
        "rechnung": "So wird gerechnet: ein Satz und je Meilenstein der Beitrag in Prozentpunkten.",
        "reflexion": "Tagesabschluss (3 Fragen) bzw. Wochenreflexion (3 Fragen).",
        "meilenstein": "Meilenstein antippen: Übersicht mit Stand, Anteil am Ziel und einer Hauptaktion (Abhaken, Stand eintragen, Fokus, Habit öffnen); „Anpassen“-Kacheln Name, Woran merkst du es (Abhaken, Zahl, Zeit, Habit), Ziel-Wert, Wie wichtig (klein/mittel/groß mit Vorschau des Anteils); löschen zeigt, wie sich die Anteile neu verteilen. Neu anlegen geführt (Knopf oben über den Meilensteinen): zuerst „Was soll zählen?“ – Etwas Neues (Name mit Vorschlägen → Woran merkst du es → Wert) oder etwas Bestehendes: eine Aufgabe (auch erledigte), Termine aus dem Kalender (jeder Termin zählt 1 oder die Zeit zählt) oder ein Habit; „Bisherige mitzählen“ mit Vorschau, wie weit der Meilenstein damit schon ist → Wie wichtig → Passt das so? mit Aufteilung des Ziels.",
        "habitzuziel": "Habit zum Ziel: bestehenden oder neuen Habit verbinden; zählt in die Prozente (Anzahl oder Wochen) oder nur als Einsatz.",
        "aufgabezuziel": "Aufgaben zum Ziel: bestehende Aufgaben einem Ziel und Meilenstein zuordnen.",
        "terminzuziel": "Termine zum Ziel: eine Termin-Serie zuordnen; zählt in Zahl (je 1) oder Zeit (Dauer) oder nur als Einsatz.",
        "zielbearbeiten": "Ziel bearbeiten (ändern): Kacheln Bis wann, Warum, Name auf der Ziel-Seite; alles andere unter Verfeinern › Details (Aussehen-Vorschau, Worum es geht, Zeitraum, löschen), dort eine Zeile antippen – Titel, Bis wann, Bereich, Warum, Aussehen (Farbe, Symbol). Löschen dort; „Als erreicht markieren“ als Kachel „Geschafft?“ unter Verfeinern.",
        "habitmenge": "Menge eintragen: wie viel vom Habit heute geschafft ist (z. B. 12 von 20 Minuten) – große Zahl, Schnellwahl halb/ganz.",
        "termin": "Termin anlegen oder ändern: Titel, Tag, von–bis (Chips 30 Min, 1 h, 2 h), Kategorie (Farbe), zählt für ein Ziel (Meilenstein Zeit/Zahl) oder erfüllt einen Habit, Wiederholung; löschen.",
        "chats": "Frühere Chats (oben links im Assistenten): Liste der letzten 30 Chats mit erster Frage und Datum; antippen öffnet ihn wieder, wischen löscht.",
        "pro": "Kompass Pro: unbegrenzte Fragen an den Assistenten und Gespräche; ohne Pro einige freie Fragen pro Tag (Regeln auf dem Gerät immer kostenlos).",
    ]

    /// Rechenregeln in Sätzen (Quelle: rechenregeln.md Fassung 2) – der Lotse erklärt, rechnet aber nie.
    static var regeln: [String] {
        [
            "Ein Ziel besteht aus Meilensteinen. Fortschritt = gewichteter Durchschnitt der Meilensteine; mittel zählt doppelt, groß dreifach.",
        ] + SchrittArt.allCases.map { "\($0.name): \($0.erklaerung)" } + [
            "Alles ohne Meilenstein (Aufgaben, Habits, Termine, Fokuszeit) zählt als Einsatz und ändert die Prozente nicht.",
            "Auf Kurs vergleicht Fortschritt mit der verstrichenen Zeit: 5 Punkte darüber = voraus, 10 darunter = hinterher.",
            "Prognose: Tempo der letzten 4 Wochen, ab 7 Tagen Verlauf.",
            "Tagesplan: wache Zeit 7–22 Uhr; enger Tag = mindestens 75 % verplant oder weniger als 90 Minuten frei; Überschneidung ab 5 Minuten; zu wenig Zeit, wenn Offenes ohne Uhrzeit länger dauert als die freie Zeit. Eigene Termine zählen für ein Ziel wie Termin-Serien und erfüllen einen Habit, sobald sie vorbei sind.",
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
                                          .terminZuZiel(id), .zielBearbeiten(id, .titel), .pro, .habitMenge(id, tag: "2026-01-01"), .habitBearbeiten(id, .menge), .termin(nil, tag: "2026-01-01", start: nil), .chats]
        return faelle.map { String($0.id.split(separator: "-")[0]) }
    }
}
