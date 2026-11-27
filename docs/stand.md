# Stand – Compass

Stand: 27. November 2026. Lebendes Dokument: nach jedem Block umschreiben, nicht anhängen.

- **Neustart** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Alles Bisherige ist gelöscht (`docs/frueher.md`). Die App heißt **Compass**, Texte auf Deutsch, Englisch später.
- **Reihenfolge** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Zuerst das ganze Design, danach die Funktionen. Alles, was offen ist, steht in `docs/offen.md`.
- **Gebaut (nur Aussehen):**
  - Designsystem „Dunkel“ mit Sternen, Lichtstrahlen und Lichterstaub in Compass-Türkis.
  - Tab-Kapsel mit drei Tabs: Home · Compass · Mein Weg.
  - Home: Bühne, Werte, Glas-Karten, schwebende Leiste.
  - Mein Weg: Habits, Aufgaben, Ziele.
  - Habits-Seite.
  - Blatt „Neuer Habit“ mit Namensfeld und Bildwahl samt Größen-Empfehlung.
- **Einheiten und Ziele** [ENTSCHEIDUNG – 27.11.2026, Gründer: „Ja, passt“]: Spannen, Schritte und Standardwerte je Einheit wie in `Kompass/Modelle/Einheit.swift` (abgesichert durch `EinheitTests`). Änderungen daran brauchen eine neue Freigabe.
- **Fortschritt** [ENTSCHEIDUNG – 27.11.2026, Gründer: „wie es am meisten Sinn macht“]: Teilwert = Anteil × Tagesziel, eingerastet (Zeit: ganze Minuten, sonst Schritt der Einheit); nur ganz rechts zählt als erledigt; „Keine Einheit“ nur ganz oder gar nicht (`Fortschritt` in `Kompass/Modelle/Habit.swift`, `FortschrittTests`).
- **Habit antippen** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Auswahl Erledigt · Fokus · Bearbeiten (Aufbau wie Opals „New Rule“). Reihenfolge: 1. Auswahl + Erledigt-Balken (gebaut), 2. Bearbeiten, 3. Fokus (ganzer Bildschirm, Bild `fokus-grund`).
- **Als Nächstes:** Der Gründer nennt den nächsten Design-Schritt.
