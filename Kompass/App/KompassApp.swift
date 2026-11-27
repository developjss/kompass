import SwiftUI

@main
struct KompassApp: App {
    @State private var speicher = Speicher()
    @State private var nav = Navigation()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("-designVorschau") { DesignVorschau() } else { Hauptansicht() }
            }
                // Kompass ist nur dunkel [ENTSCHEIDUNG – 27.11.2026]
                .preferredColorScheme(.dark)
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
    case heute, kalender, lotse, habits, ziele

    /// Aus gespeicherten Chats: alte Namen (bis 26.11.2026) führen weiter – Fortschritt → Ziele, Rückblick → Home.
    static func aus(_ roh: String) -> Bereich? {
        switch roh {
        case "fortschritt": .ziele
        case "rueckblick": .heute
        default: Bereich(rawValue: roh)
        }
    }

    var titel: String {
        switch self {
        case .heute: "Home"
        case .kalender: "Kalender"
        case .lotse: "Assistent"
        case .habits: "Habits"
        case .ziele: "Ziele"
        }
    }

    var symbol: String {
        switch self {
        case .heute: "house"
        case .kalender: "calendar"
        case .lotse: "sparkles"
        case .habits: "repeat"
        case .ziele: "target"
        }
    }
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
        case .heute: "Home zeigt, was jetzt dran ist: oben läuft oder kommt der nächste Eintrag – mit Fokus und Erledigt. Unter „Wichtig“ stehen höchstens drei Signale: volle Tage, Überschneidungen, Liegengebliebenes, Ziele hinter Plan, nahe Fristen, Serien. Lange drücken und „Passt nicht“ blendet eine Art 8 Wochen aus. Darunter: als Nächstes."
        case .kalender: "Oben die nächsten drei Einträge. Darunter Tag, Woche, Monat oder Jahr. Aufgaben und Habits ohne Uhrzeit ziehst du von unten in den Tag. Termine legst du mit „Termin hinzufügen“ an – sie können für ein Ziel zählen oder einen Habit erfüllen."
        case .habits: "Habits sind das Tägliche. Unter „Heute“ hakst du ab oder trägst eine Menge ein – halb geschafft zählt halb. „Diese Woche“ zeigt Tages- und Wochen-Habits, „Alle Habits“ Soll, Rhythmus, Quote und Serie. Die Serie zählt nur volle Tage."
        case .ziele: "Ziele haben ein Datum und einen Fortschritt in Prozent. „Voraus“, „im Plan“ oder „hinterher“ vergleicht den Fortschritt mit der Zeit seit Anlage. Wie gerechnet wird, steht in jedem Ziel unter „So wird gerechnet“."
        case .rueckblick: "Der Rückblick liegt auf Home: vier Karten zum Wischen, das Auffälligste vorn. Antippen öffnet die Statistik. Fokuszeit zählt alle Timer-Minuten der Woche, die Kurve zeigt die letzten 12 Wochen. Die Habit-Quote zählt nur geplante Tage – den heutigen erst, wenn er abgehakt ist."
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
        /// Termin-Seite (jeder Termin, auch Apple/Google): Serie „quelle:schlüssel“ und Tag als Text
        case terminSeite(serie: String, tag: String)
        /// Freie Stunde im Kalender angetippt: Termin anlegen oder Offenes einplanen
        case stunde(tag: String, start: Int)
        /// „+ Neu“ Termin mit Tag und Uhrzeit vorbelegt
        case neuTermin(tag: String, start: Int)
        /// Termin aus Apple/Google bearbeiten (Kennung, Tag als Text)
        case externTermin(id: String, tag: String)

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
            case .terminSeite(let s, let t): "terminseite-\(s)-\(t)"
            case .stunde(let t, let s): "stunde-\(t)-\(s)"
            case .neuTermin(let t, let s): "neutermin-\(t)-\(s)"
            case .externTermin(let i, let t): "externtermin-\(i)-\(t)"
            }
        }
    }

    var bereich: Bereich = .heute
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
    /// Stapel je Tab: Home (Rückblick-Karten, Analysen), Habits, Ziele – der Assistent öffnet darüber
    var heutePfad = NavigationPath()
    var habitsPfad = NavigationPath()
    var zielePfad = NavigationPath()

    func oeffneZiel(_ id: UUID) {
        if bereich == .ziele || bereich == .habits || bereich == .heute {
            haengeAn(ZielAuswahl(id: id))
        } else {
            zielePfad = NavigationPath([ZielAuswahl(id: id)])
            bereich = .ziele
        }
    }

    /// Habit-Seite öffnen (auch aus Home, Ziel oder Assistent): im eigenen Stapel bleibt der Rückweg erhalten
    func oeffneHabit(_ id: UUID) {
        if bereich == .ziele || bereich == .habits || bereich == .heute {
            haengeAn(HabitAuswahl(id: id))
        } else {
            habitsPfad = NavigationPath([HabitAuswahl(id: id)])
            bereich = .habits
        }
    }

    /// Analyse öffnen (aus Habit-/Ziel-Seite, Rückblick-Karte oder Assistent)
    func zeigeAnalyse(habit id: UUID) { zeigeAnalyse(AnalyseAuswahl(art: .habit, id: id)) }
    func zeigeAnalyse(ziel id: UUID) { zeigeAnalyse(AnalyseAuswahl(art: .ziel, id: id)) }

    /// Analyse öffnen, ohne den Rückweg zu verlieren: auf Home, Habits und Ziele kommt sie oben auf den Stapel.
    /// Aus Kalender und Assistent öffnet sie auf Home – dort liegt der Rückblick.
    func zeigeAnalyse(_ a: AnalyseAuswahl) {
        if bereich == .ziele || bereich == .habits || bereich == .heute {
            haengeAn(a)
        } else {
            heutePfad = NavigationPath([a])
            bereich = .heute
        }
    }

    /// Statistik des Rückblicks (Erledigt · Habits · Ziele · Zeit) auf Home öffnen
    func zeigeStatistik(_ art: Statistik.Art) {
        if bereich == .heute { heutePfad.append(StatistikAuswahl(art: art)) }
        else { heutePfad = NavigationPath([StatistikAuswahl(art: art)]); bereich = .heute }
    }

    /// Zurück zur Liste des aktuellen Tabs (nach dem Löschen eines Ziels oder Habits)
    func zurListe() {
        switch bereich {
        case .heute: heutePfad = NavigationPath()
        case .habits: habitsPfad = NavigationPath()
        case .ziele: zielePfad = NavigationPath()
        default: break
        }
    }

    private func haengeAn<W: Hashable>(_ wert: W) {
        switch bereich {
        case .heute: heutePfad.append(wert)
        case .habits: habitsPfad.append(wert)
        case .ziele: zielePfad.append(wert)
        default: break
        }
    }
}

/// Für NavigationLink(value:) auf ein Ziel
struct ZielAuswahl: Hashable { var id: UUID }
/// Für NavigationLink(value:) auf einen Habit
struct HabitAuswahl: Hashable { var id: UUID }
