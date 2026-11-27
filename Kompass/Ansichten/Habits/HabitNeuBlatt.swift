import SwiftUI

/// Neuer Habit (über das Plus) – Aussehen 1:1 nach Opals Regel-Blatt („Weekend Limit“), noch ohne Funktion.
/// Namen und Felder werden im nächsten Schritt angepasst. Maße und Farben aus den Vorlagen (Blatt #2C2C2C, Gruppen #363636).
struct HabitNeuBlatt: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tage: Set<Int> = [6, 7]
    @State private var name = ""
    @FocusState private var schreibt: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Kopf: Schließen · Titel · Bearbeiten
            ZStack {
                // Name des Habits: kleines Feld in grauer Kapsel, mittig
                TextField("", text: $name, prompt: Text("Name").foregroundStyle(Color(0x8E8E93)))
                    .font(.system(size: 17, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .focused($schreibt)
                    .submitLabel(.done)
                    .padding(.horizontal, 14)
                    .frame(width: 180, height: 38)
                    .background(Color(0x3A3A3A).opacity(0.75), in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.white.opacity(schreibt ? 0.22 : 0.08), lineWidth: 0.5) }
                    .tint(Color(Dunkel.akzentA))
                    .accessibilityLabel("Name des Habits")
                HStack {
                    BlattKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
                    Spacer()
                    BlattKnopf(symbol: "pencil", beschriftung: "Bearbeiten") {}
                }
            }
            .padding(.bottom, 8)

            BlattGruppe {
                BlattZeile(titel: "Apps") {
                    Image("habit-1").resizable().scaledToFill().frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
                }
            }

            BlattGruppe {
                BlattZeile(titel: "Erlaubte Zeit", unter: "Täglich") { BlattWert("1 h") }
                BlattTrenner()
                BlattZeile(titel: "Dann sperren bis") { BlattWert("Morgen") }
            }

            BlattGruppe {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("An diesen Tagen").font(.system(size: 17))
                        Spacer()
                        Text("Wochenende").font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                    }
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { i in
                            let an = tage.contains(i + 1)
                            Text(["M", "D", "M", "D", "F", "S", "S"][i]).font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(an ? Color.black : DFarbe.text)
                                .frame(width: 36, height: 36)
                                .background(an ? Color.white : Color(0x242424), in: Circle())
                                .overlay { Circle().strokeBorder(Color.white.opacity(an ? 0 : 0.08), lineWidth: 0.5) }
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 18).padding(.vertical, 14)
            }

            BlattGruppe {
                BlattZeile(titel: "Schwierigkeit") {
                    Text("Leicht").font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                    Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
                }
            }
            .padding(.top, 10)

            (Text("Damit nur die Nutzung auf diesem iPhone zählt, schalte in den Bildschirmzeit-Einstellungen „Geräteübergreifend teilen“ aus. ")
             + Text("Mehr dazu").underline().foregroundColor(Color(0x9EF0CF)))
                .font(.system(size: 13)).foregroundStyle(Color(0x8E8E93))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            Spacer(minLength: 4)

            HaltenKnopf(titel: "Gedrückt halten zum Festlegen") { dismiss() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .foregroundStyle(DFarbe.text)
        .presentationDetents([.height(612)])
        .presentationBackground { ZStack { Rectangle().fill(.ultraThinMaterial); Color(0x2C2C2C).opacity(0.62) } }
        .presentationCornerRadius(Dunkel.blattRadius)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

/// Runder Knopf im Blattkopf (Ø 44, etwas heller als das Blatt).
private struct BlattKnopf: View {
    var symbol: String
    var beschriftung: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Color(0x3F3F3F), in: Circle())
                .foregroundStyle(DFarbe.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
    }
}

private struct BlattGruppe<Inhalt: View>: View {
    @ViewBuilder var inhalt: Inhalt
    var body: some View {
        VStack(spacing: 0) { inhalt }
            .background(Color(0x3A3A3A).opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5) }
    }
}

private struct BlattZeile<Rechts: View>: View {
    var titel: String
    var unter: String?
    @ViewBuilder var rechts: Rechts
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.system(size: 17))
                if let unter { Text(unter).font(.system(size: 15)).foregroundStyle(Color(0x9A9A9E)) }
            }
            Spacer()
            rechts
        }
        .padding(.horizontal, 18)
        .frame(minHeight: unter == nil ? 52 : 62)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// BlattWert mit Auf-/Ab-Pfeilen (Auswahl-Rad folgt mit der Funktion).
private struct BlattWert: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        HStack(spacing: 6) {
            Text(text).font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
            Image(systemName: "chevron.up.chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(0x9A9A9E))
        }
    }
}

private struct BlattTrenner: View {
    var body: some View { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 18) }
}
