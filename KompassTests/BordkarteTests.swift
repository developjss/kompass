import Foundation
import SwiftUI
import Testing
@testable import Kompass

@Suite("Rückblick · Bordkarte")
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
}
