# Plattformen und Speicherung

Stand: 23. November 2026.

## Plattformen
Zuerst iPhone und Mac (SwiftUI, Weg A [ENTSCHEIDUNG – 23.11.2026]), danach Windows und Android (Web-App oder Flutter). Details: `docs/leitung/fahrplan.md` §3.

## Datenmodell (aus dem Klick-Dummy, so übernehmen)
- **Ziel:** id, Titel, Farbe, Symbol, Bereich, Fälligkeit, Warum, Status (aktiv|erreicht), Anlage, Messart (Schritte | Zahl mit Start/Aktuell/Ziel/Einheit/Verlauf), Schritte.
- **Schritt:** id, Titel, Art (auto|time|habit|number), Gewicht 1–3, geschafft, seit, Soll, Start/Aktuell/Einheit (Zahl), habitId (Habit).
- **Habit:** id, Titel, Farbe, Symbol, Rhythmus (täglich | Wochentage | n-mal pro Woche), Soll-Menge + Einheit (optional), Erinnerung (Uhrzeit, optional), Ziel (optional), Einträge {Datum: Menge}, Anlage. Alte Felder `wochentage`/`erledigt` werden beim Lesen übernommen.
- **Aufgabe:** id, Titel, Datum (leer = Eingang), Uhrzeit, Dauer, Priorität (hoch|normal), Reihenfolge, Ziel, Schritt, erledigt/Zeitpunkt, Fokuszeit, Notizen, Wiederholung, Serie, Anker-Tag.
- **Fokus-Sitzung:** Aufgabe, Ziel, Schritt, Datum, Dauer (an Mitternacht geteilt).
- **Termin-Verknüpfung:** Serie (Quelle:Schlüssel) → Ziel oder Habit, seit.
- **Reflexion:** Tag|Woche, Datum, Antworten. **Lernen:** Zeitfaktoren, Vorschlags-Quoten, eigene Schritte. **Verlauf:** Fortschritt je Ziel und Tag.

## Speicherung
- **Klick-Dummy:** Browser (gebündelt alle 0,4 s + beim Verlassen) und privat im Claude-Konto.
- **App, jetzt:** JSON-Datei auf dem Gerät (`Kompass/App/Speicher.swift`), offline vollständig.
- **App, Schritt 1:** lokal (SwiftData), offline vollständig.
- **Lotse-Server:** Supabase Edge Function (`supabase/functions/lotse/`), speichert nur Zähler je Geräte-ID und Tag.
- **App, Schritt 2:** Sync über einen Server (z. B. Supabase) mit Zeitstempel je Zeile; Kalendertermine werden nicht kopiert, nur die Zuordnung.
- Größe nach 2 Jahren laut Personen-Test: 280–500 KB je Person (lokal unkritisch; für Sync in Tabellen statt eines Dokuments).
