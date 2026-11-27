# Umbau nach Vorbild „Opal“ – Analyse, Designsystem, Bauplan [ENTSCHEIDUNG – 27.11.2026: nachbauen, nur dunkel, Bildschirmzeit; Bilder und Rechenregeln offen]

Auftrag des Gründers (27.11.2026): Kompass im Design der App **Opal** (Bildschirmzeit und Fokus) nachbauen – Aufbau, Abläufe, Abstände, Farben, Helligkeit, Animationen –, mit unseren Inhalten und Anforderungen. Vor dem Store wird das Design eigenständig gemacht.
Grundlage: 121 Bildschirmfotos (iPhone, 393 × 852 pt) – Onboarding 51 in zeitlicher Folge, Home 18, Profil 23, Übersichten 6, Fenster 21, Fokus 2. Sie liegen nur lokal beim Gründer (`~/Developer/Kompass-Vorbild`), nicht im Repo.

**Entscheidungen des Gründers (27.11.2026):** 1 zu 1 nachbauen und fertig machen, passend zu Kompass · nur dunkel (hell = dunkel) · Bildschirmzeit: erst messen, sperren nur im Fokus · Paywall, Anmeldung (Apple, Telefon, E-Mail) und Freunde einladen gehören dazu; was ein Konto oder einen Server braucht, wird ein sichtbarer Platzhalter (§9) · Preis vorerst 4,99 € im Monat, änderbar.

**Bilder** [ENTSCHEIDUNG – 27.11.2026, Weg B]: KI-erzeugte Bilder in Opals Bildwelt – gleiche Größe, Lage, Helligkeit und Farbstimmung, aber **eigene Motive und eigener Bildaufbau**; keine Nachbildung einzelner Opal-Bilder und keine Opal-Screenshots als Vorlage. Bewegtes (Licht, Schein, Figur, Konfetti) wird in der App gezeichnet. Jede Bildstelle ist ein benannter Platz (`BildPlatz`, `Assets.xcassets`). Texte schreiben wir neu auf Deutsch, gleich lang, gleicher Ton. [OFFEN – Prüffrage] Rechte an KI-Bildern und Nutzungsbedingungen des Generators vor dem Store prüfen.

## 1. Was Opal ausmacht (Befund)

