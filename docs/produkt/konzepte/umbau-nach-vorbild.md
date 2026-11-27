# Umbau nach Vorbild „Opal“ – Analyse, Designsystem, Bauplan [VORSCHLAG – 27.11.2026, Freigabe des Gründers offen]

Auftrag des Gründers (27.11.2026): Kompass im Design der App **Opal** (Bildschirmzeit und Fokus) nachbauen – Aufbau, Abläufe, Abstände, Farben, Helligkeit, Animationen –, mit unseren Inhalten und Anforderungen. Vor dem Store wird das Design eigenständig gemacht.
Grundlage: 89 Bildschirmfotos (iPhone, 393 × 852 pt) – Onboarding 51 in zeitlicher Folge, Home 9, Übersichten 6, Fenster 21, Fokus 2. Sie liegen nur lokal beim Gründer (`~/Developer/Kompass-Vorbild`), nicht im Repo.

**Grenze** (vorgeschlagene Regel, `docs/team/arbeitsweise.md` §2): Nachgebaut werden Aufbau, Maße, Schriftgrößen, Farben, Licht und Bewegung. **Nicht** übernommen werden Bilder, 3D-Figuren (Opal-Stein, Fels, Höhle), Fotos, Icons, Logo, Siegel, Markennamen und Texte von Opal – an ihrer Stelle stehen eigene Inhalte in gleicher Größe und Lage. Texte schreiben wir neu, auf Deutsch, gleich lang und im gleichen Ton.

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
| Anmeldung Apple/Telefon/E-Mail | kein Konto bis Phase 4 | **weglassen** |
| „Du verbringst 13 Jahre am Handy“ (Walze) | Fest gerechnet aus der Schätzung: Stunden/Tag × 365 ÷ 16 Wachstunden → Tage/Jahr; × verbleibende Jahre bis 80 → Jahre. Fußnote mit Rechenweg | **übernehmen** – neue Rechenregel §16 |
| „Opal holt dir 4 Jahre zurück“ | nur mit Annahme im Klartext („wenn du 30 % weniger nutzt“), fest gerechnet | **anpassen** |
| Erlaubnis Bildschirmzeit, Mitteilungen (Dialog im Leuchtrahmen mit Pfeil) | Bildschirmzeit, Kalender, Mitteilungen – je ein Schritt | **übernehmen** |
| Zusammenfassung mit drei Nutzen | „Dein Plan“: drei Zeilen aus den Antworten | **übernehmen** |
| Testphase-Erinnerung, Paywall-Karussell | erst nach Preis-Entscheidung (Pro) | **später** – Recht/Preise brauchen Freigabe |
| „Lass uns Regeln festlegen“ + Regel-Karten | „Lass uns deine ersten Habits festlegen“: Vorschläge als Foto-Karten (Lesen 20 Min, Sport 3×/Woche, Handyfreier Morgen …), aus den Antworten nach festen Regeln | **übernehmen** |
| „Funktioniert für 97 % der Nutzer wie dich“ | Wir haben diese Daten nicht – das wäre erfunden | **weglassen**; später nur mit „Lernen über alle Nutzer“ und Einwilligung |
| Ablenkungen wählen (Apple-Auswahlliste) | gleiche Apple-Liste: „Welche Apps halten dich ab?“ | **übernehmen** (Bildschirmzeit, §5) |
| Freunde einladen mit Belohnung | kein Server, rechtlich heikel | **weglassen** |
| Willkommen mit Konfetti | ja | **übernehmen** |
| Meilenstein-Steine sammeln, „Besitzt 27 %“ | Meilensteine für Serien und Fokusstunden (7/30/100/300 Tage, 10/50/100/500/1000 h) als Sammelstücke; ohne Prozent anderer Nutzer | **übernehmen**, Prozent weglassen |
| Apps-Seite (blockierte Apps, Regeln, Einstellungen als Karten) | Habits-Seite im selben Aufbau: oben heute fällige Habits als Reihe, darunter Habit-Karten, unten Einstellungen-Karten | **übernehmen** |
| Timer (Digitaluhr, ± , Schnellwahl ∞/15m/30m/1h, Lineal, „Für dich“-Karten) | Fokus-Timer mit Aufgabe/Ziel; „Für dich“ = Fokus-Vorschläge (Lernen, Lesen, Tiefe Arbeit) | **übernehmen** |
| Hard Mode (nicht vorzeitig beenden) | „Durchziehen“-Schalter im Fokus | **übernehmen** (Pro offen) |
| Warteraum (Lichtring, „Warte 11 s“, Atemübung) | Pause, bevor man den Fokus abbricht | **übernehmen** |
| Geräusche und Einschlafgeschichten | eigene Inhalte fehlen | **später** |
| Editor-Blätter (Von/Bis, Tage, Schwierigkeit, Hold to Commit, „Ungespeichert“) | Habit-, Ziel-, Aufgaben-Editor | **übernehmen** |
| Tab-Leiste mit 3 Tabs | 5 Tabs (Home, Journal, Assistent, Habits, Ziele) in derselben Kapsel | **anpassen** |
| Gesprächs-Oberfläche | auch der Assistent (Berater) spricht so | **übernehmen** |

**Folge:** Opal ist dunkel. Der helle Neuentwurf vom 27.11. (Creme, Glas) und „Nachtblau“ werden damit abgelöst – [OFFEN] Entscheidung des Gründers: Kompass nur dunkel?

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

## 6. Neue Rechenregeln (je Freigabe des Gründers)

