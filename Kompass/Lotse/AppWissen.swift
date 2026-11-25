import Foundation

/// Was der Lotse über die App weiß – aus dem Code erzeugt, nicht von Hand gepflegt.
/// Quellen: `Bereich` (Tabs), `InfoThema` (Erklärtexte), `SchrittArt` (Rechenregeln), `Werkzeuge` (was er tun kann).
/// Ein Test (`LotseTests`) prüft, dass jeder Tab, jedes Fenster und jede Meilenstein-Art beschrieben ist –
/// wer etwas Neues baut, muss den Lotsen mitziehen, sonst wird der Test rot.
enum AppWissen {

    /// Kurzbeschreibung je Tab – auch Antwort auf „Wo finde ich …?“
    static let bereiche: [Bereich: String] = [
        .heute: "Home (erster Tab): oben die Bühne mit dem großen Wort („Jetzt dran“, „Läuft gerade“, „In 28 Min dran“, „Alles geschafft“) und dem 747; rechts oben Datum, (i) und + Neu. Darunter die Karte vorn mit genau einer Sache – Termin, der läuft oder in ≤ 60 Min beginnt, sonst die wichtigste offene Aufgabe ohne Uhrzeit, sonst ein offener Habit – mit Fokus starten · Erledigt (Habit: Menge eintragen · Ganz; Termin: Im Kalender · Ändern) und „x von y geschafft · Fokus“. Dann „Als Nächstes“: drei Zeilen (Termine mit Uhrzeit rechts, Aufgaben und Habits mit Haken), „alle n ›“ öffnet den Kalender. Höchstens ein Hinweis: liegengebliebene Aufgaben mit „Auf heute“, sonst der wichtigste Tages-Hinweis (eng, Überschneidung, zu wenig Zeit). Ab 18 Uhr der Tagesabschluss (2 Min). Alles Weitere liegt im Kalender.",
        .kalender: "Kalender: oben die kurze Bühne mit dem Wort („In 57 Min · Fahrstunde“, „Heute frei“ oder der gewählte Tag) und der Bordkarte; rechts (i) und + (neuer Termin, geführt). Karte vorn: Umschalter Tag · Woche · Monat (das Jahr liegt im Monat unter „Jahr ansehen“) und die Wochenleiste (Tag antippen). Tag: Überschrift Heute/Wochentag, Leiste „Vorschläge“ mit drei Aufgaben oder Habits samt freier Uhrzeit (antippen zeigt „um 11:15 einplanen“, „alle n“ zeigt den Rest, zurück auf die Leiste ziehen = ohne Uhrzeit), dann die Zeitleiste: Einträge mit Ziel-Zeichen, Aufgaben und Habits direkt abhaken, freie Stunde antippen = „Was um 14:00?“, Einträge halten und ziehen (Vorschau am Zielort; Serien fragen „nur dieser oder alle“). Woche: Spalten mit Blöcken, ziehen zwischen Tagen. Monat: Raster mit Punkten, darunter die Einträge des gewählten Tags, Vorschläge als Stapel (3 + alle). Jahr: zwölf Monate. Apple- und Google-Termine erscheinen live und lassen sich bearbeiten, verschieben und löschen.",
        .fortschritt: "Fortschritt, umgeschaltet zwischen Ziele und Habits (Chip oben rechts in der Marke). Ziele: Bühne mit dem Wort „x von y auf Kurs“ (§4) und dem Kompass; Karte vorn mit Filter Alle · Hinterher · Erreicht und dem Ziel mit dem größten Hebel (Ring, nächster Schritt, Lage); darunter „Alle Ziele“ mit „Mehr“ (Sortieren: Frist, Fortschritt, Hinterher zuerst) und je Ziel eine Zeile mit Ring, Frist und Lage. Ziel-Seite: Bühne mit Prozent und Lage als Wort, darunter der Zieltitel, und dem A380; Karte vorn „Dein nächster Schritt“ (§1) mit einer Handlung (Fokus starten, Meilenstein öffnen oder anlegen) und Analyse; zwei Kacheln Meilensteine und Verfeinern; darunter die Meilensteine als Karten mit Stand und „zählt x %“, „Meilenstein hinzufügen“ geführt. Habits: Bühne mit „x von y heute“ und der Bordkarte; Karte vorn mit den heutigen Habits (Haken je Zeile, der erste offene mit Menge bekommt „Eintragen“), Erledigte eingeklappt; darunter „Diese Woche“ je Habit mit Wochenpunkten oder Segment-Balken. Habit-Seite: Bühne mit Serie oder „Heute offen“ und dem Kompass; Karte vorn mit Ring, Stand, Serie und einer Handlung (Abhaken oder Menge eintragen) plus Analyse; vier Kacheln Wann · Wie viel · Erinnerung · Verfeinern; darunter „Zählt in“.",
        .lotse: "Assistent (Tab in der Mitte, früher „Lotse“): dieser Chat. Fragen zur App, zu Zielen, Habits, Aufgaben, Terminen und zur Analyse, dazu allgemeine Fragen und Aktuelles über die Websuche (mit Quellen); Aufgaben und Termine anlegen. Merkt sich auf Wunsch Vorlieben (Einstellungen › Assistent › „Das merkt sich der Assistent“, dort löschbar). Antwortet über Claude (Kontingent, Pro); ohne Netz mit Regeln auf dem Gerät.",
        .rueckblick: "Rückblick: oben die Bordkarte der Woche (KMP, MO → SO, Gate = aktive Ziele, Fokuszeit) – den goldenen Abschnitt abreißen (nach rechts ziehen oder antippen), dahinter liegt die Aussage „x % deiner Pläne geschafft“; abgerissen bleibt je Woche abgerissen. Woche (Plan geschafft, Fokuszeit mit Kurve über 12 Wochen, Ziele mit Balken und Lage, Zeit pro Ziel, Habits mit Quote, Auslastung, Wochenreflexion). Ziel oder Habit antippen öffnet die Analyse. Ziel-Analyse: Prozent, Lage, Plan heute, Prognose (fertig am … bei diesem Tempo, vor/nach der Frist), Verlauf-Kurve mit gestricheltem Plan, Meilensteine mit Stand, Einsatz der letzten 8 Wochen, verbundene Habits. Habit-Analyse: Quote 30 Tage, Serie, beste Serie, Quote 90 Tage, Raster der letzten 12 Wochen (ein Kästchen pro Tag), Anteil je Woche, Rhythmus, seit wann, insgesamt erledigt.",
    ]

