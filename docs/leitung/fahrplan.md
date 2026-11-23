# Fahrplan – Phasen und Bausteine

Stand: 23. November 2026. Einzelne Aufgaben, Pflichten und Termine stehen in `docs/leitung/aufgaben/aufgaben.json` (`/fahrplan`); hier stehen Phasen, Reihenfolge und Begründung.

## 1. Ziel

Kompass veröffentlichen: zuerst iPhone und Mac (App Store), danach Windows und Android. [OFFEN] Nur für den Gründer oder als Produkt mit Abo – das entscheidet, wie früh Konto, Sync und Bezahlung kommen.

## 2. Phasen

| Phase | Inhalt | Ende, wenn … |
|---|---|---|
| **0 Klick-Dummy** ✓ | HTML-Prototyp (Desktop + iPhone), Rechenregeln, Personen-Test | erledigt 23.11.2026 |
| **1 Entscheiden & testen** | Name, Technik-Weg, Sprache, Geschäftsmodell; Gründer nutzt den Klick-Dummy eine Woche | alle [OFFEN] aus `entscheidungen.md` Abschnitt 2 entschieden |
| **2 iPhone-MVP** | Xcode-Projekt `Kompass/`; Rechen-Logik + Tests zuerst; Heute, Habits, Ziele, Fokus-Timer; lokale Speicherung (SwiftData); Apple-Kalender lesen (EventKit) | Personen-Test als Swift-Test grün, Gründer nutzt die App täglich |
| **3 Version 1 Apple** | Mac-App, Google-Kalender (OAuth), Rückblick, Widgets („Jetzt dran“, Habits heute), Erinnerungen, Vorschläge mit KI | TestFlight mit Freunden |
| **4 Sync & weitere Plattformen** | Konto und Server (z. B. Supabase), Web-App für Windows/Android, Outlook | Daten auf allen Geräten gleich |
| **5 Store** | Store-Texte, Datenschutz, Preis/Abo, Review | App im Store |
| **6 Lernen über alle Nutzer** | anonyme Zusammenfassung von Zeitfaktoren und Vorschlags-Quoten | `konzepte/lernen-ueber-alle-nutzer.md` umgesetzt |

## 3. Technik-Weg [OFFEN – Gründer entscheidet]

- **Weg A (Vorschlag Claude):** iPhone und Mac zuerst in **SwiftUI** – gleiche Werkzeuge wie Gapless, Apple-Kalender über EventKit am einfachsten, Widgets nur so richtig. Windows und Android danach als Web-App mit demselben Server.
- **Weg B:** **Flutter** für alle Plattformen ab Tag 1. Schneller überall, aber Apple-Extras (Widgets, Live Activities) brauchen trotzdem Swift.

## 4. Was aus dem Klick-Dummy in die App wandert

- **1:1:** Rechenregeln (`docs/produkt/rechenregeln.md`), Datenmodell (`docs/technik/plattformen-und-speicherung.md`), Textregeln und Design-Tokens (`docs/produkt/design.md`), Personen-Test-Personas (`prototyp/tests/personas.py`).
- **Neu bauen:** Oberfläche in SwiftUI (Gapless-Komponenten als Vorbild, kein geteilter Code), echte Kalender-Anbindung, Speicherung, Benachrichtigungen.

## 5. Risiken

- [RISIKO] Google verlangt für Kalender-Zugriff eine Prüfung der App (sensible Bereiche) – früh beantragen (Phase 3).
- [RISIKO] Kalenderdaten sind persönlich (Geburtstage, Gesundheitstermine) – nur lesen, nur Zuordnung speichern (`docs/recht/recht-und-sicherheit.md`).
- [RISIKO] Viele starke Wettbewerber im Bereich To-do/Habits. Abgrenzung über Ziel-Rechnung und Kalender-Ergänzung, nicht über Funktionsmenge.