1. **Schwarz mit Licht von oben.** Grund ist reines Schwarz (#000000). Oben liegt ein weicher Lichtkegel, Standard salbeigrün (#749171 am oberen Rand, nach ~250 pt in Schwarz verlaufend). Für Pro/Belohnung lila, im Intro grau-blau.
2. **Eine Figur als Begleiter.** Ein leuchtender Stein „spricht“ mit dir; im Onboarding klein oben (≈ 90 pt), bei großen Momenten groß in der Mitte.
3. **Onboarding als Gespräch.** Text schreibt sich Buchstabe für Buchstabe. Ältere Zeilen rutschen nach oben, werden grau, **unscharf** und verblassen. Deine Antwort erscheint grün (#8AB994), danach eine kurze, persönliche Reaktion („Viel lernen. Nur nicht, wie man die eine App schließt.“).
4. **Kapseln überall.** Knöpfe, Auswahl, Eingabe, Tab-Leiste, Plaketten – alles voll gerundet.
5. **Glas-Blätter.** Bearbeiten passiert in Blättern über der unscharf gezogenen Seite: Radius ≈ 40, Fläche dunkles Glas (#2B2B2B), oben runde Knöpfe (Schließen/Zurück links, Bearbeiten rechts), darunter gruppierte Zeilen.
6. **Verbindlichkeit als Geste.** „Gedrückt halten zum Festlegen“ (Hold to Commit/Start) füllt den Knopf mit Licht. Abbrechen kostet eine kurze Wartezeit („Warte 11 s“).
7. **Ein Akzent-Verlauf.** Limette #D3FFA0 → Aqua #A9FBEF für große Zahlen, Fortschritt, leuchtende Ränder, Unterglühen der Knöpfe.
8. **Große Momente mit Zahlen.** Eine Zahlen-Walze (12 · 13 · 14 · 15 Jahre) rollt und rastet ein; Mitte groß und scharf, Rand klein und unscharf.
9. **Belohnung als Sammeln.** Meilensteine als Steine auf einem Sockel; Antippen bricht sie auf, darunter der Fortschritt („0/100 Tage“).
10. **Home = Bühne + Karten.** Oben Logo, rechts Serie (Flamme + Zahl), Pro-Plakette, Profil-Knopf. Darunter die Figur groß im Fels, „Wird ausgewertet · 12:00 übrig“, drei Werte (Wert · Bildschirmzeit · Ablenker). Darunter Karten: Einrichtungs-Hinweis mit Knopf, „Erster Schritt geschafft“ mit Flamme, Erkenntnisse (gesperrt bis ein Tag voll ist). Über der Tab-Leiste schwebt die laufende Sitzung („Study Time 2:08:09 · Entsperren“).
11. **Entsperren mit Reibung.** „Ich will nutzen …“ → Spiel wählen (Farbwort, Merken) → Merk-Kacheln → Atmen mit Lichtring und „Warte 4 s“ → „Für … 5 Minuten“ als Rad → Entsperren.
12. **Profil als schwebendes Menü** (oben rechts): Name, Sperrbildschirme, Hinweise, Teilen, Einstellungen. Einstellungen als langes Blatt in Gruppen: Pro-Karte, Konto, Personalisieren, App-Symbole, Hilfe, Integrationen, Berechtigungen, Erweitert, Teilen, Sonstiges, Folgen, Version.
13. **Kleine Erlebnisse:** Notfall-Pass als Ausweis mit Strichcode und „Halten zum Einlösen“ (rot), Urlaubsmodus, Belohnungen für Einladungen mit Code aus 5 Kacheln.

## 2. Designsystem (gemessen, @3x → pt)

| Baustein | Wert |
|---|---|
| Grund | #000000; Blätter #1C1C1E–#2B2B2B (Glas, Unschärfe ≈ 30) |
| Licht oben | Kegel #749171 → transparent, Höhe ≈ 260 pt; Varianten Lila (Pro), Blau-grau (Intro) |
| Text | Weiß #FFFFFF; zweitrangig ≈ #8E8E93; Antwort grün #8AB994; Akzent-Verlauf #D3FFA0 → #A9FBEF |
| Schrift | SF Pro (System). Großer Titel 34 Bold · Satz im Gespräch 20 Regular · Überschrift 22–24 Semibold zentriert · Zeile 17 Regular · Unterzeile 15 Regular grau · Etikett 13 · Tab 10 · Zahl der Walze ≈ 56 Heavy mit Verlauf · Aufforderung „Tippen zum Weiter“ 15 Semibold, Großbuchstaben, Verlauf |
| Seitenrand | 20 pt (Gespräch: Text ab x = 24) |
| Hauptknopf | Kapsel 345 × 54, Fläche #313532, oben feiner heller Rand, unten Glühen Limette → Aqua; Text 17 Medium weiß; deaktiviert grau ohne Glühen |
| Kauf-Knopf | Kapsel, gefüllt Mint-Grün (Verlauf #49614F → hell), Text weiß 20 Medium |
| Auswahl-Zeile | Kapsel 345 × 58, #202020, Symbol 18 grün links (x = 16), Text 17; Abstand 14 |
| Eingabe | Kapsel 345 × 54, #1C1C1E, Rand #3A3A3C, Platzhalter grau |
| Gruppen-Zeilen | Radius 22, #FFFFFF 8 % auf Glas, Zeilenhöhe 52, Trennlinie 0,5 |
| Tage-Wahl | 7 Kreise Ø 34, an = weiß mit schwarzem Buchstaben, aus = #3A3A3C |
| Von/Bis | zwei Zeilen, links Punkt–gestrichelte Linie–Kreis |
| Regler „Schwierigkeit“ | Kapsel-Bahn, weißer Knopf mit Symbol, Füllung mit Glitzer |
| Runde Knöpfe | Ø 44, #FFFFFF 12 %, Symbol 17 |
| Tab-Leiste | schwebende Kapsel ≈ 272 × 60, #0A0A0A Glas, aktiver Tab als dunklere Kapsel, Symbol 24 + Text 10 |
| Karten (Regeln, Vorschläge) | Radius 28–36, Foto vollflächig, oben Symbolfolge (Kalender → Schild), unten Zeit 13, Titel 17 Semibold, Plus/Haken rund 44 rechts |
| Plakette | Kapsel Höhe 24, Rand 1 pt, Text 13 Semibold („Pro“, „Besitzt 27 %“) |
| Seitenpunkte | 5 Punkte Ø 6, aktiv weiß |
| Bewegung | Schreibmaschine ≈ 35 ms/Zeichen; Verlauf: Unschärfe 0 → 6, Deckkraft 1 → 0,35; Walze mit Feder; Halten-Knopf füllt in ≈ 1,2 s mit Haptik; Blätter mit Feder von unten; Konfetti beim Abschluss |

[OFFEN] Werte aus Standbildern: Dauer und Federung der Animationen sind geschätzt. Bildschirmaufnahmen vom Gründer würden sie genau machen.

## 3. Was zu Kompass passt (Bewertung)

| Opal | Kompass | Urteil |
|---|---|---|
| Intro: Stein bricht auf, Feuer kommt zum Vorschein | Eigene Figur (siehe §4) zeigt „was in dir steckt“ | **übernehmen** (eigene Figur) |
| Gespräch: Name, Ziel, Alter, Beruf, Bildschirmzeit | Name, „Was willst du verbessern?“ (Ziele erreichen, Gewohnheiten, weniger Handy, besser schlafen, mehr Ruhe, Anderes), Alter, Lebenslage (Schule, Ausbildung, Studium, Job, selbstständig, Eltern), Bildschirmzeit-Schätzung | **übernehmen** – Profil für Vorschläge und Muster |
| Anmeldung Apple/Telefon/E-Mail | alle drei Knöpfe; Apple funktioniert auf dem Gerät, Telefon und E-Mail sind Platzhalter bis zum Server | **übernehmen** |
| „Du verbringst 13 Jahre am Handy“ (Walze) | Fest gerechnet aus der Schätzung: Stunden/Tag × 365 ÷ 16 Wachstunden → Tage/Jahr; × verbleibende Jahre bis 80 → Jahre. Fußnote mit Rechenweg | **übernehmen** – neue Rechenregel §16 |
| „Opal holt dir 4 Jahre zurück“ | nur mit Annahme im Klartext („wenn du 30 % weniger nutzt“), fest gerechnet | **anpassen** |
| Erlaubnis Bildschirmzeit, Mitteilungen (Dialog im Leuchtrahmen mit Pfeil) | Bildschirmzeit, Kalender, Mitteilungen – je ein Schritt | **übernehmen** |
| Zusammenfassung mit drei Nutzen | „Dein Plan“: drei Zeilen aus den Antworten | **übernehmen** |
| Testphase-Erinnerung, Paywall-Karussell, „Andere Pläne“ | Pro: 4,99 € im Monat mit 7 Tagen gratis, Jahr 39,99 € [VORSCHLAG]; StoreKit 2 mit Test-Konfiguration, echte Produkte in App Store Connect später | **übernehmen** |
| „Lass uns Regeln festlegen“ + Regel-Karten | „Lass uns deine ersten Habits festlegen“: Vorschläge als Foto-Karten (Lesen 20 Min, Sport 3×/Woche, Handyfreier Morgen …), aus den Antworten nach festen Regeln | **übernehmen** |
| „Funktioniert für 97 % der Nutzer wie dich“ | Wir haben diese Daten nicht – das wäre erfunden | **weglassen**; später nur mit „Lernen über alle Nutzer“ und Einwilligung |
| Ablenkungen wählen (Apple-Auswahlliste) | gleiche Apple-Liste: „Welche Apps halten dich ab?“ | **übernehmen** (Bildschirmzeit, §5) |
| Freunde einladen, Code, Belohnungen, Geschenkkarte | Teilen funktioniert (Link und Code); Zählen der Anmeldungen und Belohnungen brauchen den Server → Platzhalter | **übernehmen** |
| Willkommen mit Konfetti | ja | **übernehmen** |
| Meilenstein-Steine sammeln, „Besitzt 27 %“ | Meilensteine für Serien und Fokusstunden (7/30/100/300 Tage, 10/50/100/500/1000 h) als Sammelstücke; ohne Prozent anderer Nutzer | **übernehmen**, Prozent weglassen |
| Apps-Seite (blockierte Apps, Regeln, Einstellungen als Karten) | Habits-Seite im selben Aufbau: oben heute fällige Habits als Reihe, darunter Habit-Karten, unten Einstellungen-Karten | **übernehmen** |
| Timer (Digitaluhr, ± , Schnellwahl ∞/15m/30m/1h, Lineal, „Für dich“-Karten) | Fokus-Timer mit Aufgabe/Ziel; „Für dich“ = Fokus-Vorschläge (Lernen, Lesen, Tiefe Arbeit) | **übernehmen** |
| Hard Mode (nicht vorzeitig beenden) | „Durchziehen“-Schalter im Fokus | **übernehmen** (Pro offen) |
| Warteraum (Lichtring, „Warte 11 s“, Atemübung) | Pause, bevor man den Fokus abbricht | **übernehmen** |
| Geräusche und Einschlafgeschichten | Aufbau fertig, Inhalte als Platzhalter (eigene Aufnahmen fehlen) | **übernehmen, Inhalt später** |
| Editor-Blätter (Von/Bis, Tage, Schwierigkeit, Hold to Commit, „Ungespeichert“) | Habit-, Ziel-, Aufgaben-Editor | **übernehmen** |
| Tab-Leiste mit 3 Tabs | 5 Tabs (Home, Journal, Assistent, Habits, Ziele) in derselben Kapsel | **anpassen** |
| Gesprächs-Oberfläche | auch der Assistent (Berater) und das tägliche Journal sprechen so | **übernehmen** |
| Home (Figur, drei Werte, Karten, schwebende Sitzung) | Figur · Tageswert (§19) · Ablenkung (§17) · Habits heute; Karten = Signale (§12), Serie, Erkenntnisse = Muster (§15) und Rückblick-Karten (§14); schwebend: laufender Fokus | **übernehmen** |
| Entsperren mit Spielen, Atmen, Rad | Fokus vorzeitig beenden: Warteraum mit Atmen oder Merk-Spiel, dann „Für … Minuten“ | **übernehmen** |
| Profil-Menü und Einstellungen | gleiche Gruppen mit Kompass-Inhalten (Konto, Hinweise, Warteraum, Sperrbildschirme, App-Symbole, Hilfe = Assistent, Apple Health, Kalender, Bildschirmzeit, Daten, Teilen, Wiederherstellen, Über) | **übernehmen** |
| Notfall-Pass, Urlaubsmodus, PIN, Löschschutz | Notfall-Pass (§17), Urlaubsmodus (§18) ja; PIN und Löschschutz als Platzhalter | **übernehmen** |
| Sperrbildschirm-Themen (Zitate, Witze, Haiku) | eigene Texte, wenige Themen | **übernehmen** |
| Apple Health (Schritte, Schlaf) | gut für Muster (Schlaf und Stimmung) – neues Framework, Rückfrage | **Platzhalter** |
| Opal für Mac, QR-Code, Community, Social-Links | Platzhalter-Zeilen | **Platzhalter** |

**Folge:** Kompass wird nur dunkel [ENTSCHEIDUNG – 27.11.2026]. Der helle Neuentwurf vom 27.11. und „Nachtblau“ sind abgelöst.

## 4. Eigene Figur statt Opal-Stein

[VORSCHLAG] Eine leuchtende Kugel, in SwiftUI gezeichnet (Farbverlauf-Netz, iOS 18+), die sich langsam bewegt und die Farbe wechselt – passend zum Wunsch nach bewegtem Hintergrund. Sie „atmet“, wenn der Assistent schreibt, leuchtet grün bei Erfolg, lila bei Belohnung. Kein Bild, keine Lizenz, eigen. Meilensteine: dieselbe Kugel in Stufen (matt → glänzend → leuchtend). Fotos für Karten: echte, frei lizenzierte Fotos – [OFFEN] Quelle wählen (neuer Anbieter = Rückfrage).

## 5. Bildschirmzeit für Kompass

**Nutzen:** Kompass kann zeigen, warum Habits liegen bleiben – „An Tagen mit mehr als 2 h Instagram schaffst du Lesen nur zu 30 %“ – und im Fokus Apps sperren.

**Technik** [HYPOTHESE – vor Bau mit Apples Doku prüfen]: Apples Frameworks *FamilyControls*, *DeviceActivity*, *ManagedSettings*.
- Die App sieht keine App-Namen und keine Minuten direkt, nur verschlüsselte Kennungen. Nutzungszahlen zeigt eine abgeschottete Erweiterung, die keine Daten herausgeben darf.
- Was geht: **Schwellen** festlegen („Instagram ≥ 60 Min heute“). Die Monitor-Erweiterung meldet, wenn eine erreicht ist; das kann Kompass auf dem Gerät speichern und **fest rechnen** (Rechenregel §17). Apps sperren geht über ManagedSettings.
- Braucht die Berechtigung „Family Controls“ von Apple für den Store – beantragt der Gründer im Entwicklerkonto.
- Daten bleiben auf dem Gerät – gut für Datenschutz, passt zum Journal.
- Neue Frameworks und Erweiterungen = Rückfrage nach `CLAUDE.md`.

## 6. Neue Rechenregeln (ausformuliert in `docs/produkt/rechenregeln.md`, Freigabe des Gründers offen)

§15 Muster (Stimmung, Habits, Fokus, Ablenkung, Auslastung) · §16 Handy-Jahre · §17 Bildschirmzeit (Ablenkung, Ziel, Hinweise, Sperre nur im Fokus, Notfall-Pass) · §18 Serie und Meilensteine · §19 Tageswert 0–100 · §20 Onboarding-Profil und erste Vorschläge. Sie greifen ineinander: Die Antworten im Onboarding setzen Ziel Ablenkung (§17) und Fokusziel (§19); Habits (§6), Fokus und Journal speisen Tageswert, Serie und Muster.

## 7. Prüfung der Phasen und Blöcke (27.11.2026)

Der erste Plan war richtig im Kern (Designsystem zuerst, ein Baustein je Block). Beim Prüfen gegen die neuen Bilder und Entscheidungen fielen acht Dinge auf:
1. **Reihenfolge Bildschirmzeit:** Das Onboarding fragt schon nach Erlaubnis und Ablenkern. Die Bildschirmzeit-Grundlage muss deshalb **vor** dem Onboarding stehen, nicht am Ende.
2. **Datenmodell fehlte:** Profil, Journal, Tageswert, Serie, Ablenkung, Pro-Status brauchen einen Block mit Speicher-Version und Umzug alter Daten – vor allen Seiten.
3. **Rechnung vor Oberfläche:** §15–§20 als reine Funktionen mit Tests in einem eigenen Block, damit jede Seite nur anzeigt.
4. **Navigation fehlte:** Tab-Kapsel, Profil-Knopf oben rechts, schwebende Sitzung und das Streichen des Kalender-Tabs sind ein eigener Block.
5. **Paywall und Anmeldung** gehören jetzt in den Bau, nicht nach „später“.
6. **Kompass-eigene Seiten** (Ziele, Journal, Aufgaben) haben bei Opal kein Gegenstück – sie bekommen Opals Sprache (Bühne, Glas-Blätter, Karten), brauchen aber eigene Entwürfe.
7. **Phasen passten nicht mehr:** Die alte Phase 3 (Onboarding, Pro, Widgets) und Teile von Phase 4 (Anmeldung) wandern nach vorn. Ziel ist eine App, die nach Phase 2 in den Store **könnte** – mit benannten Platzhaltern.
8. **Prüfung am Schluss:** UI-Tests, Personen-Test und der Rote Faden müssen nach dem Umbau komplett neu laufen – ein eigener Block.

## 8. Phasen (neu)

| Phase | Inhalt | Ende, wenn … |
|---|---|---|
| **2 Umbau, fertig bis auf Konten** | Blöcke A–P unten | App läuft vollständig auf dem iPhone, alle Platzhalter benannt, Tests grün |
| **3 Store** | App Store Connect (Produkte, Preise, Datenschutz-Angaben), Apple-Berechtigung Family Controls, Rechtstexte (AGB, Datenschutz, Abo-Hinweise), TestFlight, Bilder-Lizenz klären | App im Store |
| **4 Server und Konten** | Konto-Abgleich (Supabase EU), Telefon- und E-Mail-Anmeldung, Einladungen zählen, Belohnungen, Geschenkkarte, Lernen über alle (mit Einwilligung) | Platzhalter aus §9 leben |
| **5 Weitere Geräte** | Mac, später Android/Windows | – |

## 9. Bauplan Phase 2 (Blöcke)

Jeder Block: ein Baustein, Tests, Lotse mitziehen, iPhone und Simulator, eigener PR. Alle greifen auf §2 zu – Werte stehen einmal in `Kompass/Design/`.

| # | Block | Fertig, wenn |
|---|---|---|
| A | **Designsystem:** Farben, Licht oben, Schrift-Stufen (Dynamic Type), Kapsel-Knopf mit Unterglühen, Halten-Knopf, Auswahl-Kapsel, Eingabe, Gruppen-Zeilen, Tage-Wahl, Von/Bis, Regler, Plakette, Seitenpunkte, Glas-Blatt, Rad, Tab-Kapsel; nur dunkel. Vorschau-Seite | Vorschau neben Opal-Bildern deckungsgleich; Kontrast-Tests |
| B | **Figur und Bildplätze:** eigene Kugel (Bewegung, Zustände, Reduce Motion), Sockel/Fels-Platz, benannte Bildplätze in Opals Größen | Simulator, Ruhe-Modus steht still |
| C | **Datenmodell:** Profil, Journal-Eintrag (Stimmung, Satz), Tageswert-Verlauf, Serie, Ablenkung je Tag, Ablenker-Auswahl, Fokus-Sperre, Pro, Urlaub, Notfall-Pass; Speicher-Version 3 mit Umzug | Lesen(Schreiben) = gleich, alte Daten bleiben |
| D | **Rechnung §15–§20** als reine Funktionen | Tests je Regel, Personen-Test erweitert |
| E | **Bildschirmzeit-Grundlage:** Erlaubnis, Apple-Auswahl der Ablenker, Überwachung mit Schwellen (Erweiterung), Sperre im Fokus (Erweiterung), Sperrbildschirm-Erweiterung | auf dem iPhone getestet; ohne Erlaubnis läuft alles weiter |
| F | **Navigation:** Tab-Kapsel (Home · Journal · Assistent · Habits · Ziele), Kalender-Tab weg, Profil-Knopf mit Menü, schwebende Sitzung | UI-Test Rundgang |
| G | **Onboarding 1:** Intro, Gesprächs-Baustein, Name · Anmeldung · Ziel · Alter · Lebenslage · Bildschirmzeit, „Ich werte aus …“ | Profil gespeichert, VoiceOver liest ganze Sätze |
| H | **Onboarding 2:** Handy-Jahre-Walze (§16), Erlaubnisse (Bildschirmzeit, Kalender, Mitteilungen) mit Leuchtrahmen, „Dein Plan“, Erinnerung vor Testende, Paywall | jede Erlaubnis ablehnbar |
| I | **Onboarding 3:** „Lass uns festlegen“, Ablenker wählen, Vorschlags-Karten (§20), Einladen, Willkommen mit Konfetti, erster Meilenstein | Personen-Test grün |
| J | **Home:** Bühne mit Figur, Tageswert/Ablenkung/Habits, Karten (Signale, Serie, Erkenntnisse, Rückblick), Serie-Blatt, Meilenstein-Galerie | Leer-, Lade-, Fehler-, Offline-Zustand |
| K | **Habits** im Aufbau der Apps-Seite und **Ziele** in derselben Sprache | wie bisher bedienbar |
| L | **Editor-Blätter** für Habit, Ziel, Aufgabe, Fokus-Plan (Glas-Blatt, Zeilen, Tage, Von/Bis, Schwierigkeit, Halten, „Ungespeichert“) | UI-Tests |
| M | **Fokus:** Timer (Digitaluhr, Schnellwahl, Lineal, „Für dich“, Durchziehen), Sperre, Warteraum (Atmen, Merk-Spiel, Farbwort-Spiel), „Für … Minuten“, Notfall-Pass | Fokus-Rechnung unverändert |
| N | **Journal und Assistent** im Gesprächs-Stil, Muster-Karten | Lotse-Tests |
| O | **Profil, Einstellungen, Pro:** Menü, Einstellungen-Blatt, Konto (Apple-Anmeldung, Abmelden, Löschen), Pro-Vorteile, Wiederherstellen, Einladen mit Code, Urlaubsmodus, Sperrbildschirm-Themen, App-Symbole | StoreKit-Test-Kauf im Simulator |
| P | **Abschluss:** UI-Tests neu, Personen-Test, Roter Faden neu, Platzhalter-Liste geprüft | Full-Lauf grün (nach Rückfrage) |

## 10. Platzhalter (tote Wege, bis Konto oder Server da sind)

| Stelle | Fehlt | Phase |
|---|---|---|
| Anmeldung mit Telefon, mit E-Mail; Telefonnummer im Konto | Server-Anmeldung (Supabase Auth, SMS-Anbieter) | 4 |
| Einladungen zählen, Belohnungsstufen, Code einlösen, Geschenkkarte | Server | 4 |
| Echte Pro-Produkte und Preise | App Store Connect | 3 |
| Sperre im Store-Build | Apple-Berechtigung Family Controls (Entwicklung geht ohne) | 3 |
| Apple Health, Mac-App, QR-Code, Community, Social-Links, Hilfe-Center | Entscheidung bzw. Inhalte | 3–5 |
| Geräusche, Einschlafgeschichten | eigene Aufnahmen | 3 |
| Opals Bilder | schriftliche Lizenz | 3 |
| PIN-Schutz, Löschschutz | Prüfung, ob iOS das erlaubt | 3 |

Jeder Platzhalter trägt im Code die Markierung `// PLATZHALTER(<Phase>): <was fehlt>` und in der App den Hinweis „Kommt bald“; `scripts/platzhalter.py` listet alle.

## 11. Risiken und Prüffragen

- [RISIKO] **Nachahmung:** Je näher am Original, desto größer das Risiko (App-Store-Richtlinie 4.1 „Copycats“, Wettbewerbs- und Designrecht). [OFFEN – Prüffrage] Ab wann ist ein Gesamteindruck geschützt? Vor dem Store eigenständig machen (Phase 3).
- [RISIKO] **Dunkle Muster:** Schock-Zahlen und Druck („Hold to Commit“) wirken stark. Wir zeigen den Rechenweg und erfinden keine Zahlen.
- [RISIKO] **Bildschirmzeit:** Apple-Berechtigung kann dauern oder abgelehnt werden; ohne sie fällt §5 weg, der Rest steht.
- [OFFEN] Bildschirmaufnahmen für Animationen.
