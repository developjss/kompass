import Foundation
import Testing
@testable import Kompass

// Analyse im Rückblick: nur Formulierung der Prognose (§5) – gerechnet wird in Kurs.prognose.

@Suite("Analyse · Texte")
struct AnalyseTests {
    let frist = Tag(2027, 6, 30)

    @Test func prognoseTexte() {
        #expect(ZielAnalyse.prognoseText(.keine, faellig: frist) == "Prognose ab 7 Tagen Verlauf")
        #expect(ZielAnalyse.prognoseText(.keinFortschritt(tage: 12), faellig: frist) == "Seit 12 Tagen kein Fortschritt")
        #expect(ZielAnalyse.prognoseText(.datum(Tag(2027, 6, 20), restTage: 40, tempoProTag: 0.01), faellig: frist).hasSuffix("10 Tage vor der Frist"))
        #expect(ZielAnalyse.prognoseText(.datum(Tag(2027, 7, 3), restTage: 40, tempoProTag: 0.01), faellig: frist).hasSuffix("3 Tage nach der Frist"))
        #expect(ZielAnalyse.prognoseText(.datum(frist, restTage: 40, tempoProTag: 0.01), faellig: frist).hasSuffix("genau zur Frist"))
        #expect(ZielAnalyse.prognoseKurz(.keinFortschritt(tage: 3)) == "steht")
    }

    @Test func lotseKenntAnalyseUndZaehltIn() {
        let t = AppWissen.text()
        #expect(t.contains("Habit-Analyse") && t.contains("Ziel-Analyse") && t.contains("Prognose"))
        #expect(t.contains("Zählt in"))
    }
}
