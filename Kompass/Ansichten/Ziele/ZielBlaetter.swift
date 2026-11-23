import SwiftUI

// Fenster rund um ein Ziel: Meilenstein anlegen/bearbeiten, Habit/Aufgabe/Termin hinzufügen, Ziel bearbeiten, „So wird gerechnet“.

private let de = Locale(identifier: "de_DE")

// MARK: Meilenstein

struct MeilensteinBlatt: View {
    var zielID: UUID
    var schrittID: UUID?
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    @State private var e = Schritt(titel: "")
    @State private var geladen = false
    @State private var neuerHabit = false
    @State private var habitTitel = ""
    @State private var stand: Double?
    @State private var schwellenText = ""
    @State private var loeschenFragen = false

    private var istNeu: Bool { schrittID == nil }

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let g = z.ziel(zielID)
        NavigationStack {
            Form {
                Section { TextField("Titel, z. B. Theorieprüfung", text: $e.titel) }

                Section {
                    Picker("Messen mit", selection: $e.art) {
                        ForEach(SchrittArt.allCases, id: \.self) { Label($0.name, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: { Text(e.art.erklaerung) }

                switch e.art {
                case .aufgaben: aufgabenTeil
                case .zahl: zahlTeil
                case .zeit: zeitTeil
                case .habit: habitTeil(g: g, T: T)
                }

                Section {
                    Picker("Gewicht", selection: $e.gewicht) {
                        Text("klein").tag(1)
                        Text("mittel").tag(2)
                        Text("groß").tag(3)
                    }
                    Toggle("Geschafft", isOn: $e.geschafft)
                } footer: {
                    Text("Groß zählt dreifach so viel wie klein. Geschafft = 100 %.")
                }

                if !istNeu {
                    Section {
                        Button("Meilenstein löschen", role: .destructive) { loeschenFragen = true }
                    }
                }
            }
            .navigationTitle(istNeu ? "Neuer Meilenstein" : "Meilenstein")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(istNeu ? "Hinzufügen" : "Sichern", action: sichern).disabled(!gueltig)
                }
            }
            .confirmationDialog("Meilenstein löschen? Aufgaben und Termine bleiben, zählen nur nicht mehr.", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    if let s = schrittID { speicher.aendern { $0.schrittLoeschen(ziel: zielID, schritt: s) } }
                    dismiss()
                }
            }
            .onAppear(perform: laden)
        }
    }

