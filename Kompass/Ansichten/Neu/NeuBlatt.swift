import SwiftUI

/// Anlegen: Aufgabe, Termin, Habit oder Ziel – ein Bildschirm, Chips statt Räder (Struktur v3).
struct NeuBlatt: View {
    @State var art: NeuArt
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var mitUhrzeit = false
    @State private var uhrzeit = 9 * 60
    @State private var dauer = 60
    @State private var kategorie: Kategorie?
    @State private var habitUhrzeit: Int?

    @State private var titel = ""
    @State private var datum = Date()
    @State private var mitDatum = true
    @State private var wichtig = false
    @State private var zielID: UUID?
    @State private var wiederholung: Wiederholung = .nie
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var rhythmusArt: RhythmusArt = .taeglich
    @State private var proWoche = 3
    @State private var mitMenge = false
    @State private var menge: Double = 20
    @State private var habitEinheit: Einheit = .minuten
    @State private var erinnerung: Int? = nil
    @State private var vorschlagGenutzt = false
    @State private var symbol = "star.fill"

    enum RhythmusArt: String, CaseIterable { case taeglich = "Täglich", werktags = "Werktags", tage = "Wochentage", proWoche = "n-mal pro Woche" }
    @State private var faellig = Calendar.kompass.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    /// Gewählte Meilenstein-Vorlage (Index in `ZielVorschlag.fuer(titel)`); nil = ohne Meilensteine
    @State private var vorlage: Int? = 0
    @State private var start = 0.0
    @State private var zielwert = 100.0
    @State private var einheit = ""
    @State private var zahlAngefasst = false

    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Was", selection: $art) {
                    Text("Aufgabe").tag(NeuArt.aufgabe)
                    Text("Termin").tag(NeuArt.termin)
                    Text("Habit").tag(NeuArt.habit)
                    Text("Ziel").tag(NeuArt.ziel)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .onChange(of: art) { _, neu in
                    if neu == .termin { nav.blatt = .termin(nil, tag: speicher.heute.text, start: nil) }
                }

                Section { TextField(platzhalter, text: $titel) }

