import Foundation
import SwiftUI
import Testing
@testable import Kompass

@Suite("Easter Eggs · Bordkarte, Überflug, Fokus")
struct BordkarteTests {
    @Test func merkenJeWoche() {
        var l = ""
        #expect(!Bordkarte<EmptyView>.istAbgerissen(l, woche: "2026-11-23"))
        l = Bordkarte<EmptyView>.merken(l, woche: "2026-11-23")
        #expect(Bordkarte<EmptyView>.istAbgerissen(l, woche: "2026-11-23"))
        #expect(!Bordkarte<EmptyView>.istAbgerissen(l, woche: "2026-11-16"))
        l = Bordkarte<EmptyView>.merken(l, woche: "2026-11-23")
        #expect(l == "2026-11-23")   // kein Doppel
        for i in 0..<30 { l = Bordkarte<EmptyView>.merken(l, woche: "w\(i)") }
        #expect(l.split(separator: ",").count == 26)
        #expect(!Bordkarte<EmptyView>.istAbgerissen(l, woche: "2026-11-23"))   // älteste fällt raus
    }

    @Test func ueberflugEinmalJeTag() {
        #expect(Ueberflug.faellig(gesehen: "", heute: "2026-11-25"))
        #expect(!Ueberflug.faellig(gesehen: "2026-11-25", heute: "2026-11-25"))
        #expect(Ueberflug.faellig(gesehen: "2026-11-24", heute: "2026-11-25"))
    }

    @Test func keineFlugwoerterImFokus() {
        // Kalender-App auf den ersten Blick: die Phasen heißen ruhig, der Flug bleibt Bild
        let verboten = ["flug", "boarding", "land", "cockpit", "pilot", "gate"]
        for p in [FlugRechnung.Phase.boarding, .steigflug, .reiseflug, .landeanflug, .gelandet, .warteschleife] {
            for v in verboten { #expect(!p.text.lowercased().contains(v), "\(p.text) enthält \(v)") }
        }
    }
}
