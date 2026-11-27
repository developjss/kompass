# Fahrplan – Phasen und Bausteine

Stand: 27. November 2026. Einzelne Aufgaben, Pflichten und Termine stehen in `docs/leitung/aufgaben/aufgaben.json` (`/fahrplan`); hier stehen Phasen, Reihenfolge und Begründung.

## 1. Ziel

Kompass veröffentlichen, zuerst iPhone (App Store), danach Mac, später Android und Windows. [OFFEN] Nur für den Gründer oder als Produkt mit Abo.

## 2. Phasen

| Phase | Inhalt | Ende, wenn … |
|---|---|---|
| **0–1 Klick-Dummy, Entscheiden** ✓ | HTML-Prototyp, Rechenregeln, Technik SwiftUI | erledigt 23.11.2026 |
| **2 iPhone-MVP** (läuft) | SwiftUI-App mit Home, Habits, Ziele, Assistent; **neu:** Journal statt Kalender-Tab, Berater mit gelesenen Kalendern, Muster; neues Design | Personen-Test grün, Gründer nutzt die App täglich |
| **3 Version 1 Apple** | Onboarding mit Kalender-Zugriff, Widgets, Erinnerungen, Pro (StoreKit), Mac-App | TestFlight mit Freunden |
| **4 Sync & weitere Plattformen** | Konto und Abgleich (Supabase EU), eigenes Google-Login, Android/Windows | Daten auf allen Geräten gleich |
| **5 Store** | Store-Texte, Datenschutz, Preis/Abo, Review | App im Store |
| **6 Lernen über alle Nutzer** | anonyme Zusammenfassung mit Einwilligung | `docs/produkt/konzepte/lernen-ueber-alle-nutzer.md` umgesetzt |

## 3. Reihenfolge in Phase 2 [VORSCHLAG]

1. Design-Entwurf neu, Entscheidung des Gründers.
2. Journal-Tab ersetzt den Kalender-Tab (Wochenreflexion zieht um).
3. Berater: freie Zeit aus allen Kalendern, Termine über Apples Termin-Fenster.
4. Muster als Rechenregel §15.
5. Design und Statistiken auf allen Seiten neu.

## 4. Risiken

- [RISIKO] Journaltexte sind womöglich Gesundheitsdaten (DSGVO Art. 9) – Prüffrage in `docs/recht/recht-und-sicherheit.md`.
- [RISIKO] Viele Journal-Apps mit KI. Abgrenzung nur über die Verbindung von Journal, Habits, Zielen und Kalender, fest gerechnet.
- [RISIKO] Muster brauchen ≥ 14 Tage Daten – in den ersten Wochen müssen Berater und Habits tragen.
- [RISIKO] Google verlangt für eigenes Kalender-Login eine Prüfung der App – deshalb zuerst über die Konten im iPhone.