                switch art {
                case .aufgabe:
                    Section {
                        Toggle("Mit Datum", isOn: $mitDatum)
                        if mitDatum {
                            DatePicker("Datum", selection: $datum, displayedComponents: .date)
                            Toggle("Mit Uhrzeit", isOn: $mitUhrzeit)
                            if mitUhrzeit {
                                DatePicker("Uhrzeit", selection: Binding(get: { uhr(uhrzeit) }, set: { uhrzeit = minuten($0) }), displayedComponents: .hourAndMinute)
                                ChipReihe(titel: "Dauer", auswahl: [15, 30, 60, 90, 120].map { (dauerText($0), $0 == dauer) }) { dauer = [15, 30, 60, 90, 120][$0] }
                            }
                        }
                    } footer: { Text(mitDatum ? (mitUhrzeit ? "Steht als Block im Kalender." : "Steht am Tag unter „Ohne Uhrzeit“ – ziehbar in den Kalender.") : "Landet im Eingang.") }
                    Section {
                        Toggle("Wichtig", isOn: $wichtig)
                        Picker("Wiederholen", selection: $wiederholung) {
                            ForEach(Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                        zielPicker
                        ChipReihe(titel: "Kategorie", auswahl: Kategorie.allCases.map { ($0.name, $0 == kategorie) }) { i in
                            let k = Kategorie.allCases[i]; kategorie = kategorie == k ? nil : k
                        }
                    }
                case .termin:
                    EmptyView()
                case .habit:
                    habitTeil
                case .ziel:
                    zielTeil
                }
            }
            .navigationTitle("Neu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen", action: anlegen).disabled(titel.trimmingCharacters(in: .whitespaces).isEmpty || (art == .habit && rhythmusArt == .tage && tage.isEmpty) || (art == .habit && mitMenge && menge <= 0))
                }
            }
        }
    }

    // MARK: Ziel – Datum und Meilenstein-Vorlagen aus dem Titel (habits-v2.md §9)

    private var vorlagen: [ZielVorschlag.Vorlage] { ZielVorschlag.fuer(titel) }
    private var gewaehlteVorlage: ZielVorschlag.Vorlage? { vorlage.flatMap { $0 < vorlagen.count ? vorlagen[$0] : nil } }
    private var zahlSchritt: Schritt? { gewaehlteVorlage?.schritte.first { $0.art == .zahl } }

    @ViewBuilder private var zielTeil: some View {
        let v = vorlagen
        Section {
            DatePicker("Bis wann", selection: $faellig, displayedComponents: .date)
        }
        Section {
            ChipReihe(titel: "Meilensteine", auswahl: v.map { ($0.name, false) }.enumerated().map { ($0.element.0, vorlage == $0.offset) } + [("Ohne", vorlage == nil)]) { i in
                vorlage = i < v.count ? i : nil
                zahlAngefasst = false
            }
            if let zs = zahlSchritt {
                let e = zahlAngefasst ? einheit : (zs.einheit ?? "")
                LabeledContent("Start") { TextField("0", value: Binding(get: { zahlAngefasst ? start : (zs.start ?? 0) }, set: { zahlAnfassen(zs); start = $0 }), format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                LabeledContent("Ziel") { TextField("100", value: Binding(get: { zahlAngefasst ? zielwert : (zs.soll ?? 100) }, set: { zahlAnfassen(zs); zielwert = $0 }), format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                TextField("Einheit (z. B. kg, €)", text: Binding(get: { e }, set: { zahlAnfassen(zs); einheit = $0 }))
            }
        } footer: {
            Text(gewaehlteVorlage.map { "\(vorlagen.count > 1 ? "Aus deinem Titel" : "Vorlage"): \($0.kurz). Im Ziel änderst du alles." } ?? "Meilensteine legst du danach im Ziel an.")
        }
    }

    private func zahlAnfassen(_ zs: Schritt) {
        guard !zahlAngefasst else { return }
        zahlAngefasst = true
        start = zs.start ?? 0; zielwert = zs.soll ?? 100; einheit = zs.einheit ?? ""
    }

    // MARK: Habit – Menge, Einheit, Rhythmus, Erinnerung als Chips (habits-v2.md §7)

    private var vorschlag: HabitVorschlag.Vorschlag { HabitVorschlag.fuer(titel) }

    @ViewBuilder private var habitTeil: some View {
        let v = vorschlag
        if !vorschlagGenutzt, !titel.trimmingCharacters(in: .whitespaces).isEmpty, v.einheit != nil || v.nurAbhaken {
            Section {
                Button {
                    vorschlagUebernehmen(v)
                } label: {
                    Label(v.nurAbhaken ? "Vorschlag: einfach abhaken" : "Vorschlag: \(Zahl.text(v.menge ?? 0)) \(v.einheit?.name ?? "") pro Tag", systemImage: "sparkles")
                }
            } footer: { Text("Aus deinem Titel abgeleitet – antippen übernimmt.") }
        }
        Section {
            Toggle("Mit Menge", isOn: $mitMenge)
            if mitMenge {
                LabeledContent("Soll pro Tag") {
                    TextField("20", value: $menge, format: .number.locale(Locale(identifier: "de_DE"))).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                ChipReihe(titel: "Einheit", auswahl: Einheit.allCases.map { ($0.name, $0 == habitEinheit) }) { habitEinheit = Einheit.allCases[$0] }
            }
        } footer: {
            Text(mitMenge ? "Teilmengen zählen anteilig: 10 von 20 Minuten = halb." : "Ohne Menge hakst du den Habit einfach ab.")
        }
        Section {
            ChipReihe(titel: "Wie oft", auswahl: RhythmusArt.allCases.map { ($0.rawValue, $0 == rhythmusArt) }) { rhythmusArt = RhythmusArt.allCases[$0] }
            if rhythmusArt == .tage {
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { d in
                        Button(namen[d - 1]) { if tage.contains(d) { tage.remove(d) } else { tage.insert(d) } }
                            .buttonStyle(.bordered).tint(tage.contains(d) ? Farbe.akzent : .gray)
                            .accessibilityAddTraits(tage.contains(d) ? .isSelected : [])
                    }
                }
            }
            if rhythmusArt == .proWoche { Stepper("\(proWoche)× pro Woche", value: $proWoche, in: 1...7) }
        }
        Section {
            ChipReihe(titel: "Feste Uhrzeit im Kalender", auswahl: [("keine", habitUhrzeit == nil)] + [7, 12, 18, 21].map { ("\($0):00", habitUhrzeit == $0 * 60) }) { i in
                habitUhrzeit = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
            }
            if habitUhrzeit != nil {
                DatePicker("Uhrzeit", selection: Binding(get: { uhr(habitUhrzeit ?? 0) }, set: { habitUhrzeit = minuten($0) }), displayedComponents: .hourAndMinute)
            }
        } footer: { Text(habitUhrzeit == nil ? "Ohne Uhrzeit steht der Habit am Tag unter „Ohne Uhrzeit“." : "Steht als Block im Kalender und unter „Als Nächstes“.") }
        Section {
            ChipReihe(titel: "Erinnerung", auswahl: [("aus", erinnerung == nil)] + [7, 12, 18, 21].map { ("\($0):00", erinnerung == $0 * 60) }) { i in
                erinnerung = i == 0 ? nil : [7, 12, 18, 21][i - 1] * 60
            }
            if erinnerung != nil {
                DatePicker("Uhrzeit", selection: Binding(get: { uhr(erinnerung ?? 0) }, set: { erinnerung = minuten($0) }), displayedComponents: .hourAndMinute)
            }
        } footer: { Text("Zur Uhrzeit kommt eine Mitteilung, solange der Habit offen ist. Beim ersten Mal fragt die App um Erlaubnis.") }
        Section { zielPicker }
    }

    private func vorschlagUebernehmen(_ v: HabitVorschlag.Vorschlag) {
        vorschlagGenutzt = true
        symbol = v.symbol
        if v.nurAbhaken { mitMenge = false; return }
        mitMenge = true
        if let m = v.menge { menge = m }
        if let e = v.einheit { habitEinheit = e }
    }

    private func uhr(_ m: Int) -> Date { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: m / 60, minute: m % 60)) ?? Date() }
    private func minuten(_ d: Date) -> Int { let k = Calendar.kompass.dateComponents([.hour, .minute], from: d); return (k.hour ?? 0) * 60 + (k.minute ?? 0) }

    private var habitRhythmus: Rhythmus {
        switch rhythmusArt {
        case .taeglich: .taeglich
        case .werktags: .wochentage([1, 2, 3, 4, 5])
        case .tage: .aus(tagen: tage)
        case .proWoche: .proWoche(proWoche)
        }
    }

    private func dauerText(_ m: Int) -> String { m < 60 ? "\(m) Min" : m % 60 == 0 ? "\(m / 60) h" : "\(m / 60),5 h" }

    private var platzhalter: String {
        switch art {
        case .termin: "Termin"
        case .aufgabe: "Was ist zu tun?"
        case .habit: "z. B. 20 Minuten lesen"
        case .ziel: "z. B. Halbmarathon laufen"
        }
    }

    private var zielPicker: some View {
        Picker("Ziel", selection: $zielID) {
            Text("Keins").tag(UUID?.none)
            ForEach(speicher.zustand.ziele.filter { $0.status == .aktiv }) { Text($0.titel).tag(UUID?.some($0.id)) }
        }
    }

    private func anlegen() {
        let t = titel.trimmingCharacters(in: .whitespaces)
        let k = speicher.kalender
        let heute = speicher.heute
        switch art {
        case .aufgabe:
            let tag = mitDatum ? Tag(datum, kalender: k) : nil
            let w = wiederholung, z = zielID, p: Prioritaet = wichtig ? .hoch : .normal
            let u = mitDatum && mitUhrzeit ? uhrzeit : nil, du = dauer, k = kategorie
            speicher.aendern { s in
                let a = s.aufgabeAnlegen(t, datum: tag, prio: p, zielID: z, heute: heute)
                if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) {
                    s.aufgaben[i].wiederholung = w; s.aufgaben[i].uhrzeit = u; s.aufgaben[i].dauer = du; s.aufgaben[i].kategorie = k
                }
            }
        case .habit:
            let farbe = Farbe.ziele[speicher.zustand.habits.count % Farbe.ziele.count]
            let v = vorschlag
            var h = Habit(titel: t, farbe: farbe, symbol: vorschlagGenutzt ? symbol : (v.symbol == "star.fill" ? "star.fill" : v.symbol),
                          rhythmus: habitRhythmus, menge: mitMenge ? menge : nil, einheit: mitMenge ? habitEinheit : nil,
                          erinnerung: erinnerung, zielID: zielID, angelegt: heute)
            h.uhrzeit = habitUhrzeit
            if h.erinnerung != nil {
                Task { await Erinnerungen.aktiv.erlaubnis(); speicher.aendern { $0.habits.append(h) } }
            } else {
                speicher.aendern { $0.habits.append(h) }
            }
        case .termin:
            break
        case .ziel:
            let farbe = Farbe.ziele[speicher.zustand.ziele.count % Farbe.ziele.count]
            let vl = gewaehlteVorlage
            var g = Ziel(titel: t, farbe: farbe, symbol: vl?.symbol ?? "target", bereich: vl?.bereich ?? "Allgemein", faellig: Tag(faellig, kalender: k), angelegt: heute)
            g.schritte = (vl?.schritte ?? []).map { s in
                var s = s
                if s.art == .zahl {
                    if zahlAngefasst { s.start = start; s.soll = zielwert; s.einheit = einheit.isEmpty ? nil : einheit }
                    s.aktuell = s.start
                    s.verlauf = s.start.map { [VerlaufPunkt(tag: heute, wert: $0)] }
                }
                if s.art == .habit { s.seit = heute }
                return s
            }
            speicher.aendern { $0.ziele.append(g) }
        }
        dismiss()
    }
}

