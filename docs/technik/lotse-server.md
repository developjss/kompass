# Lotse-Server – Betrieb

Stand: 23. November 2026 · Code: `supabase/functions/lotse/` · Konzept: `docs/produkt/konzepte/lotse.md`. [ENTSCHEIDUNG – 23.11.2026] Weg A: Claude über einen eigenen Server, zwei Modellgrößen.

## 1. So funktioniert es

```
App ──(Frage, App-Wissen, Werkzeuge, Stand, Schritte, Geräte-ID, Kanal, Pro)──▶ Server ──▶ Claude
App ◀──(Werkzeugaufrufe + Inhalt  oder  Text) + Kontingent──────────────────── Server ◀──
      └─ App führt Werkzeuge aus (rechnet), schickt Ergebnisse als „schritte“ zurück – bis Text kommt (höchstens 6 Runden)
```

**Fassung 2 (23.11.2026, nach Test des Gründers: „Antworten machen keinen Sinn“):**
1. **Mit Server beantwortet Claude jede Frage** (Rolle `gespraech`, Standard Claude Sonnet 5.5) – auch allgemeine Fragen (Wissen, Reisen, Rat). Vorher fingen Regeln auf dem Gerät viele Fragen falsch ab („Fahrt“ → Habit, „Zeit“ → Hilfe-Text) und Claude durfte Allgemeines nicht beantworten.
2. **Werkzeugschleife:** Braucht Claude Daten oder soll etwas angelegt werden, ruft es Werkzeuge der App (auch mehrere). Die App rechnet und schickt die Ergebnisse zurück; Claude formuliert die Antwort. Zahlen stammen immer aus der App.
3. **Stil:** Absätze, **fett**, Listen; die App stellt das dar (`AntwortText`).
4. **Regeln auf dem Gerät** (`Verstehen`) nur noch ohne Server oder bei Fehler. Wurde schon etwas angelegt, springen sie nicht ein (kein doppeltes Anlegen).
5. **Mitwachsen:** Claude bekommt bei jeder Frage `AppWissen.text()` (Bereiche, Fenster, Rechenregeln – Tests erzwingen Vollständigkeit) und alle `Werkzeuge.alle`. Neues Werkzeug oder neuer Bereich ist damit sofort bekannt, ohne Server-Deploy.
6. Eine Frage zählt einmal im Kontingent, egal wie viele Runden.

Der Server speichert **keine Fragen**. Gespeichert wird nur der Zähler je Geräte-ID und Tag (`lotse_kontingent`). Das App-Wissen ist bei allen gleich und wird als Prompt-Cache markiert.

## 2. Einrichten (Gründer, einmalig · ca. 30 Minuten)

### Anthropic-Konto
- **Dein privates Konto reicht** – auch für TestFlight. Es ist ein Konto auf `platform.claude.com` (Console, Zahlung je Nutzung mit Guthaben), **nicht** das Claude-Abo der Chat-App. Später zu einem Firmenkonto wechseln = neuen Schlüssel als Secret setzen, sonst nichts.
- Dort einen **API-Schlüssel** erzeugen. Er wird nur als Secret auf dem Server gesetzt – nie in der App, nie im Repo, nie im Chat.
- Empfehlung: in der Console ein **monatliches Ausgabenlimit** setzen (z. B. 20 €), bis echte Zahlen vorliegen.

### Supabase-Projekt (Server und Zähler)
[OFFEN] Ort des Servers: Supabase Edge Functions (Vorschlag, weil später auch der Abgleich zwischen Geräten dort laufen kann). Der Code hat keine Supabase-Abhängigkeit außer dem Zähler (PostgREST per `fetch`) und läuft auf jedem Deno/Node-Host (`behandle(req, abhaengigkeiten)` in `lotse.ts`).

```bash
# Supabase CLI installieren (einmalig, Homebrew) – neue Abhängigkeit nur auf dem Mac, nicht in der App
brew install supabase/tap/supabase
supabase login
supabase link --project-ref <projekt-ref>        # Projekt vorher im Supabase-Dashboard anlegen (Region EU)
supabase db push                                 # legt lotse_kontingent und die SQL-Funktionen an
supabase secrets set ANTHROPIC_API_KEY=sk-ant-…  # der einzige geheime Wert
supabase secrets set LOTSE_APP_SCHLUESSEL=<zufälliger Text>   # optional; derselbe Wert in LotseKonfiguration.appSchluessel
supabase functions deploy lotse
```

Bereitgestellt am 23.11.2026 (über die Supabase-Anbindung dieser Sitzung, ohne CLI): Projekt **kompass**, Region EU (Irland), URL `https://wvjgdyazlbevofyolanu.supabase.co/functions/v1/lotse`. Secrets setzt der Gründer im Dashboard: Projekt → Edge Functions → Secrets → `ANTHROPIC_API_KEY`. Diese URL in `Kompass/Lotse/ClaudeServer.swift` → `LotseKonfiguration.standardURL` eintragen (je Kanal; für Tests zuerst nur `debug`/`beta`). Im Debug/Beta-Build geht es auch ohne Build: Einstellungen → Lotse → Server-URL.

### Prüfen
```bash
curl -s -X POST https://<ref>.supabase.co/functions/v1/lotse -H 'Content-Type: application/json' \
  -d '{"frage":"Was steht heute an?","wissen":"","kurzstand":"","werkzeuge":[{"name":"heute","beschreibung":"Was heute ansteht","parameter":{}}],"verlauf":[],"nutzer":"6f9619ff-8b86-d011-b42d-00c04fc964ff","kanal":"debug","pro":false}'
# erwartet: {"art":"werkzeug","name":"heute","parameter":{},"kontingent":{...}}
```

