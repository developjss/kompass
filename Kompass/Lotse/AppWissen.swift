import Foundation

/// Was der Lotse über die App weiß – aus dem Code erzeugt, nicht von Hand gepflegt.
/// Quellen: `Bereich` (Tabs), `InfoThema` (Erklärtexte), `SchrittArt` (Rechenregeln), `Werkzeuge` (was er tun kann).
/// Ein Test (`LotseTests`) prüft, dass jeder Tab, jedes Fenster und jede Meilenstein-Art beschrieben ist –
/// wer etwas Neues baut, muss den Lotsen mitziehen, sonst wird der Test rot.
enum AppWissen {

    /// Kurzbeschreibung je Tab – auch Antwort auf „Wo finde ich …?“
    static let bereiche: [Bereich: String] = [
        .heute: "Home (erster Tab): Jetzt-Karte, darunter „Als Nächstes“ als Kartenstapel (Kopf: Nächstes in x Min oder Läuft gerade; Karten mit Tag und Ziel, Uhrzeit rechts; Alle ansehen fächert auf), darunter „Dein Tag im Blick“ als Reel (Slides: Jetzt, Danach, wie voll der Tag ist, Heute offen, Ziele, Los); dann mit dem, was läuft oder als Nächstes kommt (Termin, Aufgabe oder Habit) – Fokus starten, Erledigt, Menge; Hinweise (enger Tag, Überschneidung, zu wenig Zeit); Als Nächstes; Heute offen (Aufgaben und Habits ohne Uhrzeit); Liegen geblieben; Ziele; Tagesabschluss.",
        .kalender: "Kalender: ganz oben der Umschalter Tag (Wochenleiste, darunter Leiste „Vorschläge · ziehen oder antippen“ mit Aufgaben und Habits samt freier Uhrzeit – antippen zeigt „um 11:15 einplanen“, zurück auf die Leiste ziehen = ohne Uhrzeit; dann die Zeitleiste: Einträge mit Ziel-Zeichen, wenn sie für ein Ziel zählen, Aufgaben und Habits direkt abhaken; freie Stunde antippen = „Was um 14:00?“: neuer Termin geführt oder Offenes hierhin legen), Woche (breite Spalten, etwa 3 Tage sichtbar, waagerecht wischen; Einträge mit Titel und Uhrzeit), Monat (Raster mit farbigen Einträgen), Jahr (Auslastung); in Woche/Monat darunter „Empfehlung“ als Kartenstapel (freiester Tag bis zur Frist). Verschieben: Eintrag 0,3 s halten und ziehen – er bleibt groß, eine gestrichelte Vorschau mit Uhrzeit zeigt, wo er landet (15-Minuten-Raster); in der Woche auch auf andere Tage; über den oberen Rand = ohne Uhrzeit; Kompass-Serien verschieben nur die Uhrzeit. Vorschläge aus der Leiste ziehen: Vorschau in voller Länge an der Stelle. VoiceOver: Aktionen „15 Minuten später/früher“. Jeden Termin antippen (auch Apple/Google) öffnet die Termin-Seite. Farben nach Ziel oder Kategorie (Einstellungen). Termine aus Apple (EventKit), Google als Beispiel, eigene Kompass-Termine.",
        .fortschritt: "Fortschritt: oben umschalten zwischen Zielen (Filter-Kacheln Alle · Auf Kurs · Hinterher · Erreicht, Sortieren, Zielkarten mit Ring; Ziel-Seite: oben Stand (Ring, Prozent, Lage, Als Nächstes, „Analyse im Rückblick“ öffnet die Ziel-Analyse mit Verlauf und Prognose), darunter Einstellungs-Kacheln Bis wann · Warum · Name · Verfeinern (Kacheln Aufgaben, Habits, Termine, Einsatz, Details, „Geschafft?“ = als erreicht markieren), darunter die Meilensteine als Karten mit Stand und „zählt x %“ – antippen zum Ändern, „Meilenstein hinzufügen“ geführt; Liste mit Filter-Kacheln Alle · Auf Kurs · Hinterher · Erreicht und Sortieren nach Frist, Jahr, Fortschritt, Hinterher zuerst, Bereich, Name) und Habits (Heute abhaken oder Menge eintragen, Diese Woche, Alle Habits mit Soll, Rhythmus, Erinnerung, Quote, Serie).",
        .lotse: "Assistent (Tab in der Mitte, früher „Lotse“): dieser Chat. Fragen zur App, zu Zielen, Habits, Aufgaben, Terminen und zur Analyse, dazu allgemeine Fragen und Aktuelles über die Websuche (mit Quellen); Aufgaben und Termine anlegen. Merkt sich auf Wunsch Vorlieben (Einstellungen › Assistent › „Das merkt sich der Assistent“, dort löschbar). Antwortet über Claude (Kontingent, Pro); ohne Netz mit Regeln auf dem Gerät.",
        .rueckblick: "Rückblick: oben die Bordkarte der Woche (KMP, MO → SO, Gate = aktive Ziele, Fokuszeit) – den goldenen Abschnitt abreißen (nach rechts ziehen oder antippen), dahinter liegt die Aussage „x % deiner Pläne geschafft“; abgerissen bleibt je Woche abgerissen. Woche (Plan geschafft, Fokuszeit mit Kurve über 12 Wochen, Ziele mit Balken und Lage, Zeit pro Ziel, Habits mit Quote, Auslastung, Wochenreflexion). Ziel oder Habit antippen öffnet die Analyse. Ziel-Analyse: Prozent, Lage, Plan heute, Prognose (fertig am … bei diesem Tempo, vor/nach der Frist), Verlauf-Kurve mit gestricheltem Plan, Meilensteine mit Stand, Einsatz der letzten 8 Wochen, verbundene Habits. Habit-Analyse: Quote 30 Tage, Serie, beste Serie, Quote 90 Tage, Raster der letzten 12 Wochen (ein Kästchen pro Tag), Anteil je Woche, Rhythmus, seit wann, insgesamt erledigt.",
    ]

