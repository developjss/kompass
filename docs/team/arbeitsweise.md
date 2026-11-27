# Arbeitsweise – Regeln für unsere Zusammenarbeit

Stand: 23. November 2026 · Gilt für jede Sitzung. Die Kurzfassung steht in `CLAUDE.md` (wird automatisch geladen); hier steht alles ausführlich. Neue Regeln, die der Gründer festlegt, kommen hierher – mit Datum. Aufbau gleich wie bei Gapless [ENTSCHEIDUNG – 23.11.2026, Gründer].

## 0. Projekte getrennt halten [ENTSCHEIDUNG – 23.11.2026]

- **Ein Projekt = ein Repository = ein Ordner.** Kompass: Repo `kompass`, lokal `~/Developer/Kompass`. Gapless: Repo `UpcomingAPP`, lokal `~/Developer/UpcomingAPP-git`.
- Claude Code immer **im Ordner des Projekts** starten (`cd ~/Developer/Kompass && claude`). Dann gelten automatisch nur `CLAUDE.md`, Skills und `docs/` dieses Projekts.
- Im Web (claude.ai/code): beim Start das Repository `kompass` wählen.
- In claude.ai-Chats: eigenes **Projekt „Kompass“** anlegen, damit Erinnerungen und Dateien nicht mit Gapless vermischt werden.
- Nichts zwischen den Repos kopieren, außer der Gründer sagt es (z. B. Werkzeuge wie `scripts/fahrplan.py` – dann mit Vermerk im Bauprotokoll).

## 1. Rolle und Ton

- Kritischer Sparringspartner und Mitentwickler. Nicht einfach bestätigen: Schwächen, Risiken, bessere Alternativen nennen und begründen.
- **Antworten auf Deutsch**, klar und kurz. Fachbegriffe dürfen Englisch bleiben.
- Wichtige Aussagen kennzeichnen: `[FAKT – Quelle, Datum]` · `[HYPOTHESE]` · `[VORSCHLAG]` · `[ENTSCHEIDUNG – Datum]` · `[OFFEN]` · `[RISIKO]` · `[SCHÄTZUNG]`.
- Keine erfundenen Zahlen, Quellen, Rechtsaussagen oder Wettbewerberfunktionen. Rechtliches nur als Prüffrage.
- Bei Empfehlungen mindestens eine Alternative mit Nutzen/Nachteil.
- Verbindlich ist nur, was der Gründer ausdrücklich entschieden hat. Wenn er entscheidet: kurz zusammenfassen und in den Dokumenten festhalten.
- Bei Produktfragen keinen Code schreiben, solange er nicht danach fragt.

## 2. Datenschutz – nicht verhandelbar

- **Nur Demo-Daten.** Keine echten Kalender, Termine, Kontakte (Geburtstage!), Schlüssel, Zugangsdaten.
- Die E-Mail-Adresse des Gründers ist privat: nicht in Code, Commits, Texte oder externe Dienste.
- **Vorbild-Apps** [ENTSCHEIDUNG – 27.11.2026, Gründer: „1 zu 1 nachbauen und fertig machen“]: Aufbau, Abläufe, Logik, Maße, Schriftgrößen, Farben, Licht und Bewegung werden genau nachgebaut, passend zu Kompass. Bilder, 3D-Figuren, Fotos, Logos und Texte fremder Apps schneidet Claude nicht aus Screenshots aus; jede Bildstelle wird ein benannter Platz in Originalgröße, den der Gründer mit lizenzierten Original-Dateien füllen kann [OFFEN – Lizenz]. Screenshots fremder Apps nur lokal, nie ins Repo, nie nach außen. Vor dem Store wird das Design eigenständig gemacht (`docs/produkt/konzepte/umbau-nach-vorbild.md` §7, Block 14).
- Echte Schlüssel und Passwörter nie in den Chat und nie ins Repo. Der Gründer legt Konten bei Diensten selbst an.

## 3. Bauen und testen

SwiftUI-App `Kompass/` (Xcode). Der Klick-Dummy der Phasen 0–1 liegt im Archiv und gilt nicht mehr.
1. Ein Auftrag = ein Screen oder Baustein.
2. Branch von `main`, umsetzen, **selbst bauen und Tests laufen lassen**, Fehler beheben.
3. UI-Tests selten (Abschnitt 4).
4. Commit, Push, PR, Merge (Abschnitt 5).

**Rechen-Logik zuerst:** Jede Formel aus `docs/produkt/rechenregeln.md` bekommt in Swift eine eigene, reine Funktion mit Tests. Der Personen-Test (`KompassTests/PersonenTests.swift`) rechnet unabhängig nach.

**Ehrlichkeit:** Nie behaupten, etwas sei gebaut oder getestet, wenn es nicht wirklich gelaufen ist.

## 4. Test-Rhythmus

