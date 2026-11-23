import Foundation

/// Was der Lotse über die App weiß – aus dem Code erzeugt, nicht von Hand gepflegt.
/// Quellen: `Bereich` (Tabs), `InfoThema` (Erklärtexte), `SchrittArt` (Rechenregeln), `Werkzeuge` (was er tun kann).
/// Ein Test (`LotseTests`) prüft, dass jeder Tab, jedes Fenster und jede Meilenstein-Art beschrieben ist –
/// wer etwas Neues baut, muss den Lotsen mitziehen, sonst wird der Test rot.
enum AppWissen {

    /// Kurzbeschreibung je Tab – auch Antwort auf „Wo finde ich …?“
    static let bereiche: [Bereich: String] = [
        .heute: "Heute: die eine Aufgabe, die jetzt dran ist, dann Wichtig, Weitere, Geschafft, fällige Habits, Termine und die nächsten Ziele. Unten der Tagesabschluss.",
        .kalender: "Kalender: Wochenleiste, Termine aus Google/Apple neben deinen Aufgaben mit Uhrzeit, Aufgaben ohne Uhrzeit, Eingang für Ideen ohne Datum.",
        .fortschritt: "Fortschritt: oben umschalten zwischen Zielen (Prozent, Auf Kurs, Frist, Meilensteine) und Habits (Woche abhaken, Serie, Quote).",
        .lotse: "Lotse: dieser Chat. Fragen zur App, zu Zielen, Habits, Aufgaben, Terminen und zur Analyse; Aufgaben anlegen.",
        .rueckblick: "Rückblick: Fokuszeit der Woche mit Kurve über 12 Wochen, Zeit pro Ziel, Habit-Quote, Wochenreflexion.",
    ]

    /// Fenster (Sheets) und was man dort tut – Schlüssel = Präfix der `Navigation.Blatt`-id
    static let fenster: [String: String] = [
        "neu": "+ Neu: Aufgabe, Habit oder Ziel anlegen.",
        "info": "(i): kurze Erklärung der Seite.",
        "einstellungen": "Daten & Kalender: Beispielkalender ein/aus, Speicherort, Demo-Daten neu laden.",
        "aufgabe": "Aufgabe: Titel, erledigt, wichtig, Datum, Wiederholung, Ziel, Notizen, löschen oder Serie beenden.",
        "habit": "Habit: Serie, beste Serie, Quote, Wochentage, Ziel, löschen.",
        "fokus": "Fokus-Timer: läuft zur Aufgabe, Pause/Weiter, Fertig bucht die Zeit (an Mitternacht geteilt, höchstens 4 h am Stück).",
        "rechnung": "So wird gerechnet: ein Satz und je Meilenstein der Beitrag in Prozentpunkten.",
        "reflexion": "Tagesabschluss (3 Fragen) bzw. Wochenreflexion (3 Fragen).",
        "meilenstein": "Meilenstein: Titel, Messart (Abhaken, Zahl, Zeit, Habit), Soll, Gewicht klein/mittel/groß, geschafft, Zwischenstände, Stand eintragen, löschen.",
        "habitzuziel": "Habit zum Ziel: bestehenden oder neuen Habit verbinden; zählt in die Prozente (Anzahl oder Wochen) oder nur als Einsatz.",
        "aufgabezuziel": "Aufgaben zum Ziel: bestehende Aufgaben einem Ziel und Meilenstein zuordnen.",
        "terminzuziel": "Termine zum Ziel: eine Termin-Serie zuordnen; zählt in Zahl (je 1) oder Zeit (Dauer) oder nur als Einsatz.",
        "zielbearbeiten": "Ziel bearbeiten: Titel, Warum, Bereich, Datum, Farbe, löschen (Aufgaben und Habits bleiben).",
    ]

    /// Rechenregeln in Sätzen (Quelle: rechenregeln.md Fassung 2) – der Lotse erklärt, rechnet aber nie.
    static var regeln: [String] {
        [
            "Ein Ziel besteht aus Meilensteinen. Fortschritt = gewichteter Durchschnitt der Meilensteine; mittel zählt doppelt, groß dreifach.",
        ] + SchrittArt.allCases.map { "\($0.name): \($0.erklaerung)" } + [
            "Alles ohne Meilenstein (Aufgaben, Habits, Termine, Fokuszeit) zählt als Einsatz und ändert die Prozente nicht.",
            "Auf Kurs vergleicht Fortschritt mit der verstrichenen Zeit: 5 Punkte darüber = voraus, 10 darunter = hinterher.",
            "Prognose: Tempo der letzten 4 Wochen, ab 7 Tagen Verlauf.",
            "Habit-Serie: geplante Tage rückwärts bis zum ersten verpassten; heute zählt erst nach dem Abhaken. Quote = erledigte ÷ geplante Tage der letzten 30 Tage.",
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
        let faelle: [Navigation.Blatt] = [.neu(nil), .info(.heute), .einstellungen, .aufgabe(id), .habit(id), .fokus(id), .rechnung(id),
                                          .reflexion(woche: false), .meilenstein(ziel: id, schritt: nil), .habitZuZiel(id), .aufgabeZuZiel(id),
                                          .terminZuZiel(id), .zielBearbeiten(id)]
        return faelle.map { String($0.id.split(separator: "-")[0]) }
    }
}
