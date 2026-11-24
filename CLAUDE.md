# Projektregeln – Kompass

- Kompass ist ein **eigenes Projekt**. Nichts aus anderen Projekten (z. B. Gapless) hier ablegen und nichts von hier dorthin. Design-Vorbild ist Gapless (Harbor 2), Code wird nicht geteilt.
- Nur Demo-Daten; keine echten Kalender, Konten, Schlüssel, Zugangsdaten oder Screenshots mit persönlichen Daten. Echte Schlüssel nie in Chat oder Repo.
- **Fortschritt, Serien, Quoten, Zeiten und Prognosen deterministisch berechnen** (Formeln in `docs/produkt/rechenregeln.md`) und mit Tests absichern. KI macht höchstens Vorschläge und Texte – sie rechnet nie.
- Jede Ansicht hat Lade-, Leer-, Fehler- und Offline-Zustand.
- Barrierefreiheit: Dynamic Type, VoiceOver, Reduce Motion.
- Textregeln (Gapless): ≤ ~35 Wörter je Bildschirmhöhe, eine Zeile = ein Fakt, Erklärungen hinter (i), Überschrift = Aussage.
- Ein Auftrag = ein Screen oder Baustein. Danach bauen, prüfen, committen.
- **Lotse mitziehen:** Neuer Bereich, neues Fenster, neue Rechenregel oder neue Fähigkeit → `AppWissen` und `Werkzeuge` ergänzen, Beispielfragen in `LotseTests` (`docs/produkt/konzepte/lotse.md` §3). Der Lotse rechnet nie und ändert nur über Werkzeuge.
- Keine neuen Abhängigkeiten, SDKs oder Anbieter ohne Rückfrage.
- App-Texte auf Deutsch (Zielmarkt Deutschland/Europa zuerst) [OFFEN: Englisch zusätzlich, `docs/leitung/fahrplan.md`].

# Zusammenarbeit
- Zuerst `docs/stand.md` lesen (Stand, nächste Schritte); Wegweiser zu allen Dokumenten: `docs/README.md`; ausführliche Regeln: `docs/team/arbeitsweise.md`. Aufgaben: `/fahrplan` (`docs/leitung/aufgaben/aufgaben.json`, eine Quelle).
- Antworten auf Deutsch, kurz und klar. Kritischer Sparringspartner: Schwächen und Alternativen nennen.
- Kennzeichnungen: [FAKT – Quelle, Datum] · [HYPOTHESE] · [VORSCHLAG] · [ENTSCHEIDUNG – Datum] · [OFFEN] · [RISIKO] · [SCHÄTZUNG]. Nichts erfinden; Rechtliches nur als Prüffrage.
- Tests: jeder Block Tests; vor größeren Schritten der **Personen-Test** (`prototyp/tests/`, später als Swift-Tests). Testanweisungen an den Gründer nur als: App-Tests, UI-Tests oder Full. Full/UI-Lauf nur auf Ansage oder nach Rückfrage (~alle 10 Builds); jedes Update sofort auf iPhone und Simulator.
- Nie behaupten, etwas sei gebaut oder getestet, wenn es nicht gelaufen ist.
- Merge: Claude merged selbst, wenn alle Tests grün sind und geprüft ist; „Ja, mergen“ des Gründers bleibt Pflicht bei Recht, Preisen/Kauf, **Rechenregeln** (mehr als Fehlerbehebung mit Test), Sicherheit/Datenschutz, neuen Abhängigkeiten, Regeländerungen und allem, was der Gründer testen oder entscheiden muss. Merge-Beschreibung ohne private E-Mail (`docs/team/arbeitsweise.md`, Abschnitt 5).
- Alle 3–4 gemergten Blöcke gebündelt: `docs/technik/bauprotokoll.md`; bei Entscheidungen `docs/leitung/entscheidungen.md` + Fachdokument; `docs/stand.md` aktuell halten; ändert sich etwas Sichtbares, ein Ablauf oder ein Speicherort: **Roten Faden** anpassen, bauen und prüfen (`docs/produkt/roter-faden/pruefen.py`). Zentrales Dokument des Gründers: kurz halten, kürzen statt anhängen.
