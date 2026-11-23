import Foundation
import Testing
@testable import Kompass

// Personen-Test (Aufgabe s-personentest, Struktur v3): sechs Personen benutzen die App 3,5 Jahre lang Tag für Tag –
// unterschiedlich geschickt. Nach jedem Tag prüfen unabhängige Nachrechnungen und Invarianten, ob alle Zahlen stimmen.
// Deterministisch (fester Zufall); Bericht: docs/technik/berichte/personen-test-struktur-v3-2026-11-23.md

/// Fester Zufall (SplitMix64), damit jeder Lauf gleich ist.
struct Wuerfel {
    var s: UInt64
    mutating func zahl() -> Double {
        s &+= 0x9E3779B97F4A7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return Double((z ^ (z >> 31)) >> 11) / Double(1 << 53)
    }
    mutating func ja(_ p: Double) -> Bool { zahl() < p }
    mutating func bis(_ n: Int) -> Int { min(n - 1, Int(zahl() * Double(n))) }
    mutating func eins<T>(_ a: [T]) -> T? { a.isEmpty ? nil : a[bis(a.count)] }
}

/// Wie eine Person die App benutzt.
struct Person: Sendable, CustomStringConvertible {
    var name: String
    /// 0 = probiert alles falsch, 1 = nutzt alles wie gedacht
    var geschick: Double
    /// Anteil der Tage, an denen die App geöffnet wird
    var aktiv: Double
    var aufgabenProTag: Int
    var habits: Int
    var termineProWoche: Int
    var ziele: Int
    var nutztZiehen: Bool
    var nutztTimer: Bool
    var chaos: Double
    var description: String { name }

    static let alle: [Person] = [
        Person(name: "Lena · Studentin, strukturiert", geschick: 0.9, aktiv: 0.92, aufgabenProTag: 3, habits: 3, termineProWoche: 4, ziele: 3, nutztZiehen: true, nutztTimer: true, chaos: 0.02),
        Person(name: "Tom · Azubi, chaotisch", geschick: 0.35, aktiv: 0.7, aufgabenProTag: 2, habits: 2, termineProWoche: 2, ziele: 2, nutztZiehen: true, nutztTimer: true, chaos: 0.35),
        Person(name: "Erika · Rentnerin, wenig Technik", geschick: 0.3, aktiv: 0.35, aufgabenProTag: 1, habits: 1, termineProWoche: 1, ziele: 1, nutztZiehen: false, nutztTimer: false, chaos: 0.05),
        Person(name: "Jonas · Gewohnheitstier", geschick: 0.75, aktiv: 0.97, aufgabenProTag: 1, habits: 6, termineProWoche: 1, ziele: 2, nutztZiehen: true, nutztTimer: false, chaos: 0.05),
        Person(name: "Mia · Planerin mit vollem Kalender", geschick: 0.8, aktiv: 0.9, aufgabenProTag: 4, habits: 2, termineProWoche: 14, ziele: 2, nutztZiehen: true, nutztTimer: true, chaos: 0.08),
        Person(name: "Ahmet · Gründer, nutzt alles", geschick: 0.97, aktiv: 0.95, aufgabenProTag: 5, habits: 4, termineProWoche: 8, ziele: 4, nutztZiehen: true, nutztTimer: true, chaos: 0.12),
    ]
}

@MainActor
@Suite("Personen-Test · 6 Personen × 3,5 Jahre", .serialized)
struct PersonenTests {
    static let start = Tag(2026, 11, 23)
    static let tage = 3 * 365 + 182

