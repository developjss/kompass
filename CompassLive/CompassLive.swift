import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Erweiterung „CompassLive“: Live-Aktivität für den Fokus auf Sperrbildschirm und in der Dynamic Island.
/// Aussehen nach der Vorlage des Gründers: „Compass“, „Fokus · Habit“, große Restzeit, türkiser Balken, gläserner Kompass.
@main
struct CompassLiveBundle: WidgetBundle {
    var body: some Widget { FokusLiveAktivitaet() }
}

private extension Color {
    init(_ hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

private let tuerkis = Color(0x2FD0D1)
private let tuerkisHell = Color(0xA7FFFF)

struct FokusLiveAktivitaet: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FokusAktivitaet.self) { k in
            SperrAnsicht(name: k.attributes.habitName, stand: k.state, abgelaufen: k.isStale)
                .activityBackgroundTint(Color(0x062422))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { k in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image("live-kugel").resizable().scaledToFill()
                        .frame(width: 44, height: 44).clipShape(Circle())
                        .overlay { Circle().strokeBorder(tuerkisHell.opacity(0.5), lineWidth: 1) }
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Zeit(stand: k.state, abgelaufen: k.isStale)
                        .font(.system(size: 30, weight: .semibold))
                        .frame(maxWidth: 110, alignment: .trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 1) {
                        Text("Compass").font(.system(size: 15, weight: .semibold))
                        Text(untertitel(k.attributes.habitName, k.state, k.isStale)).font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Balken(stand: k.state, abgelaufen: k.isStale)
                        PauseKnopf(stand: k.state, abgelaufen: k.isStale)
                    }
                    .padding(.horizontal, 6).padding(.top, 4)
                }
            } compactLeading: {
                Image("live-kugel").resizable().scaledToFill()
                    .frame(width: 22, height: 22).clipShape(Circle())
            } compactTrailing: {
                Zeit(stand: k.state, abgelaufen: k.isStale)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tuerkisHell)
                    .frame(maxWidth: 52)
            } minimal: {
                Image("live-kugel").resizable().scaledToFill()
                    .frame(width: 22, height: 22).clipShape(Circle())
            }
            .keylineTint(tuerkis)
        }
    }
}

private func untertitel(_ name: String, _ s: FokusAktivitaet.ContentState, _ abgelaufen: Bool) -> String {
    if abgelaufen || (!s.pausiert && s.ende <= .now) { return "Geschafft · \(name)" }
    return s.pausiert ? "Pausiert · \(name)" : "Fokus · \(name)"
}

/// Sperrbildschirm: links Text und Zeit, rechts der Kompass, unten der Balken.
private struct SperrAnsicht: View {
    var name: String
    var stand: FokusAktivitaet.ContentState
    var abgelaufen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Compass").font(.system(size: 24, weight: .semibold))
                    Text(untertitel(name, stand, abgelaufen)).font(.system(size: 14)).foregroundStyle(.white.opacity(0.65))
                    Zeit(stand: stand, abgelaufen: abgelaufen, klein: false)
                        .font(.system(size: 40, weight: .medium))
                        .frame(width: 150, alignment: .leading)
                        .padding(.top, 4)
                }
                Spacer(minLength: 8)
                VStack(spacing: 6) {
                    Image("live-kompass").resizable().scaledToFit()
                        .frame(height: 80)
                        .mask(RadialGradient(colors: [.black, .black, .clear], center: .center, startRadius: 0, endRadius: 48))
                        .shadow(color: tuerkis.opacity(0.5), radius: 10)
                    PauseKnopf(stand: stand, abgelaufen: abgelaufen)
                }
                .frame(width: 112)
            }
            Balken(stand: stand, abgelaufen: abgelaufen)
        }
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 14)
        .foregroundStyle(.white)
        .background {
            // Hintergrund: Landebahn bei Nacht, abgedunkelt
            ZStack {
                Image("live-grund").resizable().scaledToFill().opacity(0.55)
                LinearGradient(colors: [Color(0x062422).opacity(0.85), Color(0x0B3B38).opacity(0.35)], startPoint: .leading, endPoint: .trailing)
            }
            .clipped()
        }
        .overlay {
            ContainerRelativeShape().strokeBorder(LinearGradient(colors: [tuerkisHell.opacity(0.45), tuerkis.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        }
    }
}

/// Restzeit: zählt von selbst herunter (auch ohne App), steht in der Pause still.
private struct Zeit: View {
    var stand: FokusAktivitaet.ContentState
    var abgelaufen: Bool
    /// Kleine Plätze (Dynamic Island) dürfen die Zeit verkleinern, der Sperrbildschirm nicht
    var klein = true
    var body: some View {
        Group {
            if abgelaufen || (!stand.pausiert && stand.ende <= .now) {
                Text("00:00")
            } else if stand.pausiert {
                Text(FokusUhrText.text(stand.restSekunden))
            } else {
                Text(timerInterval: Date.now...stand.ende, countsDown: true)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(klein ? 0.6 : 1)
        .multilineTextAlignment(.leading)
    }
}

/// Türkiser Balken: füllt sich von selbst, steht in der Pause still.
private struct Balken: View {
    var stand: FokusAktivitaet.ContentState
    var abgelaufen: Bool
    var body: some View {
        Group {
            if abgelaufen || (!stand.pausiert && stand.ende <= .now) {
                ProgressView(value: 1)
            } else if stand.pausiert {
                let gesamt = max(stand.ende.timeIntervalSince(stand.start), 1)
                ProgressView(value: min(max(1 - Double(stand.restSekunden) / gesamt, 0), 1))
            } else {
                ProgressView(timerInterval: stand.start...stand.ende, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
            }
        }
        .progressViewStyle(.linear)
        .tint(tuerkis)
        .shadow(color: tuerkis.opacity(0.8), radius: 4)
    }
}

/// Pause / Weiter direkt auf dem Sperrbildschirm (läuft in der App über einen LiveActivityIntent).
private struct PauseKnopf: View {
    var stand: FokusAktivitaet.ContentState
    var abgelaufen: Bool
    var body: some View {
        if !(abgelaufen || (!stand.pausiert && stand.ende <= .now)) {
            Group {
                if stand.pausiert {
                    Button(intent: FokusWeiterIntent()) { knopf(symbol: "play.fill", titel: "Weiter") }
                } else {
                    Button(intent: FokusPausierenIntent()) { knopf(symbol: "pause.fill", titel: "Pause") }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func knopf(symbol: String, titel: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 11, weight: .bold))
            Text(titel).font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 12).frame(height: 30)
        .background(Capsule().fill(.white))
    }
}
