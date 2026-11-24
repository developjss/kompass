import SwiftUI

/// Termin aus dem Apple- oder Google-Kalender in Kompass bearbeiten: Titel, Tag, Von, Bis, löschen.
/// Gespeichert wird direkt im Kalender des Geräts (bei Serien nur dieses Vorkommen).
struct ExternTerminBlatt: View {
    var id: String
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var titel = ""
    @State private var start = Date()
    @State private var ende = Date()
    @State private var kalenderName = ""
    @State private var serie = false
    @State private var geladen = false
    @State private var fehler: String?
    @State private var loeschenFragen = false

    var body: some View {
        NavigationStack {
            Form {
                if geladen {
                    Section {
                        TextField("Titel", text: $titel).font(.kompass(.title3, .bold))
                    }
                    Section {
                        DatePicker("Beginn", selection: $start)
                        DatePicker("Ende", selection: $ende, in: start...)
                    } footer: {
                        Text(serie ? "Gehört zu einer Serie – geändert wird nur dieser Termin." : "Wird in „\(kalenderName)“ gespeichert.")
                    }
                    if let fehler { Section { Text(fehler).foregroundStyle(Farbe.kritisch) } }
                    Section {
                        Button("Termin löschen", role: .destructive) { loeschenFragen = true }
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
                    Button("Sichern", action: sichern).disabled(!geladen || titel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Termin löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) { loeschen() }
            } message: { Text("Er wird auch im \(kalenderName)-Kalender gelöscht\(serie ? " (nur dieser Termin der Serie)" : "").") }
            .onAppear(perform: laden)
        }
    }

    private func laden() {
        guard !geladen, let a = AppleKalender.aktiv.angaben(id, am: tag, kalender: speicher.kalender) else { return }
        titel = a.titel; start = a.start; ende = a.ende; kalenderName = a.kalender; serie = a.serie
        geladen = true
    }

    private func sichern() {
        do {
            try AppleKalender.aktiv.speichern(id: id, am: tag, titel: titel.trimmingCharacters(in: .whitespaces), start: start, ende: ende,
                                              kalenderID: nil, kalender: speicher.kalender)
            speicher.appleKalenderLesen()
            dismiss()
        } catch {
            fehler = "Konnte nicht gespeichert werden. Erlaubt der Kalender Änderungen?"
        }
    }

    private func loeschen() {
        do {
            try AppleKalender.aktiv.loeschen(id, am: tag, kalender: speicher.kalender)
            speicher.appleKalenderLesen()
            dismiss()
        } catch {
            fehler = "Konnte nicht gelöscht werden."
        }
    }
}