/// Aufgabe bearbeiten: Titel, Datum, Wichtig, Wiederholung, Ziel, Notizen; Löschen (nur diese / Serie beenden).
struct AufgabeBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let a = speicher.zustand.aufgabe(id) {
                Form {
                    Section {
                        TextField("Titel", text: feld(\.titel))
                        Toggle("Erledigt", isOn: Binding(get: { a.erledigt }, set: { _ in speicher.aendern { $0.umschalten(id, jetzt: speicher.jetzt()) } }))
                        Toggle("Wichtig", isOn: Binding(get: { a.prio == .hoch }, set: { neu in speicher.aendern { s in setze(&s) { $0.prio = neu ? .hoch : .normal } } }))
                    }
                    Section {
                        Toggle("Mit Datum", isOn: Binding(get: { a.datum != nil }, set: { neu in
                            let h = speicher.heute
                            speicher.aendern { s in setze(&s) { $0.datum = neu ? h : nil } }
                        }))
                        if let d = a.datum {
                            DatePicker("Datum", selection: Binding(get: { d.datum() }, set: { neu in
                                let t = Tag(neu, kalender: speicher.kalender)
                                speicher.aendern { s in setze(&s) { $0.datum = t } }
                            }), displayedComponents: .date)
                        }
                        Picker("Wiederholen", selection: feld(\.wiederholung)) {
                            ForEach(Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                        Picker("Ziel", selection: Binding(get: { a.zielID }, set: { neu in
                            let h = speicher.heute
                            speicher.aendern { s in
                                let schritt = Fortschritt.naechsterOffenerSchritt(s.ziel(neu), in: s, heute: h)?.id
                                setze(&s) { $0.zielID = neu; $0.schrittID = schritt }
                            }
                        })) {
                            Text("Keins").tag(UUID?.none)
                            ForEach(speicher.zustand.ziele) { Text($0.titel).tag(UUID?.some($0.id)) }
                        }
                        if a.fokusSekunden > 0 { LabeledContent("Fokuszeit", value: Zahl.dauer(a.fokusSekunden)) }
                    }
                    Section("Notizen") { TextField("Notizen", text: feld(\.notizen), axis: .vertical) }
                    Section {
                        Button("Löschen", role: .destructive) {
                            speicher.aendern { $0.loeschen(id, heute: speicher.heute) }
                            dismiss()
                        }
                        if !a.einmalig {
                            Button("Serie beenden", role: .destructive) {
                                speicher.aendern { $0.loeschen(id, serieBeenden: true, heute: speicher.heute) }
                                dismiss()
                            }
                        }
                    }
                }
                .navigationTitle("Aufgabe")
                .navigationBarTitleDisplayMode(.inline)
                .schliessenKnopf()
            } else {
                ContentUnavailableView("Aufgabe nicht gefunden", systemImage: "checklist", description: Text("Sie wurde vielleicht gelöscht."))
            }
        }
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
}