    @Test(arguments: Person.alle)
    func person(_ p: Person) throws {
        var saat: UInt64 = 7
        for c in p.name.unicodeScalars { saat = saat &* 31 &+ UInt64(c.value) }
        var w = Wuerfel(s: saat)
        var z = Zustand()
        let k = Calendar.kompass
        var befunde: [String] = []
        func pruefe(_ ok: Bool, _ text: @autoclosure () -> String) { if !ok && befunde.count < 25 { befunde.append(text()) } }

        // Start: Ziele mit Meilensteinen, Habits
        for g in 0..<p.ziele {
            var ziel = Ziel(titel: "Ziel \(g)", farbe: Farbe.ziele[g % 10], symbol: "target", bereich: "x", faellig: Self.start.plus(tage: 120 + 200 * g), angelegt: Self.start)
            ziel.schritte = [
                Schritt(titel: "Abhaken", art: .aufgaben, gewicht: 1 + g % 3),
                Schritt(titel: "Zeit", art: .zeit, gewicht: 2, soll: Double(10 + 5 * g)),
                Schritt(titel: "Zahl", art: .zahl, gewicht: 3, soll: g % 2 == 0 ? 100 : 0, start: g % 2 == 0 ? 0 : 50, aktuell: g % 2 == 0 ? 0 : 50, schwellen: [25]),
            ]
            z.ziele.append(ziel)
        }
        let rhythmen: [Rhythmus] = [.taeglich, .wochentage([1, 3, 5]), .proWoche(3), .taeglich, .wochentage([6, 7]), .proWoche(2)]
        for i in 0..<p.habits {
            var h = Habit(titel: "Habit \(i)", farbe: Farbe.ziele[(i + 3) % 10], symbol: "star", rhythmus: rhythmen[i % 6],
                          menge: i % 2 == 0 ? Double(10 + 10 * i) : nil, einheit: i % 2 == 0 ? .minuten : nil, zielID: z.ziele.first?.id, angelegt: Self.start)
            if w.ja(p.geschick) { h.uhrzeit = [7, 12, 18, 21][i % 4] * 60 }
            if i == 0, let g = z.ziele.first { z.habits.append(h); z.habitVerknuepfen(h.id, ziel: g.id, alsMeilenstein: .anzahl, soll: 60, heute: Self.start); continue }
            if i == 1, let g = z.ziele.last { z.habits.append(h); z.habitVerknuepfen(h.id, ziel: g.id, alsMeilenstein: .wochen, soll: 12, heute: Self.start); continue }
            z.habits.append(h)
        }
        // Wiederkehrende Termine (eigene)
        for i in 0..<min(p.termineProWoche, 6) {
            let wd = i % 7
            let s = (8 + (i * 3) % 12) * 60
            var t = EigenerTermin(titel: "Termin \(i)", tag: Self.start.plus(tage: wd), start: s, ende: s + [30, 60, 90, 120][i % 4],
                                  kategorie: Kategorie.allCases[i % 6], wiederholung: [.woechentlich, .werktags, .taeglich, .monatlich][i % 4])
            if i == 0, let g = z.ziele.first, let zs = g.schritte.first(where: { $0.art == .zeit }) { t.zielID = g.id; t.schrittID = zs.id }
            if i == 1, let h = z.habits.first { t.habitID = h.id }
            z.terminSpeichern(t)
        }

        var tag = Self.start
        for n in 0..<Self.tage {
            tag = Self.start.plus(tage: n)
            let jetztMin = 6 * 60 + w.bis(17 * 60)
            let jetzt = tag.datum(kalender: k).addingTimeInterval(TimeInterval(jetztMin * 60))
            let quelle: (Tag) -> [Termin] = { [z] d in Kalenderquelle.termine(am: d, zustand: z, heute: tag) }

            if w.ja(p.aktiv) {
                // Aufgaben anlegen (manche mit Uhrzeit, Ziel, Wiederholung)
                for _ in 0..<p.aufgabenProTag where w.ja(0.6) {
                    let datum: Tag? = w.ja(0.15) ? nil : tag.plus(tage: w.bis(4))
                    let titel = w.ja(p.chaos) ? "" : "Aufgabe \(n)"
                    let prio: Prioritaet = w.ja(0.3) ? .hoch : .normal
                    let zid: UUID? = w.ja(0.5) ? w.eins(z.ziele)?.id : nil
                    let a = z.aufgabeAnlegen(titel, datum: datum, prio: prio, zielID: zid, heute: tag)
                    if let i = z.aufgaben.firstIndex(where: { $0.id == a.id }) {
                        if w.ja(p.geschick * 0.5) { z.aufgaben[i].uhrzeit = (7 + w.bis(14)) * 60 + [0, 15, 30, 45][w.bis(4)]; z.aufgaben[i].dauer = [15, 30, 60, 90][w.bis(4)] }
                        if w.ja(0.05) { z.aufgaben[i].wiederholung = Wiederholung.allCases[1 + w.bis(4)] }
                        if w.ja(0.3) { z.aufgaben[i].kategorie = w.eins(Kategorie.allCases) }
                        if w.ja(p.chaos * 0.2) { z.aufgaben[i].dauer = [0, -10, 2000][w.bis(3)] } // Unsinn
                    }
                }
                // Abarbeiten
                let heuteOffen = z.aufgaben.filter { $0.datum == tag && !$0.erledigt }
                for a in heuteOffen where w.ja(p.geschick * 0.8) {
                    if p.nutztTimer && w.ja(0.3) {
                        z.timerStarten(a.id, jetzt: jetzt)
                        z.timerStoppen(jetzt: jetzt.addingTimeInterval(TimeInterval(60 * (5 + w.bis(120)))))
                    }
                    z.erledigen(a.id, jetzt: jetzt)
                }
                if w.ja(p.chaos) { if let a = w.eins(z.aufgaben) { z.umschalten(a.id, jetzt: jetzt) } }
                if w.ja(p.chaos * 0.5) { if let a = w.eins(z.aufgaben) { z.loeschen(a.id, serieBeenden: w.ja(0.5), heute: tag) } }
                // Ziehen: Offenes ohne Uhrzeit in eine Lücke, Eingang auf heute
                if p.nutztZiehen && w.ja(0.4) {
                    if let a = z.aufgaben.first(where: { $0.datum == nil && !$0.erledigt }) { z.aufgabeEinplanen(a.id, tag: tag, uhrzeit: w.ja(0.5) ? (8 + w.bis(12)) * 60 : nil) }
                    if let h = w.eins(Tagesplan.ohneZeit(am: tag, zustand: z).habits) { z.habitEinplanen(h.id, tag: tag, uhrzeit: (7 + w.bis(15)) * 60) }
                    if w.ja(p.chaos) { if let h = w.eins(z.habits) { z.habitEinplanen(h.id, tag: tag, uhrzeit: [-50, 3000, 0][w.bis(3)]) } }
                }
                // Habits: abhaken oder Teilmenge
                for h in z.habits where HabitRechnung.geplant(h, am: tag) && w.ja(p.geschick) {
                    if let m = h.menge, w.ja(0.4) { z.habitEintragen(h.id, menge: (m * (0.2 + w.zahl() * 1.2)).rounded(), am: tag) }
                    else { z.habitUmschalten(h.id, am: tag) }
                    if w.ja(p.chaos * 0.3) { z.habitEintragen(h.id, menge: [-5, 0, 1e9][w.bis(3)], am: tag) }
                }
                // Zahl-Meilensteine
                for g in z.ziele where w.ja(0.05) {
                    if let s = g.schritte.first(where: { $0.art == .zahl }) {
                        let unsinn: [Double] = [-1e6, .nan, 1e12]
                        let richtung: Double = (s.soll ?? 0) > (s.start ?? 0) ? 1 : -1
                        let normal: Double = (s.aktuell ?? 0) + richtung * Double(w.bis(6))
                        let wert: Double = w.ja(p.chaos) ? unsinn[w.bis(3)] : normal
                        z.zahlEintragen(wert, ziel: g.id, schritt: s.id, heute: tag)
                    }
                }
                // Abhaken-Meilenstein manchmal
                if w.ja(0.01), let g = w.eins(z.ziele), let s = g.schritte.first(where: { $0.art == .aufgaben }) { z.schrittUmschalten(ziel: g.id, schritt: s.id, heute: tag) }
                // Termine anlegen (einmalig), auch sich überschneidend
                for _ in 0..<p.termineProWoche where w.ja(1.0 / 7.0) {
                    let s = (7 + w.bis(14)) * 60
                    var t = EigenerTermin(titel: "Einmal \(n)", tag: tag.plus(tage: w.bis(10)), start: s, ende: s + [30, 60, 120][w.bis(3)])
                    if w.ja(p.chaos * 0.3) { t.ende = t.start - 30 } // verkehrt herum
                    if w.ja(0.2) { t.zielID = w.eins(z.ziele)?.id }
                    z.terminSpeichern(t)
                }
                if w.ja(p.chaos * 0.2), let t = w.eins(z.eigeneTermine) { z.terminLoeschen(t.id) }
                // Selten: Ziel löschen und neu anlegen, Habit löschen, Farbe nach Kategorie umschalten
                if w.ja(p.chaos * 0.01), let g = w.eins(z.ziele) { z.zielLoeschen(g.id) }
                if w.ja(p.chaos * 0.01), let h = w.eins(z.habits) { z.habitLoeschen(h.id) }
                if w.ja(0.003) { z.einstellungen.farbenNachKategorie.toggle() }
                if w.ja(0.002), let g = w.eins(z.ziele.filter { $0.status == .aktiv }), let i = z.ziele.firstIndex(where: { $0.id == g.id }) { z.ziele[i].status = .erreicht }
            }

            // Wie im Speicher nach jeder Änderung
            let kopie = z
            z.termineAbgleichen(heute: tag) { d in Kalenderquelle.termine(am: d, zustand: kopie, heute: tag) }
            z.habitsAusTerminen(heute: tag, jetzt: jetztMin)
            z.verlaufFortschreiben(heute: tag)

            // ---------- Prüfungen ----------
            for g in z.ziele {
                let f = Fortschritt.ziel(g, in: z, heute: tag)
                pruefe(f.isFinite && f >= 0 && f <= 1, "\(tag) Ziel \(g.titel): Fortschritt \(f)")
                if g.status == .erreicht { pruefe(f == 1, "\(tag) erreichtes Ziel nicht 100 %") }
                else if !g.schritte.isEmpty {
                    // unabhängig: Gewichte 1/2/3, sonst 1
                    var sw = 0.0, s = 0.0
                    for x in g.schritte {
                        let gw = Double([1, 2, 3].contains(x.gewicht) ? x.gewicht : 1)
                        let a = Fortschritt.stand(x, in: z, heute: tag).anteil
                        pruefe(a.isFinite && a >= 0 && a <= 1, "\(tag) Meilenstein \(x.titel): Anteil \(a)")
                        sw += gw; s += gw * a
                    }
                    pruefe(abs(f - s / sw) < 1e-9, "\(tag) Ziel \(g.titel): \(f) ≠ \(s / sw)")
                }
                for v in z.verlauf[g.id] ?? [] { pruefe(v.wert >= 0 && v.wert <= 1 && v.wert.isFinite, "\(tag) Verlauf außerhalb 0–1") }
            }
            for h in z.habits {
                let q = HabitRechnung.quote(h, heute: tag)
                pruefe(q.isFinite && q >= 0 && q <= 1, "\(tag) Habit \(h.titel): Quote \(q)")
                let serie = HabitRechnung.serie(h, heute: tag)
                pruefe(serie >= 0 && serie <= h.angelegt.tage(bis: tag) + 1, "\(tag) Habit \(h.titel): Serie \(serie)")
                if case .proWoche = h.rhythmus {} else {
                    var r = 0, d = h.voll(am: tag) ? tag : tag.plus(tage: -1)
                    while d >= h.angelegt { if HabitRechnung.geplant(h, am: d) { if h.anteil(am: d) >= 1 { r += 1 } else { break } }; d = d.plus(tage: -1) }
                    pruefe(r == serie, "\(tag) Habit \(h.titel): Serie \(serie), nachgerechnet \(r)")
                }
                pruefe(h.anteil(am: tag) >= 0 && h.anteil(am: tag) <= 1, "\(tag) Habit-Anteil außerhalb 0–1")
                pruefe(h.dauerMinuten > 0, "\(tag) Habit-Dauer ≤ 0")
            }
            // Tagesplan: verplante Minuten unabhängig über ein Minutenraster
            let b = Tagesplan.bloecke(am: tag, zustand: z, termine: quelle(tag))
            var raster = [Bool](repeating: false, count: Tagesplan.wachBis - Tagesplan.wachVon)
            for x in b where !x.erledigt {
                pruefe(x.ende > x.start, "\(tag) Block \(x.titel) endet vor dem Start (\(x.start)–\(x.ende))")
                for m in max(x.start, Tagesplan.wachVon)..<max(max(x.start, Tagesplan.wachVon), min(x.ende, Tagesplan.wachBis)) { raster[m - Tagesplan.wachVon] = true }
            }
            let a = Tagesplan.auslastung(b)
            let rVerplant = raster.reduce(0) { $0 + ($1 ? 1 : 0) }
            pruefe(a.verplant == rVerplant, "\(tag) verplant \(a.verplant) ≠ Raster \(rVerplant)")
            pruefe(a.frei == raster.count - rVerplant && a.frei >= 0, "\(tag) frei falsch")
            let engErwartet: Bool = Double(rVerplant) >= 675 || raster.count - rVerplant < 90
            pruefe(a.eng == engErwartet, "\(tag) enger Tag falsch")
            let nx = Tagesplan.naechste(zustand: z, heute: tag, jetzt: jetztMin, termine: quelle)
            pruefe(nx.count <= 3, "\(tag) mehr als 3 als nächstes")
            let sortiert = zip(nx, nx.dropFirst()).allSatisfy { (x: Tagesplan.Block, y: Tagesplan.Block) -> Bool in x.tag < y.tag || (x.tag == y.tag && x.start <= y.start) }
            pruefe(sortiert, "\(tag) Als Nächstes unsortiert")
            pruefe(nx.allSatisfy { !$0.erledigt && ($0.tag > tag || $0.ende > jetztMin) }, "\(tag) Als Nächstes enthält Vergangenes/Erledigtes")
            let erwartetErster = b.filter { !$0.erledigt && $0.ende > jetztMin }.first
            if let e = erwartetErster { pruefe(nx.first?.id == e.id, "\(tag) Als Nächstes beginnt nicht mit \(e.titel)") }
            if n % 7 == 0 {
                let hw = Tagesplan.hinweise(zustand: z, heute: tag, jetzt: jetztMin, termine: quelle)
                pruefe(Set(hw.map(\.id)).count == hw.count, "\(tag) doppelte Hinweise")
                let offen = b.filter { !$0.erledigt && $0.ende > jetztMin }
                var ueber = false
                for i in 0..<offen.count { for j in (i + 1)..<offen.count where min(offen[i].ende, offen[j].ende) - max(offen[i].start, offen[j].start) >= 5 { ueber = true } }
                pruefe(ueber == hw.contains { $0.art == .ueberschneidung && $0.tag == tag }, "\(tag) Überschneidung \(ueber) nicht als Hinweis")
                let bil = Tagesplan.woche(zustand: z, montag: tag.montag, heute: tag, termine: quelle)
                pruefe(bil.quote >= 0 && bil.quote <= 1 && bil.quote.isFinite, "\(tag) Wochenbilanz \(bil.quote)")
                let er = ErinnerungRechnung.termine(habits: z.habits.map { var h = $0; h.erinnerung = h.uhrzeit; return h }, heute: tag, jetztMinuten: jetztMin)
                pruefe(er.count <= ErinnerungRechnung.hoechstens && er.allSatisfy { $0.tag > tag || $0.minuten > jetztMin }, "\(tag) Erinnerungen falsch")
            }
            // Wiederholungen: je Serie höchstens eine offene Zukunfts-Kopie
            let serien = Dictionary(grouping: z.aufgaben.filter { $0.serie != nil && !$0.erledigt && ($0.datum ?? tag) > tag }, by: { $0.serie! })
            pruefe(serien.values.allSatisfy { $0.count <= 1 }, "\(tag) Serie mit mehreren offenen Kopien")
            // Speichern/Lesen ohne Verlust (alle 90 Tage)
            if n % 90 == 0 {
                let wieder = try JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(z))
                pruefe(wieder == z, "\(tag) Speichern/Lesen verändert den Zustand")
            }
            // Lotse antwortet (alle 30 Tage), rechnet nicht selbst
            if n % 30 == 0 {
                for name in [Werkzeug.Name.heute, .naechstes, .tagesplan, .woche, .freieZeit, .ziele, .habits, .analyse, .empfehlen] {
                    let x = Werkzeuge.ausfuehren(WerkzeugAufruf(name: name), z: z, heute: tag, jetzt: jetzt, kalender: k)
                    pruefe(!x.text.isEmpty && !x.text.contains("nan") && !x.text.contains("inf"), "\(tag) Lotse \(name): „\(x.text.prefix(60))“")
                }
            }
            if befunde.count >= 25 { break }
        }
        #expect(befunde.isEmpty, Comment(rawValue: "\(p.name): \(befunde.count) Befunde\n" + befunde.joined(separator: "\n")))
        #expect(tag >= Self.start.plus(tage: Self.tage - 1) || !befunde.isEmpty)
    }
}
