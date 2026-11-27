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
- **Habit antippen** [ENTSCHEIDUNG – 27.11.2026, Gründer]: Auswahl Erledigt · Fokus · Bearbeiten (Aufbau wie Opals „New Rule“). Reihenfolge: 1. Auswahl + Erledigt-Balken (gebaut), 2. Bearbeiten (gebaut: gleiches Blatt wie „Neuer Habit“, gefüllt), 3. Fokus (gebaut: ganzer Bildschirm, Bild `fokus-grund`, Uhr mit Segment-Ziffern, Einstellen → Läuft → Pause/Beenden → Geschafft; Regeln in `Fokus`, `FokusTests`). [ENTSCHEIDUNG – 27.11.2026, Gründer] Habits mit Zeit laufen genau mit ihrer Zeit (Rest bis zum Tagesziel, sonst ganzes Tagesziel), ohne Einstellen; nur Habits ohne Zeit haben Schnellwahl und Lineal.
- **Live-Aktivität** [ENTSCHEIDUNG – 27.11.2026, Gründer: „ja so bauen“]: Erweiterung `CompassLive` (Apple ActivityKit/WidgetKit, kein fremder Anbieter), gemeinsamer Code in `Gemeinsam/`. Sperrbildschirm nach Vorlage des Gründers, Dynamic Island. Fokus-Ende: zweimal vibrieren in der App, sonst Mitteilung „Geschafft“.
- **Fokus-Ende** [ENTSCHEIDUNG – 27.11.2026, Gründer: „ja“]: Habit mit Zeit → bei Ablauf 100 %, beim Beenden zählt die fokussierte Zeit. Habit ohne Zeit → nach Ablauf oder Beenden Abfrage mit dem Compass-Balken. Zurücksetzen (App und Sperrbildschirm) → nichts gutgeschrieben.
- **Als Nächstes:** Der Gründer nennt den nächsten Design-Schritt.
