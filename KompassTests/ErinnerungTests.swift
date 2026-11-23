import Foundation
import Testing
@testable import Kompass

// Habit-Erinnerungen: welche Mitteilungen geplant werden (habits-v2.md §8).

@Suite("Habits v2 · Erinnerungen")
struct ErinnerungTests {
    let heute = Tag(2027, 5, 5) // Mittwoch

    @Test func taeglichNurOffeneTageUndHeuteNurVorDerUhrzeit() {
        var h = Habit(titel: "Lesen", farbe: "#000000", symbol: "x", menge: 20, einheit: .minuten, erinnerung: 21 * 60, angelegt: heute.plus(tage: -3))
        h.eintragen(20, am: heute.plus(tage: 2)) // vorab voll → kein Termin
        let t = ErinnerungRechnung.termine(habits: [h], heute: heute, jetztMinuten: 10 * 60)
        #expect(t.count == 6 && t.first?.tag == heute && t.first?.minuten == 21 * 60)
        #expect(!t.contains { $0.tag == heute.plus(tage: 2) })
        // Uhrzeit heute schon vorbei → erst ab morgen
        let spaeter = ErinnerungRechnung.termine(habits: [h], heute: heute, jetztMinuten: 21 * 60)
        #expect(spaeter.count == 5 && spaeter.first?.tag == heute.plus(tage: 1))
        #expect(t.first?.id == "habit-\(h.id.uuidString)-2027-05-05")
        #expect(ErinnerungRechnung.text(h) == "Heute noch offen: 20 min.")
    }

    @Test func wochentageUndProWoche() {
        let w = Habit(titel: "Lernen", farbe: "#000000", symbol: "x", rhythmus: .wochentage([1, 2, 3, 4, 5]), erinnerung: 18 * 60, angelegt: Tag(2027, 4, 1))
        let tw = ErinnerungRechnung.termine(habits: [w], heute: heute, jetztMinuten: 0)
        #expect(tw.map(\.tag) == [Tag(2027, 5, 5), Tag(2027, 5, 6), Tag(2027, 5, 7), Tag(2027, 5, 10), Tag(2027, 5, 11)])
        #expect(ErinnerungRechnung.text(w) == "Heute noch offen.")
        // 3× pro Woche, zwei schon geschafft → nur noch, bis die Woche voll ist; nächste Woche wieder alle Tage
        var p = Habit(titel: "Sport", farbe: "#000000", symbol: "x", rhythmus: .proWoche(3), menge: 45, einheit: .minuten, erinnerung: 7 * 60, angelegt: Tag(2027, 4, 1))
        p.eintragen(45, am: Tag(2027, 5, 3)); p.eintragen(45, am: Tag(2027, 5, 4))
        let tp = ErinnerungRechnung.termine(habits: [p], heute: heute, jetztMinuten: 0)
        #expect(tp.map(\.tag) == [Tag(2027, 5, 5), Tag(2027, 5, 6), Tag(2027, 5, 7), Tag(2027, 5, 8), Tag(2027, 5, 9), Tag(2027, 5, 10), Tag(2027, 5, 11)])
    }

    @Test func ohneErinnerungNichtsUndObergrenze() {
        let ohne = Habit(titel: "x", farbe: "#000000", symbol: "x", angelegt: heute)
        #expect(ErinnerungRechnung.termine(habits: [ohne], heute: heute, jetztMinuten: 0).isEmpty)
        let viele = (0..<12).map { Habit(titel: "h\($0)", farbe: "#000000", symbol: "x", erinnerung: 8 * 60 + $0, angelegt: heute) }
        let t = ErinnerungRechnung.termine(habits: viele, heute: heute, jetztMinuten: 0)
        #expect(t.count == ErinnerungRechnung.hoechstens)
        #expect(t.first?.tag == heute && t.last?.tag == heute.plus(tage: 4)) // nach Tag, dann Uhrzeit sortiert
    }
}
