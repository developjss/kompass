import SwiftUI

/// Termin anlegen oder ändern (Struktur v3 §4): Titel, Tag, von–bis, Kategorie, zählt für Ziel/Habit, Wiederholung.
/// Ein Bildschirm, Chips statt Räder.
struct TerminBlatt: View {
    var terminID: UUID?
    var tag: Tag?
    var start: Int?
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var t: EigenerTermin?
    @State private var loeschenFragen = false
    @FocusState private var titelFokus: Bool

    private let dauern = [30, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Form {
                if t != nil {
                    Section {
                        TextField("Titel, z. B. Fahrstunde", text: Binding(get: { t?.titel ?? "" }, set: { t?.titel = $0 }))
                            .font(.kompass(.title3, .bold)).focused($titelFokus)
                    }
                    Section {
                        DatePicker("Tag", selection: Binding(get: { t?.tag.datum() ?? Date() }, set: { t?.tag = Tag($0, kalender: speicher.kalender) }), displayedComponents: .date)
                        DatePicker("Von", selection: Binding(get: { uhr(t?.start ?? 0) }, set: { neu in
                            let d = (t?.ende ?? 0) - (t?.start ?? 0)
                            t?.start = minuten(neu); t?.ende = min(24 * 60 - 1, minuten(neu) + max(d, 15))
                        }), displayedComponents: .hourAndMinute)
                        DatePicker("Bis", selection: Binding(get: { uhr(t?.ende ?? 0) }, set: { t?.ende = max((t?.start ?? 0) + 5, minuten($0)) }), displayedComponents: .hourAndMinute)
                        ChipReihe(titel: "Dauer", auswahl: dauern.map { (dauerText($0), (t?.ende ?? 0) - (t?.start ?? 0) == $0) }) { i in
                            if let s = t?.start { t?.ende = min(24 * 60 - 1, s + dauern[i]) }
                        }
                    }
                    Section {
                        ChipReihe(titel: "Kategorie", auswahl: Kategorie.allCases.map { ($0.name, $0 == t?.kategorie) }) { i in
                            let k = Kategorie.allCases[i]; t?.kategorie = t?.kategorie == k ? nil : k
                        }
                        Picker("Wiederholen", selection: Binding(get: { t?.wiederholung ?? .nie }, set: { t?.wiederholung = $0 })) {
                            ForEach(Wiederholung.allCases, id: \.self) { Text($0.name).tag($0) }
                        }
                    }
                    zaehltTeil
                    if terminID != nil {
                        Section {
                            Button("Termin löschen", role: .destructive) { loeschenFragen = true }
                        }
                    }
                }
            }
            .navigationTitle(terminID == nil ? "Neuer Termin" : "Termin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(terminID == nil ? "Anlegen" : "Sichern", action: sichern)
                        .disabled((t?.titel.trimmingCharacters(in: .whitespaces) ?? "").isEmpty)
                }
            }
            .confirmationDialog("Termin löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    if let id = terminID { speicher.aendern { $0.terminLoeschen(id) } }
                    dismiss()
                }
            } message: { Text(t?.wiederholung == .nie ? "" : "Die ganze Serie wird gelöscht.") }
            .onAppear(perform: laden)
        }
        .presentationDetents([.large])
    }

    /// Zählt für: nichts · Ziel (mit Meilenstein Zeit/Zahl) · Habit
    @ViewBuilder private var zaehltTeil: some View {
        let z = speicher.zustand
        let ziele = z.ziele.filter { $0.status == .aktiv }
        Section {
            Picker("Für ein Ziel", selection: Binding(get: { t?.zielID }, set: { neu in
                t?.zielID = neu
                t?.schrittID = z.ziel(neu)?.schritte.first { $0.art == .zeit || $0.art == .zahl }?.id
            })) {
                Text("Keins").tag(UUID?.none)
                ForEach(ziele) { Text($0.titel).tag(UUID?.some($0.id)) }
            }
            if let g = z.ziel(t?.zielID) {
                let passend = g.schritte.filter { $0.art == .zeit || $0.art == .zahl }
                Picker("Zählt in", selection: Binding(get: { t?.schrittID }, set: { t?.schrittID = $0 })) {
                    Text("Nur Einsatz").tag(UUID?.none)
                    ForEach(passend) { s in Text("\(s.titel) · \(s.art == .zeit ? "Dauer" : "je 1")").tag(UUID?.some(s.id)) }
                }
            }
            Picker("Erfüllt Habit", selection: Binding(get: { t?.habitID }, set: { t?.habitID = $0 })) {
                Text("Keinen").tag(UUID?.none)
                ForEach(z.habits) { Text($0.titel).tag(UUID?.some($0.id)) }
            }
        } header: { Text("Zählt für") } footer: {
            Text(zaehltText)
        }
    }

    private var zaehltText: String {
        let z = speicher.zustand
        var teile: [String] = []
        if let g = z.ziel(t?.zielID) {
            if let s = z.schritt(t?.schrittID, in: g.id) { teile.append("Jeder stattgefundene Termin zählt in „\(s.titel)“.") }
            else { teile.append("Zählt als Einsatz für „\(g.titel)“, ändert die Prozente nicht.") }
        }
        if let h = z.habit(t?.habitID) { teile.append("„\(h.titel)“ ist erledigt, sobald der Termin vorbei ist.") }
        return teile.isEmpty ? "Optional: Termin zählt für ein Ziel oder erfüllt einen Habit." : teile.joined(separator: " ")
    }

    private func laden() {
        guard t == nil else { return }
        if let id = terminID, let x = speicher.zustand.eigenerTermin(id) { t = x; return }
        let d = tag ?? speicher.heute
        let s = start ?? naechsteViertelstunde()
        t = EigenerTermin(titel: "", tag: d, start: s, ende: min(24 * 60 - 1, s + 60))
        titelFokus = true
    }

    private func naechsteViertelstunde() -> Int {
        let m = speicher.jetztMinuten
        return min(23 * 60, ((m + 14) / 15) * 15 + (m % 60 > 45 ? 0 : 0))
    }

    private func sichern() {
        guard var neu = t else { return }
        neu.titel = neu.titel.trimmingCharacters(in: .whitespaces)
        neu.habitBis = nil
        let fertig = neu
        speicher.aendern { $0.terminSpeichern(fertig) }
        dismiss()
    }

    private func dauerText(_ m: Int) -> String { m < 60 ? "\(m) Min" : m % 60 == 0 ? "\(m / 60) h" : "\(m / 60),5 h" }
    private func uhr(_ m: Int) -> Date { Calendar.kompass.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: m / 60, minute: m % 60)) ?? Date() }
    private func minuten(_ d: Date) -> Int { let k = Calendar.kompass.dateComponents([.hour, .minute], from: d); return (k.hour ?? 0) * 60 + (k.minute ?? 0) }
}