    /// Fenster (Sheets) und was man dort tut – Schlüssel = Präfix der `Navigation.Blatt`-id
    static let fenster: [String: String] = [
        "neu": "+ Neu, geführt in Schritten: Was (Aufgabe, Termin, Habit, Ziel als Kacheln) → Titel (mit Beispielen und Vorschlag) → Wann → Details → bei Ziel und Habit „Verbinden“ → Passt das so? → Anlegen. Ziel: Meilenstein-Vorlage aus dem Titel, Bereich und Warum, dann „Was zählt schon dafür?“ – bestehende Habits, Termin-Serien (jeder Termin zählt einmal) und Aufgaben werden Meilensteine, Bisheriges zählt auf Wunsch mit. Habit: Rhythmus, Uhrzeit, Menge, Erinnerung, dann „Gehört er zu etwas?“ – Ziel (zählt als Meilenstein in die Prozente oder nur Einsatz), Tage der letzten Woche nachtragen, ein Kompass-Termin, der ihn erfüllt.",
        "info": "(i): kurze Erklärung der Seite.",
        "terminseite": "Termin-Seite (jeden Termin im Kalender antippen, auch aus Apple oder Google): oben Titel, Tag, Uhrzeit und Herkunft; Kacheln Zählt für (Ziel wählen), Zählt in (Meilenstein Zeit = Dauer zählt, Zahl = jeder Termin zählt 1, oder Nur Einsatz), Erfüllt Habit (nur Kompass-Termine), Bearbeiten (Kompass) bzw. Ändern im Apple-/Google-Kalender; bei Apple/Google gilt die Wahl für die ganze Serie; Ziel-Analyse; Termin löschen (Kompass).",
        "stunde": "Freie Stunde im Kalender (Tag) angetippt: „Was um 14:00?“ – Neuer Termin (geführt, Zeit vorbelegt) oder eine offene Aufgabe bzw. einen Habit genau zu dieser Uhrzeit einplanen.",
        "neutermin": "Neuer Termin aus dem Kalender: wie „+ Neu“ Termin mit Tag und Uhrzeit vorbelegt (Titel → Wann → Zählt er für etwas? Ziel, Zählt in Meilenstein oder Nur Einsatz, Habit, Wiederholung → Passt das so?).",
        "einstellungen": "Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo-Daten neu laden.",
        "aufgabe": "Aufgabe: Titel, erledigt, wichtig, Datum, Wiederholung, Ziel und „Zählt in“ (Meilenstein „Aufgaben“ = zählt erledigt, „Zeit“ = zählt die Fokuszeit, „Nur Einsatz“ = zählt nicht in die Prozente; ohne passenden Meilenstein Hinweis und „Meilenstein Aufgaben anlegen“), Notizen, löschen oder Serie beenden.",
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
                                          .terminSeite(serie: "apple:x", tag: "2026-01-01"), .stunde(tag: "2026-01-01", start: 600), .neuTermin(tag: "2026-01-01", start: 600)]
        return faelle.map { String($0.id.split(separator: "-")[0]) }
    }
}
