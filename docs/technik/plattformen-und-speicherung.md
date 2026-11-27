# Plattformen und Speicherung

Stand: 27. November 2026.

## Plattformen
Zuerst iPhone (SwiftUI [ENTSCHEIDUNG – 23.11.2026]), dann Mac, später Android und Windows (`docs/leitung/fahrplan.md`).

## Kalender
Nur lesen (EventKit, nach Zustimmung): damit sieht Kompass alle Kalender, die im iPhone eingerichtet sind (iCloud, Google, Outlook). Termine legt man über Apples Termin-Fenster an (EventKitUI), Kompass speichert keine Termine, nur Zuordnungen (Termin-Serie → Ziel oder Habit).

## Datenmodell (`Kompass/Modell/Modell.swift`)
- **Ziel:** id, Titel, Farbe, Symbol, Bereich, Fälligkeit, Warum, Status (aktiv|erreicht), Anlage, Messart (Schritte | Zahl mit Start/Aktuell/Ziel/Einheit/Verlauf), Schritte.
- **Schritt:** id, Titel, Art (auto|time|habit|number), Gewicht 1–3, geschafft, seit, Soll, Start/Aktuell/Einheit (Zahl), habitId (Habit).
- **Habit:** id, Titel, Farbe, Symbol, Rhythmus (täglich | Wochentage | n-mal pro Woche), Soll-Menge + Einheit (optional), Erinnerung (Uhrzeit, optional), Ziel (optional), Einträge {Datum: Menge}, Anlage. Alte Felder `wochentage`/`erledigt` werden beim Lesen übernommen.
- **Erinnerungen:** lokale Mitteilungen über UserNotifications (`Kompass/App/Erinnerungen.swift`), nichts verlässt das Gerät. Nach jeder Änderung werden die nächsten 7 Tage neu geplant (Kennung `habit-<id>-<datum>`); die App fragt beim ersten Einschalten einer Erinnerung um Erlaubnis.
- **Aufgabe:** id, Titel, Datum (leer = Eingang), Uhrzeit, Dauer, Priorität (hoch|normal), Reihenfolge, Ziel, Schritt, erledigt/Zeitpunkt, Fokuszeit, Notizen, Wiederholung, Serie, Anker-Tag.
- **Fokus-Sitzung:** Aufgabe, Ziel, Schritt, Datum, Dauer (an Mitternacht geteilt).
- **Termin-Verknüpfung:** Serie (Quelle:Schlüssel) → Ziel oder Habit, seit.
- **Reflexion:** Tag|Woche, Datum, Antworten (wird zum Journal-Eintrag mit Stimmung 1–5). **Lernen:** Zeitfaktoren, Vorschlags-Quoten, eigene Schritte. **Verlauf:** Fortschritt je Ziel und Tag.

## Speicherung
- **App, jetzt:** JSON-Datei auf dem Gerät (`Kompass/App/Speicher.swift`), offline vollständig.
- **App, Schritt 1:** lokal (SwiftData), offline vollständig.
- **Lotse-Server:** Supabase Edge Function (`supabase/functions/lotse/`), speichert nur Zähler je Geräte-ID und Tag.
- **App, Schritt 2:** Sync über einen Server (z. B. Supabase) mit Zeitstempel je Zeile; Kalendertermine werden nicht kopiert, nur die Zuordnung. Journaltexte nur mit Einwilligung (Prüffrage in `docs/recht/recht-und-sicherheit.md`).
- Größe nach 2 Jahren laut Personen-Test: 280–500 KB je Person (lokal unkritisch; für Sync in Tabellen statt eines Dokuments).
