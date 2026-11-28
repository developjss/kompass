# Plan – Compass nach Vorbild Opal

Stand: 27. November 2026 · [ENTSCHEIDUNG – 27.11.2026, Gründer: „von Grund auf neu, erst 1 zu 1 wie Opal“].
Vorlage: 130 Bildschirmfotos beim Gründer (`~/Developer/Kompass-Vorbild`: onboarding 1–51 in zeitlicher Folge, Home, Übersichten, offene Fenster, Fokus, Profil). Sie kommen nie ins Repo.

## Grenze

Nachgebaut werden Aufbau, Abläufe, Funktionen, Maße, Schriftgrößen, Farben, Licht und Bewegung. **Nicht** übernommen werden Opals Bilder, 3D-Figuren, Fotos, Logo, Name und Texte – an ihrer Stelle stehen eigene Bilder in derselben Bildwelt (benannte Bildplätze), eigene deutsche Texte in gleicher Länge und der Name Compass. [RISIKO] Vor dem Store muss Compass eigenständig genug sein (Store-Richtlinie gegen Nachahmer) – Prüffrage für einen Anwalt.

## Designsystem (gemessen, 393 × 852 pt)

Grund #000000 · Licht oben #779373 (Pro lila, Intro blau-grau), nach 200 pt schwarz · Text weiß, zweitrangig #96969B, Antwort #8AB994 · Akzent-Verlauf #D3FFA0 → #A9FBEF · Kapsel-Knopf 54 pt mit Unterglühen · Auswahl-Kapsel 58 pt #202020 · Glas-Blatt Radius 40 #2B2B2B · Gruppen Radius 22 · Schrift SF Pro: Titel 34 Bold, Gespräch 20, Überschrift 22 Semibold, Zeile 17, Unterzeile 15. Code: `Kompass/Design/`.

## Blöcke

Jeder Block: bauen, Tests, **jede Seite ablichten und neben das Opal-Bild legen**, auf iPhone und Simulator iPhone 18 Pro installieren, PR.

| # | Block | Vorlage |
|---|---|---|
| 1 | Gerüst: Tab-Kapsel (Home · Meine Apps · Timer), Profil-Knopf, Datenmodell | Übersichten |
| 2 | Bildschirmzeit-Kern: Erlaubnis, App-Auswahl, Sperren, Messen, Sperrbildschirm | – |
| 3 | Onboarding 1–18: Intro, Gespräch, Fragen | onboarding 1–18 |
| 4 | Onboarding 19–32: Jahre-Walze, Erlaubnisse, Plan, Paywall | onboarding 19–32 |
| 5 | Onboarding 33–51: Regeln erklären, Ablenker, Vorschläge, Einladen, Willkommen, erster Meilenstein | onboarding 33–51 |
| 6 | Meine Apps: gesperrte Apps, Regeln, Immer/Nie erlaubt | Übersichten, Fenster |
| 7 | Regeln: Sitzung, Zeitplan, Zeitlimit, Ort; Schwierigkeit; Halten zum Festlegen | Fenster |
| 8 | Timer: Digitaluhr, Schnellwahl, Lineal, „Für dich“, Durchziehen | Übersichten, Fenster |
| 9 | Entsperren: App wählen, Spiele, Atmen, Dauer-Rad | Home, Fokus |
| 10 | Home: Figur, Werte, Karten, schwebende Sitzung, Serie | Home |
| 11 | Meilensteine als Sammelstücke | Home |
| 12 | Profil und Einstellungen: Konto, Pro, Notfall-Pass, Urlaub, Themen, Hinweise, Einladen | Profil |
| 13 | Abschluss: Tests, Platzhalter-Liste, Vergleich jeder Seite | alle |

## Platzhalter (bis Konto oder Server da sind)

Anmeldung per Telefon und E-Mail · Einladungen zählen, Belohnungen, Geschenkkarte · echte Pro-Produkte (App Store Connect; vorerst 4,99 € im Monat) · Apples Berechtigung „Family Controls“ für den Store · Geräusche und Geschichten · Community, Mac-App. Im Code markiert mit `// PLATZHALTER: …`, in der App „Kommt bald“.

## Offen

- [OFFEN] Rechenregeln (Wert, Bildschirmzeit, Serie, Meilensteine) – werden mit Block 2 und 10 neu geschrieben, mit Tests und Freigabe.
- [OFFEN] Bilder: KI-erzeugt in Opals Bildwelt mit eigenen Motiven; Generator kostet Guthaben – Rückfrage vor dem ersten Bild.
