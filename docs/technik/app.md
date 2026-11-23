# Die App (SwiftUI)

Stand: 23. November 2026 · erste, grobe Fassung. Design und Rechnung wie im Klick-Dummy; Funktionen und Design ändern sich noch stark.

## Öffnen und starten

- `Kompass.xcodeproj` in Xcode öffnen, Scheme **Kompass** (Entwicklung) oder **Kompass Beta** wählen, iPhone-Simulator, Start.
- Ab iOS 26, iPhone und iPad. Mac folgt.
- Tests: Scheme Kompass → Product › Test (⌘U). Ohne Xcode-Oberfläche:

```bash
xcodebuild -project Kompass.xcodeproj -scheme Kompass -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Varianten

| Scheme | Konfiguration | Name auf dem Gerät | Bundle-ID |
|---|---|---|---|
| Kompass | Debug | Kompass Dev | app.kompass.Kompass.dev |
| Kompass Beta | Beta | Kompass Beta | app.kompass.Kompass.beta |
| (Archiv) | Release | Kompass | app.kompass.Kompass |

[OFFEN] Bundle-ID und Apple-Team: Platzhalter, bis App-Name und Apple-Entwicklerkonto feststehen.

## Aufbau

| Ordner | Was |
|---|---|
| `Kompass/Rechnung/` | Rechen-Logik als reine Funktionen (= `docs/produkt/rechenregeln.md`): `Tag` (Kalendertag, sommerzeitfest), Fortschritt, Auf Kurs, Prognose, Habits, Wiederholung, Fokus-Timer, Lernen, Aktionen |
| `Kompass/Modell/` | Datenmodell (Ziel, Schritt, Habit, Aufgabe, Fokus-Sitzung, Zustand) |
| `Kompass/App/` | Start, Navigation, Speicher (Laden/Speichern, Lade- und Fehlerzustand) |
| `Kompass/Design/` | Farben, Maße, Schrift, Bausteine (Seitenkopf, gruppierte Liste, Verlaufskarte, Haken …) nach `docs/produkt/design.md` |
| `Kompass/Ansichten/` | Heute, Kalender, Fortschritt (Ziele · Habits), Ziel-Detail, Lotse (Chat), Rückblick, Fokus, Neu, Aufgabe, Einstellungen |
| `Kompass/Lotse/` | Assistent: `AppWissen` (aus dem Code), `Werkzeuge`, `Verstehen` (Regeln), `Sprachmodell` (Schnittstelle), `Lotse` (Steuerung) – `docs/produkt/konzepte/lotse.md` |
| `Kompass/Demo/` | Demo-Daten (fester Zufall) und Beispieltermine |
| `KompassTests/` | Swift-Tests der Rechen-Logik (Randfälle aus `prototyp/tests/unit.py` und mehr) |

Neue Dateien in diesen Ordnern erkennt Xcode automatisch (synchronisierte Ordner) – keine Projektdatei anfassen.

## Regeln

- Gerechnet wird nur in `Kompass/Rechnung/` – Ansichten zeigen nur an. Jede Rechenänderung zuerst in `rechenregeln.md`, dann hier, dann Test.
- `heute` und `jetzt` werden übergeben, nie im Rechen-Code gelesen – so ist jede Lage testbar.
- Speicherung vorläufig als JSON-Datei auf dem Gerät (Application Support, Dateischutz). [OFFEN] SwiftData (`s-speicher`), danach Sync.
- Kalender: noch Beispieltermine. [OFFEN] EventKit (`s-eventkit`), Google.
- Lotse: Regeln auf dem Gerät zuerst; freie Formulierungen gehen an den Kompass-Server (`ClaudeServer`, URL in `LotseKonfiguration`). Kein Schlüssel, kein Modellname in der App. Jeder neue Screen/Werkzeug muss ins `AppWissen` (Test erzwingt es). Betrieb: `lotse-server.md`.

## Noch nicht drin (gegenüber dem Klick-Dummy)

Stundenraster mit Ziehen & Ablegen im Kalender, Zeitachse auf der Ziele-Seite, Vorschläge (Vorlagen + KI) beim Anlegen eines Ziels, Termine direkt im Kalender zuordnen, Hochzählen der Zahlen. Personen-Test als Swift-Test (`s-personentest`).

Seit Rechnung Fassung 2: Meilensteine, Aufgaben, Habits und Termine lassen sich im Ziel hinzufügen, abhaken und lösen (`Kompass/Ansichten/Ziele/ZielDetail.swift`, `ZielBlaetter.swift`). Gespeicherte Daten der Fassung 1 werden beim Start durch die neue Demo ersetzt (es gab nur Demo-Daten).
