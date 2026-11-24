# Design – nach Gapless „Harbor 2“

Stand: 23. November 2026. Vorbild ist das Designsystem von Gapless (`Tokens.swift`, `design.md` dort). Werte hier übernommen, damit beide Apps zueinander passen; **kein geteilter Code**. Abgleich per Messung am 23.11.2026 (Screenshots + Texterkennung).

## 1. Textregeln (wie Gapless)

1. ca. ≤ 35 Wörter pro Bildschirmhöhe auf Hauptseiten.
2. Eine Zeile = ein Fakt; höchstens ein „·“.
3. Erklärsätze höchstens einmal pro Seite oder hinter (i).
4. Keine Aussage doppelt.
5. Überschrift = Aussage, kein Etikett darüber, kein Untertitel.
6. Höchstens 3 Flächen-Arten pro Screen (Grund, weiße Karte, Verlaufskarte); keine getönten, gestrichelten oder farbig gerahmten Hinweiskästen.

Gemessen 23.11.2026 (iPhone, Wörter je Bildschirm): Gapless Insights 32, Net worth 35, Bills 37, Overview 56 · Kompass nach Umbau: Heute ~44, Kalender 40, Habits 40, Ziele 33, Rückblick 29.

## 1a. Hick’s Law [VORSCHLAG – 24.11.2026]

Höchstens 3–5 Wahlmöglichkeiten je Entscheidung, eine Hauptaktion je Bildschirm, Voreinstellung statt Frage, Stufen statt Listen („Mehr“, „Details“). Analyse je Bereich und Plan: `konzepte/hicks-law.md`.

## 2. Farben „Nachtflug“ (hell / dunkel) [ENTSCHEIDUNG – 24.11.2026]

Indigo trägt, Seladon ist die Handlung, Gold zeigt, was zählt. Entwurf: https://claude.ai/artifact/DfYjA5AX77ed6CfnVLANHe (Code: `Kompass/Design/Farben.swift`).

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| grund | #F3F6F4 | #0B1325 | Grund |
| grundOben | #E1ECE7 | #1A2950 | Verlauf oben |
| karte | #FFFFFF | #121D38 | Karten, Listen |
| text | #0B1325 | #EAF1EE | Text |
| zweitrangig | #56657A | #93A3B8 | Unterzeilen |
| akzent (Seladon) | #3A7262 | #A9CDBE | Handlung, Auswahl |
| akzentWeich | #DCEBE4 | #22364A | „+ Neu“, Chips |
| aufFarbe | #FFFFFF | #0B1325 | Schrift/Zeichen auf Akzent- und Palette-Flächen |
| gold / goldText | #F2B53A / #855B00 | #F2B53A | Ring, Prozent, Erfolg (Text hell nur tief) |
| warnung | #855B00 | #F2B53A | „hinterher“ |
| kritisch | #BA3228 | #FF7A6E | „überfällig“ |