- **§15 Muster** (aus `journal-und-berater.md` §5), ergänzt um Bildschirmzeit als Gruppe.
- **§16 Handy-Jahre:** Stunden je Tag = Mitte der gewählten Spanne (unter 1 h → 0,5; 1–3 → 2; 3–4 → 3,5; 4–5 → 4,5; 5–7 → 6; 7+ → 8; „weiß nicht“ → kein Zahlen-Bildschirm). Wache Tage je Jahr = Stunden × 365 ÷ 16. Wache Jahre bis 80 = wache Tage je Jahr × (80 − Alter) ÷ 365. „Zurück“ = dieselbe Rechnung mit 30 % weniger. Ganze Zahlen, Fußnote mit Rechenweg. Beispiel: 2 h, 21 Jahre → 46 Tage im Jahr, 7 Jahre bis 80; zurück 2 Jahre. (Opal rechnet sichtbar mit der oberen Grenze: 3 h → 68 Tage – wir nehmen die Mitte, das ist ehrlicher.)
- **§17 Bildschirmzeit-Signale:** Schwellen 30/60/120 Min je gewählter App-Gruppe und Tag; Signal und Muster nur aus gemeldeten Schwellen.
- **§18 Meilensteine:** Serien 7/30/100/150/300 Tage, Fokusstunden 10/50/100/500/1000/2000.
- **Habit-Vorschläge im Onboarding:** feste Tabelle Antwort → Vorschlag.

## 7. Bauplan in Blöcken

Jeder Block: ein Baustein, Tests, Lotse mitziehen, iPhone und Simulator, eigener PR. Alle Blöcke greifen auf §2 zu – Werte stehen einmal in `Kompass/Design/` (`Opal`-Werte heißen dort neutral, z. B. `Licht`, `Kapsel`).

| # | Block | Fertig, wenn |
|---|---|---|
| 0 | Entscheidungen: Regel §2, nur dunkel?, Bildschirmzeit ja/nein, Fotos-Quelle; Rechenregeln §16–§18 freigeben | „Ja“ des Gründers |
| 1 | **Designsystem:** Farben, Licht oben, Schrift-Stufen (Dynamic Type), Kapsel-Knopf mit Unterglühen, Halten-Knopf, Auswahl-Kapsel, Eingabe, Gruppen-Zeilen, Tage-Wahl, Von/Bis, Regler, Plakette, Seitenpunkte, Glas-Blatt, Tab-Kapsel. Vorschau-Seite mit allen Teilen | Vorschau neben Opal-Bildern deckungsgleich in Maß und Farbe; Kontrast-Tests |
| 2 | **Figur:** Kugel mit Bewegung, Zuständen und Reduce Motion | Simulator, Ruhe-Modus steht still |
| 3 | **Onboarding 1 – Gespräch:** Intro (4 Seiten), Gesprächs-Baustein (Schreibmaschine, Verlauf unscharf, Antwort grün), Fragen Name · Ziel · Alter · Lebenslage · Bildschirmzeit, „Ich werte aus …“ | Profil gespeichert, VoiceOver liest ganze Sätze, Tests |
| 4 | **Onboarding 2 – Zahlen und Erlaubnisse:** Walze (§16), Erlaubnis-Schritte mit Leuchtrahmen und Pfeil (Bildschirmzeit, Kalender, Mitteilungen), „Dein Plan“ | Rechnung getestet, Ablehnen jeder Erlaubnis funktioniert |
| 5 | **Onboarding 3 – erste Habits:** Vorschlags-Karten-Karussell, Halten zum Festlegen, „Überspringen“, Willkommen mit Konfetti | Habits angelegt, Personen-Test grün |
| 6 | **Tab-Kapsel und Home** | [OFFEN] Opals Haupt-Home fehlt in den Bildern (nur Meilensteine) – Bilder nachliefern |
| 7 | **Habits-Seite** im Aufbau der Apps-Seite | Leer-, Lade-, Fehlerzustand |
| 8 | **Editor-Blätter** für Habit, Ziel, Aufgabe (Glas-Blatt, Zeilen, Tage, Von/Bis, Schwierigkeit, Halten, „Ungespeicherte Änderungen“) | alle Felder wie bisher, UI-Tests |
| 9 | **Fokus** im Timer-Aufbau (Digitaluhr selbst gezeichnet, Schnellwahl, Lineal, „Für dich“, Durchziehen, Warteraum) | Rechnung Fokus unverändert, Tests |
| 10 | **Meilensteine** als Sammelstücke (§18) | Tests je Schwelle |
| 11 | **Bildschirmzeit** Stufe 1 messen (§17, Muster), Stufe 2 sperren im Fokus | nach Apple-Berechtigung; Gerätetest |
| 12 | **Journal, Ziele, Assistent** im selben Stil (Assistent nutzt den Gesprächs-Baustein) | Lotse-Tests |
| 13 | **Pro und Paywall** im Aufbau von Opal | nach Preis-Entscheidung, Recht geprüft |
| 14 | **Eigenständig machen** vor dem Store: Farben, Figur, Texte, Abläufe so weit ändern, dass Kompass nicht mehr als Kopie wirkt | Gründer und Prüfung (§8) |

## 8. Risiken und Prüffragen

- [RISIKO] **Nachahmung:** Je näher am Original, desto größer das Risiko (App-Store-Richtlinie 4.1 „Copycats“, Wettbewerbs- und Designrecht). [OFFEN – Prüffrage] Ab wann ist ein Gesamteindruck geschützt? Block 14 ist Pflicht vor TestFlight mit Fremden.
- [RISIKO] **Dunkle Muster:** Schock-Zahlen und Druck („Hold to Commit“) wirken stark. Wir zeigen den Rechenweg und erfinden keine Zahlen.
- [RISIKO] **Bildschirmzeit:** Apple-Berechtigung kann dauern oder abgelehnt werden; ohne sie fällt §5 weg, der Rest steht.
- [OFFEN] Bildschirmaufnahmen für Animationen; Bilder von Opals Haupt-Home.
