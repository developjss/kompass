# Personen-Test Struktur v3 – 6 Personen × 3,5 Jahre

Stand: 23. November 2026 · Swift-Test `KompassTests/PersonenTests.swift` (Aufgabe `s-personentest`), deterministisch (fester Zufall), Zeitraum 23.11.2026 – 22.05.2030 (1.277 Tage je Person).

## 1. Was geprüft wird

Jede Person benutzt die App Tag für Tag über die echten Aktionen (`Kompass/Rechnung/Aktionen.swift`): Aufgaben anlegen (mit/ohne Tag, Uhrzeit, Dauer, Ziel, Kategorie, Wiederholung), erledigen, Fokus-Timer, Habits abhaken und Teilmengen eintragen, Aufgaben/Habits in den Kalender ziehen, Termine anlegen (einmalig, wöchentlich, werktags, täglich, monatlich; mit Ziel oder Habit), Zahl-Meilensteine, Ziele erreicht/gelöscht, Farben umschalten. Ungeschickte Personen machen auch Unsinn (leere Titel, Dauer −10 oder 2000 Min, Mengen −5 und 10⁹, Zahl NaN/±10¹², Termin endet vor dem Start, Uhrzeit −50/3000).

Nach **jedem Tag** rechnet der Test unabhängig nach:

| Prüfung | Wie |
|---|---|
| Ziel-Fortschritt | 0–100 %, = Σ(Gewicht × Stand) ÷ Σ Gewicht mit eigener Gewichtsregel; erreicht = 100 % |
| Meilensteine, Verlauf | jeder Stand und Verlaufswert endlich und in 0–1 |
| Habits | Quote 0–1; Serie per eigener Rückwärtszählung (Tages-Habits); Anteil 0–1; Dauer > 0 |
| Tagesplan | verplante Minuten über ein eigenes Minutenraster (7–22 Uhr), frei, enger Tag; Blöcke enden nach dem Start |
| Als Nächstes | höchstens 3, sortiert, nichts Vergangenes oder Erledigtes, beginnt mit dem nächsten offenen Block |
| Hinweise (wöchentlich) | Überschneidung genau dann, wenn zwei offene Blöcke ≥ 5 Min überlappen; keine doppelten Hinweise |
| Wochenbilanz, Erinnerungen | Quote 0–1; ≤ 60 Mitteilungen, nur Zukunft |
| Wiederholungen | je Serie höchstens eine offene Kopie in der Zukunft |
| Speichern | alle 90 Tage: Lesen(Schreiben(Zustand)) == Zustand |
| Lotse | alle 30 Tage: 9 Werkzeuge antworten, kein „nan“/„inf“ |

## 2. Personen und Ergebnis

| Person | Geschick | So nutzt sie die App | Ergebnis |
|---|---|---|---|
| Lena · Studentin, strukturiert | hoch | 3 Ziele, 3 Habits mit Uhrzeit, Vorlesungen als Termine, Ziehen, Timer | grün |
| Tom · Azubi, chaotisch | niedrig | viel Unsinn, löscht Aufgaben/Ziele/Habits, schaltet hin und her | grün |
| Erika · Rentnerin, wenig Technik | niedrig | öffnet die App an jedem 3. Tag, ein Habit, nie Uhrzeiten | grün |
| Jonas · Gewohnheitstier | mittel | 6 Habits (täglich, Wochentage, n-mal pro Woche), Teilmengen, Ziehen | grün |
| Mia · Planerin | hoch | 14 Termine je Woche, viele Überschneidungen, Termine mit Habit | **2 Befunde → behoben** |
| Ahmet · Gründer | sehr hoch | alles, inkl. Wiederholungen, Zahl-Meilensteine mit Zwischenständen, Ziele erreicht | **5 Befunde → behoben** |

## 3. Befund und Behebung

- **Doppelte Hinweise** (Mia 2×, Ahmet 5×): Überschneiden sich zwei gleich benannte Termine mit demselben dritten Block, entstanden zwei Hinweise mit gleicher Kennung. In der Home-Liste hätte SwiftUI Zeilen vertauscht oder verschluckt. **Behoben** in `Tagesplan.hinweise` (gleicher Hinweis am gleichen Tag nur einmal), Test `TagesplanBefundTests.gleicheTitelGebenEinenHinweis`.
- Unsinns-Eingaben (Dauer ≤ 0, riesige Mengen, NaN, Termin endet vor Start, Uhrzeit außerhalb 0–24 h) führten in 7.662 simulierten Tagen zu **keiner** falschen Zahl: Rechnung begrenzt, ignoriert oder klemmt sie.

## 4. Verstehen die Personen die App? [SCHÄTZUNG – Durchsicht der Bildschirme, kein echter Nutzertest]

| Person | Was sie sofort versteht | Wo sie hängen bleibt | Änderung |
|---|---|---|---|
| Erika | Home: große Karte „Als Nächstes … Abhaken“ | Ziehen in den Kalender (Geste unbekannt) | Hinweiszeile „Halten und in den Kalender ziehen“; Haken funktioniert ohne Ziehen |
| Tom | Haken, „+ Neu“ | Hinweise zu Überschneidungen waren lang | Text gekürzt: „A und B gleichzeitig“ |
| Jonas | Habit-Seite, Menge eintragen | wo die feste Uhrzeit eines Habits einstellbar ist | Fakten-Zeile „Im Kalender“ auf der Habit-Seite |
| Lena | Tag/Woche/Monat/Jahr | Woche: Titel in schmalen Spalten | Titel einzeilig gekürzt, Überschneidungen nebeneinander |
| Mia | Hinweise „enger Tag“ | – | – |
| Ahmet | Rückblick „x % deiner Pläne geschafft“ | – | – |

[RISIKO] Ziehen & Ablegen ist nur per langem Drücken erreichbar. VoiceOver-Nutzer haben im Eingang die Aktion „Auf … legen“; eine Uhrzeit setzen sie über die Aufgabe selbst.

## 5. Grenzen

Der Test prüft Rechnung und Daten, nicht die Wahrnehmung. Echte Nutzer (TestFlight) bleiben nötig. Laufzeit: etwa 4–5 Minuten im Simulator.
