import SwiftUI

/// Compass – Neustart am 27.11.2026. Aufbau und Abläufe nach dem Vorbild (siehe `docs/plan.md`), nur dunkel.
@main
struct CompassApp: App {
    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("-designVorschau") { DesignVorschau() } else { Hauptansicht() }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Die drei Bereiche des Vorbilds.
enum Bereich: String, CaseIterable, Hashable {
    case home, apps, timer

    var titel: String {
        switch self {
        case .home: "Home"
        case .apps: "Meine Apps"
        case .timer: "Timer"
        }
    }

    var symbol: String {
        switch self {
        case .home: "circle"
        case .apps: "circle.grid.2x2.fill"
        case .timer: "play.fill"
        }
    }
}

/// Gerüst: drei Tabs, jede Seite noch leer (Block 1 baut die Tab-Kapsel und den Profil-Knopf).
struct Hauptansicht: View {
    @State private var bereich: Bereich = .home

    var body: some View {
        TabView(selection: $bereich) {
            ForEach(Bereich.allCases, id: \.self) { b in
                Tab(b.titel, systemImage: b.symbol, value: b) { LeereSeite(bereich: b) }
            }
        }
        .tint(DFarbe.text)
    }
}

/// Platzhalter je Bereich, bis der Block dazu gebaut ist.
struct LeereSeite: View {
    var bereich: Bereich
    var body: some View {
        VStack(spacing: 12) {
            Figur(zustand: .ruhig, groesse: 90)
            Text(bereich.titel).font(DSchrift.grosserTitel)
            Text("Wird neu gebaut.").font(DSchrift.zeile).foregroundStyle(DFarbe.zweitrangig)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dunkelGrund()
        .accessibilityIdentifier("seite.\(bereich.rawValue)")
    }
}