Stand-Karten (Home, Ziel, Habit, Rückblick): in beiden Modi nachtblau (#24396E → #0F1A35) mit Goldschein oben rechts und Goldrand; Ring und Prozent in Gold, Knöpfe Seladon mit Nacht-Schrift.

Ziel-, Habit- und Kalenderfarben: nur Abstufungen der Palette – `Farbe.tonArt` legt jede bunte Hex-Farbe nach Farbton auf Seladon, Seladon tief, Indigo hell, Gold, Gold hell oder Gold tief (je hell/dunkel). Auswahl beim Anlegen: 6 Familien. Unterschieden wird vor allem am Symbol.

Kontraste (WCAG): dunkel Text 16:1, Seladon 10,7:1, Gold 10:1; hell Gold-Text #855B00 5,5:1, Seladon #3A7262 5,1:1.

## 3. Maße

| Maß | Wert |
|---|---|
| Seitenrand | 16 pt |
| Kartenradius | 22 pt (Verlaufskarten 24) |
| Abstand Überschrift → Inhalt | 12 pt; zwischen Abschnitten 32 pt |
| Zeilenhöhe | min. 64 pt (kompakt 52) |
| Icon in Zeilen | 40 pt rund, weiche Kachel in Zielfarbe |
| Buttons | Kapsel, min. 44 pt |
| Titel-Abstand zur Statusleiste | 14 pt |

## 4. Schrift

Seitentitel und große Zahlen in Serif (New York, Dynamic Type); sonst SF Pro Rounded: Large Title 34 · Abschnitt (Title 2) 22 bold · Text 17 semibold/medium · Unterzeile 15 · Klein 13 semibold. Im Web/Windows/Android: Nunito als Ersatz.

## 5. Bausteine

- **Seitenkopf:** großer Titel links, rechts „+ Neu“ (Kapsel, accentSoft), (i), Einstellungen (runde Knöpfe). Keine App-Kopfleiste auf dem Handy.
- **Abschnitt:** Titel 22 bold, rechts ein kurzer Wert oder Link („Alle ›“).
- **Gruppierte Liste:** Zeilen in einer weißen Karte, Trennlinie ab 66 pt; letzte Zeile „+ Aufgabe“. Je Gruppe 3 Einträge, dann „N weitere ⌄“.
- **Verlaufskarten** (wie „Insights“): Titel, große Zahl (40 heavy), eine Zeile, Mini-Grafik; tief → hell, weicher Lichtschein oben links, farbiger Schatten.
- **Hinzufügen-Kacheln** (wie „Add“): 2×2 Verlaufskacheln, weißes Symbol im Glaskreis.
- **Tab-Leiste:** schwebende Glas-Kapsel, aktives Symbol kräftiger, aktiver Tab mit accentSoft. Fünf Tabs: Heute · Kalender · **Lotse** (Mitte) · Fortschritt · Rückblick.
- **Umschalter** (Fortschritt: Ziele · Habits): Kapsel in accentSoft, aktives Segment als weiße Kapsel mit leichtem Schatten, unter dem Seitenkopf.
- **Chat (Lotse):** Nutzer-Blasen in accent/weiß rechts, Lotse-Blasen als weiße Karte links mit Sprung-Link und Daumen; Vorschläge als Chips; Eingabe als Kapsel mit rundem Senden-Knopf.
- **Seitenfuß:** Speicherstatus + „Daten & Kalender“ unten auf jeder Seite.

## 6. Bewegung (Reduce Motion: alles aus)

Kurven zeichnen sich in 1,25 s von links nach rechts mit leuchtender Spitze; Zahlen zählen hoch; Balken und Ringe wachsen beim Öffnen; Haken ploppen (Feder) mit kurzer Vibration; Fenster mit iOS-Federkurve. Nur beim ersten Öffnen einer Ansicht, nicht bei jeder Änderung.

## 6a. Kalender (24.11.2026)

- „Als Nächstes“ steht auf Home; der Kalender beginnt mit Tag · Woche · Monat · Jahr.
- Tag: 64 pt je Stunde, überlappende Einträge brechen um. Woche: breite Spalten (~3 Tage sichtbar), waagerecht wischen.
- Ziehen: halten 0,3 s, Eintrag bleibt groß, gestrichelte Vorschau mit Uhrzeit (15-Min-Raster), Woche auch über Tage, über den oberen Rand = ohne Uhrzeit.
- Apple/Google (EventKit): live aktualisiert (`EKEventStoreChanged`), verschieben/bearbeiten/löschen/anlegen direkt im Kalender des Geräts; Google über das iOS-Konto (keine eigene Google-Anbindung).

## 7. Gadgets (Nachtflug)

- **Fokus als Flug** (`FokusBlatt`, `FlugRechnung`): Nachthimmel, Route KMP → Kürzel des Ziels, Flugzeug an der Stelle Fokuszeit ÷ geplante Dauer der Aufgabe (mind. 5 Min). Phasen: Boarding, Steigflug (< 15 %), Reiseflughöhe, Landeanflug (≥ 80 %), Gelandet, Warteschleife (Pause). Instrumente Höhe (FL, Sinusbogen bis FL350), Strecke, Ankunft. Haptik beim Abheben und Landen. Reduce Motion: Wolken stehen, Flugzeug springt ohne Gleiten. Nur Anzeige – gebucht wird wie bisher (`FokusRechnung`).
- **Rückblick als Bordkarte** (`Bordkarte`): oben im Rückblick die Bordkarte der Woche (Woche, KMP + KW, MO → SO, Von/Nach, Gate = aktive Ziele, Fokuszeit). Goldenen Abschnitt nach rechts ziehen (> 60 pt) oder antippen: er reißt ab und fällt, dahinter erscheint die Aussage-Karte. Je Woche gemerkt (höchstens 26 Wochen). Haptik beim Abreißen; Reduce Motion: ohne Fallen.
