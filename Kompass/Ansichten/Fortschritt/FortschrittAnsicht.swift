import SwiftUI

/// Tab „Fortschritt“: Ziele und Habits in einem Tab, aber getrennt – oben wählt man, was man sehen will.
struct FortschrittAnsicht: View {
    @Environment(Navigation.self) private var nav

    var body: some View {
        switch nav.fortschrittTeil {
        case .ziele: ZieleAnsicht()
        case .habits: HabitsAnsicht()
        }
    }
}

/// Der Umschalter Ziele · Habits (Kapsel, wie ein Segment-Regler in Gapless).
struct FortschrittWahl: View {
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(spacing: 4) {
            ForEach(FortschrittTeil.allCases, id: \.self) { teil in
                let an = nav.fortschrittTeil == teil
                Button {
                    withAnimation(.snappy(duration: 0.2)) { nav.fortschrittTeil = teil }
                } label: {
                    Text(teil.titel)
                        .font(.kompass(.subheadline, .bold)).lineLimit(1).minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(an ? Farbe.karte : Color.clear, in: Capsule())
                        .foregroundStyle(an ? Farbe.text : Farbe.zweitrangig)
                        .shadow(color: an ? .black.opacity(0.06) : .clear, radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(an ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Farbe.akzentWeich.opacity(0.7), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ziele oder Habits anzeigen")
    }
}
