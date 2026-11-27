# Dokumente – Wegweiser

Stand: 27. November 2026. `docs/` ist gegliedert **wie die Landkarte**: Jeder Ast hat einen Ordner. Wer etwas sucht, schaut hier; wer etwas Neues festhält, legt es in den Ordner des Bereichs, zu dem es gehört. Aufbau bewusst gleich wie bei Gapless, damit beide Projekte gleich funktionieren – aber getrennt bleiben.

## Einstieg

0. **Für den Gründer:** `docs/produkt/roter-faden/kompass-roter-faden.docx` – die App Seite für Seite
1. `CLAUDE.md` (Kurzregeln, wird automatisch geladen)
2. `docs/stand.md` – wo wir stehen
3. **`/fahrplan`** – was heute, bald und später dran ist (je Person)
4. `docs/team/arbeitsweise.md` – wie wir arbeiten

## Bereiche (wie die Landkarte)

| Ordner | Landkarte | Was drin ist |
|---|---|---|
| `leitung/` | Leitung & Strategie | `fahrplan.md` (Phasen, Bausteine, Plattformen) · `entscheidungen.md` (Register) · `aufgaben/` (`/fahrplan`) |
| `produkt/` | Produkt & Design | **`roter-faden/kompass-roter-faden.docx` (zentrales Dokument)** · `grundlage.md` (Idee, 6 Prinzipien, Zielgruppe, Funktionen) · `rechenregeln.md` (alle Formeln) · `design.md` (Nachtblau, Neuentwurf läuft) · `inhalte-und-assets.md` · `konzepte/` (noch nicht gebaut: `journal-und-berater.md` – der neue Plan, `lotse.md`, `lernen-ueber-alle-nutzer.md`) |
| `technik/` | Technik | `app.md` (SwiftUI-App: öffnen, Aufbau) · `lotse-server.md` (Server des Lotsen) · `bauprotokoll.md` (jede gemergte Änderung) · `plattformen-und-speicherung.md` (SwiftUI, Sync, Kalender-APIs) · `berichte/` (Personen-Test) |
| `marketing/` | Marketing & Wachstum | Store-Texte, Website (kommt) |
| `support/` | Support | FAQ, Hilfetexte (kommt) |
| `finanzen/` | Finanzen & Umsatz | Kosten, Preise (kommt) |
| `recht/` | Recht & Datenschutz | `recht-und-sicherheit.md` (Prüffragen: Kalenderdaten, KI, Store) |
| `team/` | Wer macht mit | `arbeitsweise.md` (Regeln der Zusammenarbeit) |
| `landkarte/` | die Karte selbst | `landkarte.json` + Seite |
| `archiv/` | – | Erledigtes und Überholtes, mit Index (Klick-Dummy, gebaute Konzepte). **Gilt nicht mehr – keine Grundlage für Entscheidungen.** |

Außerhalb von `docs/`: `Kompass/` (SwiftUI-App), `KompassTests/` (inkl. Personen-Test), `supabase/` (Server des Assistenten), `scripts/` (Fahrplan, Ordnung).

Jeder Bereichsordner hat ein kurzes `README.md`: was dort hingehört.

## Ablage-Regeln (zukunftssicher)

- **Wohin?** In den Ordner des Landkarten-Asts, zu dem es gehört. Passt nichts: `leitung/`.
- **Neue Entscheidung:** `leitung/entscheidungen.md` und das Fachdokument des Bereichs.
- **Neue Aufgabe, Pflicht oder Frist:** `leitung/aufgaben/aufgaben.json` (`/fahrplan`), mit `landkarte`-Knoten.
- **Neues Konzept:** `produkt/konzepte/`; gebaut → `archiv/`.
- **Testbericht:** `technik/berichte/`, Name mit Datum.
- **Erledigt oder überholt:** sofort nach `archiv/`, im Archiv-Index eintragen, nie löschen. Die aktuellen Dokumente beschreiben den Stand selbst und verweisen nicht ins Archiv.
- **Dateinamen:** klein, deutsch, mit Bindestrich, ohne Nummern; Datum nur bei Berichten und Archiv-Ständen.
- **Kennzeichnungen:** `[FAKT – Quelle, Datum]` · `[HYPOTHESE]` · `[VORSCHLAG]` · `[ENTSCHEIDUNG – Datum]` · `[OFFEN]` · `[RISIKO]` · `[SCHÄTZUNG]`.
- **Ordnung halten:** `python3 scripts/ordnung.py` prüft Verweise, Wegweiser, Alter und Archiv; monatlich und vor Doku-PRs.
