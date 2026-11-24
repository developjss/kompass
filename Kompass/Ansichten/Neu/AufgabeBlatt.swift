import SwiftUI

/// Aufgabe als Seite (Blattwerk, Hick): kurze Bühne mit dem Wort (Tag, darunter Uhrzeit oder offen) und dem startenden 747,
/// Karte vorn mit Haken, Titel und Fokus · Wichtig; „Zählt für“ (`Einordnung`, 3 + weitere), Wann in Stufen, Rest unter „Mehr“.
/// Alles wird sofort gespeichert.
struct AufgabeBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false
    @State private var mehr = false
    @State private var genau = false

    private enum Wann: String, CaseIterable { case heute = "Heute", morgen = "Morgen", datum = "Datum", ohne = "Ohne Datum" }
    private let tageszeiten = [("Vormittag", 9 * 60), ("Nachmittag", 14 * 60), ("Abend", 18 * 60)]

    var body: some View {
        Group {
            if let a = speicher.zustand.aufgabe(id) {
                BuehnenSeite(hoehe: Mass.buehneKurz, wort: wort(a), objekt: .b747Abflug, platz: .aufgabe, marke: {
                    RahmenKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
                    MarkenTitel(text: "Aufgabe")
                    Spacer(minLength: 8)
                    if a.prio == .hoch { MarkenHinweis(text: "wichtig") }
                    RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.heute) }
                }) {
                    kopf(a)
                    VStack(alignment: .leading, spacing: 12) {
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
                        MehrKnopf(offen: $mehr, zu: "Mehr: Wiederholen, Kategorie, Notizen")
                        if mehr {
                            mehrKarte(a)
                            notizen
                            Button("Aufgabe löschen") { loeschenFragen = true }.buttonStyle(.rotBreit)
                        }
                    }
                    .padding(.horizontal, Mass.rand).padding(.top, 12)
                }
                .confirmationDialog("Aufgabe löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                    if a.einmalig {
                        Button("Löschen", role: .destructive) { speicher.aendern { $0.loeschen(id, heute: speicher.heute) }; dismiss() }
                    } else {
                        Button("Nur diese Aufgabe löschen", role: .destructive) { speicher.aendern { $0.loeschen(id, heute: speicher.heute) }; dismiss() }
                        Button("Serie beenden", role: .destructive) { speicher.aendern { $0.loeschen(id, serieBeenden: true, heute: speicher.heute) }; dismiss() }
                    }
                } message: { Text(a.einmalig ? "" : "Die Aufgabe wiederholt sich \(a.wiederholung.name.lowercased()).") }
            } else {
                ContentUnavailableView("Aufgabe nicht gefunden", systemImage: "checklist", description: Text("Sie wurde vielleicht gelöscht."))
                    .background(Farbe.grund.ignoresSafeArea())
            }
        }
        .presentationDetents([.large])
    }

    // MARK: Teile

    private func wort(_ a: Aufgabe) -> Wort {
        let T = speicher.heute
        let tag: String = a.datum == nil ? "Eingang" : a.datum == T ? "Heute" : a.datum == T.plus(tage: 1) ? "Morgen" : a.datum! < T ? "Überfällig"
            : a.datum!.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
        let akzent = a.erledigt ? "erledigt." : a.uhrzeit.map { Tagesplan.uhr($0) + "." } ?? "offen."
        return Wort(zeilen: [tag], akzent: akzent, groesse: Wort.kleinGroesse)
    }

    private func kopf(_ a: Aufgabe) -> some View {
        VornKarte {
            HStack(alignment: .top, spacing: 10) {
                Haken(an: a.erledigt, farbe: Farbe.handlung, groesse: 28, beschriftung: a.titel) { speicher.aendern { $0.umschalten(id, jetzt: speicher.jetzt()) } }
                    .padding(.top, -6)
                TextField("Titel", text: feld(\.titel), axis: .vertical)
                    .font(.karteTitel).foregroundStyle(Farbe.text).strikethrough(a.erledigt).lineLimit(1...3)
            }
            Etikett(text: wannText(a))
            HStack(spacing: 8) {
                Button { nav.blatt = .fokus(a.id) } label: { Label("Fokus starten", systemImage: "play.fill") }.buttonStyle(.haupt)
                Button { speicher.aendern { s in setze(&s) { $0.prio = $0.prio == .hoch ? .normal : .hoch } } } label: {
                    Label("Wichtig", systemImage: a.prio == .hoch ? "star.fill" : "star")
                }
                .buttonStyle(.leise)
                .accessibilityValue(a.prio == .hoch ? "an" : "aus")
            }
            .padding(.top, 4)
            if a.fokusSekunden > 0 {
                Text(Zahl.dauer(a.fokusSekunden) + " Fokus bisher").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
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
                let u = a.uhrzeit
                ChipReihe(titel: "Uhrzeit (optional)", auswahl: tageszeiten.map { ($0.0, u == $0.1 && !genau) } + [("genau", u != nil && (genau || !tageszeiten.contains { $0.1 == u }))]) { i in
                    if i < tageszeiten.count {
                        let neu = tageszeiten[i].1
                        let aus = u == neu && !genau
                        genau = false
                        speicher.aendern { s in setze(&s) { $0.uhrzeit = aus ? nil : neu } }
                    } else if u != nil && (genau || !tageszeiten.contains { $0.1 == u }) {
                        genau = false
                        speicher.aendern { s in setze(&s) { $0.uhrzeit = nil } }
                    } else {
                        genau = true
                        if u == nil { speicher.aendern { s in setze(&s) { $0.uhrzeit = 10 * 60 } } }
                    }
                }
                if let u, genau || !tageszeiten.contains(where: { $0.1 == u }) {
                    DatePicker("Genau", selection: Binding(get: { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: u / 60, minute: u % 60)) ?? Date() }, set: { neu in
                        let k = Calendar.kompass.dateComponents([.hour, .minute], from: neu)
                        let m = (k.hour ?? 0) * 60 + (k.minute ?? 0)
                        speicher.aendern { s in setze(&s) { $0.uhrzeit = m } }
                    }), displayedComponents: .hourAndMinute).font(.zeile)
                }
                if a.uhrzeit != nil {
                    ChipReihe(titel: "Dauer", auswahl: [15, 30, 60, 90].map { ($0 < 60 ? "\($0) Min" : $0 % 60 == 0 ? "\($0 / 60) h" : "1,5 h", $0 == a.dauer) }) { i in
                        let du = [15, 30, 60, 90][i]
                        speicher.aendern { s in setze(&s) { $0.dauer = du } }
                    }
                }
            } else {
                Text("Liegt im Eingang. Der Kalender schlägt sie vor – oder hier einen Tag wählen.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        }
    }

    private func mehrKarte(_ a: Aufgabe) -> some View {
        Karte(titel: "Wiederholen und Kategorie") {
            ChipReihe(titel: "Wiederholen", auswahl: Wiederholung.allCases.map { ($0.name, $0 == a.wiederholung) }) { i in
                let w = Wiederholung.allCases[i]
                speicher.aendern { s in setze(&s) { $0.wiederholung = w } }
            }
            ChipReihe(titel: "Kategorie (Farbe ohne Ziel)", auswahl: Kategorie.allCases.map { ($0.name, $0 == a.kategorie) }, grenze: 3) { i in
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

    private func wannText(_ a: Aufgabe) -> String {
        guard let d = a.datum else { return "Ohne Datum · im Eingang" }
        let T = speicher.heute
        var t = d == T ? "Heute" : d == T.plus(tage: 1) ? "Morgen" : d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
        if let u = a.uhrzeit { t += " · \(Tagesplan.uhr(u))–\(Tagesplan.uhr(u + a.dauer))" } else { t += " · \(a.dauer) min" }
        if !a.einmalig { t += " · \(a.wiederholung.name.lowercased())" }
        if let g = speicher.zustand.ziel(a.zielID) { t += " · \(g.titel)" }
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
                Etikett(text: titel)
                inhalt
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Mass.karte, style: .continuous).strokeBorder(Farbe.linie, lineWidth: 1))
        }
    }
}

