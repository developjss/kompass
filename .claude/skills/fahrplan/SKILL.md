---
name: fahrplan
description: Zeigt den Fahrplan von Kompass – was heute zu tun ist, was bald kommt und was später – für eine Person oder als Überblick aller. Weist Aufgaben zu, hakt sie ab, legt neue an und exportiert nach Excel/CSV. Nutzen bei "/fahrplan", "was ist heute dran", "meine Aufgaben", "Aufgaben für <Name>", "Fahrplan exportieren".
---

# /fahrplan

Eine Quelle für alle Aufgaben: `docs/leitung/aufgaben/aufgaben.json` (Bausteine, wiederkehrende Pflichten, Stichtage, Ereignisse). Gerechnet wird nur im Skript `scripts/fahrplan.py`; nie Termine selbst ausrechnen.

## Ablauf

1. **Prüfen:** `python3 scripts/fahrplan.py check` und `python3 scripts/ordnung.py`. Fehler zuerst nennen (bei eigenen Änderungen beheben). Hinweise der Ordnungs-Prüfung nur kurz erwähnen; ist die Aufgabe `r-aufraeumen` fällig, die Hinweise abarbeiten und danach `erledigt r-aufraeumen`.
2. **Person klären:**
   - Nennt der Aufruf eine Person (`/fahrplan Claude`, `/fahrplan alle`), diese nehmen. `python3 scripts/fahrplan.py team` zeigt Namen und ids.
   - Sonst mit AskUserQuestion fragen: „Für wen?“ – Optionen: „Alle · Überblick“ und die Personen aus `team`, die Aufgaben haben (höchstens 4 Optionen; der Rest über „Other“).
3. **Übersicht holen:** `python3 scripts/fahrplan.py heute --wer <id|alle>` (Datum = heute; `--datum` nur auf Wunsch).
4. **Antworten auf Deutsch, aufbereitet:**
   - **Heute zu tun** zuerst: überfällig, heute, dazu die wichtigsten Aufgaben ohne Datum. Je Punkt eine Zeile: was, wer, bis wann.
   - Dann **Bald (14 Tage)**, **Als Nächstes**, **Wartet** und **Später** – nur Zahlen und die 2–3 wichtigsten.
   - Bei „Alle“: die Tabelle „Überblick je Person“ als Trichter zeigen und sagen, wo es hakt.
   - Kennzeichnungen der Projektregeln nutzen ([OFFEN], [RISIKO] …), keine Termine erfinden.
5. **Seite anbieten:** `python3 scripts/fahrplan.py view --out <scratchpad>/view.json` und `docs/leitung/aufgaben/fahrplan.html` mit dem Artifact-Tool veröffentlichen, `files: {"view.json": <absoluter Pfad>}`. Steht in `docs/leitung/aufgaben/README.md` schon eine URL, dorthin veröffentlichen, damit der Link gleich bleibt; sonst neu anlegen und die URL dort eintragen.

## Ändern

- **Zuweisen:** `python3 scripts/fahrplan.py zuweisen <id> <person-id>`
- **Erledigt:** `python3 scripts/fahrplan.py erledigt <id>` (wiederkehrend: setzt `erledigtAm`, der nächste Termin rückt nach)
- **Neue Aufgabe:** Eintrag in `aufgaben.json` nach dem Schema in `meta.hinweis` (id klein mit Bindestrich, `wer`, `status`, `prio`, `faellig` oder `phase`/`nach`/`wiederholung`/`ausloeser`, `landkarte` = Knoten-id aus `docs/landkarte/landkarte.json`). Danach `check`.
- **Neue Person:** Eintrag in `team` (`id`, `name`, `rolle`, `art`: intern|extern|ki|spaeter). Echte Namen nur, wenn der Gründer sie nennt.
- Jede Änderung geht wie jede Doku-Änderung über Branch, PR und Merge (`docs/team/arbeitsweise.md`, Abschnitt 5). Kleine Änderungen sammeln.

## Export

- Excel: `python3 scripts/fahrplan.py export --format xlsx --out <scratchpad>/fahrplan-<datum>.xlsx [--wer <id>]`
- CSV (Semikolon, für deutsches Excel): `--format csv`
- Die Datei mit SendUserFile schicken (display: attach).

## Stimmig halten

- Neue wiederkehrende Pflicht, Stichtag oder Rolle → hier eintragen, nicht in ein anderes Dokument.
- Aufgaben verweisen über `landkarte` auf Knoten der Landkarte; `check` meldet unbekannte Knoten. Ändert sich der Stand eines Bereichs, auch die Landkarte nachziehen.
- Erledigte Bausteine zusätzlich im Bauprotokoll, Entscheidungen im Register.
- `meta.phase` hochsetzen, wenn eine Phase beginnt; Aufgaben „ab Phase N“ rücken dann automatisch nach vorn.