    /// Fenster (Sheets) und was man dort tut – Schlüssel = Präfix der `Navigation.Blatt`-id
    static let fenster: [String: String] = [
        "neu": "+ Neu, geführt in Stufen (eine Frage je Schritt, Serif-Frage mit grünem Fragezeichen, Punkte unten, grüner Knopf Weiter, bei optionalen Schritten Überspringen): Was (vier Kacheln: Aufgabe, Termin, Habit, Ziel) → Titel (Beispiele) → Wann (Aufgabe: Tag Heute · Morgen · Datum · Ohne Datum; Uhrzeit erst nach dem Tag: Vormittag · Nachmittag · Abend · genau; Dauer erst nach der Uhrzeit. Termin: Tag, Von, Bis, Dauer. Habit: Rhythmus, feste Uhrzeit. Ziel: Frist) → Details (Aufgabe: Zählt für mit Ziel 3 + weitere und Meilenstein, Wichtig als Schalter, Wiederholen und Kategorie unter „Mehr“; Termin: Speichern in, Zählt für, Zählt in, unter „Mehr“ Habit, Wiederholen, Kategorie; Habit: Menge, Einheit 3 + weitere, Erinnerung; Ziel: Zahl-Meilenstein, Bereich, Warum) → Verbinden (Ziel: Habits, Termine, Aufgaben je 3 + weitere; Habit: Ziel, letzte 7 Tage, Termin) → Fertig (weiße Karte mit Zusammenfassung, Anlegen).",
        "info": "(i): kurze Erklärung der Seite.",
        "terminseite": "Termin-Seite (jeden Termin im Kalender antippen, auch aus Apple oder Google): kurze Bühne mit Uhrzeit und Titel als Wort, Herkunft (Kompass, Apple, Google); Karte vorn mit Tag · Zeit · Dauer · Wiederholung, Titel, Bearbeiten (Kompass-Termine und beschreibbare Apple/Google-Kalender) und Ziel-Analyse; darunter Kacheln Zählt für (Ziel), Zählt in (Meilenstein Zeit oder Zahl, sonst nur Einsatz), Erfüllt Habit (eigene Termine), Bearbeiten; ein Satz, was die Auswahl bewirkt; Löschen (Serie: nur dieser oder alle).",
        "externtermin": "Termin aus dem Apple- oder Google-Kalender bearbeiten: Titel, Tag, Von, Bis; speichert direkt in den Kalender des Geräts (bei Serien nur dieses Vorkommen); Termin löschen. Nur-Lese-Kalender (z. B. Feiertage, Abos) lassen sich nicht ändern.",
        "stunde": "Freie Stunde im Kalender (Tag) angetippt: „Was um 14:00?“ – drei Wege: Neuer Termin (geführt, Zeit vorbelegt), bis zu drei offene Aufgaben oder Habits genau hierhin legen, Fokus starten mit dem, was jetzt dran ist.",
        "neutermin": "Neuer Termin aus dem Kalender: wie „+ Neu“ Termin mit Tag und Uhrzeit vorbelegt (Titel → Wann → Zählt er für etwas? Ziel, Zählt in Meilenstein oder Nur Einsatz, Habit, Wiederholung → Passt das so?).",
        "einstellungen": "Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo-Daten neu laden.",
        "aufgabe": "Aufgabe als Seite in drei Ebenen: kurze Bühne mit dem Wort (Heute · Morgen · Überfällig · Datum, darunter Uhrzeit oder offen/erledigt) und dem startenden 747; Karte vorn mit Haken, Titel (bearbeitbar) und Fokus starten · Wichtig; „Zählt für“: Ziel (3 + weitere), Meilenstein (3 + weitere), ein Satz, ob und wie die Aufgabe zählt; Wann in Stufen: Tag (Heute · Morgen · Datum · Ohne), dann Uhrzeit (Vormittag · Nachmittag · Abend · genau), dann Dauer; unter „Mehr“: Wiederholen, Kategorie, Notizen, Löschen. Alles wird sofort gespeichert.",
        "habit": "Habit-Seite (im Tab Fortschritt): oben Stand heute (Ring, Menge oder offen/erledigt, Serie) mit einer Handlung (Abhaken bzw. Menge eintragen) und „Analyse“ (öffnet die Habit-Analyse im Rückblick: Serie, Quote, 12-Wochen-Raster); Einstellungs-Kacheln Wann (Rhythmus, Uhrzeit) · Wie viel (Menge) · Erinnerung · Verfeinern (Name, Aussehen, Im Kalender, Ziel, Tage nachtragen der letzten 14 Tage, löschen); darunter „Zählt für“ (Ziele und Meilensteine). Habits-Übersicht: Kacheln „Heute“ (x/y geschafft) und „Alle Habits“ (Wochenpunkte).",
        "habitbearbeiten": "Habit bearbeiten (einstellen, ändern): eine Zeile antippen – Titel, Menge mit Einheit (oder nur abhaken), Rhythmus (täglich, werktags, Wochentage, n-mal pro Woche), Erinnerung (aus oder Uhrzeit; beim ersten Mal fragt die App nach Erlaubnis für Mitteilungen), Ziel, Farbe und Symbol.",
        "fokus": "Fokus als Flug: ein Flugzeug fliegt über einen Nachthimmel von KMP zum Kürzel des Ziels; die Strecke ist die geplante Dauer der Aufgabe. Darunter Fokuszeit, Phase (Steigflug, Reiseflughöhe, Landeanflug, Gelandet, Warteschleife = Pause) und Instrumente Höhe, Strecke, Ankunft. Pause/Weiter; Fertig bucht die Zeit (an Mitternacht geteilt, höchstens 4 h am Stück); nach der Landung läuft der Timer weiter.",
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
                                          .terminZuZiel(id), .zielBearbeiten(id, .titel), .pro, .habitMenge(id, tag: "2026-01-01"), .habitBearbeiten(id, .menge), .termin(nil, tag: "2026-01-01", start: nil), .chats,
                                          .terminSeite(serie: "apple:x", tag: "2026-01-01"), .stunde(tag: "2026-01-01", start: 600), .neuTermin(tag: "2026-01-01", start: 600), .externTermin(id: "a:b", tag: "2026-01-01")]
        return faelle.map { String($0.id.split(separator: "-")[0]) }
    }
}
