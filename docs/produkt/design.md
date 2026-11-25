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

## 2. Farben „Nachtblau“ (hell / dunkel) [ENTSCHEIDUNG – 25.11.2026, Gründer: „Ja, in die App“]

Nachtblau trägt, Creme spricht, Schwarz ist die Handlung; Messing ist die eine warme Marke („jetzt“). Löst „Blattwerk“ (Rosé/Weinrot/Grün, 24.11.2026) ab. Prototyp mit allen Seiten und Maßen: https://claude.ai/artifact/RQGm6b7z7stGnGBBEi8TwT (Code: `Kompass/Design/Farben.swift`, `Buehne.swift`; Tests `KompassTests/BlattwerkTests.swift`).

| Token | Hell | Dunkel | Verwendung |
|---|---|---|---|
| grund | #F3F1E6 Creme | #0F141B Nacht | Seitengrund |
| buehne | Verlauf #26364B → #33475F → #415671 (168°) | #0B1017 → #141C27 → #1E2A39 | Ebene 1; Fläche allein #33475F / #141C27 |
| schein | Dunst 30 % | #6084B0 24 % | Lichtkegel 380 pt oben rechts |
| saum | → grund | → grund | untere 160 pt (kurz 112, lang 190): 58 % = 5 %, 80 % = 38 %, unten voll |
| karte | #FDFCF6 | #182029 | Karten, Listen, Tabbar |
| papier | #FBF9F1 | #1F2935 | Bordkarte (Statistik) |
| text | #141B24 | #F3F1E6 | Text auf Karten und Grund |
| wort / wortAkzent | #F3F1E6 / #9FBAD6 Dunst | gleich | Bühnen-Wort, Marke; das letzte Wort in Dunst |
| zweitrangig | #5E6B7C | #9AA8B9 | Unterzeilen, Etiketten |
| akzent (Text) | #3F5571 | #9FBAD6 | Handlung als Text und Zeichen |
| handlung (Fläche) | #141B24 Schwarz | #F3F1E6 Creme | Hauptknopf, Ring, Haken, gewählter Tag |
| aufFarbe | #F3F1E6 | #0F141B | Schrift auf der Handlungsfläche |
| jetzt | #C9A227 Messing | gleich | Punkt am heutigen Tag, Zeitlinie, Strecke im Fokus – sonst nirgends |
| akzentWeich | #DCDDD6 | #262A2F | Tab-Pille, Vorschläge, Band „dein Normal“ |
| linie | #D6D5CD | #2F3337 | Trennlinien, Rahmen |
| warnung / warnungGrund | Nachtblau / #DCE4EE | Dunst / #22303F | „hinterher“ |
| kritisch / kritischGrund | Creme / Nachtblau | Nacht / Creme | „überfällig“ |

Alte Namen `gold`, `goldText`, `seladon`, `nacht`, `indigo`, `violett`, `gruen` zeigen auf die neuen Rollen, bis alle Seiten umgebaut sind.

Ziel-, Habit- und Kalenderfarben: `Farbe.tonArt` legt jede bunte Hex-Farbe nach Farbton auf sechs Blau-, Dunst- und Schiefertöne (je hell/dunkel); Gold/Gelb wird Oliv bzw. Messing.

Kontraste (WCAG): Creme auf Nachtblau 8,4 : 1, Text auf Karte 14,5 : 1, Akzent als Text 6,7 : 1, Dunst-Wort auf der Bühne 4,7 : 1; dunkel Creme auf Karte 14,5 : 1, Zweitrangig 7,3 : 1. Messing ist nie Text auf Creme (2,5 : 1).

### 2a. Drei Ebenen: Bühne · (Objekt) · Karte

Jede Hauptseite ist wie ein Produktbild aufgebaut (`Buehne.swift`) – aber Kompass ist eine **Kalender-App**: die Seiten tragen keine Flugbilder und keine Flugbegriffe.
1. **Bühne**: Verlauf 168°, darüber der **Lichtkegel** (`Schein`), Marke bei y 62 (Name in Versalien, New York 17; rechts Datum oder Knöpfe 36 pt mit Rahmen), **Wort** bei y 118 / x 20 (New York, Großbuchstaben, 72 pt; klein 56, mittel 64, riesig 98; Zeilenabstand 0,86; das letzte Wort in Dunst). Unten der **Saum** (`Saum`): die Bühne läuft weich in den Grund aus, kein harter Schnitt. Höhe 360, kurz 250, lang 430.
2. **Objekt**: auf den Seiten leer. Die Ebene lebt in drei Momenten (Easter Eggs, Block 2): Überflug auf Home (echter 747, einmal, nur wenn alles geschafft ist; Reduce Motion: aus), 747 im Fokus (fliegt die Strecke ab), Bordkarte als Statistik (steckt hinter der Karte, zum Herausziehen; Rückblick, Analyse Ziel, Analyse Habit). Schatten zweistufig 0 6 8 (22 %) + 0 26 34 (28 %).
3. **Karte vorn** (`VornKarte`): Radius 28, Innen 18, Versatz −44 über die Bühne, Doppelschatten 0 4 10 (10 %) + 0 24 48 (28 %), oben eine Innenlinie 1 pt in Creme 55 %; darin genau eine Hauptaktion (`.buttonStyle(.haupt)`, 50 pt) und höchstens eine leise Zweitaktion (`.leise`); Löschen `.rot`. Karten-Titel New York 26, Etikett 12 heavy Versalien.

Bilder: `Assets.xcassets/nachtblau-*` – nur echte Fotos: 747 im Anflug (Überflug), 747 beim Abflug (Fokus), Landebahn, Landebahn bei Nacht (Heck der 747 auf Nachtblau getönt, Kennzeichen retuschiert). Keine erzeugten Bilder. [RISIKO] Rechte an den Foto-Vorlagen vor dem Store klären (Presse-/Stock-Fotos).

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
