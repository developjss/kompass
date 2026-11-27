import Foundation

// Demo-Daten (ursprünglich aus dem archivierten Klick-Dummy). Nur erfundene Beispiele – keine echten Daten.
// Zufall mit festem Startwert: gleiche Demo bei jedem Start (wichtig für Screenshots und Tests).

struct Zufall: RandomNumberGenerator {
    private var s: UInt64
    init(_ startwert: UInt64) { s = startwert }
    mutating func next() -> UInt64 { // SplitMix64
        s &+= 0x9E37_79B9_7F4A_7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func zahl() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

enum DemoDaten {

    static func zustand(heute T: Tag, jetzt: Date = Date(), startwert: UInt64 = 2026) -> Zustand {
        var r = Zufall(startwert)
        let Y = T.jahr
        func s(_ titel: String, _ geschafft: Bool = false) -> Schritt { Schritt(titel: titel, geschafft: geschafft) }

        var auto = Ziel(titel: "Führerschein Klasse B", farbe: "#1F7AC2", symbol: "car.fill", bereich: "Mobilität",
                        faellig: T.plus(monate: 7), warum: "Unabhängig unterwegs sein", angelegt: T.plus(monate: -5))
        auto.schritte = [
            s("Erste-Hilfe-Kurs", true), s("Sehtest", true),
            Schritt(titel: "Theorieunterricht besuchen", art: .zahl, soll: 14, start: 0, aktuell: 12, einheit: "Doppelstd."),
            Schritt(titel: "Theorie lernen", art: .zeit, gewicht: 2, soll: 25),
            Schritt(titel: "Theorieprüfung", gewicht: 2),
            Schritt(titel: "Fahrstunden", art: .zahl, gewicht: 3, soll: 30, start: 0, aktuell: 6, einheit: "Fahrstunden"),
            Schritt(titel: "Praktische Prüfung", gewicht: 2),
        ]
        var flug = Ziel(titel: "LAPL(A) bestehen", farbe: "#3B4CCA", symbol: "airplane", bereich: "Fliegen",
                        faellig: Tag(Y + 5, 9, 30), warum: "Selbst fliegen können", angelegt: T.plus(monate: -10))
        flug.schritte = [
            s("Tauglichkeitszeugnis", true),
            Schritt(titel: "Theorie: 9 Fächer lernen", art: .zeit, gewicht: 3, soll: 120),
            Schritt(titel: "Theorieprüfung", gewicht: 2),
            Schritt(titel: "Flugstunden", art: .zahl, gewicht: 3, soll: 45, start: 0, aktuell: 0, einheit: "h"),
            Schritt(titel: "Erster Alleinflug"),
            Schritt(titel: "Praktische Prüfung", gewicht: 2),
        ]
        var geld = Ziel(titel: "Millionär werden", farbe: "#9A6700", symbol: "eurosign.circle.fill", bereich: "Finanzen",
                        faellig: Tag(Y + 6, 12, 31), warum: "Finanzielle Freiheit", angelegt: T.plus(monate: -12))
        // Ziel „als Zahl“ = ein Zahl-Meilenstein; Zwischenstände werden automatisch erreicht
        geld.schritte = [
            Schritt(titel: "Vermögen", art: .zahl, gewicht: 3, soll: 1_000_000, start: 0, aktuell: 18_500, einheit: "€",
                    schwellen: [10_000, 100_000, 500_000],
                    verlauf: (0...12).map { i in VerlaufPunkt(tag: T.plus(monate: i - 12), wert: i == 12 ? 18_500 : (6000 + Double(i) * 1000 + sin(Double(i) * 1.7) * 900).rounded()) }),
        ]
        var fit = Ziel(titel: "Fit: 75 kg & Halbmarathon", farbe: "#15803D", symbol: "figure.run", bereich: "Gesundheit",
                       faellig: Tag(Y + 1, 6, 30), warum: "Energie für alles andere", angelegt: T.plus(monate: -6))
        fit.schritte = [
            Schritt(titel: "Gewicht", art: .zahl, gewicht: 2, soll: 75, start: 86, aktuell: 81, einheit: "kg",
                    verlauf: (0...12).map { i in VerlaufPunkt(tag: T.plus(tage: (i - 12) * 14), wert: i == 12 ? 81 : ((86 - Double(i) * 0.42 + sin(Double(i)) * 0.4) * 10).rounded() / 10) }),
            s("10 km unter 60 min"),
            Schritt(titel: "Halbmarathon laufen", gewicht: 2),
        ]

        // Habits mit Menge und Einheit; Einträge der letzten 70 Tage mit festem Zufall (teils Teilmengen)
        func hb(_ titel: String, _ farbe: String, _ symbol: String, _ rhythmus: Rhythmus, _ menge: Double?, _ einheit: Einheit?, _ ziel: UUID?, _ p: Double, erinnerung: Int? = nil) -> Habit {
            var h = Habit(titel: titel, farbe: farbe, symbol: symbol, rhythmus: rhythmus, menge: menge, einheit: einheit, erinnerung: erinnerung, zielID: ziel, angelegt: T.plus(tage: -70))
            for i in 1...70 {
                let d = T.plus(tage: -i)
                guard h.wochentage.contains(d.wochentag) else { continue }
                if case .proWoche(let n) = rhythmus, HabitRechnung.summe(h, von: d.montag, bis: d) >= Double(n) { continue }
                let w = r.zahl()
                if w < p { h.eintragen(menge ?? 1, am: d) }
                else if let m = menge, w < p + 0.1 { h.eintragen((m * 0.5).rounded(), am: d) }
            }
            return h
        }
        var habits = [
            hb("Buch lesen", "#7A4FD6", "book.fill", .taeglich, 20, .minuten, nil, 0.78, erinnerung: 21 * 60),
            hb("LAPL-Theorie lernen", "#3B4CCA", "airplane", .wochentage([1, 2, 3, 4, 5]), 30, .minuten, flug.id, 0.7, erinnerung: 18 * 60),
            hb("Führerschein-Fragen", "#1F7AC2", "car.fill", .taeglich, 30, .mal, auto.id, 0.82),
            hb("Sport", "#15803D", "figure.run", .proWoche(3), 45, .minuten, fit.id, 0.75, erinnerung: 17 * 60 + 30),
            hb("Kein Handy nach 22 Uhr", "#B8456E", "moon.fill", .taeglich, nil, nil, nil, 0.55),
        ]
        habits[0].eintragen(12, am: T)
        habits[0].uhrzeit = 21 * 60           // Buch lesen: abends fest im Kalender
        habits[1].uhrzeit = 18 * 60           // LAPL-Theorie werktags 18:00
        auto.schritte.insert(Schritt(titel: "Prüfungsfragen üben", art: .habit, seit: T.plus(tage: -70), soll: 60, habitID: habits[2].id), at: 4)
        fit.schritte.insert(Schritt(titel: "Sport 3× pro Woche, 8 Wochen", art: .habit, seit: T.plus(tage: -70), soll: 8,
                                    habitID: habits[3].id, habitModus: .wochen), at: 1)
        flug.schritte.insert(Schritt(titel: "Theorie-Routine 12 Wochen", art: .habit, seit: T.plus(tage: -70), soll: 12,
                                     habitID: habits[1].id, habitModus: .wochen), at: 2)

        var o = 0.0
        func tk(_ titel: String, _ datum: Tag?, _ ziel: UUID?, _ prio: Prioritaet, uhr: Int? = nil, dauer: Int = 60,
                erledigt: Date? = nil, fokus: TimeInterval = 0) -> Aufgabe {
            defer { o += 1 }
            return Aufgabe(titel: titel, datum: datum, uhrzeit: uhr, dauer: dauer, prio: prio, reihenfolge: o, zielID: ziel,
                           erledigt: erledigt != nil, erledigtAm: erledigt, fokusSekunden: fokus)
        }
        let d1 = T.plus(tage: 1), d2 = T.plus(tage: 2), d3 = T.plus(tage: 3)
        var aufgaben = [
            tk("Theorie-Fragebogen Kapitel 4", T, auto.id, .hoch),
            tk("Meteorologie: Kapitel Wolken", T, flug.id, .hoch, uhr: 10 * 60),
            tk("Sparplan für Dezember aufsetzen", T, geld.id, .hoch, uhr: 16 * 60, dauer: 45),
            tk("Paket zur Post bringen", T, nil, .normal, dauer: 20),
            tk("Visum-Verlängerung klären", T, nil, .normal, dauer: 30),
            tk("Morgen-Check-in", T, nil, .normal, erledigt: jetzt.addingTimeInterval(-3 * 3600), fokus: 8 * 60),
            tk("5-km-Lauf", T, fit.id, .hoch, erledigt: jetzt.addingTimeInterval(-2 * 3600), fokus: 32 * 60),
            tk("Fahrstunde vorbereiten", d1, auto.id, .hoch),
            tk("Navigation: Übungsaufgaben", d1, flug.id, .hoch, uhr: 9 * 60, dauer: 90),
            tk("Wochenplanung", d1, nil, .normal),
            tk("Business-Idee: Landingpage testen", d2, geld.id, .hoch),
            tk("Intervalltraining", d2, fit.id, .hoch),
            tk("Flugschule anrufen: Termine", d3, flug.id, .hoch),
            tk("Steuerunterlagen sortieren", T.plus(tage: -1), nil, .normal, erledigt: jetzt.addingTimeInterval(-26 * 3600)),
            tk("Geschenk für Lena besorgen", nil, nil, .normal),
            tk("Depot-Anbieter vergleichen", nil, geld.id, .hoch),
        ]

        let ziele = [auto, flug, geld, fit]
        var sitzungen: [FokusSitzung] = []
        for i in 1...56 {
            let d = T.plus(tage: -i)
            for (gi, g) in ziele.enumerated() {
                let basis = [0.7, 1.1, 0.6, 0.8][gi]
                if r.zahl() < 0.72 { sitzungen.append(FokusSitzung(zielID: g.id, tag: d, sekunden: (basis * (0.4 + r.zahl() * 1.4) * 3600).rounded())) }
            }
            if r.zahl() < 0.8 { sitzungen.append(FokusSitzung(tag: d, sekunden: ((0.3 + r.zahl()) * 3600).rounded())) }
        }
        sitzungen.append(FokusSitzung(zielID: fit.id, tag: T, sekunden: 32 * 60))
        sitzungen.append(FokusSitzung(tag: T, sekunden: 8 * 60))

        // Aufgaben und Sitzungen fallen in den Zeit-Schritt ihres Ziels (wie im Klick-Dummy)
        func zeitSchritt(_ id: UUID?) -> UUID? { ziele.first { $0.id == id }?.schritte.first { $0.art == .zeit }?.id }
        for i in aufgaben.indices { aufgaben[i].schrittID = zeitSchritt(aufgaben[i].zielID) }
        for i in sitzungen.indices { sitzungen[i].schrittID = zeitSchritt(sitzungen[i].zielID) }

        aufgaben[3].kategorie = .freizeit
        aufgaben[4].kategorie = .arbeit
        aufgaben[9].kategorie = .arbeit
        var z = Zustand(ziele: ziele, habits: habits, aufgaben: aufgaben, sitzungen: sitzungen)
        // Eigene Termine: Vorlesung (Studium), Gym erfüllt den Habit Sport und zählt als Einsatz für „Fit“
        z.terminSpeichern(EigenerTermin(titel: "Vorlesung BWL", tag: T.montag.plus(tage: -14), start: 11 * 60 + 30, ende: 13 * 60,
                                        kategorie: .studium, wiederholung: .woechentlich))
        z.terminSpeichern(EigenerTermin(titel: "Gym", tag: T.montag.plus(tage: -14).plus(tage: 4), start: 18 * 60, ende: 19 * 60,
                                        kategorie: .gesundheit, zielID: fit.id, habitID: habits[3].id, wiederholung: .woechentlich, habitBis: T.plus(tage: -1)))
        z.terminSpeichern(EigenerTermin(titel: "Abendessen mit Mia", tag: T.plus(tage: 2), start: 19 * 60, ende: 21 * 60, kategorie: .freizeit))
        z.lernen.zeitVerhaeltnisse = [1.2, 1.35]
        z.einstellungen.googleBeispiel = true
        z.einstellungen.appleBeispiel = true
        // Termine: jede Fahrstunde zählt in „Fahrstunden“, der Schnupperflug als Einsatz für LAPL
        let fahrstunden = auto.schritte.first { $0.titel == "Fahrstunden" }?.id
        z.terminVerknuepfen(serie: "google:fahr", titel: "Fahrstunde (Do)", ziel: auto.id, schritt: fahrstunden, seit: T.plus(tage: -21))
        z.terminVerknuepfen(serie: "google:fahr2", titel: "Fahrstunde (Di)", ziel: auto.id, schritt: fahrstunden, seit: T.plus(tage: -21))
        z.terminVerknuepfen(serie: "google:flug", titel: "Schnupperflug", ziel: flug.id, schritt: nil, seit: T.plus(tage: -30))
        z.termineAbgleichen(heute: T) { Beispieltermine.termine(am: $0, google: true, apple: true, heute: T) }
        // Demo-Verlauf: wöchentliche Stände von der Anlage bis heute (damit „Auf Kurs“ und Prognose etwas zeigen)
        for g in ziele {
            let jetztP = Fortschritt.ziel(g, in: z, heute: T)
            let n = max(1, g.angelegt.tage(bis: T) / 7)
            z.verlauf[g.id] = (0...n).map { i in
                VerlaufPunkt(tag: g.angelegt.plus(tage: i * 7), wert: ((jetztP * pow(Double(i) / Double(n), 1.15)) * 10_000).rounded() / 10_000)
            }
        }
        return z
    }
}
