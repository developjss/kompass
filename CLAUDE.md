# Projektregeln – Compass

- Compass ist ein **eigenes Projekt** (Neustart 27.11.2026). Was früher war, steht in `docs/frueher.md` – nur Rückblick, **keine Grundlage**: nichts daraus zurückholen, keine Entscheidung darauf stützen.
- **Vorbild Opal:** Aufbau, Abläufe, Funktionen, Maße, Farben, Licht und Bewegung genau nachbauen (`docs/plan.md`). Opals Bilder, Logo, Name und Texte nie übernehmen oder nachbilden; Screenshots des Vorbilds bleiben lokal, nie ins Repo.
- Nur Demo-Daten; keine echten Konten, Schlüssel, Zugangsdaten oder Screenshots mit persönlichen Daten. Echte Schlüssel nie in Chat oder Repo.
- **Zahlen fest rechnen** (Werte, Zeiten, Serien) und mit Tests absichern. KI macht höchstens Texte und Vorschläge – sie rechnet nie.
- Jede Ansicht hat Lade-, Leer-, Fehler- und Offline-Zustand. Barrierefreiheit: Dynamic Type, VoiceOver, Reduce Motion.
- Ein Auftrag = ein Screen oder Baustein. Danach bauen, prüfen, committen.
- Keine neuen Abhängigkeiten, SDKs oder Anbieter ohne Rückfrage.
- App-Texte auf Deutsch; Englisch später möglich (Texte nicht fest verdrahten, wo es einfach geht).
- Was ein Konto oder einen Server braucht: sichtbarer Platzhalter, im Code `// PLATZHALTER: …`.

# Zusammenarbeit
- Zuerst `docs/stand.md` und `docs/plan.md` lesen.
- **Der Gründer gibt die Schritte vor** [ENTSCHEIDUNG – 27.11.2026]: Er nennt, was als Nächstes eingebaut wird. Vor dem Bauen kommt eine kurze Vorab-Info: wie es umgesetzt wird, wie nah es dem Vorbild kommt (in Prozent, mit Grund für jede Lücke) und was dafür fehlt. Gebaut wird erst nach seinem Ja. `docs/plan.md` ist nur die Übersicht, keine Reihenfolge.
- Antworten auf Deutsch, kurz und klar. Kritischer Sparringspartner: Schwächen und Alternativen nennen.
- Kennzeichnungen: [FAKT – Quelle, Datum] · [HYPOTHESE] · [VORSCHLAG] · [ENTSCHEIDUNG – Datum] · [OFFEN] · [RISIKO] · [SCHÄTZUNG]. Nichts erfinden; Rechtliches nur als Prüffrage.
- **Nach jedem Bau:** durch die App gehen, jede geänderte Seite ablichten und neben das passende Opal-Bild legen; Unterschiede nennen. Dann auf das iPhone des Gründers und den Simulator iPhone 18 Pro installieren.
- Tests: jeder Block Tests. Testanweisungen an den Gründer nur als: App-Tests, UI-Tests oder Full. Full/UI-Lauf nur auf Ansage oder nach Rückfrage.
- Nie behaupten, etwas sei gebaut oder getestet, wenn es nicht gelaufen ist.
- Merge: Claude merged selbst, wenn alle Tests grün sind und geprüft ist; „Ja, mergen“ des Gründers bleibt Pflicht bei Recht, Preisen/Kauf, Rechenregeln, Sicherheit/Datenschutz, neuen Abhängigkeiten, Regeländerungen und allem, was der Gründer testen oder entscheiden muss. Merge-Beschreibung ohne private E-Mail.
- `docs/stand.md` nach jedem Block umschreiben (kürzen statt anhängen); Entscheidungen mit Datum dort oder in `docs/plan.md`.