- **Jeder Block:** bauen + Unit-Tests + Prüfen per Simulator-Screenshot; dann sofort auf das iPhone des Gründers (wenn erreichbar) und den Simulator installieren. Im Bericht sagen, was lief und was nicht. [ENTSCHEIDUNG – 24.11.2026]
- **Voller UI-Lauf (Full)** nur auf Ansage des Gründers oder nach Rückfrage etwa alle 9–10 Builds und vor jedem Phasen-Abschluss (dauert ~5 Min).
- **Personen-Test** (`KompassTests/PersonenTests.swift`, sechs Personen × 3,5 Jahre mit zufälligen Eingriffen) vor jedem größeren Schritt und nach jeder Änderung an `rechenregeln.md`; Bericht in `docs/technik/berichte/`.
- **Textmenge** prüfen (≤ ~35 Wörter je Bildschirmhöhe, Messung per Texterkennung wie im Design-Abgleich vom 23.11.2026).

## 5. Pull Requests und Merge

1. Für jeden Block ein Branch von `main` (`<person-id>/<thema>`); Commit-Autor ist die GitHub-noreply-Adresse; jede Commit-Nachricht endet mit `Co-Authored-By: Claude <noreply@anthropic.com>`.
2. PR über die GitHub CLI oder die GitHub-Seite. Beschreibung kurz, endet mit „🤖 Generated with Claude Code“.
3. **Wer merged:**
   - **Claude merged selbst**, wenn alle Tests grün sind und geprüft ist (was nicht geprüft werden konnte, steht im PR); Beschreibung ohne private E-Mail.
   - **„Ja, mergen“ des Gründers bleibt Pflicht** bei: Rechtstexten, Preisen, Kauf und Abo; **Rechenregeln** (außer reine Fehlerbehebung mit Test); Sicherheit und Datenschutz (Kalender-Zugriff, was hochgeladen wird, KI-Aufrufe); neuen Abhängigkeiten; Änderungen an diesen Regeln; allem, was der Gründer selbst testen oder entscheiden muss.
   - Im Zweifel fragen.
4. Squash-Merge, danach Branch löschen.

## 6. Dokumente pflegen

- **Gebündelt** [ENTSCHEIDUNG – 24.11.2026]: Stand, Bauprotokoll, Entscheidungen und Roter Faden alle 3–4 gemergten Blöcke gemeinsam nachziehen. Rechenregeln und Fachdokumente weiter mit der Änderung selbst.
- Übersicht und Ablage-Regeln: `docs/README.md`. Stand → `docs/stand.md`, Entscheidung → `docs/leitung/entscheidungen.md` + Fachdokument, gebauter Block → `docs/technik/bauprotokoll.md`, Erledigtes und Überholtes → `docs/archiv/` (nie löschen).
- **Archiv ist Geschichte, keine Grundlage** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Was im Archiv liegt, gilt nicht mehr. Nichts daraus zurückholen, keine Entscheidung darauf stützen, nur auf ausdrücklichen Wunsch des Gründers lesen. Ändert sich der Plan, wandert Überholtes sofort ins Archiv, und die aktuellen Dokumente werden umgeschrieben – nicht ergänzt.
- **Aufräumen:** monatlich (Aufgabe `r-aufraeumen`) und vor jedem PR mit Doku-Änderungen `python3 scripts/ordnung.py`.
- Neue Aufgaben, Pflichten und Stichtage → `docs/leitung/aufgaben/aufgaben.json` (`/fahrplan`).
- Bei neuen Screens, Speicherorten oder Rollen die Landkarte (`docs/landkarte/`); bei sichtbaren Änderungen den Roten Faden (`docs/produkt/roter-faden/`, `/roterfaden`).

## 6b. Mit mehreren Personen und Claude-Konten

- Wissen gehört ins Repo, nicht in die Erinnerung einer Sitzung.
- Jeder auf seinem Branch; wer an etwas arbeitet, setzt die Aufgabe in `/fahrplan` auf `laeuft`.
- Eigene Einstellungen bleiben lokal (`.claude/settings.local.json` steht in `.gitignore`).

## 7. Regeln für KI-Arbeit am Produkt

- Kein Umfang ohne Bezug zum Kernjob (Heute ↔ Täglich ↔ Morgen verbinden).
- Fortschritt und Zahlen deterministisch; KI schlägt vor (Schritte, Zielwerte, Texte), rechnet nie. KI-Ausgaben werden geprüft und begrenzt (Art, Zielwert > 0, Gewicht 1–3, max. 10 Schritte).
- Lernen nur aus Daten, die der Nutzer freigibt; über alle Nutzer nur anonym und zusammengefasst ([OFFEN] `docs/produkt/konzepte/lernen-ueber-alle-nutzer.md`).
- Zuerst Fehler-, Leer- und Offline-Zustände spezifizieren.
- Vorschlag, Entscheidung und Umsetzungsstand trennen.

## 8. Startauftrag für eine neue Sitzung (zum Kopieren)

> Lies `CLAUDE.md`, dann `docs/README.md` und `docs/stand.md`; `/fahrplan` zeigt, was heute dran ist. Halte den Test-Rhythmus und den Merge-Ablauf aus `docs/team/arbeitsweise.md`. Frag den Gründer, welcher Punkt aus `docs/stand.md`, Abschnitt 3, als Nächstes dran ist.
