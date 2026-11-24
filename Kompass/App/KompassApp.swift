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
                    Erinnerungen.aktiv.oeffnen = { id in nav.oeffneHabit(id) }
                    Erinnerungen.aktiv.starten()
                    await speicher.laden()
                    Sprachmodelle.einrichten(pro: speicher.zustand.einstellungen.pro)
                }
                .onChange(of: speicher.zustand.einstellungen.pro) { _, neu in Sprachmodelle.einrichten(pro: neu) }
                .onChange(of: phase) { _, neu in
                    if neu == .background { Lotse.neuerChat(speicher: speicher) }
                    if neu != .active { speicher.speichernJetzt() } else if speicher.lage == .bereit { speicher.appleKalenderLesen() }
                }
        }
    }
}

/// Die fünf Tabs in Reihenfolge; der Lotse steht in der Mitte. Ziele und Habits teilen sich „Fortschritt“ (Umschalter oben).
enum Bereich: String, Hashable, CaseIterable {
    case heute, kalender, lotse, fortschritt, rueckblick

    var titel: String {
        switch self {
        case .heute: "Home"
        case .kalender: "Kalender"
        case .fortschritt: "Fortschritt"
        case .lotse: "Assistent"
        case .rueckblick: "Rückblick"
        }
    }

    var symbol: String {
        switch self {
        case .heute: "house"
        case .kalender: "calendar"
        case .fortschritt: "target"
        case .lotse: "sparkles"
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
    case aufgabe, termin, habit, ziel
    var id: String { rawValue }
}

/// Ansicht im Kalender
enum KalenderModus: String, Hashable, CaseIterable {
    case tag, woche, monat, jahr
    var titel: String {
        switch self {
        case .tag: "Tag"
        case .woche: "Woche"
        case .monat: "Monat"
        case .jahr: "Jahr"
        }
    }
}

/// Welche Zeile der Ziel-Seite bearbeitet wird
enum ZielFeld: String, Hashable, CaseIterable {
    case titel, faellig, bereich, warum, aussehen
}

/// Welche Zeile der Habit-Seite bearbeitet wird (je Zeile ein Editor, wie bei einer Gapless-Transaktion)
enum HabitFeld: String, Hashable, CaseIterable {
    case titel, menge, rhythmus, kalender, erinnerung, ziel, aussehen
}

enum InfoThema: String, Hashable, Identifiable, CaseIterable {
    case heute, kalender, habits, ziele, rueckblick, lotse
    var id: String { rawValue }

    var titel: String {
        switch self {
        case .heute: "Home"
        case .kalender: "Kalender"
        case .habits: "Habits"
        case .ziele: "Ziele"
        case .rueckblick: "Rückblick"
        case .lotse: "Assistent"
        }
    }

    var text: String {
        switch self {
        case .heute: "Home zeigt, was jetzt dran ist: oben läuft oder kommt der nächste Eintrag – mit Fokus und Erledigt. Hinweise warnen vor engen Tagen, Überschneidungen und zu wenig Zeit. Darunter: als Nächstes, was heute noch offen ist, und deine Ziele."
        case .kalender: "Oben die nächsten drei Einträge. Darunter Tag, Woche, Monat oder Jahr. Aufgaben und Habits ohne Uhrzeit ziehst du von unten in den Tag. Termine legst du mit „+ Neu“ an – sie können für ein Ziel zählen oder einen Habit erfüllen."
        case .habits: "Habits sind das Tägliche. Unter „Heute“ hakst du ab oder trägst eine Menge ein – halb geschafft zählt halb. „Diese Woche“ zeigt Tages- und Wochen-Habits, „Alle Habits“ Soll, Rhythmus, Quote und Serie. Die Serie zählt nur volle Tage."
        case .ziele: "Ziele haben ein Datum und einen Fortschritt in Prozent. „Voraus“, „im Plan“ oder „hinterher“ vergleicht den Fortschritt mit der Zeit seit Anlage. Wie gerechnet wird, steht in jedem Ziel unter „So wird gerechnet“."
        case .rueckblick: "Fokuszeit zählt alle Timer-Minuten der Woche, die Kurve zeigt die letzten 12 Wochen. Die Habit-Quote zählt nur geplante Tage – den heutigen erst, wenn er abgehakt ist."
        case .lotse: "Der Assistent kennt deine Ziele, Habits, Aufgaben und Termine. Frag ihn, was als Nächstes ansteht, wie voll dein Tag ist oder warum ein Ziel bei 54 % steht – oder lass ihn Aufgaben und Termine anlegen. Jeder Start der App beginnt einen neuen Chat; frühere findest du oben links. Er rechnet nie selbst: Zahlen kommen immer aus der App."
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
        case fokus(UUID)
        case rechnung(UUID)
        case reflexion(woche: Bool)
        /// Meilenstein eines Ziels bearbeiten (nil = neu)
        case meilenstein(ziel: UUID, schritt: UUID?)
        case habitZuZiel(UUID)
        case aufgabeZuZiel(UUID)
        case terminZuZiel(UUID)
        /// Eine Zeile der Ziel-Seite bearbeiten
        case zielBearbeiten(UUID, ZielFeld)
        case pro
        /// Menge eines Habits für einen Tag eintragen (Tag als Text, damit der Fall Hashable bleibt)
        case habitMenge(UUID, tag: String)
        /// Eine Zeile der Habit-Seite bearbeiten
        case habitBearbeiten(UUID, HabitFeld)
        /// Frühere Chats mit dem Assistenten
        case chats
        /// Termin anlegen (id nil) oder bearbeiten; Tag als Text, Start in Minuten
        case termin(UUID?, tag: String, start: Int?)

        var id: String {
            switch self {
            case .neu(let a): "neu-\(a?.rawValue ?? "")"
            case .info(let t): "info-\(t.rawValue)"
            case .einstellungen: "einstellungen"
            case .aufgabe(let i): "aufgabe-\(i)"
            case .fokus(let i): "fokus-\(i)"
            case .rechnung(let i): "rechnung-\(i)"
            case .reflexion(let w): "reflexion-\(w)"
            case .meilenstein(let z, let s): "meilenstein-\(z)-\(s?.uuidString ?? "neu")"
            case .habitZuZiel(let z): "habitzuziel-\(z)"
            case .aufgabeZuZiel(let z): "aufgabezuziel-\(z)"
            case .terminZuZiel(let z): "terminzuziel-\(z)"
            case .zielBearbeiten(let z, let f): "zielbearbeiten-\(z)-\(f.rawValue)"
            case .pro: "pro"
            case .habitMenge(let h, let t): "habitmenge-\(h)-\(t)"
            case .habitBearbeiten(let h, let f): "habitbearbeiten-\(h)-\(f.rawValue)"
            case .chats: "chats"
            case .termin(let i, let t, let s): "termin-\(i?.uuidString ?? "neu")-\(t)-\(s ?? -1)"
            }
        }
    }

    var bereich: Bereich = .heute
    var fortschrittTeil: FortschrittTeil = .ziele
    /// Kalender: gewählter Tag (nil = heute) und Ansicht
    var kalenderTag: Tag?
    var kalenderModus: KalenderModus = .tag

    /// Kalender an einem Tag öffnen
    func oeffneKalender(_ tag: Tag?, modus: KalenderModus = .tag) {
        kalenderTag = tag
        kalenderModus = modus
        bereich = .kalender
    }
    var blatt: Blatt?
    /// Navigationspfad im Tab Fortschritt (Ziel- und Habit-Seiten; der Lotse öffnet darüber)
    var fortschrittPfad = NavigationPath()

    func oeffneZiel(_ id: UUID) {
        zeige(.ziele)
        fortschrittPfad = NavigationPath([ZielAuswahl(id: id)])
    }

    /// Habit-Seite im Tab Fortschritt öffnen (auch aus Heute, Ziel oder Lotse)
    func oeffneHabit(_ id: UUID) {
        if bereich == .fortschritt, fortschrittTeil == .habits {
            fortschrittPfad.append(HabitAuswahl(id: id))
        } else {
            zeige(.habits)
            fortschrittPfad = NavigationPath([HabitAuswahl(id: id)])
        }
    }

    /// Stapel im Tab Rückblick (Analyse eines Habits oder Ziels)
    var rueckblickPfad = NavigationPath()

    /// Analyse im Rückblick öffnen (aus Habit-/Ziel-Seite, Rückblick oder Lotse)
    func zeigeAnalyse(habit id: UUID) {
        rueckblickPfad = NavigationPath([AnalyseAuswahl(art: .habit, id: id)])
        bereich = .rueckblick
    }

    func zeigeAnalyse(ziel id: UUID) {
        rueckblickPfad = NavigationPath([AnalyseAuswahl(art: .ziel, id: id)])
        bereich = .rueckblick
    }

    func zeige(_ teil: FortschrittTeil) {
        fortschrittTeil = teil
        bereich = .fortschritt
    }
}

/// Für NavigationLink(value:) auf ein Ziel
struct ZielAuswahl: Hashable { var id: UUID }
/// Für NavigationLink(value:) auf einen Habit
struct HabitAuswahl: Hashable { var id: UUID }
