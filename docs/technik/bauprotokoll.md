# Bauprotokoll

Neueste oben. Je gemergtem Block eine Zeile: Datum · Kürzel · was · Tests.

| Datum | Kürzel | Was | Tests |
|---|---|---|---|
| 23.11.2026 | P2-XC | Xcode-Projekt `Kompass` (Schemes Debug/Beta), Rechen-Logik in Swift (`Kompass/Rechnung/`), fünf Bereiche grob wie im Klick-Dummy, Speicher als JSON, Demo-Daten. Beschreibung: `docs/technik/app.md` | 42 Swift-Tests grün, Debug und Beta gebaut, im Simulator geprüft (hell/dunkel) |
| 23.11.2026 | P0-FP | Fahrplan-Seite veröffentlicht (Link in `docs/leitung/aufgaben/README.md`); Gapless-Reste entfernt (Logo „G“, „fertig bis auf Plaid“); Ordnungs-Prüfung: Test-Ausgabe `ergebnis.json` darf fehlen | `scripts/test_fahrplan.py` + `test_ordnung.py` 19 grün, `ordnung.py` 0 Fehler |
| 23.11.2026 | P0-ORG | Projekt angelegt wie Gapless: CLAUDE.md, Skills `/fahrplan` und `/roterfaden`, docs/ nach Landkarte, Fahrplan, Roter Faden (Fassung 1), Landkarte. Werkzeuge `scripts/fahrplan.py`, `scripts/ordnung.py`, `docx_bau.py` aus Gapless übernommen (Vermerk nach Arbeitsweise §0). | `fahrplan.py check`, `ordnung.py`, `pruefen.py` grün |
| 23.11.2026 | P0-DS | Design wie Gapless: Textmenge ≤ ~35 Wörter, Kopf, gruppierte Listen, Verlaufskarten, Seitenfuß | Personen-Test grün |
| 23.11.2026 | P0-RR | Rechenregeln: Schritte, Gewichte, Auf Kurs, Prognose, Lernen, Vorschläge (Vorlagen + KI), „So wird gerechnet“ | Personen-Test mit Eingriffen grün, 18 Randfälle grün |
| 23.11.2026 | P0-FX | 13 Fehler aus dem Personen-Test behoben (Serien, Quoten, Timer, Fälligkeit, Wiederholung …) | `docs/technik/berichte/personen-zwei-jahres-test-2026-11-23.md` |
| 23.11.2026 | P0-KD | Klick-Dummy: Heute, Kalender (Planen + Kalender in einem), Habits, Ziele, Rückblick, Fokus; Desktop + iPhone | im Browser geprüft |
