import SwiftUI

/// Fokus-Timer: startet beim Öffnen, Pause/Weiter, „Fertig“ bucht die Zeit (an Mitternacht geteilt, höchstens 4 h).
struct FokusBlatt: View {
    var aufgabeID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var meldung: String?

    var body: some View {
        let z = speicher.zustand
        let a = z.aufgabe(aufgabeID)
        let ziel = z.ziel(a?.zielID)
        let laeuft = z.timer?.aufgabeID == aufgabeID && z.timer?.laeuftSeit != nil
        VStack(spacing: 20) {
            Spacer()
            Text("Fokus").font(.klein).foregroundStyle(.white.opacity(0.8))
            Text(a?.titel ?? "Aufgabe").font(.kompass(.title2, .heavy)).multilineTextAlignment(.center)
            if let ziel { Text(ziel.titel).font(.unterzeile).opacity(0.85) }
            TimelineView(.periodic(from: .now, by: 1)) { kontext in
                Text(uhr(z.timer?.aufgabeID == aufgabeID ? z.timerSekunden(jetzt: kontext.date) : 0))
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .accessibilityLabel("Fokuszeit")
            }
            if let meldung { Text(meldung).font(.unterzeile).multilineTextAlignment(.center) }
            HStack(spacing: 12) {
                Button {
                    speicher.aendern { s in
                        if laeuft { s.timerPausieren(jetzt: speicher.jetzt()) } else { s.timerStarten(aufgabeID, jetzt: speicher.jetzt()) }
                    }
                } label: {
                    Label(laeuft ? "Pause" : "Weiter", systemImage: laeuft ? "pause.fill" : "play.fill")
                        .frame(minWidth: 120, minHeight: 50).background(.white.opacity(0.2), in: Capsule())
                }
                Button {
                    var buchung: FokusRechnung.Buchung?
                    speicher.aendern { buchung = $0.timerStoppen(jetzt: speicher.jetzt()) }
                    if buchung?.gekappt == true {
                        meldung = "Timer lief über 4 Stunden – gezählt werden 4 Stunden."
                    } else {
                        dismiss()
                    }
                } label: {
                    Label("Fertig", systemImage: "stop.fill")
                        .frame(minWidth: 120, minHeight: 50).background(Farbe.seladon, in: Capsule()).foregroundStyle(Farbe.nacht)
                }
            }
            .font(.kompass(.headline, .bold))
            .buttonStyle(.plain)
            Spacer()
            Button("Schließen – Timer läuft weiter") { dismiss() }.font(.unterzeile).opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: Farbe.indigo, startPoint: .bottom, endPoint: .top).ignoresSafeArea())
        .onAppear {
            if a != nil, z.timer?.aufgabeID != aufgabeID || z.timer?.laeuftSeit == nil {
                speicher.aendern { $0.timerStarten(aufgabeID, jetzt: speicher.jetzt()) }
            }
        }
    }

    private func uhr(_ s: TimeInterval) -> String {
        let n = Int(s)
        return n >= 3600 ? String(format: "%d:%02d:%02d", n / 3600, n / 60 % 60, n % 60) : String(format: "%02d:%02d", n / 60, n % 60)
    }
}