    // Abhaken: Aufgaben dieses Meilensteins direkt hier
    @ViewBuilder private var aufgabenTeil: some View {
        if let sid = schrittID {
            let liste = speicher.zustand.aufgaben.filter { $0.schrittID == sid }
            Section {
                ForEach(liste) { a in
                    Button {
                        speicher.aendern { $0.umschalten(a.id, jetzt: speicher.jetzt()) }
                    } label: {
                        Label(a.titel, systemImage: a.erledigt ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(a.erledigt ? Farbe.zweitrangig : Farbe.text)
                    }
                    .swipeActions {
                        Button("Lösen", role: .destructive) {
                            speicher.aendern { $0.aufgabeZuordnen(a.id, ziel: zielID, schritt: nil, automatisch: false, heute: speicher.heute) }
                        }
                    }
                }
                AufgabeHinzufuegen(platzhalter: "Aufgabe hinzufügen", datum: nil, prio: .hoch, zielID: zielID, schrittID: sid)
            } header: {
                Text("Aufgaben")
            } footer: {
                Text("Erledigte Aufgaben füllen bis 90 %. Wischen löst eine Aufgabe.")
            }
        } else {
            Section { Text("Aufgaben fügst du nach dem Anlegen hinzu.").foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder private var zahlTeil: some View {
        Section("Von – bis") {
            zahlFeld("Start", wert: Binding(get: { e.start ?? 0 }, set: { e.start = $0 }))
            zahlFeld("Ziel", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            TextField("Einheit (kg, €, Fahrstunden …)", text: Binding(get: { e.einheit ?? "" }, set: { e.einheit = $0 }))
        }
        Section {
            zahlFeld("Stand heute", wert: Binding(get: { stand ?? e.aktuell ?? e.start ?? 0 }, set: { stand = $0 }))
            TextField("Zwischenstände, z. B. 10.000; 100.000", text: $schwellenText).keyboardType(.numbersAndPunctuation)
        } footer: {
            Text("Zwischenstände hakt Kompass selbst ab, sobald der Stand sie erreicht. Zugeordnete Termine zählen je 1 dazu.")
        }
    }

    @ViewBuilder private var zeitTeil: some View {
        let r = LernRechnung.zeitfaktor(speicher.zustand.lernen.zeitVerhaeltnisse)
        Section {
            zahlFeld("Soll-Stunden", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            if istNeu, abs(r - 1) >= 0.05, let soll = e.soll, soll > 0 {
                Button("Vorschlag: \(Zahl.text(LernRechnung.vorschlagStunden(soll, verhaeltnisse: speicher.zustand.lernen.zeitVerhaeltnisse))) h") {
                    e.soll = LernRechnung.vorschlagStunden(soll, verhaeltnisse: speicher.zustand.lernen.zeitVerhaeltnisse)
                }
            }
        } footer: {
            Text(abs(r - 1) >= 0.05 ? "Du brauchst bisher im Schnitt \(Zahl.text(r, stellen: 1))× so lange wie geplant." : "Zählt Fokus-Timer dieses Meilensteins und zugeordnete Termine.")
        }
    }

    @ViewBuilder private func habitTeil(g: Ziel?, T: Tag) -> some View {
        Section {
            Toggle("Neuen Habit anlegen", isOn: $neuerHabit)
            if neuerHabit {
                TextField("Habit, z. B. 30 Fragen üben", text: $habitTitel)
            } else {
                Picker("Habit", selection: $e.habitID) {
                    Text("Wählen").tag(UUID?.none)
                    ForEach(speicher.zustand.habits) { Text($0.titel).tag(UUID?.some($0.id)) }
                }
            }
            Picker("Zählen", selection: Binding(get: { e.modus }, set: { e.habitModus = $0 })) {
                ForEach(HabitModus.allCases, id: \.self) { Text($0.name).tag($0) }
            }
            zahlFeld(e.modus == .wochen ? "Soll-Wochen" : "Soll-Anzahl", wert: Binding(get: { e.soll ?? 0 }, set: { e.soll = $0 }))
            if istNeu, let h = speicher.zustand.habit(e.habitID), let g, !neuerHabit {
                let v = e.modus == .wochen ? LernRechnung.vorschlagWochen(h, heute: T, bis: g.faellig) : LernRechnung.vorschlagAnzahl(h, heute: T, bis: g.faellig)
                Button("Vorschlag aus deinem Verlauf: \(Zahl.text(v))") { e.soll = v }
            }
        } footer: {
            Text(e.modus == .wochen ? "Eine Woche zählt, wenn alle geplanten Tage erledigt sind." : "Jedes Abhaken ab heute zählt einmal.")
        }
    }

    private func zahlFeld(_ titel: String, wert: Binding<Double>) -> some View {
        LabeledContent(titel) {
            TextField(titel, value: wert, format: .number.locale(de)).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
        }
    }

    private var gueltig: Bool {
        guard !e.titel.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch e.art {
        case .aufgaben: return true
        case .zahl: return (e.soll ?? 0) != (e.start ?? 0)
        case .zeit: return (e.soll ?? 0) > 0
        case .habit: return (e.soll ?? 0) > 0 && (neuerHabit ? !habitTitel.trimmingCharacters(in: .whitespaces).isEmpty : e.habitID != nil)
        }
    }

    private func laden() {
        guard !geladen else { return }
        geladen = true
        if let sid = schrittID, let s = speicher.zustand.schritt(sid, in: zielID) {
            e = s
            schwellenText = (s.schwellen ?? []).map { Zahl.text($0) }.joined(separator: "; ")
        } else {
            e = Schritt(titel: "", seit: speicher.heute)
        }
    }

    private func sichern() {
        var x = e
        x.titel = x.titel.trimmingCharacters(in: .whitespaces)
        let T = speicher.heute
        let neuerStand = stand
        let titelHabit = habitTitel.trimmingCharacters(in: .whitespaces)
        let neu = neuerHabit && x.art == .habit
        if x.art == .habit { x.seit = x.seit ?? T }
        if x.art == .zahl {
            x.schwellen = schwellenText.split(whereSeparator: { ";/ \n".contains($0) })
                .compactMap { Double($0.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) }
            if x.schwellen?.isEmpty == true { x.schwellen = nil }
            if x.aktuell == nil { x.aktuell = x.start ?? 0 }
        }
        let zid = zielID
        speicher.aendern { s in
            if neu {
                let farbe = s.ziel(zid)?.farbe ?? Farbe.ziele[0]
                let h = Habit(titel: titelHabit, farbe: farbe, symbol: "star.fill", wochentage: [1, 2, 3, 4, 5, 6, 7], zielID: zid, angelegt: T)
                s.habits.append(h)
                x.habitID = h.id
            }
            s.schrittSpeichern(x, ziel: zid)
            if x.art == .zahl, let w = neuerStand, w != x.aktuell { s.zahlEintragen(w, ziel: zid, schritt: x.id, heute: T) }
        }
        dismiss()
    }
}

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

struct ZielBearbeitenBlatt: View {
    var zielID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var g: Ziel?
    @State private var loeschenFragen = false

    var body: some View {
        NavigationStack {
            Form {
                if g != nil {
                    Section {
                        TextField("Titel", text: Binding(get: { g?.titel ?? "" }, set: { g?.titel = $0 }))
                        TextField("Warum ist dir das wichtig?", text: Binding(get: { g?.warum ?? "" }, set: { g?.warum = $0 }), axis: .vertical)
                        TextField("Bereich", text: Binding(get: { g?.bereich ?? "" }, set: { g?.bereich = $0 }))
                        DatePicker("Bis wann", selection: Binding(get: { g?.faellig.datum() ?? Date() }, set: { g?.faellig = Tag($0, kalender: speicher.kalender) }), displayedComponents: .date)
                    }
                    Section("Farbe") {
                        HStack(spacing: 8) {
                            ForEach(Farbe.ziele, id: \.self) { f in
                                Button { g?.farbe = f } label: {
                                    Circle().fill(Color(hex: f)).frame(width: 26, height: 26)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: g?.farbe == f ? 3 : 0))
                                        .frame(minWidth: 30, minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Farbe \(f)")
                                .accessibilityAddTraits(g?.farbe == f ? .isSelected : [])
                            }
                        }
                    }
                    Section {
                        Button("Ziel löschen", role: .destructive) { loeschenFragen = true }
                    } footer: {
                        Text("Aufgaben, Habits und Termine bleiben erhalten.")
                    }
                }
            }
            .navigationTitle("Ziel bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        if let neu = g { speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == neu.id }) { s.ziele[i] = neu } } }
                        dismiss()
                    }
                    .disabled((g?.titel.trimmingCharacters(in: .whitespaces) ?? "").isEmpty)
                }
            }
            .confirmationDialog("Ziel wirklich löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    let id = zielID
                    speicher.aendern { $0.zielLoeschen(id) }
                    dismiss()
                }
            }
            .onAppear { if g == nil { g = speicher.zustand.ziel(zielID) } }
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
