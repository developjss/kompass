import SwiftUI

// Fenster rund um ein Ziel: Meilenstein anlegen/bearbeiten, Habit/Aufgabe/Termin hinzufügen, Ziel bearbeiten, „So wird gerechnet“.

private let de = Locale(identifier: "de_DE")

// MARK: Habit hinzufügen

struct HabitZuZielBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var neu = false
    @State private var gewaehlt: UUID?
    @State private var titel = ""
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var zaehlt = true
    @State private var modus: HabitModus = .wochen
    @State private var soll: Double = 8
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let frei = z.habits.filter { h in h.zielID != zielID }
        NavigationStack {
            Form {
                Picker("", selection: $neu) {
                    Text("Bestehender").tag(false)
                    Text("Neuer").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if neu {
                    Section {
                        TextField("z. B. 20 Minuten lesen", text: $titel)
                        HStack(spacing: 4) {
                            ForEach(1...7, id: \.self) { d in
                                Button(namen[d - 1]) { if tage.contains(d) { tage.remove(d) } else { tage.insert(d) } }
                                    .buttonStyle(.bordered).tint(tage.contains(d) ? Farbe.akzent : .gray)
                                    .accessibilityAddTraits(tage.contains(d) ? .isSelected : [])
                            }
                        }
                    }
                } else {
                    Section {
                        if frei.isEmpty { Text("Alle Habits hängen schon an diesem Ziel.").foregroundStyle(.secondary) }
                        ForEach(frei) { h in
                            Button { gewaehlt = h.id; vorschlag(h) } label: {
                                HStack {
                                    Text(h.titel).foregroundStyle(Farbe.text)
                                    Spacer()
                                    if gewaehlt == h.id { Image(systemName: "checkmark").foregroundStyle(Farbe.akzent) }
                                }
                            }
                        }
                    }
                }

                Section {
                    Toggle("Zählt in die Prozente", isOn: $zaehlt)
                    if zaehlt {
                        Picker("Zählen", selection: $modus) {
                            ForEach(HabitModus.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                        .onChange(of: modus) { _, _ in if let h = z.habit(gewaehlt) { vorschlag(h) } }
                        LabeledContent(modus == .wochen ? "Soll-Wochen" : "Soll-Anzahl") {
                            TextField("", value: $soll, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad)
                        }
                    }
                } footer: {
                    Text(zaehlt ? "Wird als Meilenstein angelegt. Vorschlag aus deinem bisherigen Verlauf." : "Erscheint im Ziel als Einsatz, ohne die Prozente zu ändern.")
                }
            }
            .navigationTitle("Habit zum Ziel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        let n = neu, t = titel.trimmingCharacters(in: .whitespaces), d = tage, m: HabitModus? = zaehlt ? modus : nil, so = soll, wahl = gewaehlt, zid = zielID
                        speicher.aendern { s in
                            var hid = wahl
                            if n {
                                let h = Habit(titel: t, farbe: s.ziel(zid)?.farbe ?? Farbe.ziele[0], symbol: "star.fill", wochentage: d, zielID: zid, angelegt: T)
                                s.habits.append(h)
                                hid = h.id
                            }
                            if let hid { s.habitVerknuepfen(hid, ziel: zid, alsMeilenstein: m, soll: so, heute: T) }
                        }
                        dismiss()
                    }
                    .disabled(neu ? titel.trimmingCharacters(in: .whitespaces).isEmpty || tage.isEmpty : gewaehlt == nil || (zaehlt && soll <= 0))
                }
            }
        }
    }

    private func vorschlag(_ h: Habit) {
        guard let g = speicher.zustand.ziel(zielID) else { return }
        soll = modus == .wochen ? LernRechnung.vorschlagWochen(h, heute: speicher.heute, bis: g.faellig)
                                : LernRechnung.vorschlagAnzahl(h, heute: speicher.heute, bis: g.faellig)
    }
}

// MARK: Bestehende Aufgabe hinzufügen

