import Testing
@testable import Kompass

/// Designsystem „Dunkel“: Lesbarkeit der Textfarben (WCAG AA ≥ 4,5 : 1) auf allen Flächen.
struct DunkelTests {
    @Test func textIstAufAllenFlaechenLesbar() {
        for flaeche in [Dunkel.grund, Dunkel.blatt, Dunkel.kapsel, Dunkel.eingabe, Dunkel.knopf] {
            #expect(Dunkel.kontrast(Dunkel.text, flaeche) >= 4.5)
        }
    }

    @Test func zweitrangigUndAntwortSindAufGrundUndKapselLesbar() {
        for farbe in [Dunkel.zweitrangig, Dunkel.antwort, Dunkel.akzentA, Dunkel.akzentB, Dunkel.pro] {
            #expect(Dunkel.kontrast(farbe, Dunkel.grund) >= 4.5)
            #expect(Dunkel.kontrast(farbe, Dunkel.kapsel) >= 4.5)
        }
    }

    @Test func zweitrangigIstAufBlattLesbar() {
        // Blatt ist die hellste Fläche – zweitrangiger Text muss dort noch AA erreichen
        #expect(Dunkel.kontrast(Dunkel.zweitrangig, Dunkel.blatt) >= 4.5)
    }
}

/// Gerüst: die drei Bereiche des Vorbilds in fester Reihenfolge.
struct GeruestTests {
    @Test func dreiBereicheInReihenfolge() {
        #expect(Bereich.allCases.map(\.titel) == ["Home", "Meine Apps", "Mein Weg"])
    }
}
