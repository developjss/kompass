import SwiftUI

/// Kompass Pro – vorerst Vorstellung und Test-Schalter. [OFFEN] Kauf über StoreKit (Aufgabe l-storekit), Preis, Prüfung auf dem Server.
struct ProBlatt: View {
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let pro = speicher.zustand.einstellungen.pro
        let k = LotseStand.geteilt.kontingent
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Verlaufskarte(farben: Farbe.buehneVerlauf) {
                        KartenLabel(text: "Kompass Pro")
                        Text(pro ? "Pro ist aktiv." : "Der Assistent ohne Grenze.").font(.kompass(.title2, .heavy))
                        Text(pro ? "Unbegrenzte Fragen und Gespräche." : "Ohne Pro: \(k?.limit ?? 5) freie Fragen pro Tag. Klare Fragen beantwortet der Assistent immer kostenlos.")
                            .font(.unterzeile).opacity(0.9)
                    }
                    GruppierteListe {
                        Zeile(symbol: "infinity", text: "Unbegrenzte Fragen an den Assistenten")
                        Zeile(symbol: "bubble.left.and.bubble.right", text: "Gespräche: Ziel-Konflikte, Prioritäten")
                        Zeile(symbol: "arrow.triangle.2.circlepath", text: "Später: Abgleich zwischen Geräten")
                    }
                    if Kanal.aktuell == .store {
                        Text("Pro kommt mit der Veröffentlichung im App Store.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    } else {
                        Button(pro ? "Pro zum Testen ausschalten" : "Pro zum Testen einschalten") {
                            speicher.aendern { $0.einstellungen.pro.toggle() }
                        }
                        .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
                        .background(Farbe.handlung, in: Capsule()).foregroundStyle(Farbe.aufFarbe)
                        Text("Testversion: In Debug-, Beta- und TestFlight-Builds gilt Pro ohne Kauf.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                    }
                }
                .padding(Mass.rand)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle("Kompass Pro")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
        .presentationDetents([.medium, .large])
    }

    private struct Zeile: View {
        var symbol: String
        var text: String
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: symbol).foregroundStyle(Farbe.akzent).frame(width: 44)
                Text(text).font(.zeile).foregroundStyle(Farbe.text)
                Spacer()
            }
            .frame(minHeight: Mass.zeileKompakt)
        }
    }
}
