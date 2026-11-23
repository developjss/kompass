import SwiftUI

/// Lade-, Fehler- und Bereit-Zustand der ganzen App; danach die fünf Bereiche als Tab-Leiste.
struct Hauptansicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        switch speicher.lage {
        case .laedt:
            ProgressView("Lädt …")
                .font(.unterzeile)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Farbe.grund)
        case .fehler(let text):
            FehlerAnsicht(text: text)
        case .bereit:
            Bereiche()
        }
    }
}

private struct FehlerAnsicht: View {
    var text: String
    @Environment(Speicher.self) private var speicher

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(Farbe.kritisch)
            Text(text).font(.kompass(.title3, .bold)).multilineTextAlignment(.center)
            Button("Erneut versuchen") { Task { await speicher.laden() } }
                .buttonStyle(.borderedProminent)
            Button("Neu beginnen (alte Daten werden gesichert)") { speicher.neuBeginnen() }
                .font(.unterzeile)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Farbe.grund)
    }
}

private struct Bereiche: View {
    @Environment(Navigation.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        TabView(selection: $nav.bereich) {
            Tab(Bereich.heute.titel, systemImage: Bereich.heute.symbol, value: Bereich.heute) { NavigationStack { HeuteAnsicht().zielZiel() } }
            Tab(Bereich.kalender.titel, systemImage: Bereich.kalender.symbol, value: Bereich.kalender) { NavigationStack { KalenderAnsicht() } }
            Tab(Bereich.lotse.titel, systemImage: Bereich.lotse.symbol, value: Bereich.lotse) { NavigationStack { LotseAnsicht().zielZiel() } }
            Tab(Bereich.fortschritt.titel, systemImage: Bereich.fortschritt.symbol, value: Bereich.fortschritt) { NavigationStack(path: $nav.fortschrittPfad) { FortschrittAnsicht().zielZiel() } }
            Tab(Bereich.rueckblick.titel, systemImage: Bereich.rueckblick.symbol, value: Bereich.rueckblick) { NavigationStack { RueckblickAnsicht() } }
        }
        .tint(Farbe.akzent)
        .sheet(item: $nav.blatt) { blatt in
            BlattInhalt(blatt: blatt)
        }
    }
}

private extension View {
    func zielZiel() -> some View {
        navigationDestination(for: ZielAuswahl.self) { ZielDetail(id: $0.id) }
    }
}

private struct BlattInhalt: View {
    var blatt: Navigation.Blatt
    var body: some View {
        switch blatt {
        case .neu(let art): NeuBlatt(art: art ?? .aufgabe)
        case .info(let t): InfoBlatt(thema: t)
        case .einstellungen: EinstellungenBlatt()
        case .aufgabe(let id): AufgabeBlatt(id: id)
        case .habit(let id): HabitBlatt(id: id)
        case .fokus(let id): FokusBlatt(aufgabeID: id)
        case .rechnung(let id): RechnungBlatt(zielID: id)
        case .reflexion(let woche): ReflexionBlatt(woche: woche)
        case .meilenstein(let z, let s): MeilensteinBlatt(zielID: z, schrittID: s)
        case .habitZuZiel(let z): HabitZuZielBlatt(zielID: z)
        case .aufgabeZuZiel(let z): AufgabeZuZielBlatt(zielID: z)
        case .terminZuZiel(let z): TerminZuZielBlatt(zielID: z)
        case .zielBearbeiten(let z): ZielBearbeitenBlatt(zielID: z)
        case .pro: ProBlatt()
        case .habitMenge(let h, let t): HabitMengeBlatt(habitID: h, tag: Tag(text: t) ?? Tag(Date()))
        }
    }
}

struct InfoBlatt: View {
    var thema: InfoThema
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(thema.text).font(.kompass(.body, .medium)).lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Mass.rand)
            }
            .navigationTitle(thema.titel)
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
        .presentationDetents([.medium])
    }
}

extension View {
    func schliessenKnopf() -> some View { modifier(SchliessenKnopf()) }
}

private struct SchliessenKnopf: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Schließen", systemImage: "xmark") { dismiss() }
            }
        }
    }
}
