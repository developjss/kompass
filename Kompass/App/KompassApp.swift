import SwiftUI

@main
struct KompassApp: App {
    @State private var speicher = Speicher()
    @State private var nav = Navigation()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Hauptansicht()
                .environment(speicher)
                .environment(nav)
                .task {
                    await speicher.laden()
                    Sprachmodelle.einrichten(pro: speicher.zustand.einstellungen.pro)
                }
                .onChange(of: speicher.zustand.einstellungen.pro) { _, neu in Sprachmodelle.einrichten(pro: neu) }
                .onChange(of: phase) { _, neu in
                    if neu != .active { speicher.speichernJetzt() }
                }
        }
    }
}

/// Die fünf Tabs in Reihenfolge; der Lotse steht in der Mitte. Ziele und Habits teilen sich „Fortschritt“ (Umschalter oben).
enum Bereich: String, Hashable, CaseIterable {
    case heute, kalender, lotse, fortschritt, rueckblick

    var titel: String {
        switch self {
        case .heute: "Heute"
        case .kalender: "Kalender"
        case .fortschritt: "Fortschritt"
        case .lotse: "Lotse"
        case .rueckblick: "Rückblick"
        }
    }

    var symbol: String {
        switch self {
        case .heute: "sun.max"
        case .kalender: "calendar"
        case .fortschritt: "target"
        case .lotse: "sparkles.rectangle.stack"
        case .rueckblick: "chart.bar"
        }
    }
}

/// Was im Tab „Fortschritt“ gezeigt wird – getrennt, nie vermischt.
enum FortschrittTeil: String, Hashable, CaseIterable {
    case ziele, habits
    var titel: String { self == .ziele ? "Ziele" : "Habits" }
}

enum NeuArt: String, Hashable, Identifiable {
    case aufgabe, habit, ziel
    var id: String { rawValue }
}

enum InfoThema: String, Hashable, Identifiable, CaseIterable {
    case heute, kalender, habits, ziele, rueckblick, lotse
    var id: String { rawValue }

    var titel: String {
        switch self {
        case .heute: "Heute"
        case .kalender: "Kalender"
        case .habits: "Habits"
        case .ziele: "Ziele"
        case .rueckblick: "Rückblick"
        case .lotse: "Lotse"
        }
    }

    var text: String {
        switch self {
        case .heute: "Oben steht die eine Aufgabe, die jetzt dran ist. „Wichtig“ zahlt auf deine Ziele ein, „Weitere“ nicht. Mit dem Auge zeigst du nur eine Aufgabe. Erledigtes landet unter „Geschafft“."
        case .kalender: "Termine aus Google oder Apple stehen neben deinen Aufgaben. Der Eingang sammelt Ideen ohne Datum. Kompass ergänzt deinen Kalender, ersetzt ihn aber nicht."
        case .habits: "Habits sind das Tägliche. Unter „Heute“ hakst du ab oder trägst eine Menge ein – halb geschafft zählt halb. „Diese Woche“ zeigt Tages- und Wochen-Habits, „Alle Habits“ Soll, Rhythmus, Quote und Serie. Die Serie zählt nur volle Tage."
        case .ziele: "Ziele haben ein Datum und einen Fortschritt in Prozent. „Voraus“, „im Plan“ oder „hinterher“ vergleicht den Fortschritt mit der Zeit seit Anlage. Wie gerechnet wird, steht in jedem Ziel unter „So wird gerechnet“."
        case .rueckblick: "Fokuszeit zählt alle Timer-Minuten der Woche, die Kurve zeigt die letzten 12 Wochen. Die Habit-Quote zählt nur geplante Tage – den heutigen erst, wenn er abgehakt ist."
        case .lotse: "Der Lotse kennt deine Ziele, Habits, Aufgaben und Termine. Frag ihn, was heute ansteht, wann du Zeit hast oder warum ein Ziel bei 54 % steht – oder lass ihn eine Aufgabe anlegen. Er rechnet nie selbst: Zahlen kommen immer aus der App."
        }
    }
}

/// Welches Fenster (Sheet) offen ist und welcher Bereich gewählt ist.
@MainActor
@Observable
final class Navigation {
    enum Blatt: Identifiable, Hashable {
        case neu(NeuArt?)
        case info(InfoThema)
        case einstellungen
        case aufgabe(UUID)
        case habit(UUID)
        case fokus(UUID)
        case rechnung(UUID)
        case reflexion(woche: Bool)
        /// Meilenstein eines Ziels bearbeiten (nil = neu)
        case meilenstein(ziel: UUID, schritt: UUID?)
        case habitZuZiel(UUID)
        case aufgabeZuZiel(UUID)
        case terminZuZiel(UUID)
        case zielBearbeiten(UUID)
        case pro
        /// Menge eines Habits für einen Tag eintragen (Tag als Text, damit der Fall Hashable bleibt)
        case habitMenge(UUID, tag: String)

        var id: String {
            switch self {
            case .neu(let a): "neu-\(a?.rawValue ?? "")"
            case .info(let t): "info-\(t.rawValue)"
            case .einstellungen: "einstellungen"
            case .aufgabe(let i): "aufgabe-\(i)"
            case .habit(let i): "habit-\(i)"
            case .fokus(let i): "fokus-\(i)"
            case .rechnung(let i): "rechnung-\(i)"
            case .reflexion(let w): "reflexion-\(w)"
            case .meilenstein(let z, let s): "meilenstein-\(z)-\(s?.uuidString ?? "neu")"
            case .habitZuZiel(let z): "habitzuziel-\(z)"
            case .aufgabeZuZiel(let z): "aufgabezuziel-\(z)"
            case .terminZuZiel(let z): "terminzuziel-\(z)"
            case .zielBearbeiten(let z): "zielbearbeiten-\(z)"
            case .pro: "pro"
            case .habitMenge(let h, let t): "habitmenge-\(h)-\(t)"
            }
        }
    }

    var bereich: Bereich = .heute
    var fortschrittTeil: FortschrittTeil = .ziele
    var blatt: Blatt?
    /// Navigationspfad im Tab Fortschritt (der Lotse öffnet darüber ein Ziel)
    var fortschrittPfad: [ZielAuswahl] = []

    func oeffneZiel(_ id: UUID) {
        zeige(.ziele)
        fortschrittPfad = [ZielAuswahl(id: id)]
    }

    func zeige(_ teil: FortschrittTeil) {
        fortschrittTeil = teil
        bereich = .fortschritt
    }
}

/// Für NavigationLink(value:) auf ein Ziel
struct ZielAuswahl: Hashable { var id: UUID }
