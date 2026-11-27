# Der rote Faden

**Wo:** hier (`docs/produkt/roter-faden/kompass-roter-faden.docx`) und nach jedem Bauen auf dem Mac automatisch als Kopie in **iCloud Drive › Kompass › „Kompass – Der rote Faden.docx“**. Die Kopie nicht bearbeiten – sie wird überschrieben.

Das zentrale Dokument des Gründers: wie Kompass funktioniert. **Eine Seite der App = eine Seite im Dokument**, oben eine Brotkrume, unten „↑ Kapitel · ↑ Inhalt“. Aufbau wie bei Gapless.

**Nicht in Word bearbeiten** – die Datei wird gebaut. Änderungen gehören in die Quellen:

| Datei | Inhalt |
|---|---|
| `roter_faden.py` | der Text: `kapitel(...)` und `seite(...)` |
| `bilder/` | Bildschirmfotos aus dem Simulator (nur Demo-Daten, JPG 420 px breit) |
| `abdeckung-ausnahmen.txt` | Ansichten/Fenster, die bewusst keine eigene Seite haben (mit Grund) |
| `pruefen.py`, `seiten.swift` | die Prüfung |
| `docx_bau.py` | Werkzeug (nur Python-Standard), aus Gapless übernommen |

## Rhythmus

| Wann | Was |
|---|---|
| Jeder Block mit sichtbarer Änderung | Bilder neu, Text anpassen, bauen, schnelle Prüfung |
| Jeder Block ohne sichtbare Änderung | nur schnelle Prüfung |
| Wöchentlich (Aufgabe `r-roterfaden`) | `/roterfaden` |
| Vor TestFlight/Store | volle Prüfung mit PDF (Mac) |

```bash
python3 docs/produkt/roter-faden/roter_faden.py    # bauen
python3 docs/produkt/roter-faden/pruefen.py        # schnelle Prüfung
python3 docs/produkt/roter-faden/pruefen.py --pdf  # volle Prüfung (Mac mit Pages)
```

Ab Phase 2 prüft `pruefen.py` zusätzlich die Seiten aus dem Swift-Code (wie bei Gapless: `navigationTitle`, Tabs).
