# Stand und nächste Schritte – Kompass

Stand: 27. November 2026 (Europe/Berlin) · **Lebendes Dokument:** nach jedem gemergten Block und jeder Entscheidung umschreiben, nicht anhängen. Wegweiser: `docs/README.md`. Arbeitsweise: `docs/team/arbeitsweise.md`. Was in `docs/archiv/` liegt, gilt nicht mehr.

## 1. Worum es geht

- **Kompass** (Arbeitstitel): Habits, Ziele, Aufgaben und Journal in einer App, dazu ein Assistent als **Berater**.
- **Neuer Plan** [ENTSCHEIDUNG – 27.11.2026]: Kompass liest die Kalender (Apple; Google und Outlook über die Konten im iPhone) und legt selbst keine Termine an. Der Kalender-Tab fällt weg, an seine Stelle kommt das **Journal**. Konzept: `docs/produkt/konzepte/journal-und-berater.md`.
- **Kern:** alles fest gerechnet und nachvollziehbar (`docs/produkt/rechenregeln.md`). Die KI formuliert und schlägt vor, sie rechnet nie.
- **Ziel:** veröffentlichen, zuerst iPhone (`docs/leitung/fahrplan.md`).
- Repo `kompass` (privat), getrennt von Gapless. Lokal: `~/Developer/Kompass`.

## 2. Was gebaut ist (main, 27.11.2026)

SwiftUI-App `Kompass.xcodeproj` (iOS 26), Speicherung als Datei auf dem Gerät, nur Demo-Daten. Aufbau: `docs/technik/app.md`.

| Bereich | Stand | Nach dem neuen Plan |
|---|---|---|
| Tabs | Home · Kalender · Assistent · Habits · Ziele | Kalender → **Journal** |
| Home | Karte vorn, bis zu drei Signale (§12), Rückblick als Karten zum Wischen (§14), Als Nächstes, Hinzufügen | bleibt, Termine nur gelesen |
| Kalender | Tag/Woche/Monat/Jahr, Ziehen, Empfehlungs-Stapel (§9.1), eigene Termine, Apple-Kalender lesen | fällt weg; Lesen bleibt |
| Habits, Ziele | eigene Tabs, Seiten, Meilensteine, Rechnung §1–§7 | bleibt |
| Rückblick | Wochenwort (§11), Statistik-Seiten (§13), Wochenreflexion | Reflexion zieht ins Journal |
| Assistent | Claude über Server (Supabase EU, `docs/technik/lotse-server.md`), Werkzeuge rechnen, offline Regeln | wird der Berater |
| Design | „Nachtblau“ (`docs/produkt/design.md`) | wird neu entworfen |

**Tests:** 242 App-Testfälle grün (26.11.2026), Personen-Test als Swift-Test (`KompassTests/PersonenTests.swift`). UI-Tests seit PR #58 angepasst, nicht gelaufen.

## 3. Nächste Schritte

1. **Design neu:** Entwurf https://claude.ai/artifact/2dKAvMBcFbtiXpxn3tKHcf (27.11.2026: Home, Journal, Assistent, Habits, Ziele, Bausteine; Hintergrund in Bewegung, Glaskarten, Nunito) – der Gründer entscheidet.
2. **Entscheidungen** zu Aufgaben, Google und Journal-Datenschutz (`docs/leitung/entscheidungen.md` §2).
3. **Personen-Test Journal:** 4 Personen × 3 Wochen – trägt man täglich ein, ab wann entsteht ein Muster?
4. **Bauen** in vier Blöcken: Journal-Tab statt Kalender → Berater (freie Zeit, Apples Termin-Fenster) → Muster (Rechenregel §15, Freigabe) → Design und Statistiken neu.
5. **Roter Faden** nach dem Journal-Block neu (beschreibt noch die App mit Kalender-Tab).