/// „Zählt für“: Ziel und Meilenstein wählen (je 3 + weitere) und in einem Satz sehen, ob und wie die Aufgabe zählt – und was fehlt.
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
            Etikett(text: "Zählt für")
            if ziele.isEmpty {
                Text("Noch kein Ziel angelegt.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            } else {
                ChipReihe(titel: "Ziel", auswahl: [("Keins", zielID == nil)] + ziele.map { ($0.titel, $0.id == zielID) }, grenze: 4) { i in
                    zielWaehlen(i == 0 ? nil : ziele[i - 1].id)
                }
            }
            if let g {
                let passend = g.schritte.filter { $0.art == .aufgaben || $0.art == .zeit }
                if !passend.isEmpty {
                    ChipReihe(titel: "Meilenstein", auswahl: [("Nur Einsatz", schrittID == nil || !passend.contains { $0.id == schrittID })]
                              + passend.map { ("\($0.titel) · \($0.art == .zeit ? "Fokuszeit" : "erledigt")", $0.id == schrittID) }, grenze: 4) { i in
                        schrittWaehlen(i == 0 ? nil : passend[i - 1].id)
                    }
                    .accessibilityIdentifier("aufgabe.meilenstein")
                }
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: e.zaehlt ? "checkmark.seal.fill" : "info.circle.fill")
                    .font(.title3).foregroundStyle(e.zaehlt ? Farbe.akzent : Farbe.warnung)
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
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Mass.karte, style: .continuous).strokeBorder(Farbe.linie, lineWidth: 1))
    }
}
