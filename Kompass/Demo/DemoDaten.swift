import Foundation

// Demo-Daten wie im Klick-Dummy (`seed()` in prototyp/index.html). Nur erfundene Beispiele – keine echten Daten.
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
            Schritt(titel: "Fahrstunden", art: .zahl, gewicht: 3, soll: 30, start: 0, aktuell: 6, einheit: "Std."),
            Schritt(titel: "Praktische Prüfung", gewicht: 2),
        ]
        var flug = Ziel(titel: "LAPL(A) bestehen", farbe: "#3B4CCA", symbol: "airplane", bereich: "Fliegen",
                        faellig: Tag(Y + 5, 9, 30), warum: "Selbst fliegen können", angelegt: T.plus(monate: -10))
        flug.schritte = [
            s("Tauglichkeitszeugnis", true),
            Schritt(titel: "Theorie: 9 Fächer lernen", art: .zeit, gewicht: 3, soll: 120),
            Schritt(titel: "Theorieprüfung", gewicht: 2),
            Schritt(titel: "Flugstunden", art: .zahl, gewicht: 3, soll: 45, start: 0, aktuell: 0, einheit: "Std."),
            Schritt(titel: "Erster Alleinflug"),
            Schritt(titel: "Praktische Prüfung", gewicht: 2),
        ]
        var geld = Ziel(titel: "Millionär werden", farbe: "#9A6700", symbol: "eurosign.circle.fill", bereich: "Finanzen",
                        faellig: Tag(Y + 6, 12, 31), warum: "Finanzielle Freiheit", angelegt: T.plus(monate: -12))
        geld.zahl = ZahlMessung(start: 0, aktuell: 18_500, ziel: 1_000_000, einheit: "€",
                                verlauf: (0...12).map { i in VerlaufPunkt(tag: T.plus(monate: i - 12), wert: i == 12 ? 18_500 : (6000 + Double(i) * 1000 + sin(Double(i) * 1.7) * 900).rounded()) })
        geld.schritte = [s("Notgroschen 10.000 €", true), s("Erstes Business mit Umsatz"), s("100.000 € Vermögen"), s("500.000 € Vermögen")]
        var fit = Ziel(titel: "Fit: 75 kg & Halbmarathon", farbe: "#15803D", symbol: "figure.run", bereich: "Gesundheit",
                       faellig: Tag(Y + 1, 6, 30), warum: "Energie für alles andere", angelegt: T.plus(monate: -6))
        fit.zahl = ZahlMessung(start: 86, aktuell: 81, ziel: 75, einheit: "kg",
                               verlauf: (0...12).map { i in VerlaufPunkt(tag: T.plus(tage: (i - 12) * 14), wert: i == 12 ? 81 : ((86 - Double(i) * 0.42 + sin(Double(i)) * 0.4) * 10).rounded() / 10) })
        fit.schritte = [s("3× pro Woche Sport, 2 Monate lang", true), s("10 km unter 60 min"), s("Halbmarathon laufen")]

        func hb(_ titel: String, _ farbe: String, _ symbol: String, _ tage: Set<Int>, _ ziel: UUID?, _ p: Double) -> Habit {
            var h = Habit(titel: titel, farbe: farbe, symbol: symbol, wochentage: tage, zielID: ziel, angelegt: T.plus(tage: -70))
            for i in 1...70 {
                let d = T.plus(tage: -i)
                if tage.contains(d.wochentag) && r.zahl() < p { h.erledigt.insert(d) }
            }
            return h
        }
        let alle: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        var habits = [
            hb("20 Minuten Buch lesen", "#7A4FD6", "book.fill", alle, nil, 0.78),
            hb("LAPL-Theorie lernen", "#3B4CCA", "airplane", [1, 2, 3, 4, 5], flug.id, 0.7),
            hb("Führerschein-Fragen (30 Stk.)", "#1F7AC2", "car.fill", alle, auto.id, 0.82),
            hb("Sport / Laufen", "#15803D", "figure.run", [1, 3, 5], fit.id, 0.75),
            hb("Kein Handy nach 22 Uhr", "#B8456E", "moon.fill", alle, nil, 0.55),
        ]
        habits[0].erledigt.insert(T)
        auto.schritte.insert(Schritt(titel: "Prüfungsfragen üben", art: .habit, seit: T.plus(tage: -70), soll: 60, habitID: habits[2].id), at: 4)

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
            tk("Paket zur Post bringen", T, nil, .normal),
            tk("Visum-Verlängerung klären", T, nil, .normal),
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

        var z = Zustand(ziele: ziele, habits: habits, aufgaben: aufgaben, sitzungen: sitzungen)
        z.lernen.zeitVerhaeltnisse = [1.2, 1.35]
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
