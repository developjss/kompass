import SwiftUI

/// Aufgabe als Seite (Nachtflug, 24.11.2026): oben Titel mit Haken, darunter „Zählt für“ – ob und wie die Aufgabe
/// in ein Ziel zählt, in einem Satz (`Einordnung`) – dann Wann, Mehr, Notizen. Alles wird sofort gespeichert.
struct AufgabeBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    private enum Wann: String, CaseIterable { case heute = "Heute", morgen = "Morgen", datum = "Datum", ohne = "Ohne Datum" }

    var body: some View {
        NavigationStack {
            Group {
                if let a = speicher.zustand.aufgabe(id) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            kopf(a)
                            ZaehltKarte(zielID: a.zielID, schrittID: a.schrittID, einmalig: a.einmalig, aufgabeID: a.id,
                                        zielWaehlen: { neu in
                                            let h = speicher.heute
                                            speicher.aendern { s in
                                                let g = s.ziel(neu)
                                                let schritt = Fortschritt.naechsterOffenerSchritt(g, in: s, heute: h)?.id
                                                    ?? g?.schritte.first { $0.art == .aufgaben || $0.art == .zeit }?.id
                                                s.aufgabeZuordnen(id, ziel: neu, schritt: schritt, automatisch: false, heute: h)
                                            }
                                        },
                                        schrittWaehlen: { neu in
                                            let h = speicher.heute, zid = a.zielID
                                            speicher.aendern { $0.aufgabeZuordnen(id, ziel: zid, schritt: neu, automatisch: false, heute: h) }
                                        })
                            wann(a)
                            mehr(a)
                            notizen
                            loeschenKnoepfe(a)
                        }
                        .padding(Mass.rand).padding(.bottom, 24)
                        .frame(maxWidth: 720).frame(maxWidth: .infinity)
                    }
                    .background(Farbe.grund.ignoresSafeArea())
                } else {
                    ContentUnavailableView("Aufgabe nicht gefunden", systemImage: "checklist", description: Text("Sie wurde vielleicht gelöscht."))
                }
            }
            .navigationTitle("Aufgabe")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
    }

    // MARK: Teile

    private func kopf(_ a: Aufgabe) -> some View {
        let ziel = speicher.zustand.ziel(a.zielID)
        return Verlaufskarte(farben: ziel.map { Farbe.verlauf($0.farbe) } ?? Farbe.indigo) {
            HStack(alignment: .top, spacing: 12) {
                Button { speicher.aendern { $0.umschalten(id, jetzt: speicher.jetzt()) } } label: {
                    Image(systemName: a.erledigt ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(a.erledigt ? Farbe.seladon : .white.opacity(0.85))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(a.erledigt ? "Erledigt – zurücknehmen" : "Als erledigt abhaken")
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Titel", text: feld(\.titel), axis: .vertical)
                        .font(.kompass(.title3, .heavy)).strikethrough(a.erledigt)
                    Text(wannText(a)).font(.unterzeile).opacity(0.85)
                }
            }
            HStack(spacing: 8) {
                Button { speicher.aendern { s in setze(&s) { $0.prio = $0.prio == .hoch ? .normal : .hoch } } } label: {
                    Label(a.prio == .hoch ? "Wichtig" : "Normal", systemImage: a.prio == .hoch ? "star.fill" : "star")
                        .font(.kompass(.subheadline, .bold)).padding(.horizontal, 14).frame(minHeight: 40)
                        .background(.white.opacity(a.prio == .hoch ? 0.24 : 0.12), in: Capsule())
                        .foregroundStyle(a.prio == .hoch ? Farbe.gold : .white)
                }
                .buttonStyle(.plain)
                Button { nav.blatt = .fokus(a.id) } label: {
                    Label("Fokus", systemImage: "airplane.departure").font(.kompass(.subheadline, .bold))
                        .padding(.horizontal, 14).frame(minHeight: 40)
                        .background(Farbe.seladon, in: Capsule()).foregroundStyle(Farbe.nacht)
                }
                .buttonStyle(.plain)
                if a.fokusSekunden > 0 {
                    Text(Zahl.dauer(a.fokusSekunden) + " Fokus").font(.klein).opacity(0.85)
                }
            }
            .padding(.top, 8)
        }
    }

    private func wann(_ a: Aufgabe) -> some View {
        let T = speicher.heute
        let w: Wann = a.datum == nil ? .ohne : a.datum == T ? .heute : a.datum == T.plus(tage: 1) ? .morgen : .datum
        return Karte(titel: "Wann") {
            ChipReihe(titel: "Tag", auswahl: Wann.allCases.map { ($0.rawValue, $0 == w) }) { i in
                let neu: Tag? = switch Wann.allCases[i] {
                case .heute: T
                case .morgen: T.plus(tage: 1)
                case .datum: a.datum ?? T.plus(tage: 2)
                case .ohne: nil
                }
                speicher.aendern { s in setze(&s) { $0.datum = neu; if neu == nil { $0.uhrzeit = nil } } }
            }
            if let d = a.datum {
                if w == .datum {
                    DatePicker("Datum", selection: Binding(get: { d.datum() }, set: { neu in
                        let t = Tag(neu, kalender: speicher.kalender)
                        speicher.aendern { s in setze(&s) { $0.datum = t } }
                    }), displayedComponents: .date).font(.zeile)
                }
                ChipReihe(titel: "Uhrzeit", auswahl: [("keine", a.uhrzeit == nil)] + [9, 12, 15, 18].map { ("\($0):00", a.uhrzeit == $0 * 60) }) { i in
                    let u: Int? = i == 0 ? nil : [9, 12, 15, 18][i - 1] * 60
                    speicher.aendern { s in setze(&s) { $0.uhrzeit = u } }
                }
                if let u = a.uhrzeit {
                    DatePicker("Genau", selection: Binding(get: { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: u / 60, minute: u % 60)) ?? Date() }, set: { neu in
                        let k = Calendar.kompass.dateComponents([.hour, .minute], from: neu)
                        let m = (k.hour ?? 0) * 60 + (k.minute ?? 0)
                        speicher.aendern { s in setze(&s) { $0.uhrzeit = m } }
                    }), displayedComponents: .hourAndMinute).font(.zeile)
                    ChipReihe(titel: "Dauer", auswahl: [15, 30, 60, 90, 120].map { ($0 < 60 ? "\($0) Min" : $0 % 60 == 0 ? "\($0 / 60) h" : "1,5 h", $0 == a.dauer) }) { i in
                        let du = [15, 30, 60, 90, 120][i]
                        speicher.aendern { s in setze(&s) { $0.dauer = du } }
                    }
                }
            } else {
                Text("Liegt im Eingang. In den Kalender ziehen oder hier einen Tag wählen.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        }
    }

    private func mehr(_ a: Aufgabe) -> some View {
        Karte(titel: "Mehr") {
            ChipReihe(titel: "Wiederholen", auswahl: Wiederholung.allCases.map { ($0.name, $0 == a.wiederholung) }) { i in
                let w = Wiederholung.allCases[i]
                speicher.aendern { s in setze(&s) { $0.wiederholung = w } }
            }
            ChipReihe(titel: "Kategorie", auswahl: Kategorie.allCases.map { ($0.name, $0 == a.kategorie) }) { i in
                let k = Kategorie.allCases[i]
                speicher.aendern { s in setze(&s) { $0.kategorie = $0.kategorie == k ? nil : k } }
            }
        }
    }

    private var notizen: some View {
        Karte(titel: "Notizen") {
            TextField("Was gehört dazu?", text: feld(\.notizen), axis: .vertical).lineLimit(2...8).font(.zeile)
        }
    }

    private func loeschenKnoepfe(_ a: Aufgabe) -> some View {
        VStack(spacing: 4) {
            Button("Aufgabe löschen", role: .destructive) { loeschenFragen = true }
                .font(.kompass(.subheadline, .bold)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .confirmationDialog("Aufgabe löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
            if a.einmalig {
                Button("Löschen", role: .destructive) { speicher.aendern { $0.loeschen(id, heute: speicher.heute) }; dismiss() }
            } else {
                Button("Nur diese Aufgabe löschen", role: .destructive) { speicher.aendern { $0.loeschen(id, heute: speicher.heute) }; dismiss() }
                Button("Serie beenden", role: .destructive) { speicher.aendern { $0.loeschen(id, serieBeenden: true, heute: speicher.heute) }; dismiss() }
            }
        } message: { Text(a.einmalig ? "" : "Die Aufgabe wiederholt sich \(a.wiederholung.name.lowercased()).") }
    }

    private func wannText(_ a: Aufgabe) -> String {
        guard let d = a.datum else { return "Ohne Datum · im Eingang" }
        let T = speicher.heute
        var t = d == T ? "Heute" : d == T.plus(tage: 1) ? "Morgen" : d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
        if let u = a.uhrzeit { t += " · \(Tagesplan.uhr(u))–\(Tagesplan.uhr(u + a.dauer))" }
        if !a.einmalig { t += " · \(a.wiederholung.name.lowercased())" }
        return t
    }

    private func setze(_ s: inout Zustand, _ f: (inout Aufgabe) -> Void) {
        if let i = s.aufgaben.firstIndex(where: { $0.id == id }) { f(&s.aufgaben[i]) }
    }

    private func feld<W>(_ pfad: WritableKeyPath<Aufgabe, W>) -> Binding<W> {
        Binding(
            get: { speicher.zustand.aufgabe(id)![keyPath: pfad] },
            set: { neu in speicher.aendern { s in if let i = s.aufgaben.firstIndex(where: { $0.id == id }) { s.aufgaben[i][keyPath: pfad] = neu } } }
        )
    }

    /// Weiße Karte mit kleinem Titel
    private struct Karte<Inhalt: View>: View {
        var titel: String
        @ViewBuilder var inhalt: Inhalt
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(titel).font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text)
                inhalt
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

/// „Zählt für“: Ziel und Meilenstein wählen und in einem Satz sehen, ob und wie die Aufgabe zählt – und was fehlt.
/// Wird beim Bearbeiten und beim Anlegen genutzt.
struct ZaehltKarte: View {
    var zielID: UUID?
    var schrittID: UUID?
    var einmalig: Bool
    var aufgabeID: UUID?
    var zielWaehlen: (UUID?) -> Void
    var schrittWaehlen: (UUID?) -> Void
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let e = Einordnung.fuer(zielID: zielID, schrittID: schrittID, einmalig: einmalig, aufgabeID: aufgabeID, in: z)
        let ziele = z.ziele.filter { $0.status == .aktiv }
        let g = z.ziel(zielID)
        VStack(alignment: .leading, spacing: 12) {
            Text("Zählt für").font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text)
            if ziele.isEmpty {
                Text("Noch kein Ziel angelegt.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            } else {
                ChipReihe(titel: "Ziel", auswahl: [("Keins", zielID == nil)] + ziele.map { ($0.titel, $0.id == zielID) }) { i in
                    zielWaehlen(i == 0 ? nil : ziele[i - 1].id)
                }
            }
            if let g {
                let passend = g.schritte.filter { $0.art == .aufgaben || $0.art == .zeit }
                if !passend.isEmpty {
                    ChipReihe(titel: "Zählt in", auswahl: [("Nur Einsatz", schrittID == nil || !passend.contains { $0.id == schrittID })]
                              + passend.map { ("\($0.titel) · \($0.art == .zeit ? "Fokuszeit" : "erledigt")", $0.id == schrittID) }) { i in
                        schrittWaehlen(i == 0 ? nil : passend[i - 1].id)
                    }
                    .accessibilityIdentifier("aufgabe.meilenstein")
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: e.zaehlt ? "checkmark.seal.fill" : "info.circle.fill")
                    .font(.title3).foregroundStyle(e.zaehlt ? Farbe.akzent : Farbe.goldText)
                Text(e.satz).font(.unterzeile).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background((e.zaehlt ? Farbe.akzentWeich : Farbe.warnungGrund), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .accessibilityElement(children: .combine)
            if case .nurEinsatz(_, false) = e, let g {
                Button { nav.blatt = .meilenstein(ziel: g.id, schritt: nil) } label: {
                    Label("Meilenstein für „\(g.titel)“ anlegen", systemImage: "plus.circle.fill").font(.kompass(.subheadline, .bold))
                        .foregroundStyle(Farbe.akzent)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
