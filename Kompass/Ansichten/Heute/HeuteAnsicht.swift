import SwiftUI

/// Heute: eine Aufgabe „Jetzt dran“, dann Wichtig / Weitere / Geschafft, Habits, Termine, Ziele.
struct HeuteAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var alleGeschafften = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let offen = z.aufgaben.filter { $0.datum == T && !$0.erledigt }.sorted { $0.reihenfolge < $1.reihenfolge }
        let wichtig = offen.filter { $0.prio == .hoch }
        let weitere = offen.filter { $0.prio != .hoch }
        let geschafft = z.aufgaben.filter { a in a.erledigt && a.erledigtAm.map { Tag($0, kalender: speicher.kalender) == T } == true }
            .sorted { ($0.erledigtAm ?? .distantPast) > ($1.erledigtAm ?? .distantPast) }
        let liegen = z.aufgaben.filter { a in a.datum.map { $0 < T } == true && !a.erledigt }.sorted { ($0.datum ?? T) < ($1.datum ?? T) }
        let jetzt = wichtig.first ?? weitere.first
        let einstellung = z.einstellungen

        Seite(titel: "Heute", info: .heute) {
            JetztDranKarte(aufgabe: jetzt, erledigt: geschafft.count, gesamt: offen.count + geschafft.count)

            if !liegen.isEmpty {
                AbschnittKopf(titel: "Liegen geblieben") {
                    Button("Alle auf heute") {
                        speicher.aendern { s in for a in liegen { if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) { s.aufgaben[i].datum = T } } }
                    }
                }
                GruppierteListe {
                    ForEach(liegen.prefix(3)) { AufgabeZeile(aufgabe: $0, datumZeigen: true) }
                    if liegen.count > 3 { LeerZeile(text: "\(liegen.count - 3) weitere") }
                }
            }

            AbschnittKopf(titel: "Wichtig") {
                Button {
                    speicher.aendern { $0.einstellungen.nurEineAufgabe.toggle() }
                } label: { Image(systemName: einstellung.nurEineAufgabe ? "eye.slash" : "eye") }
                    .accessibilityLabel(einstellung.nurEineAufgabe ? "Alle wichtigen Aufgaben zeigen" : "Nur eine Aufgabe zeigen")
            }
            GruppierteListe {
                ForEach(einstellung.nurEineAufgabe ? Array(wichtig.prefix(1)) : wichtig) { AufgabeZeile(aufgabe: $0) }
                if einstellung.nurEineAufgabe && wichtig.count > 1 { LeerZeile(text: "\(wichtig.count - 1) ausgeblendet") }
                AufgabeHinzufuegen(platzhalter: "Wichtige Aufgabe", datum: T, prio: .hoch)
            }

            AbschnittKopf(titel: "Weitere") {
                Button {
                    speicher.aendern { $0.einstellungen.weitereAusblenden.toggle() }
                } label: {
                    if einstellung.weitereAusblenden { Text("\(weitere.count) versteckt") } else { Image(systemName: "eye") }
                }
                .accessibilityLabel(einstellung.weitereAusblenden ? "Weitere einblenden" : "Weitere ausblenden")
            }
            if !einstellung.weitereAusblenden {
                GruppierteListe {
                    ForEach(weitere) { AufgabeZeile(aufgabe: $0) }
                    AufgabeHinzufuegen(platzhalter: "Aufgabe", datum: T, prio: .normal)
                }
            }

            if !geschafft.isEmpty {
                AbschnittKopf(titel: "Geschafft") { Text("\(geschafft.count)").foregroundStyle(Farbe.zweitrangig) }
                GruppierteListe {
                    ForEach(alleGeschafften ? geschafft : Array(geschafft.prefix(3))) { AufgabeZeile(aufgabe: $0) }
                    if geschafft.count > 3 {
                        Button(alleGeschafften ? "Weniger" : "\(geschafft.count - 3) weitere") { alleGeschafften.toggle() }
                            .font(.unterzeile).frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }

            HabitsHeute()
            TermineHeute()

            AbschnittKopf(titel: "Ziele") { Button("Alle ›") { nav.zeige(.ziele) } }
            let aktiv = z.ziele.filter { $0.status == .aktiv }.sorted { $0.faellig < $1.faellig }
            GruppierteListe {
                if aktiv.isEmpty { LeerZeile(text: "Noch keine Ziele.") }
                ForEach(aktiv.prefix(3)) { ZielZeile(ziel: $0) }
            }

            PfeilZeile(symbol: "moon", text: z.reflexionen["tag:\(T.text)"] == nil ? "Tagesabschluss · 2 Min." : "Tagesabschluss ✓") {
                nav.blatt = .reflexion(woche: false)
            }
            .padding(.top, Mass.abschnitt)
        }
    }
}

