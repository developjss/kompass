# Ziele, Habits, Aufgaben, Termine – Analyse und Rechnung v2

Stand: 23. November 2026 · Grundlage: Durchklicken der SwiftUI-App (Simulator) und `rechenregeln.md` v1. Umgesetzt in `Kompass/Rechnung/` und im Ziel-Detail; Regeln in `rechenregeln.md` (v2). [OFFEN] Freigabe durch den Gründer („Ja, mergen“).

## 1. Was beim Durchklicken auffiel (v1)

| # | Fund | Folge |
|---|---|---|
| 1 | „Ziel als Zahl“: Schritte sind nur „Planung“ und zählen nicht | „Fit: 75 kg & Halbmarathon“ zeigte 45 %, obwohl der Halbmarathon fehlt |
| 2 | Habits am Ziel zählen nur, wenn es zusätzlich einen Habit-Schritt gibt | Ein verknüpfter Habit bewegt die Prozente nicht – wirkt kaputt |
| 3 | Kalendertermine zählen nirgends | „Fahrstunden 6 von 30“ muss man von Hand pflegen, obwohl jede Fahrstunde im Kalender steht |
| 4 | Zwischenziele („100.000 € Vermögen“) muss man selbst abhaken | doppelte Pflege, Widerspruch zur Zahl möglich |
| 5 | Im Ziel lässt sich nichts hinzufügen, entfernen oder eintragen | Ziel ist nur Anzeige, nicht Werkzeug |
| 6 | Habit-Schritt zählt nur „Anzahl“ | „3× pro Woche, 8 Wochen“ lässt sich nicht abbilden; Durchhalten zählt nicht |
| 7 | „So wird gerechnet“ zeigt Formeln | schwer lesbar; gewünscht: kurz, wer wie viel beiträgt |
| 8 | Lernen nur als Formel, ohne Wirkung in der App | „App lernt dazu“ ist nicht sichtbar |

## 2. Das Modell v2 in einem Satz

**Ein Ziel besteht aus Meilensteinen. Fortschritt = gewichteter Durchschnitt der Meilensteine. Aufgaben, Habits, Fokuszeit und Termine fließen über Meilensteine ein – alles andere ist „Einsatz“ und ändert die Prozente nicht.**

Warum so: Prozente messen *Ergebnis*, nicht *Fleiß*. Wer 40 Stunden lernt und die Prüfung nicht hat, ist nicht bei 100 %. Einsatz wird trotzdem sichtbar (Abschnitt „Einsatz“, Rückblick).

### Vier Arten, einen Meilenstein zu messen

| Art | Stand | Was einfließt |
|---|---|---|
| Abhaken | fertig = 100 %; mit Aufgaben bis 90 % (erledigte ÷ alle) | Aufgaben dieses Meilensteins |
| Zahl | (Ist − Start) ÷ (Ziel − Start), beide Richtungen | eingetragene Stände + **je Termin 1** (z. B. Fahrstunde) |
| Zeit | Stunden ÷ Soll | Fokus-Timer + **Dauer zugeordneter Termine** |
| Habit | Anzahl ÷ Soll **oder** erfüllte Wochen ÷ Soll-Wochen | Abhaken des Habits ab Anlage |

- „Ziel als Zahl“ ist jetzt ein Ziel mit einem Zahl-Meilenstein. **Zwischenstände** (10.000 €, 100.000 €) hängen am Zahl-Meilenstein und werden automatisch erreicht – sie zählen nicht doppelt.
- Gewicht klein/mittel/groß = 1/2/3 bleibt.
- Abgehakt = 100 %; ein Meilenstein bei 100 % wird *nicht* automatisch abgehakt (der Nutzer bestätigt).

### Habit „Wochen durchhalten“

Eine Woche zählt, wenn an **allen geplanten Tagen** dieser Woche abgehakt ist (ab Anlage des Meilensteins). Die laufende Woche zählt erst, wenn sie erfüllt ist. So wird „3× pro Woche Sport, 8 Wochen“ exakt abbildbar und belohnt Durchhalten statt Einzeltage.

### Termine

Eine Termin-Serie (z. B. „Fahrstunde Do“) wird einem Ziel zugeordnet – optional einem Meilenstein. Es zählen nur **stattgefundene** Termine ab der Zuordnung (optional 4 Wochen rückwirkend). Gespeichert werden nur Tag und Dauer, kein Titel des einzelnen Termins, kein Ort, keine Teilnehmer.

