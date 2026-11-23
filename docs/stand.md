# Stand und nächste Schritte – Kompass

Stand: 23. November 2026 (Europe/Berlin) · **Lebendes Dokument:** nach jedem gemergten Block und nach jeder Entscheidung aktualisieren. Wo welches Dokument liegt: `docs/README.md`. Wie wir arbeiten: `docs/team/arbeitsweise.md`.

## 1. Worum es geht

- **Kompass** (Arbeitstitel) verbindet **heute** (Aufgaben, Termine), **täglich** (Habits) und **morgen** (Ziele über Monate und Jahre) in einer App. Jede Aufgabe, jeder Habit und jeder Kalendertermin kann einem Ziel zugeordnet werden.
- **USP** [VORSCHLAG]: ergänzt Google- und Apple-Kalender (ersetzt sie nicht, kann es aber) und zeigt ehrlich, wie viel vom Alltag wirklich auf große Ziele einzahlt – mit nachvollziehbarer Rechnung („So wird gerechnet“).
- Ziel: veröffentlichen. Zuerst iPhone und Mac, danach Windows und Android (`docs/leitung/fahrplan.md`).
- Ausgangspunkt: Word „Idee“ des Gründers mit 6 Prinzipien (liegt beim Gründer, nicht im Repo), Inhalt in `docs/produkt/grundlage.md`.
- Repo: `kompass` (privat), getrennt von Gapless. Lokal: `~/Developer/Kompass` (Gapless bleibt in `~/Developer/UpcomingAPP-git`).

## 2. Aktueller Stand

**Phase 0 – Klick-Dummy: fertig (23.11.2026)** – alles in `prototyp/`:
- Fünf Bereiche: Heute, Kalender (Planen und Kalender in einem), Habits, Ziele, Rückblick. Fokus-Timer, Hinzufügen-Kacheln, Einstellungen mit Kalender-Verbindung (Beispieltermine).
- Design wie Gapless (Harbor 2): Indigo, SF Pro Rounded, Verlaufskarten, gruppierte Listen, Text ≤ ~35 Wörter je Bildschirm (`docs/produkt/design.md`).
- **Fortschritts-Rechnung** mit Schritten (Aufgaben/abhaken, Zeit, Habit, Zahl), Gewichten, „Auf Kurs“, Prognose und Lernen; Vorschläge aus Vorlagen und KI (`docs/produkt/rechenregeln.md`).
- Speicherung: Browser + privat im Claude-Konto (nur Prototyp).
- **Personen-Test** (4 Personen × 2 Jahre, ~46.000 Vergleiche, 324 zufällige Eingriffe): grün. 13 Fehler gefunden und behoben (`docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md`).
- Veröffentlichte Klick-Dummys: Desktop https://claude.ai/artifact/WGCELrUQhpXXw83xyqfoyG · iPhone https://claude.ai/artifact/8eGuar3yT9cbmESEypVfRq
- Plan-Dokument (erste Fassung, teils überholt): https://claude.ai/artifact/C4GGc8iQmAQj542WrpLP9b

**Phase 2 begonnen – erste SwiftUI-Fassung (23.11.2026):** `Kompass.xcodeproj` mit Schemes Kompass und Kompass Beta. Rechen-Logik als Swift-Port mit 42 Tests, fünf Bereiche grob wie im Klick-Dummy, Speicherung als Datei auf dem Gerät, Beispieltermine. Kein Server, keine echte Kalender-Anbindung. Details und Lücken: `docs/technik/app.md`.

**Rechnung Fassung 2 (23.11.2026, wartet auf „Ja, mergen“):** Ziele bestehen nur aus Meilensteinen; Aufgaben, Habits, Termine fließen über Meilensteine ein, der Rest zählt als Einsatz. Ziel-Detail zum Bearbeiten. Analyse: `docs/produkt/konzepte/ziele-und-rechnung.md`.

## 3. Nächste Schritte

Reihenfolge: `/fahrplan` (Phase 1).
1. **Entscheidungen des Gründers** (`docs/leitung/entscheidungen.md`, [OFFEN]): App-Name, Sprache der App-Texte, nur für sich oder verkaufen (Abo), 90-%-Regel und Habit-Zählung bestätigen.
2. Klick-Dummy eine Woche selbst nutzen, Funde in `/fahrplan` sammeln.
3. Phase 2 weiter: Personen-Test als Swift-Test, SwiftData, dann Heute, Habits, Ziele fein ausbauen (Design und Funktionen ändern sich noch).
