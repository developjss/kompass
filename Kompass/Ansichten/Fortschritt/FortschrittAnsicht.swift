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

    var body: some View {
        let andere: FortschrittTeil = nav.fortschrittTeil == .ziele ? .habits : .ziele
        Button { nav.fortschrittTeil = andere } label: {
            Text(andere.titel).font(.kompass(.caption, .heavy))
                .padding(.horizontal, 12).frame(minHeight: 32)
                .background(Farbe.karte, in: Capsule())
                .overlay(Capsule().strokeBorder(Farbe.linie, lineWidth: 1))
                .foregroundStyle(Farbe.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Zu \(andere.titel) wechseln")
    }
}