/// Auswahl als Chips in einer Zeile (umbrechend) – wie „How often“ in Gapless statt Picker-Rad.
struct ChipReihe: View {
    var titel: String
    /// (Text, gewählt)
    var auswahl: [(String, Bool)]
    var waehlen: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titel).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            FliessLayout(abstand: 8) {
                ForEach(Array(auswahl.enumerated()), id: \.offset) { i, a in
                    Button { waehlen(i) } label: {
                        Text(a.0).font(.kompass(.subheadline, .semibold))
                            .padding(.horizontal, 12).frame(minHeight: 36)
                            .background(a.1 ? Farbe.akzent : Farbe.akzentWeich, in: Capsule())
                            .foregroundStyle(a.1 ? .white : Farbe.akzent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(a.1 ? .isSelected : [])
                }
            }
        }
        .padding(.vertical, 4)
    }
}

/// Einfaches umbrechendes Layout für Chips.
struct FliessLayout: Layout {
    var abstand: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let breite = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, zeile: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > 0, x + g.width > breite { x = 0; y += zeile + abstand; zeile = 0 }
            x += g.width + abstand
            zeile = max(zeile, g.height)
        }
        return CGSize(width: breite, height: y + zeile)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, zeile: CGFloat = 0
        for s in subviews {
            let g = s.sizeThatFits(.unspecified)
            if x > bounds.minX, x + g.width > bounds.maxX { x = bounds.minX; y += zeile + abstand; zeile = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(g))
            x += g.width + abstand
            zeile = max(zeile, g.height)
        }
    }
}