struct AufgabeZuZielBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var gewaehlt: Set<UUID> = []
    @State private var schritt: UUID?
    @State private var suche = ""

    var body: some View {
        let z = speicher.zustand
        let g = z.ziel(zielID)
        let liste = z.aufgaben.filter { !$0.erledigt && $0.zielID != zielID && (suche.isEmpty || $0.titel.localizedCaseInsensitiveContains(suche)) }
        NavigationStack {
            Form {
                Section {
                    Picker("Zählt für", selection: $schritt) {
                        Text("Nächsten offenen Meilenstein").tag(UUID?.none)
                        ForEach(g?.schritte.filter { $0.art == .aufgaben || $0.art == .zeit } ?? []) { Text($0.titel).tag(UUID?.some($0.id)) }
                    }
                }
                Section {
                    if liste.isEmpty { Text("Keine offenen Aufgaben ohne dieses Ziel.").foregroundStyle(.secondary) }
                    ForEach(liste) { a in
                        Button {
                            if gewaehlt.contains(a.id) { gewaehlt.remove(a.id) } else { gewaehlt.insert(a.id) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(a.titel).foregroundStyle(Farbe.text)
                                    if let anderes = z.ziel(a.zielID) { Text("jetzt: \(anderes.titel)").font(.footnote).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                if gewaehlt.contains(a.id) { Image(systemName: "checkmark").foregroundStyle(Farbe.akzent) }
                            }
                        }
                    }
                }
            }
            .searchable(text: $suche, prompt: "Aufgaben suchen")
            .navigationTitle("Aufgaben zum Ziel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        let ids = gewaehlt, s = schritt, zid = zielID, T = speicher.heute
                        speicher.aendern { st in for id in ids { st.aufgabeZuordnen(id, ziel: zid, schritt: s, heute: T) } }
                        dismiss()
                    }
                    .disabled(gewaehlt.isEmpty)
                }
            }
        }
    }
}

// MARK: Termin-Serie hinzufügen

struct TerminZuZielBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var serie: String?
    @State private var schritt: UUID?
    @State private var rueckwirkend = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let e = z.einstellungen
        let serien = Beispieltermine.serien(google: e.googleBeispiel, apple: e.appleBeispiel, heute: T)
        let g = z.ziel(zielID)
        let passend = g?.schritte.filter { $0.art == .zeit || ($0.art == .zahl && ($0.soll ?? 0) > ($0.start ?? 0)) } ?? []
        NavigationStack {
            Form {
                if serien.isEmpty {
                    Section {
                        Text("Kein Kalender verbunden.")
                        Button("Kalender verbinden") { nav.blatt = .einstellungen }
                    }
                } else {
                    Section("Termin-Serie") {
                        ForEach(serien, id: \.serie) { s in
                            Button { serie = s.serie } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(s.titel).foregroundStyle(Farbe.text)
                                        Text(s.wann).font(.footnote).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if serie == s.serie { Image(systemName: "checkmark").foregroundStyle(Farbe.akzent) }
                                }
                            }
                        }
                    }
                    Section {
                        Picker("Zählt in", selection: $schritt) {
                            Text("Nur Einsatz").tag(UUID?.none)
                            ForEach(passend) { Text($0.titel).tag(UUID?.some($0.id)) }
                        }
                        Toggle("Letzte 4 Wochen mitzählen", isOn: $rueckwirkend)
                    } footer: {
                        Text("Nur stattgefundene Termine zählen: bei Zeit die Dauer, bei Zahl je 1. Gespeichert werden nur Tag und Dauer.")
                    }
                }
            }
            .navigationTitle("Termine zum Ziel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        guard let s = serien.first(where: { $0.serie == serie }) else { return }
                        let zid = zielID, sid = schritt, seit = rueckwirkend ? T.plus(tage: -28) : T
                        speicher.aendern { $0.terminVerknuepfen(serie: s.serie, titel: s.titel, ziel: zid, schritt: sid, seit: seit) }
                        dismiss()
                    }
                    .disabled(serie == nil)
                }
            }
        }
    }
}

// MARK: Ziel bearbeiten

/// Editor für genau eine Fakten-Zeile der Ziel-Seite (Titel, Bis wann, Bereich, Warum, Aussehen).
struct ZielBearbeitenBlatt: View {
    var zielID: UUID
    var feld: ZielFeld
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var g: Ziel?

    private let symbole = ["target", "graduationcap.fill", "car.fill", "airplane", "figure.run", "eurosign.circle.fill", "book.fill", "house.fill",
                           "heart.fill", "briefcase.fill", "hammer.fill", "character.book.closed.fill", "globe.europe.africa.fill", "music.note", "star.fill", "leaf.fill"]

