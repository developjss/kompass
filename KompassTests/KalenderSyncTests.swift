import Foundation
import Testing
@testable import Kompass

// Apple/Google: Google erkennen, Kennungen aus der Serie lesen (Beispieltermine sind nicht bearbeitbar).

@Suite("Kalender · Apple und Google")
struct KalenderSyncTests {
    @Test func googleErkennen() {
        #expect(AppleKalender.istGoogle(quelle: "Google", kalender: "Arbeit"))
        #expect(AppleKalender.istGoogle(quelle: "Gmail", kalender: "Privat"))
        #expect(AppleKalender.istGoogle(quelle: "Andere", kalender: "max@gmail.com"))
        #expect(AppleKalender.istGoogle(quelle: "CalDAV", kalender: "abc@group.calendar.google.com"))
        #expect(!AppleKalender.istGoogle(quelle: "iCloud", kalender: "Zuhause"))
    }

    @Test func externeKennung() {
        #expect(KalenderAktion.externeID("apple:5F3A:9C21") == "5F3A:9C21")
        #expect(KalenderAktion.externeID("google:AB12:CD34") == "AB12:CD34")
        #expect(KalenderAktion.externeID("google:fahrstunde") == nil)     // Beispieltermin
        #expect(KalenderAktion.externeID("kompass:123") == nil)
        #expect(KalenderAktion.externeID(nil) == nil)
    }
}
