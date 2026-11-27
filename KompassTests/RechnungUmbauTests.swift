import Foundation
import Testing
@testable import Kompass

/// Umbau Block D: Rechenregeln §15–§20 (Vorschlag) – je Regel die Grenzfälle.
struct RechnungUmbauTests {
    let T = Tag(2026, 11, 27)

    // MARK: §16 Handy-Jahre
    @Test func handyJahreBeispielAusDenRechenregeln() {
        let h = Bildschirm.handyJahre(.eins3, alter: 21)!
        #expect(h.tageJeJahr == 46)       // 2 × 365 ÷ 16 = 45,6
        #expect(h.jahreBis80 == 7)        // 45,6 × 59 ÷ 365 = 7,4
        #expect(h.jahreZurueck == 2)      // 30 % von 7,4 = 2,2
    }

    @Test func handyJahreOhneSchaetzungOderAusserhalbDesAlters() {
        #expect(Bildschirm.handyJahre(.weissNicht, alter: 30) == nil)
        let h = Bildschirm.handyJahre(.ueber7, alter: 85)!
        #expect(h.tageJeJahr == 183)      // 8 × 365 ÷ 16 = 182,5 → 183
        #expect(h.jahreBis80 == nil && h.jahreZurueck == nil)
    }

    // MARK: §17 Ablenkung
    @Test func zielAusSchaetzungAuf15MinutenGerundet() {
        let b = Bildschirmzeit()
        #expect(Bildschirm.zielMinuten(b, spanne: .eins3) == 90)    // 120 × 0,7 = 84 → 90
        #expect(Bildschirm.zielMinuten(b, spanne: .unter1) == 15)   // 21 → 15
        #expect(Bildschirm.zielMinuten(b, spanne: .weissNicht) == nil)
        var eigen = Bildschirmzeit(); eigen.zielMinuten = 5
        #expect(Bildschirm.zielMinuten(eigen, spanne: .eins3) == 15)
    }

    @Test func ablenkungIstHoechsteSchwelleUndOhneUeberwachungKeineDaten() {
        var b = Bildschirmzeit()
        #expect(Bildschirm.ablenkung(b, am: T) == nil)
        Bildschirm.melden(&b, minuten: 45, am: T)
        Bildschirm.melden(&b, minuten: 30, am: T)
        #expect(Bildschirm.ablenkung(b, am: T) == 45)
        b.ueberwacht.insert(T.plus(tage: -1).text)
        #expect(Bildschirm.ablenkung(b, am: T.plus(tage: -1)) == 0)
    }

    @Test func hinweisSchwellenJeHaeufigkeit() {
        #expect(Bildschirm.hinweisSchwellen(.aus, ziel: 90).isEmpty)
        #expect(Bildschirm.hinweisSchwellen(.niedrig, ziel: 90) == [90])
        #expect(Bildschirm.hinweisSchwellen(.mittel, ziel: 90) == [45, 90])
        #expect(Bildschirm.hinweisSchwellen(.hoch, ziel: 60) == [15, 30, 45, 60])
    }