Tests des Servers: `deno test supabase/functions/lotse/` (Deno installieren oder in der Supabase CLI enthalten).

## 3. Einstellungen auf dem Server (Umgebungsvariablen, kein Deploy nötig)

| Variable | Standard | Bedeutung |
|---|---|---|
| `ANTHROPIC_API_KEY` | – | Pflicht. Schlüssel des Anthropic-Kontos |
| `LOTSE_MODELLE` | siehe `modelle.ts` | JSON `{"werkzeugwahl":[…],"gespraech":[…]}` – Kandidaten je Rolle, erster verfügbarer gewinnt |
| `LOTSE_FREI_PRO_TAG` | 5 | Fragen pro Tag ohne Pro (nur Server-Fragen; Regeln sind frei) |
| `LOTSE_PRO_PRO_TAG` | 300 | Obergrenze mit Pro (Schutz vor Missbrauch) |
| `LOTSE_TESTER_FREI` | `true` | Debug/Beta/TestFlight gelten als Pro. **Zur Store-Veröffentlichung auf `false`.** |
| `LOTSE_APP_SCHLUESSEL` | – | Optionaler gemeinsamer Schlüssel App ↔ Server |

## 4. Wenn Modelle eingestellt werden

Anthropic kündigt das Ende eines Modells vorher an. Der Server fragt die Modellliste ab (`models.retrieve`) und nimmt je Rolle den ersten Kandidaten, der noch da ist; fällt ein Modell mitten im Betrieb weg (404), rückt der nächste nach. Neue Modelle aufnehmen: `LOTSE_MODELLE` setzen – kein App-Update. Faustregel beim Wechsel: Werkzeugwahl bleibt bei der kleinsten Klasse (Haiku-Nachfolger), Gespräch bei der mittleren (Sonnet-Nachfolger); `effort: low` beibehalten, dann die Beispielfragen aus `LotseTests` gegen den Server prüfen.

## 5. Kontingent, Pro, TestFlight

- **Frei:** 5 Server-Fragen am Tag (Zeitzone des Nutzers). Danach 429 → die App zeigt „Deine 5 freien Fragen sind aufgebraucht“ mit Sprung zu Kompass Pro.
- **Pro:** bis 300 am Tag. Heute meldet die App Pro selbst (`Einstellungen.pro`, nur in Debug/Beta schaltbar). [RISIKO] Vor dem Store: Kauf über StoreKit (`l-storekit`) und Prüfung des Kaufs auf dem Server (`l-pro-pruefung`), dann `LOTSE_PRO_PRUEFUNG=an`.
- **TestFlight:** Builds mit Sandbox-Beleg melden Kanal `testflight`; solange `LOTSE_TESTER_FREI=true`, zählen Tester wie Pro. Beim Store-Start umstellen – kein App-Update nötig.
- **Geräte-ID:** zufällige UUID in den UserDefaults, kein Konto. Neuinstallation = neue ID (bewusst einfach; Missbrauch begrenzt der App-Schlüssel und das Pro-Limit).

## 6. Kosten im Blick [SCHÄTZUNG]

Fassung 2: jede Frage geht an Sonnet, oft 2 Runden → ≈ 1–2 Cent je Frage (App-Wissen und Werkzeuge im Prompt-Cache). 1.000 aktive Nutzer × 10 Fragen/Tag → **≈ 3.000–6.000 $ im Monat** (Fassung 1: 40–60 $). [RISIKO] Für den Store vor Preisentscheidung prüfen: günstigeres Modell per `LOTSE_MODELLE` (ohne Deploy), freie Fragen pro Tag (`LOTSE_FREI_PRO_TAG`), Pro-Preis. Nachrechnen: Console → Usage; nach einer Woche TestFlight die echten Zahlen in dieses Dokument.

## 6a. Erster Live-Test (23.11.2026)

| Frage | Ergebnis | Dauer |
|---|---|---|
| „Ich muss übermorgen unbedingt den Fahrlehrer wegen der Prüfung anrufen“ | Werkzeug `aufgabeAnlegen`: Titel, Datum 25.11., wichtig ja, Ziel Führerschein | 3,5 s |
| „Soll ich mich eher auf den Führerschein oder auf Fitness konzentrieren?“ | Stufe 2 (Sonnet): Empfehlung Fitness mit Begründung aus dem Kurzstand, nennt fehlende Zahlen | 5,0 s |
| „hey, danke dir!“ | kurzer Satz, kein Werkzeug | 1,6 s |

Gelernt: Leere Textblöcke lehnt die API ab (400) → Server lässt leeres Wissen weg. `service_role` braucht ausdrücklich `grant execute` auf die Zähler-Funktionen (403 sonst).

## 7. Störfälle

| Was | Verhalten der App |
|---|---|
| Server nicht erreichbar / 5xx | Antwort mit Regeln, Hinweis „Server gerade nicht erreichbar“ |
| 429 Kontingent | Text mit Sprung zu Pro |
| Modell weg (404) | Server nimmt den nächsten Kandidaten; nichts sichtbar |
| Anthropic ausgelastet (Rate-Limit) | 503 → Regeln |
| Ablehnung durch Sicherheitsfilter | Text „Dazu kann ich nichts sagen …“ |

## 8. Datenschutz als Prüffragen [OFFEN]
Auftragsverarbeitung mit Anthropic (und Supabase, Region EU); Datenschutzerklärung: Fragen gehen an einen Server in … / an Anthropic, werden nicht gespeichert; Opt-in beim ersten Nutzen des Lotsen (noch nicht gebaut, Aufgabe `l-einwilligung`); Kurzstand enthält Zieltitel und Habit-Namen – nichts Weiteres.
