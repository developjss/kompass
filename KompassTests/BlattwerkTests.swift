import Foundation
import Testing
import UIKit
@testable import Kompass

// Nachtblau-Palette: bunte Farben (Ziele, Habits, Kalender) landen in Blau-, Dunst- und Schiefertönen; Dunkles, Helles, Graues bleibt.
// Kontraste nach WCAG, Bilder vorhanden, Bühne und Karte in den Maßen des Prototyps.

@Suite("Nachtblau · Palette")
struct NachtblauTests {
    @Test func familienDerDemoFarben() {
        #expect(Farbe.tonArt("#1F7AC2") == .beere)       // Führerschein (Blau)
        #expect(Farbe.tonArt("#15803D") == .gruen)       // Fit (Grün)
        #expect(Farbe.tonArt("#9A6700") == .gruenTief)   // Millionär (Gold)
        #expect(Farbe.tonArt("#3B4CCA") == .weinrot)     // LAPL (Indigo)
        #expect(Farbe.tonArt("#7A4FD6") == .rosa)        // Lila
        #expect(Farbe.tonArt("#B8456E") == .wein)        // Rosa/Rot
    }

    @Test func dunkleHelleUndGraueBleiben() {
        #expect(Farbe.tonArt("#0F141B") == nil)
        #expect(Farbe.tonArt("#F3F1E6") == nil)
        #expect(Farbe.tonArt("#6B7285") == nil)
        #expect(Farbe.tonArt("kaputt") == nil)
    }

    @Test func auswahlDeckJedeFamilieGenauEinmal() {
        let arten = Farbe.ziele.compactMap { Farbe.tonArt($0) }
        #expect(arten.count == Farbe.ziele.count)
        #expect(Set(arten.map { "\($0)" }).count == Farbe.ziele.count)
    }

    @Test func kontrasteHell() {
        #expect(Nachtblau.kontrast(Nachtblau.creme, Nachtblau.blau) >= 7)                // Wort auf Bühne
        #expect(Nachtblau.kontrast(Nachtblau.schwarz, Nachtblau.cremeKarte) >= 7)        // Text auf Karte
        #expect(Nachtblau.kontrast(Nachtblau.schwarz, Nachtblau.creme) >= 7)             // Text auf Grund
        #expect(Nachtblau.kontrast(Nachtblau.zweitrangigHell, Nachtblau.cremeKarte) >= 4.5)
        #expect(Nachtblau.kontrast(Nachtblau.akzentHell, Nachtblau.creme) >= 4.5)        // Handlung als Text
        #expect(Nachtblau.kontrast(Nachtblau.creme, Nachtblau.schwarz) >= 7)             // Schrift auf dem Knopf
        #expect(Nachtblau.kontrast(Nachtblau.dunst, Nachtblau.blau) >= 4.5)              // letztes Wort auf der Bühne
    }

    @Test func kontrasteDunkel() {
        #expect(Nachtblau.kontrast(Nachtblau.creme, Nachtblau.nacht) >= 7)
        #expect(Nachtblau.kontrast(Nachtblau.creme, Nachtblau.nachtKarte) >= 7)
        #expect(Nachtblau.kontrast(Nachtblau.zweitrangigDunkel, Nachtblau.nachtKarte) >= 4.5)
        #expect(Nachtblau.kontrast(Nachtblau.dunst, Nachtblau.nacht) >= 4.5)
        #expect(Nachtblau.kontrast(Nachtblau.dunst, Nachtblau.blauDunkel) >= 4.5)
        #expect(Nachtblau.kontrast(Nachtblau.nacht, Nachtblau.creme) >= 7)               // Schrift auf dem Creme-Knopf
    }

    @Test func messingNurAlsMarke() {
        // Messing ist nie Text auf Creme – nur Punkt, Linie, Strecke
        #expect(Nachtblau.kontrast(Nachtblau.messing, Nachtblau.creme) < 4.5)
    }

    @Test func kontrastFormel() {
        #expect(abs(Nachtblau.kontrast(0xFFFFFF, 0x000000) - 21) < 0.01)
        #expect(abs(Nachtblau.kontrast(0x808080, 0x808080) - 1) < 0.01)
    }
}

@Suite("Nachtblau · Bühne")
struct BuehneTests {
    @Test func jedesObjektHatEinBild() {
        for o in Objekt.allCases {
            #expect(UIImage(named: o.rawValue, in: Bundle(for: Speicher.self), with: nil) != nil, "Bild fehlt: \(o.rawValue)")
        }
    }

    @Test func nurFokusUndUeberflugHabenEinObjekt() {
        #expect(Objekt.allCases.count == 4)
        #expect(Platz.fokus.links == 0 && Platz.fokus.breite == 190)
        #expect(Platz.ueberflug.links! < 0, "der Überflug beginnt außerhalb der Bühne")
    }

    @Test func masseDerEbenen() {
        #expect(Mass.buehne == 360 && Mass.buehneKurz == 270 && Mass.buehneLang == 430)
        #expect(Mass.karteVorn == 28 && Mass.karteVornVersatz == -44)
        #expect(Mass.saum(fuer: Mass.buehneKurz) == 150)
        #expect(Mass.saum(fuer: Mass.buehne) == 210)
        #expect(Mass.saum(fuer: Mass.buehneLang) == 240)
    }

    @Test func wortGroessen() {
        #expect(Wort.kleinGroesse < Wort.mittel && Wort.mittel < Wort.gross && Wort.gross < Wort.riesig)
        let w = Wort(zeilen: ["3 von 4"], akzent: "auf Kurs.")
        #expect(w.groesse == Wort.gross && w.klein == nil)
    }
}
