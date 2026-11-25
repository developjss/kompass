import SwiftUI

/// Termin aus dem Apple- oder Google-Kalender in Kompass bearbeiten – mit denselben Eigenschaften wie in der
/// Kalender-App: Titel, Ort, ganztägig, Beginn/Ende, Wiederholung, Kalender, Erinnerungen, URL, Notizen.
/// Bei Serien wird gefragt: nur dieser Termin oder dieser und alle folgenden. Gespeichert wird im Kalender des Geräts.
struct ExternTerminBlatt: View {
    var id: String
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var d = AppleKalender.Details()
    @State private var original: AppleKalender.Details?
    @State private var fehler: String?
    @State private var loeschenFragen = false
    @State private var serie: SerienAuftrag?

    /// Hick: drei Vorschläge, der Rest hinter „weitere“
    private let erinnerungsWahl: [(String, Int)] = [("15 Min", 15), ("1 Std", 60), ("1 Tag", 1440), ("Zum Termin", 0), ("5 Min", 5), ("30 Min", 30)]

    var body: some View {
        NavigationStack {
            Form {
                if original != nil {
                    Section {
                        TextField("Titel", text: $d.titel).font(.kompass(.title3, .bold))
                        TextField("Ort", text: $d.ort)
                    }
                    Section {
                        Toggle("Ganztägig", isOn: $d.ganztaegig)
                        DatePicker("Beginn", selection: $d.start, displayedComponents: d.ganztaegig ? .date : [.date, .hourAndMinute])
                        DatePicker("Ende", selection: $d.ende, in: d.start..., displayedComponents: d.ganztaegig ? .date : [.date, .hourAndMinute])
                        Picker("Wiederholen", selection: $d.wiederholung) {
                            ForEach(AppleKalender.Details.Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                    }
                    Section {
                        let kalender = AppleKalender.aktiv.beschreibbareKalender()
                        Picker("Kalender", selection: $d.kalenderID) {
                            ForEach(kalender) { c in Text("\(c.google ? "Google · " : "")\(c.titel)").tag(c.id) }
                        }
                        ChipReihe(titel: "Erinnerung", auswahl: erinnerungsWahl.map { ($0.0, d.erinnerungen.contains($0.1)) }, grenze: 3) { i in
                            let m = erinnerungsWahl[i].1
                            if let j = d.erinnerungen.firstIndex(of: m) { d.erinnerungen.remove(at: j) } else { d.erinnerungen.append(m); d.erinnerungen.sort() }
                        }
                    }
                    Section {
                        TextField("URL", text: $d.url).keyboardType(.URL).textInputAutocapitalization(.never)
                        TextField("Notizen", text: $d.notizen, axis: .vertical).lineLimit(3...8)
                    }
                    if !d.teilnehmer.isEmpty {
                        Section {
                            ForEach(d.teilnehmer, id: \.self) { Text($0) }
                        } header: { Text("Teilnehmer") } footer: { Text("Einladungen verwaltet der \(d.kalenderName)-Kalender.") }
                    }
                    if let fehler { Section { Text(fehler).foregroundStyle(Farbe.kritisch) } }
                    Section {
                        Button("Termin löschen", role: .destructive) { loeschenFragen = true }
                    } footer: {
                        Text("Änderungen landen direkt in „\(d.kalenderName)“ und erscheinen überall, wo der Kalender synchronisiert.")
                    }
                } else {
                    ContentUnavailableView("Termin nicht gefunden", systemImage: "calendar", description: Text("Er wurde vielleicht im Kalender gelöscht."))
                }
            }
            .navigationTitle("Termin bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern", action: sichernFragen).disabled(original == nil || d.titel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Termin löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                if original?.serie == true {
                    Button("Nur diesen Termin löschen", role: .destructive) { loeschen(alle: false) }
                    Button("Diesen und alle folgenden löschen", role: .destructive) { loeschen(alle: true) }
                } else {
                    Button("Löschen", role: .destructive) { loeschen(alle: false) }
                }
            } message: { Text("Er wird auch im \(d.kalenderName)-Kalender gelöscht.") }
            .serienFrage($serie)
            .onAppear(perform: laden)
        }
    }

    private func laden() {
        guard original == nil, let x = AppleKalender.aktiv.details(id, am: tag, kalender: speicher.kalender) else { return }
        d = x; original = x
    }

    private func sichernFragen() {
        d.titel = d.titel.trimmingCharacters(in: .whitespaces)
        if original?.serie == true {
            serie = SerienAuftrag(titel: d.titel, allesText: "Diesen und alle folgenden") { nur in sichern(alle: !nur) }
        } else {
            sichern(alle: false)
        }
    }

    private func sichern(alle: Bool) {
        do {
            // Wiederholung ändern betrifft immer die Serie ab hier
            try AppleKalender.aktiv.speichern(id, am: tag, details: d, alle: alle || d.wiederholung != original?.wiederholung, kalender: speicher.kalender)
            speicher.appleKalenderLesen()
            dismiss()
        } catch {
            fehler = "Konnte nicht gespeichert werden. Erlaubt der Kalender Änderungen?"
        }
    }

    private func loeschen(alle: Bool) {
        do {
            try AppleKalender.aktiv.loeschen(id, am: tag, alle: alle, kalender: speicher.kalender)
            speicher.appleKalenderLesen()
            dismiss()
        } catch {
            fehler = "Konnte nicht gelöscht werden."
        }
    }
}
