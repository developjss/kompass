# Klick-Dummy

Stand: 23. November 2026 · Phase 0. Kein App-Code – ein HTML-Prototyp zum Ausprobieren und als genaue Vorlage für die SwiftUI-App.

| Datei | Was |
|---|---|
| `index.html` | Desktop-Ansicht (Mac/Windows); unter 760 px Breite automatisch Handy-Ansicht |
| `phone.html` | dieselbe App im iPhone-Rahmen (auf dem Handy ohne Rahmen) |
| `tests/run.py` | Personen-Test: 4 Personen × 2 Jahre, zufällige Eingriffe, jede Zahl gegen `tests/sim.js` |
| `tests/unit.py` | Randfälle (Wiederholung, Fälligkeit, Mitternacht, KW, Fortschritt) |
| `tests/personas.py` | die vier Personen (Vermögen, Tagesablauf) |

**Öffnen:** Datei im Browser öffnen. Veröffentlicht: Desktop https://claude.ai/artifact/WGCELrUQhpXXw83xyqfoyG · iPhone https://claude.ai/artifact/8eGuar3yT9cbmESEypVfRq

**Pflege:** `phone.html` entsteht aus `index.html` (gleicher Code + iPhone-Rahmen). Nach Änderungen an `index.html` beide neu veröffentlichen, Tests laufen lassen, Bilder neu (`python3 scripts/bilder.py`) und den Roten Faden bauen.

**Wo was im Code steht** (Abschnitte in `index.html`): Helfer · Demo-Daten (`seed`) · Speicherung · Fortschritts-Rechnung (= `docs/produkt/rechenregeln.md`) · Vorschläge & Lernen · Kalender (Beispieltermine) · Ansichten (`vHome`, `vCal`, `vHabits`, `vGoals`, `vReview`) · Fenster (`sheet…`) · Fokus-Timer · Aktionen (`A`) · Drag & Drop.

**Speicherung:** im Browser und – wenn als Artefakt in claude.ai geöffnet – privat im Claude-Konto. KI-Vorschläge nur im Artefakt (claude.ai fragt einmal nach Erlaubnis); offline gibt es die Vorlagen.
