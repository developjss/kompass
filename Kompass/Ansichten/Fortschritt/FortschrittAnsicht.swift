import SwiftUI

/// Tab „Fortschritt“: Ziele und Habits in einem Tab, aber getrennt – jede Hälfte bringt ihre eigene Bühne mit,
/// in deren Marke der Umschalter steht (Blattwerk, Hick: eine Entscheidung oben, nicht zwei).
struct FortschrittAnsicht: View {
    @Environment(Navigation.self) private var nav

    var body: some View {
        switch nav.fortschrittTeil {
        case .ziele: ZieleAnsicht()
        case .habits: HabitsAnsicht()
        }
    }
}

/// Der Umschalter in der Marke: zeigt die jeweils andere Hälfte als Chip.
struct FortschrittWahl: View {
    @Environment(Navigation.self) private var nav
    @Environment(\.accessibilityReduceMotion) private var ruhig

    /// Beide Teile immer sichtbar: der gewählte in Creme, der andere als Schrift – man sieht, dass man wechseln kann.
    var body: some View {
        HStack(spacing: 2) {
            ForEach([FortschrittTeil.ziele, .habits], id: \.self) { teil in
                let an = nav.fortschrittTeil == teil
                Button { withAnimation(ruhig ? nil : .snappy(duration: 0.2)) { nav.fortschrittTeil = teil } } label: {
                    Text(teil.titel).font(.kompass(.subheadline, .heavy))
                        .padding(.horizontal, 16).frame(minHeight: 36)
                        .background(an ? Farbe.wort : .clear, in: Capsule())
                        .foregroundStyle(an ? Color(roh: "#141B24") : Farbe.wort)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(teil.titel)
                .accessibilityAddTraits(an ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Farbe.wort.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(Farbe.wort.opacity(0.22), lineWidth: 1))
    }
}