    @Test func wartezeitUndNotfallPass() {
        #expect(Bildschirm.wartezeit(.leicht, abbruecheHeute: 3) == 10)
        #expect(Bildschirm.wartezeit(.steigend, abbruecheHeute: 2) == 30)
        #expect(Bildschirm.wartezeit(.durchziehen, abbruecheHeute: 0) == nil)
        var b = Bildschirmzeit()
        #expect(Bildschirm.notfallPassFrei(b, heute: T))
        b.notfallPass = Calendar.kompass.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 12))
        #expect(!Bildschirm.notfallPassFrei(b, heute: T))                 // gleiche Woche (Di → Fr)
        #expect(Bildschirm.notfallPassFrei(b, heute: Tag(2026, 11, 30)))  // nächster Montag
    }

    @Test func ablenkungsWertLinearZwischenZielUndDoppeltemZiel() {
        #expect(Bildschirm.ablenkungsWert(minuten: 60, ziel: 90) == 1)
        #expect(Bildschirm.ablenkungsWert(minuten: 135, ziel: 90) == 0.5)
        #expect(Bildschirm.ablenkungsWert(minuten: 200, ziel: 90) == 0)
    }

    // MARK: §18 Serie und Meilensteine
    private func leer() -> Zustand { Zustand() }

    @Test func serieZaehltFokusHabitsJournalUndUeberspringtUrlaub() {
        var z = leer()
        z.sitzungen = [FokusSitzung(tag: T.plus(tage: -1), sekunden: 600), FokusSitzung(tag: T.plus(tage: -2), sekunden: 599)]
        #expect(KompassSerie.laenge(z, heute: T) == 1)          // heute offen, gestern ja, vorgestern < 10 Min
        z.journal[T.plus(tage: -2).text] = JournalEintrag(stimmung: 3)
        #expect(KompassSerie.laenge(z, heute: T) == 2)
        z.urlaub = [Urlaub(von: T.plus(tage: -4).text, bis: T.plus(tage: -3).text)]
        z.journal[T.plus(tage: -5).text] = JournalEintrag(satz: "Gut.")
        #expect(KompassSerie.laenge(z, heute: T) == 3)          // Urlaub bricht nicht und zählt nicht
        z.journal[T.text] = JournalEintrag(stimmung: 4)
        #expect(KompassSerie.laenge(z, heute: T) == 4)          // heute zählt, sobald erfüllt
    }

    @Test func habitTagZaehltNurWennAlleGeplantenErledigt() {
        var z = leer()
        var a = Habit(titel: "Lesen", farbe: "#1F7AC2", symbol: "book", wochentage: [1, 2, 3, 4, 5, 6, 7], angelegt: T.plus(tage: -10))
        let b = Habit(titel: "Sport", farbe: "#15803D", symbol: "figure.run", wochentage: [1, 2, 3, 4, 5, 6, 7], angelegt: T.plus(tage: -10))
        a.eintraege[T.plus(tage: -1)] = 1
        z.habits = [a, b]
        #expect(!KompassSerie.zaehlt(z, am: T.plus(tage: -1)))
        z.habits[1].eintraege[T.plus(tage: -1)] = 1
        #expect(KompassSerie.zaehlt(z, am: T.plus(tage: -1)))
    }

    @Test func meilensteineBleibenErreicht() {
        var z = leer()
        z.sitzungen = [FokusSitzung(tag: T, sekunden: 10 * 3600)]
        let neu = KompassSerie.merken(&z, heute: T, jetzt: Date(timeIntervalSince1970: 0))
        #expect(neu == ["fokus-10"])
        z.sitzungen = []
        #expect(KompassSerie.meilensteine(z, heute: T).first { $0.id == "fokus-10" }?.erreicht == true)
        #expect(KompassSerie.meilensteine(z, heute: T).first { $0.id == "serie-7" }?.erreicht == false)
    }

    // MARK: §19 Tageswert
    @Test func tageswertMitAllenTeilen() {
        let t = Tageswert.Teile(habits: 1, fokus: 0.5, ablenkung: 0, journal: 1)
        #expect(Tageswert.wert(t) == 63)   // 40 + 12,5 + 0 + 10 = 62,5 → 63
    }

    @Test func tageswertRechnetFehlendeTeileHoch() {
        let t = Tageswert.Teile(habits: nil, fokus: 1, ablenkung: nil, journal: 0)
        #expect(Tageswert.wert(t) == 71)   // 25 ÷ 35 = 71,4
        #expect(Tageswert.wert(Tageswert.Teile(habits: nil, fokus: 0, ablenkung: nil, journal: 0)) == 0)
    }

    @Test func fokusZielJeLebenslage() {
        var p = Profil(); p.lebenslage = .studium
        #expect(Tageswert.fokusZiel(p) == 90)
        p.lebenslage = .job
        #expect(Tageswert.fokusZiel(p) == 60)
        p.lebenslage = nil
        #expect(Tageswert.fokusZiel(p) == 45)
    }

    // MARK: §15 Muster
    @Test func musterAblenkungUndStimmungMitGrenzen() {
        var z = leer()
        z.profil.spanne = .eins3                                   // Ziel 90 Min
        for i in 1...14 {
            let tag = T.plus(tage: -i)
            Bildschirm.melden(&z.bildschirmzeit, minuten: i <= 7 ? 150 : 60, am: tag)
            z.journal[tag.text] = JournalEintrag(stimmung: i <= 7 ? 2 : 4)
        }
        let b = Muster.befunde(z, heute: T)
        #expect(b.first?.id == "ablenkung-stimmung")
        #expect(b.first?.text == "An Tagen über deinem Handy-Ziel: Stimmung 2,0 statt 4,0")
        #expect(Muster.befunde(z, heute: T, stumm: ["ablenkung-stimmung"]).isEmpty)
        // nur 13 Tage → kein Muster
        z.journal[T.plus(tage: -14).text] = nil
        #expect(Muster.befunde(z, heute: T).isEmpty)
    }

    @Test func musterBrauchtMindestensEinenHalbenPunkt() {
        #expect(Muster.vergleich([3, 3, 3, 3, 3, 3, 3], [3.4, 3.4, 3.4, 3.4, 3.4, 3.4, 3.4], schwelle: 0.5, faktor: 20) == nil)
        #expect(Muster.vergleich([4, 4, 4, 4], [3, 3, 3, 3, 3, 3, 3, 3, 3, 3], schwelle: 0.5, faktor: 20) == nil)  // Gruppe < 5
        #expect(Muster.vergleich([4, 4, 4, 4, 4, 4, 4], [3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5], schwelle: 0.5, faktor: 20)?.staerke == 10)
    }

    // MARK: §20 Onboarding-Vorschläge
    @Test func vorschlaegeFolgenDenAntwortenHoechstensVier() {
        var p = Profil()
        p.lebenslage = .job
        p.verbessern = [.schlafen, .wenigerHandy, .ziele, .ruhe, .anderes]
        let v = OnboardingVorschlag.vorschlaege(p)
        #expect(v.map(\.id) == ["handy-weg", "handyfreier-morgen", "ziel-fokus", "atmen"])
        #expect(v[2].start == 18 * 60)
        #expect(v[0].grund == "Weil du „Besser schlafen“ gewählt hast")
        #expect(OnboardingVorschlag.vorschlaege(Profil()).map(\.id) == ["lesen"])
    }
}
