import Testing
@testable import Kompass

/// Tage eines Habits: Text rechts und Umschalten.
struct WochentageTests {
    @Test func texte() {
        #expect(Wochentage.text(Set(1...7)) == "Täglich")
        #expect(Wochentage.text([1, 2, 3, 4, 5]) == "Werktags")
        #expect(Wochentage.text([6, 7]) == "Wochenende")
        #expect(Wochentage.text([1]) == "Nur Montag")
        #expect(Wochentage.text([7]) == "Nur Sonntag")
        #expect(Wochentage.text([5, 1, 3]) == "Mo, Mi, Fr")
        #expect(Wochentage.text([1, 2, 3, 4, 5, 6]) == "Mo, Di, Mi, Do, Fr, Sa")
        #expect(Wochentage.text([]) == "Keine Tage")
    }

    @Test func letzterTagBleibtAn() {
        var tage: Set<Int> = [3]
        #expect(Wochentage.umschalten(3, in: &tage) == false)
        #expect(tage == [3])
    }

    @Test func umschaltenFuegtHinzuUndEntfernt() {
        var tage: Set<Int> = [6, 7]
        #expect(Wochentage.umschalten(1, in: &tage))
        #expect(tage == [1, 6, 7])
        #expect(Wochentage.umschalten(6, in: &tage))
        #expect(tage == [1, 7])
        #expect(Wochentage.umschalten(9, in: &tage) == false)
    }
}
