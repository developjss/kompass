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
            Tab(Bereich.rueckblick.titel, systemImage: Bereich.rueckblick.symbol, value: Bereich.rueckblick) { NavigationStack(path: $nav.rueckblickPfad) { RueckblickAnsicht().navigationDestination(for: AnalyseAuswahl.self) { AnalyseSeite(auswahl: $0) }.navigationDestination(for: StatistikAuswahl.self) { StatistikSeite(auswahl: $0) } } }
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
            .navigationDestination(for: HabitAuswahl.self) { HabitDetail(id: $0.id) }
            .navigationDestination(for: HabitTeilAuswahl.self) { HabitTeilSeite(id: $0.id, teil: $0.teil) }
            .navigationDestination(for: ZielTeilAuswahl.self) { ZielTeilSeite(id: $0.id, teil: $0.teil) }
    }
}

private struct BlattInhalt: View {
    var blatt: Navigation.Blatt
    var body: some View {
        switch blatt {
        case .neu(let art): NeuBlatt(art: art)
        case .info(let t): InfoBlatt(thema: t)
        case .einstellungen: EinstellungenBlatt()
        case .aufgabe(let id): AufgabeBlatt(id: id)
        case .fokus(let id): FokusBlatt(aufgabeID: id)
        case .rechnung(let id): RechnungBlatt(zielID: id)
        case .reflexion(let woche): ReflexionBlatt(woche: woche)
        case .meilenstein(let z, let s): MeilensteinBlatt(zielID: z, schrittID: s)
        case .habitZuZiel(let z): HabitZuZielBlatt(zielID: z)
        case .aufgabeZuZiel(let z): AufgabeZuZielBlatt(zielID: z)
        case .terminZuZiel(let z): TerminZuZielBlatt(zielID: z)
        case .zielBearbeiten(let z, let f): ZielBearbeitenBlatt(zielID: z, feld: f)
        case .pro: ProBlatt()
        case .habitMenge(let h, let t): HabitMengeBlatt(habitID: h, tag: Tag(text: t) ?? Tag(Date()))
        case .habitBearbeiten(let h, let f): HabitFeldBlatt(habitID: h, feld: f)
        case .termin(let i, let t, let s): TerminBlatt(terminID: i, tag: Tag(text: t), start: s)
        case .terminSeite(let s, let t): TerminSeite(serie: s, tag: Tag(text: t) ?? Tag(Date()))
        case .stunde(let t, let s): StundeBlatt(tag: Tag(text: t) ?? Tag(Date()), start: s)
        case .neuTermin(let t, let s): NeuBlatt(art: .termin, tag: Tag(text: t), start: s)
        case .externTermin(let i, let t): ExternTerminBlatt(id: i, tag: Tag(text: t) ?? Tag(Date()))
        case .chats: ChatVerlaufBlatt()
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
