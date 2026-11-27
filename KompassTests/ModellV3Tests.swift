import Foundation
import Testing
@testable import Kompass

/// Umbau Block C: Datenmodell Version 3 – Lesen(Schreiben) bleibt gleich, alte Dateien laden ohne Fehler.
struct ModellV3Tests {
    @Test func neueFelderUeberlebenSpeichernUndLaden() throws {
        var z = DemoDaten.zustand(heute: Tag(2026, 11, 27))
        z.profil.anmeldung = .apple
        z.profil.einladungsCode = "KX7Q2"
        z.bildschirmzeit.zielMinuten = 150
        z.bildschirmzeit.schwierigkeit = .steigend
        z.urlaub = [Urlaub(von: "2026-12-20", bis: "2026-12-27")]
        z.meilensteine["serie-7"] = Date(timeIntervalSince1970: 1_800_000_000)
        z.tageswerte["2026-11-26"] = 72
        z.proAbo = ProAbo(produkt: "kompass.pro.monat", seit: Date(timeIntervalSince1970: 1_800_000_000))
        // Datumswerte werden sekundengenau gespeichert (ISO 8601) – daher: einmal speichern, dann stabil
        let einmal = try JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(z))
        let zweimal = try JSONDecoder.kompass.decode(Zustand.self, from: JSONEncoder.kompass.encode(einmal))
        #expect(zweimal == einmal)
        #expect(einmal.version == 3)
        #expect(einmal.profil == z.profil)
        #expect(einmal.journal == z.journal)
        #expect(einmal.bildschirmzeit == z.bildschirmzeit)
        #expect(einmal.urlaub == z.urlaub)
        #expect(einmal.meilensteine == z.meilensteine)
        #expect(einmal.tageswerte == z.tageswerte)
        #expect(einmal.proAbo == z.proAbo)
    }

    @Test func versionZweiOhneNeueFelderLaedtMitStandardwerten() throws {
        let alt = #"{"version":2,"ziele":[],"habits":[],"aufgaben":[]}"#.data(using: .utf8)!
        let z = try JSONDecoder.kompass.decode(Zustand.self, from: alt)
        #expect(z.version == 2)
        #expect(z.profil == Profil())
        #expect(z.journal.isEmpty)
        #expect(z.bildschirmzeit.hinweise == .mittel)
        #expect(z.bildschirmzeit.schwierigkeit == .leicht)
    }

    @Test func demoHatProfilJournalUndAblenkung() {
        let z = DemoDaten.zustand(heute: Tag(2026, 11, 27))
        #expect(z.profil.onboardingFertig)
        #expect(z.journal.count >= 14)
        #expect(z.bildschirmzeit.ablenkung.count == 28)
        #expect(z.bildschirmzeit.ablenkung.values.allSatisfy { $0 % 15 == 0 && $0 >= 60 })
        #expect(z.journal.values.allSatisfy { (1...5).contains($0.stimmung ?? 0) })
    }
}
