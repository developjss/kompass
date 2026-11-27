# Konzept: Lernen über alle Nutzer

Stand: 27. November 2026 · noch nicht gebaut (die App lernt nur aus den eigenen Daten, `docs/produkt/rechenregeln.md` §7).

- Gleiche Formeln wie `docs/produkt/rechenregeln.md` §7, aber mit Summen über alle Nutzer, die zugestimmt haben.
- Übertragen werden nur **Zahlen ohne Personenbezug**: Vorlage, Schritt-Name (normalisiert), geplant/tatsächlich, gezeigt/übernommen. Keine Ziel-Titel im Freitext, keine Termine, keine Notizen.
- Persönlicher Faktor schlägt Gemeinschafts-Faktor, sobald genug eigene Daten da sind: `r = (Σ eigene + k × r_alle) ÷ (n + k)`, k = 3.
- Server: z. B. Supabase (wie bei Gapless) mit Zeilen-Sicherheit; [OFFEN] Anbieter-Freigabe durch den Gründer.
- [RISIKO] Datenschutz: Einwilligung, Widerruf, Löschung – Prüffragen in `docs/recht/recht-und-sicherheit.md`.