## 3. Lernen – ohne die Prozente anzufassen

Grundsatz: **Lernen ändert nie bestehende Prozente, nur Vorschläge und Prognosen.** Sonst wäre die Rechnung nicht nachvollziehbar.

| Was | Wie | Wo sichtbar |
|---|---|---|
| Zeitfaktor | abgehakter Zeit-Meilenstein → tatsächlich ÷ geplant; r = (Σ + 3) ÷ (n + 3) | „Vorschlag: 28 h – du brauchst im Schnitt 1,1× so lange“ beim Anlegen |
| Habit-Soll (Anzahl) | geplante Tage bis zur Fälligkeit × bisherige 30-Tage-Quote | Vorschlag beim Verknüpfen |
| Habit-Soll (Wochen) | Wochen bis Fälligkeit × (erfüllte der letzten 8 + 1) ÷ 10 | Vorschlag beim Verknüpfen |
| Tempo | Prognose aus dem eigenen Verlauf (§5) | „Im jetzigen Tempo erreicht: April 2027“ |
| Über alle Nutzer | gleiche Formeln mit anonymen Summen | später (`lernen-ueber-alle-nutzer.md`) |

## 4. Was im Ziel jetzt geht

- **Meilensteine:** anlegen, bearbeiten (Art, Soll, Gewicht, Zwischenstände, Stand eintragen), abhaken/öffnen, löschen.
- **Aufgaben:** neu direkt im Ziel oder im Meilenstein, bestehende zuordnen (Meilenstein wählbar), lösen, abhaken.
- **Habits:** bestehend oder neu, „zählt in die Prozente“ an/aus, Anzahl oder Wochen, lösen.
- **Termine:** Serie zuordnen (Meilenstein oder nur Einsatz), lösen.
- **So wird gerechnet:** ein Satz + je Meilenstein „+x Pkt.“ – kein Rechenweg.
- **Ziel bearbeiten:** Titel, Warum, Bereich, Datum, Farbe, löschen (Aufgaben/Habits bleiben).

## 5. Weitere Verbesserungen (Vorschläge, noch nicht gebaut)

1. [VORSCHLAG] **Prognose je Meilenstein** statt nur je Ziel. Heute verschiebt jede neue Meilenstein-Struktur das Tempo (neuer Meilenstein senkt den Stand → Prognose springt). [RISIKO] bis dahin wirkt die Prognose nach Umbauten unruhig.
2. [VORSCHLAG] **Nicht-lineares „Auf Kurs“** für Zahlen mit Zinseszins (Vermögen): heute linear, dadurch „hinterher“ obwohl im Plan.
3. [VORSCHLAG] **Termine im Kalender direkt zuordnen** (Termin antippen → Ziel/Meilenstein), nicht nur im Ziel.
4. [VORSCHLAG] **Abhaken-Meilenstein mit erwarteter Aufgabenzahl**: heute sinkt der Stand, wenn man Aufgaben ergänzt (ehrlich, aber überraschend). Alternative: „geplant: 8 Aufgaben“ als Nenner, bis mehr da sind.
5. [VORSCHLAG] **Ausgefallene Termine** markieren (zählen dann nicht).
6. [VORSCHLAG] **Ziel-Vorlagen** (Führerschein, Halbmarathon …) mit typischen Meilensteinen; Übernahme-Quote lernt, welche Vorschläge passen (§7, schon gerechnet, noch ohne Oberfläche).
7. [VORSCHLAG] **Habit „x-mal pro Woche an beliebigen Tagen“** zusätzlich zu festen Wochentagen.

## 6. Offene Entscheidungen

| [OFFEN] | Vorschlag Claude |
|---|---|
| Modell v2 (nur Meilensteine zählen, Rest = Einsatz) | so übernehmen |
| Termine zählen in Zahl (je 1) und Zeit (Dauer) | so übernehmen |
| Habit-Wochen: Woche zählt nur, wenn **alle** geplanten Tage erledigt sind | so übernehmen; Alternative „≥ 80 % der Tage“ |
| 90-%-Regel bei Abhaken-Meilensteinen | so lassen |
| Meilenstein bei 100 % nicht automatisch abhaken | so lassen |
