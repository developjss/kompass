# Fahrplan – Phasen und Bausteine

Stand: 27. November 2026. Einzelne Aufgaben, Pflichten und Termine stehen in `docs/leitung/aufgaben/aufgaben.json` (`/fahrplan`); hier stehen Phasen, Reihenfolge und Begründung.

## 1. Ziel

Kompass veröffentlichen, zuerst iPhone (App Store), danach Mac, später Android und Windows – als Produkt mit Abo (Pro, vorerst 4,99 € im Monat).

## 2. Phasen

| Phase | Inhalt | Ende, wenn … |
|---|---|---|
| **0–1 Klick-Dummy, Entscheiden** ✓ | HTML-Prototyp, Rechenregeln, Technik SwiftUI | erledigt 23.11.2026 |
| **2 Umbau, fertig bis auf Konten** (läuft) | Umbau nach Vorbild Opal mit Journal, Berater, Bildschirmzeit, Onboarding, Paywall – Blöcke A–P in `docs/produkt/konzepte/umbau-nach-vorbild.md` §9 | App vollständig auf dem iPhone, Platzhalter benannt, Tests grün |
| **3 Store** | App Store Connect, Apple-Berechtigung Family Controls, Rechtstexte, Bilder-Lizenz, TestFlight | App im Store |
| **4 Server und Konten** | Konto-Abgleich (Supabase EU), Telefon/E-Mail, Einladungen und Belohnungen, Lernen über alle | Platzhalter leben |
| **5 Weitere Geräte** | Mac, später Android/Windows | – |

## 3. Reihenfolge in Phase 2

Designsystem → Figur → Datenmodell → Rechnung → Bildschirmzeit → Navigation → Onboarding (3 Blöcke) → Home → Habits/Ziele → Editoren → Fokus → Journal/Assistent → Profil/Pro → Abschluss. Begründung: `umbau-nach-vorbild.md` §7.

## 4. Risiken

- [RISIKO] Journaltexte sind womöglich Gesundheitsdaten (DSGVO Art. 9) – Prüffrage in `docs/recht/recht-und-sicherheit.md`.
- [RISIKO] Viele Journal-Apps mit KI. Abgrenzung nur über die Verbindung von Journal, Habits, Zielen und Kalender, fest gerechnet.
- [RISIKO] Muster brauchen ≥ 14 Tage Daten – in den ersten Wochen müssen Berater und Habits tragen.
- [RISIKO] Google verlangt für eigenes Kalender-Login eine Prüfung der App – deshalb zuerst über die Konten im iPhone.
