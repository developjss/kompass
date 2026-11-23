import SwiftUI

/// Anlegen: Aufgabe, Habit oder Ziel. Grobe Fassung ohne Vorschläge.
/// [OFFEN] Vorschläge aus Vorlagen und KI (rechenregeln.md §7) wie im Klick-Dummy.
struct NeuBlatt: View {
    @State var art: NeuArt
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    @State private var titel = ""
    @State private var datum = Date()
    @State private var mitDatum = true
    @State private var wichtig = false
    @State private var zielID: UUID?
    @State private var wiederholung: Wiederholung = .nie
    @State private var tage: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
    @State private var faellig = Calendar.kompass.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var alsZahl = false
    @State private var start = 0.0
    @State private var zielwert = 100.0
    @State private var einheit = ""

    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Was", selection: $art) {
                    Text("Aufgabe").tag(NeuArt.aufgabe)
                    Text("Habit").tag(NeuArt.habit)
                    Text("Ziel").tag(NeuArt.ziel)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                Section { TextField(platzhalter, text: $titel) }

                switch art {
                case .aufgabe:
                    Section {
                        Toggle("Mit Datum", isOn: $mitDatum)
                        if mitDatum { DatePicker("Datum", selection: $datum, displayedComponents: .date) }
                        Toggle("Wichtig", isOn: $wichtig)
                        Picker("Wiederholen", selection: $wiederholung) {
                            ForEach(Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                        zielPicker
                    }
                case .habit:
                    Section("An welchen Tagen") {
                        HStack {
                            ForEach(1...7, id: \.self) { d in
                                Button(namen[d - 1]) { if tage.contains(d) { tage.remove(d) } else { tage.insert(d) } }
                                    .buttonStyle(.bordered)
                                    .tint(tage.contains(d) ? Farbe.akzent : .gray)
                                    .accessibilityAddTraits(tage.contains(d) ? .isSelected : [])
                            }
                        }
                        zielPicker
                    }
                case .ziel:
                    Section {
                        DatePicker("Bis wann", selection: $faellig, displayedComponents: .date)
                        Toggle("Als Zahl messen", isOn: $alsZahl)
                        if alsZahl {
                            LabeledContent("Start") { TextField("0", value: $start, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                            LabeledContent("Ziel") { TextField("100", value: $zielwert, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                            TextField("Einheit (z. B. kg, €)", text: $einheit)
                        }
                    } footer: {
                        Text(alsZahl ? "Fortschritt = (aktuell − Start) ÷ (Ziel − Start)." : "Schritte legst du danach im Ziel an.")
                    }
                }
            }
            .navigationTitle("Neu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen", action: anlegen).disabled(titel.trimmingCharacters(in: .whitespaces).isEmpty || (art == .habit && tage.isEmpty))
                }
            }
        }
    }

    private var platzhalter: String {
        switch art {
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
            speicher.aendern { s in
                let a = s.aufgabeAnlegen(t, datum: tag, prio: p, zielID: z, heute: heute)
                if let i = s.aufgaben.firstIndex(where: { $0.id == a.id }) { s.aufgaben[i].wiederholung = w }
            }
        case .habit:
            let farbe = Farbe.ziele[speicher.zustand.habits.count % Farbe.ziele.count]
            let h = Habit(titel: t, farbe: farbe, symbol: "star.fill", wochentage: tage, zielID: zielID, angelegt: heute)
            speicher.aendern { $0.habits.append(h) }
        case .ziel:
            let farbe = Farbe.ziele[speicher.zustand.ziele.count % Farbe.ziele.count]
            var g = Ziel(titel: t, farbe: farbe, symbol: "target", bereich: "Allgemein", faellig: Tag(faellig, kalender: k), angelegt: heute)
            if alsZahl { g.zahl = ZahlMessung(start: start, aktuell: start, ziel: zielwert, einheit: einheit) }
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