    var body: some View {
        NavigationStack {
            Form {
                if g != nil {
                    switch feld {
                    case .titel:
                        Section { TextField("Titel", text: Binding(get: { g?.titel ?? "" }, set: { g?.titel = $0 })) }
                    case .faellig:
                        Section {
                            DatePicker("Bis wann", selection: Binding(get: { g?.faellig.datum() ?? Date() }, set: { g?.faellig = Tag($0, kalender: speicher.kalender) }), displayedComponents: .date)
                        } footer: { Text("„Auf Kurs“ vergleicht den Fortschritt mit der Zeit von der Anlage bis zu diesem Datum.") }
                    case .bereich:
                        Section {
                            TextField("Bereich", text: Binding(get: { g?.bereich ?? "" }, set: { g?.bereich = $0 }))
                            ChipReihe(titel: "Häufig", auswahl: ["Lernen", "Gesundheit", "Finanzen", "Arbeit", "Familie", "Allgemein"].map { ($0, $0 == g?.bereich) }) { i in
                                g?.bereich = ["Lernen", "Gesundheit", "Finanzen", "Arbeit", "Familie", "Allgemein"][i]
                            }
                        }
                    case .warum:
                        Section {
                            TextField("Warum ist dir das wichtig?", text: Binding(get: { g?.warum ?? "" }, set: { g?.warum = $0 }), axis: .vertical).lineLimit(3...6)
                        } footer: { Text("Steht unter der Kopfkarte – ein Satz reicht.") }
                    case .aussehen:
                        Section("Farbe") {
                            FliessLayout(abstand: 8) {
                                ForEach(Farbe.ziele, id: \.self) { f in
                                    Button { g?.farbe = f } label: {
                                        Circle().fill(Color(hex: f)).frame(width: 30, height: 30)
                                            .overlay(Circle().strokeBorder(.white, lineWidth: g?.farbe == f ? 3 : 0))
                                            .frame(width: 44, height: 44)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Farbe \(f)")
                                    .accessibilityAddTraits(g?.farbe == f ? .isSelected : [])
                                }
                            }
                        }
                        Section("Symbol") {
                            FliessLayout(abstand: 8) {
                                ForEach(symbole, id: \.self) { sy in
                                    let an = g?.symbol == sy
                                    let c = Color(hex: g?.farbe ?? "#3B4CCA")
                                    Button { g?.symbol = sy } label: {
                                        Image(systemName: sy).font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(an ? .white : c)
                                            .frame(width: 44, height: 44)
                                            .background(an ? c : c.opacity(0.14), in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(sy)
                                    .accessibilityAddTraits(an ? .isSelected : [])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        if var neu = g {
                            neu.titel = neu.titel.trimmingCharacters(in: .whitespaces)
                            let fertig = neu
                            speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == fertig.id }) { s.ziele[i] = fertig } }
                        }
                        dismiss()
                    }
                    .disabled((g?.titel.trimmingCharacters(in: .whitespaces) ?? "").isEmpty)
                }
            }
            .onAppear { if g == nil { g = speicher.zustand.ziel(zielID) } }
        }
        .presentationDetents([.medium, .large])
    }

    private var titel: String {
        switch feld {
        case .titel: "Titel"
        case .faellig: "Bis wann"
        case .bereich: "Bereich"
        case .warum: "Warum"
        case .aussehen: "Aussehen"
        }
    }
}

// MARK: So wird gerechnet (kurz)

struct RechnungBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher

    var body: some View {
        NavigationStack {
            let z = speicher.zustand
            let T = speicher.heute
            List {
                if let g = z.ziel(zielID) {
                    let p = Fortschritt.ziel(g, in: z, heute: T)
                    let kurs = Kurs.aufKurs(g, in: z, heute: T)
                    Section {
                        Text("Fortschritt ist der Durchschnitt deiner Meilensteine. Mittel zählt doppelt, groß dreifach.")
                    }
                    Section("Woher die \(Zahl.prozent(p)) kommen") {
                        if g.schritte.isEmpty { Text("Noch keine Meilensteine – deshalb 0 %.").foregroundStyle(.secondary) }
                        ForEach(g.schritte) { s in
                            let st = Fortschritt.stand(s, in: z, heute: T)
                            LabeledContent {
                                Text("+\(Zahl.text(Fortschritt.beitrag(s, in: g, z: z, heute: T) * 100, stellen: 1)) Pkt.").monospacedDigit()
                            } label: {
                                Text(s.titel)
                                Text("\(Zahl.prozent(st.anteil)) · \(s.art.name)\(st.gewicht > 1 ? " · ×\(st.gewicht)" : "")")
                            }
                        }
                    }
                    Section("Was zählt") {
                        ForEach(SchrittArt.allCases, id: \.self) { a in
                            Label { Text(a.erklaerung) } icon: { Image(systemName: a.symbol) }
                        }
                        Label("Aufgaben, Habits und Termine ohne Meilenstein zählen als Einsatz, nicht in die Prozente.", systemImage: "figure.walk")
                    }
                    Section("Auf Kurs") {
                        Text(kurs.lage == .erreicht ? "Erreicht." : "Nach \(Zahl.prozent(kurs.gesamt > 0 ? Double(kurs.verstrichen) / Double(kurs.gesamt) : 0)) der Zeit wären \(Zahl.prozent(kurs.erwartet)) im Plan – du hast \(Zahl.prozent(kurs.fortschritt)): \(kurs.lage.text).")
                    }
                }
            }
            .navigationTitle("So wird gerechnet")
            .navigationBarTitleDisplayMode(.inline)
            .schliessenKnopf()
        }
        .presentationDetents([.medium, .large])
    }
}