/// Kopfkarte „Jetzt dran“ mit Fokus und Erledigt; unten Tagesfortschritt.
private struct JetztDranKarte: View {
    var aufgabe: Aufgabe?
    var erledigt: Int
    var gesamt: Int
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        Verlaufskarte(farben: Farbe.indigo) {
            if let a = aufgabe {
                KartenLabel(text: "Jetzt dran")
                Text(a.titel).font(.kompass(.title2, .heavy)).fixedSize(horizontal: false, vertical: true)
                if let g = z.ziel(a.zielID) { Text(g.titel).font(.unterzeile).opacity(0.85) }
                HStack(spacing: 8) {
                    let laeuft = z.timer?.aufgabeID == a.id
                    Button { nav.blatt = .fokus(a.id) } label: {
                        Label(laeuft ? "Fokus öffnen" : "Fokus starten", systemImage: laeuft ? "pause.fill" : "play.fill")
                            .font(.kompass(.subheadline, .bold)).padding(.horizontal, 16).frame(minHeight: 44)
                            .background(.white, in: Capsule()).foregroundStyle(Farbe.indigo[0])
                    }
                    Button { speicher.aendern { $0.erledigen(a.id, jetzt: speicher.jetzt()) } } label: {
                        Label("Erledigt", systemImage: "checkmark").font(.kompass(.subheadline, .bold))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .background(.white.opacity(0.18), in: Capsule())
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else {
                KartenLabel(text: "Alles erledigt")
                Text("Für heute ist nichts mehr offen.").font(.kompass(.title2, .heavy))
            }
            let fokus = z.sitzungen.filter { $0.tag == T }.reduce(0) { $0 + $1.sekunden } + z.timerSekunden(jetzt: speicher.jetzt())
            Balken(anteil: gesamt > 0 ? Double(erledigt) / Double(gesamt) : 0).padding(.top, 12)
            Text("\(erledigt) von \(gesamt) erledigt · \(Zahl.dauer(fokus)) Fokus").font(.klein).opacity(0.9)
        }
    }
}

private struct HabitsHeute: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let faellig = speicher.zustand.habits.filter { HabitRechnung.geplant($0, am: T) }
        AbschnittKopf(titel: "Habits") { Button("Alle ›") { nav.zeige(.habits) } }
        GruppierteListe {
            if speicher.zustand.habits.isEmpty { LeerZeile(text: "Noch keine Habits.") }
            else if faellig.isEmpty { LeerZeile(text: "Heute nichts geplant.") }
            ForEach(faellig) { h in
                HStack(spacing: 10) {
                    Haken(an: h.voll(am: T), farbe: Color(hex: h.farbe), beschriftung: h.titel) {
                        speicher.aendern { $0.habitUmschalten(h.id, am: T) }
                    }
                    .padding(.leading, 4)
                    Button { nav.blatt = .habit(h.id) } label: {
                        Text(h.titel).font(.zeile).foregroundStyle(Farbe.text).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Label("\(HabitRechnung.serie(h, heute: T))", systemImage: "flame.fill")
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig).padding(.trailing, 16)
                        .accessibilityLabel("Serie \(HabitRechnung.serie(h, heute: T))")
                }
                .frame(minHeight: Mass.zeileKompakt)
            }
        }
    }
}

private struct TermineHeute: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let e = z.einstellungen
        let termine = Beispieltermine.termine(am: T, google: e.googleBeispiel, apple: e.appleBeispiel, heute: T)
        let mitZeit = z.aufgaben.filter { $0.datum == T && $0.uhrzeit != nil }
        AbschnittKopf(titel: "Termine") { Button("Kalender ›") { nav.bereich = .kalender } }
        GruppierteListe {
            if termine.isEmpty && mitZeit.isEmpty {
                LeerZeile(text: e.googleBeispiel || e.appleBeispiel ? "Keine Termine mit Uhrzeit." : "Kalender verbinden, um Termine zu sehen.")
            }
            ForEach(Zeitleiste.eintraege(termine: termine, aufgaben: mitZeit, zustand: z), id: \.id) { ZeitleistenZeile(eintrag: $0) }
        }
    }
}

/// Termine und Aufgaben mit Uhrzeit gemeinsam nach Zeit sortiert.
enum Zeitleiste {
    struct Eintrag: Identifiable {
        var id: String
        var titel: String
        var start: Int?
        var unter: String
        var farbe: Color
        var aufgabeID: UUID?
        var erledigt = false
    }

    @MainActor
    static func eintraege(termine: [Termin], aufgaben: [Aufgabe], zustand z: Zustand) -> [Eintrag] {
        let t = termine.map { e in
            Eintrag(id: e.id, titel: e.titel, start: e.start,
                    unter: e.start.map { "\(Beispieltermine.uhrzeit($0))–\(Beispieltermine.uhrzeit(e.ende ?? $0)) · \(e.quelle.name)" } ?? "ganztägig · \(e.quelle.name)",
                    farbe: Color(hex: e.quelle.farbe))
        }
        let a = aufgaben.map { x in
            Eintrag(id: x.id.uuidString, titel: x.titel, start: x.uhrzeit,
                    unter: "\(Beispieltermine.uhrzeit(x.uhrzeit ?? 0)) · \(x.dauer) Min · Aufgabe",
                    farbe: z.ziel(x.zielID).map { Color(hex: $0.farbe) } ?? Farbe.pfeil, aufgabeID: x.id, erledigt: x.erledigt)
        }
        return (t + a).sorted { ($0.start ?? -1) < ($1.start ?? -1) }
    }
}

struct ZeitleistenZeile: View {
    var eintrag: Zeitleiste.Eintrag
    @Environment(Navigation.self) private var nav

    var body: some View {
        Button {
            if let id = eintrag.aufgabeID { nav.blatt = .aufgabe(id) }
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2).fill(eintrag.farbe).frame(width: 4, height: 36).padding(.leading, 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(eintrag.titel).font(.zeile).foregroundStyle(Farbe.text).strikethrough(eintrag.erledigt)
                    Text(eintrag.unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                }
                Spacer()
            }
            .frame(minHeight: Mass.zeileKompakt)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(eintrag.aufgabeID == nil)
    }
}
