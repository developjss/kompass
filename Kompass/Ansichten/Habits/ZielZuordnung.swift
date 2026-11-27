import SwiftUI

/// Seite „Gehört zu“ im Blatt „Neuer Habit“ – Aufbau wie Opals Schwierigkeits-Seite (Zurück-Knopf, Verlaufs-Etikett,
/// großer Titel, Erklärung), darunter die Ziele von „Mein Weg“ als kleine Bildkarten. Nur Aussehen und Auswahl.
struct ZielZuordnung: View {
    @Binding var ziel: Ziel?
    var zurueck: () -> Void
    @Environment(\.accessibilityReduceMotion) private var ruhig

    private let s: CGFloat = 0.62
    private var breite: CGFloat { 229 * s }
    private var hoehe: CGFloat { 294 * s }
    private var radius: CGFloat { 32 * s }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BlattKnopf(symbol: "chevron.left", beschriftung: "Zurück", aktion: zurueck)
                Spacer()
            }

            VStack(spacing: 8) {
                VerlaufEtikett(text: "Gehört zu")
                Text(Ziel.zeilenText(ziel)).font(.system(size: 30, weight: .bold))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .contentTransition(.opacity)
                Text(ziel == nil ? "Nicht jeder Habit braucht ein Ziel." : "Dieser Habit bringt dich deinem Ziel näher.")
                    .font(.system(size: 17)).foregroundStyle(Color(0x9A9A9E))
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
            .padding(.top, 6)
            .animation(.easeInOut(duration: 0.2), value: ziel)
            .accessibilityElement(children: .combine)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    karte(gewaehlt: ziel == nil, beschriftung: "Kein Ziel") { ziel = nil } inhalt: {
                        glasKarte(symbol: "circle.slash", titel: "Kein Ziel")
                    }
                    ForEach(Ziel.demo) { z in
                        karte(gewaehlt: ziel == z, beschriftung: z.titel) { ziel = z } inhalt: {
                            ZielKarte(titel: z.titel, unter: z.unter, dauer: z.dauer, bild: z.bild, s: s)
                                .accessibilityHidden(true)
                        }
                    }
                    // PLATZHALTER: Neues Ziel anlegen – kommt mit den Funktionen
                    glasKarte(symbol: "plus", titel: "Neues Ziel", unter: "Kommt bald")
                        .opacity(0.7)
                        .accessibilityElement(children: .combine)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .padding(.top, 30)

            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.top, 26).padding(.horizontal, 6)
            Text("Ziele legst du auf „Mein Weg“ an. Ein Habit kann zu einem Ziel gehören oder für sich stehen.")
                .font(.system(size: 13)).foregroundStyle(Color(0x8E8E93))
                .multilineTextAlignment(.center)
                .padding(.top, 16).padding(.horizontal, 12)

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.selection, trigger: ziel)
    }

    /// Antippbare Karte mit hellem Rand und Verlaufs-Haken, wenn gewählt.
    private func karte<I: View>(gewaehlt: Bool, beschriftung: String, tippen: @escaping () -> Void, @ViewBuilder inhalt: () -> I) -> some View {
        Button {
            withAnimation(ruhig ? nil : .spring(response: 0.3, dampingFraction: 0.7)) { tippen() }
        } label: {
            inhalt()
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 2.5)
                        .opacity(gewaehlt ? 1 : 0)
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.black)
                        .frame(width: 26, height: 26)
                        .background(LinearGradient(colors: DFarbe.akzentFarben, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .padding(8)
                        .scaleEffect(gewaehlt ? 1 : 0.4)
                        .opacity(gewaehlt ? 1 : 0)
                }
                .scaleEffect(gewaehlt ? 1 : 0.97)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(beschriftung)
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }

    /// Glas-Karte in Kartengröße (Kein Ziel, Neues Ziel).
    private func glasKarte(symbol: String, titel: String, unter: String? = nil) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 22, weight: .medium))
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.08), in: Circle())
            VStack(spacing: 2) {
                Text(titel).font(.system(size: 15, weight: .semibold))
                if let unter { Text(unter).font(.system(size: 12)).foregroundStyle(Color(0x8E8E93)) }
            }
        }
        .foregroundStyle(DFarbe.text)
        .frame(width: breite, height: hoehe)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 0.75)
        }
    }
}
