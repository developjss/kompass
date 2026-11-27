# Die App (SwiftUI)

Stand: 27. November 2026. Neuer Plan „Journal und Berater“: Der Kalender-Tab wird zum Journal (`docs/produkt/konzepte/journal-und-berater.md`), das Design wird neu entworfen.

## Öffnen und starten

- `Kompass.xcodeproj` in Xcode öffnen, Scheme **Kompass** (Entwicklung) oder **Kompass Beta** wählen, iPhone-Simulator, Start.
- Ab iOS 26, iPhone und iPad. Mac folgt.
- Tests: Scheme Kompass → Product › Test (⌘U) = **Full** (App-Tests + UI-Tests). **App-Tests** nur: `-only-testing:KompassTests`, **UI-Tests** nur: `-only-testing:KompassUITests` (Start mit `-demoNeu`, Bildschirmfotos im Testbericht). Der Personen-Test (`PersonenTests`, 6 Personen × 3,5 Jahre) dauert einige Minuten. Ohne Xcode-Oberfläche:

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
| `Kompass/Rechnung/` | Rechen-Logik als reine Funktionen (= `docs/produkt/rechenregeln.md`): `Tag`, Fortschritt, Kurs, Habits, Tagesplan, Zeitfenster, Signale, Wochenwort, Rückschau, Erinnerungen, Vorlagen, Aktionen |
| `Kompass/Modell/` | Datenmodell (Ziel, Schritt, Habit, Aufgabe, Fokus-Sitzung, Zustand) |
| `Kompass/App/` | Start, Navigation, Speicher (Laden/Speichern, Lade- und Fehlerzustand) |
| `Kompass/Design/` | Farben, Maße, Schrift, Bausteine (Seitenkopf, gruppierte Liste, Verlaufskarte, Haken …) nach `docs/produkt/design.md` |
| `Kompass/Ansichten/` | Heute (Home), Kalender (fällt weg), Habits, Ziele, Lotse (Assistent), Rückblick (auf Home), Fokus, Neu, Einstellungen |
| `Kompass/Lotse/` | Assistent: `AppWissen` (aus dem Code), `Werkzeuge`, `Verstehen` (Regeln), `Sprachmodell` (Schnittstelle), `Lotse` (Steuerung) – `docs/produkt/konzepte/lotse.md` |
| `Kompass/Demo/` | Demo-Daten (fester Zufall) und Beispieltermine |
| `KompassTests/` | Swift-Tests der Rechen-Logik (Randfälle und mehr), Personen-Test |
| `KompassUITests/` | UI-Tests: Rundgang, Kalender-Ansichten, Termin/Aufgabe anlegen, Habit-/Ziel-Seite, Lotse, große Schrift |

Neue Dateien in diesen Ordnern erkennt Xcode automatisch (synchronisierte Ordner) – keine Projektdatei anfassen.

## Regeln

- Gerechnet wird nur in `Kompass/Rechnung/` – Ansichten zeigen nur an. Jede Rechenänderung zuerst in `rechenregeln.md`, dann hier, dann Test.
- `heute` und `jetzt` werden übergeben, nie im Rechen-Code gelesen – so ist jede Lage testbar.
- Speicherung vorläufig als JSON-Datei auf dem Gerät (Application Support, Dateischutz). [OFFEN] SwiftData (`s-speicher`), danach Sync.
- Kalender: Apple-Kalender wird nach Zustimmung gelesen (EventKit), dazu Beispieltermine. Termine anlegen künftig nur über Apples Termin-Fenster; Google über die Konten im iPhone.
- Lotse: Regeln auf dem Gerät zuerst; freie Formulierungen gehen an den Kompass-Server (`ClaudeServer`, URL in `LotseKonfiguration`). Kein Schlüssel, kein Modellname in der App. Jeder neue Screen/Werkzeug muss ins `AppWissen` (Test erzwingt es). Betrieb: `lotse-server.md`.

## Als Nächstes

Journal-Tab statt Kalender-Tab, Berater mit freier Zeit aus allen Kalendern, Muster (Rechenregel §15), neues Design – Reihenfolge in `docs/stand.md` §3.
