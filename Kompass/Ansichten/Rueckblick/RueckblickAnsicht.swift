import Charts
import SwiftUI

/// Rückblick einer Woche: Fokuszeit (Kurve 12 Wochen), Zeit pro Ziel (Ring), Habits-Quote.
struct RueckblickAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var versatz = 0

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let von = T.montag.plus(tage: 7 * versatz), bis = von.plus(tage: 6)
        let woche = z.sitzungen.filter { $0.tag >= von && $0.tag <= bis }
        let gesamt = woche.reduce(0) { $0 + $1.sekunden }
        let fuerZiele = woche.filter { $0.zielID != nil }.reduce(0) { $0 + $1.sekunden }
        let tage = max(1, (0..<7).filter { von.plus(tage: $0) <= T }.count)
        let zwoelf = (0..<12).map { k -> Double in
            let a = von.plus(tage: -7 * (11 - k))
            return z.sitzungen.filter { $0.tag >= a && $0.tag <= a.plus(tage: 6) }.reduce(0) { $0 + $1.sekunden } / 3600
        }
        let jeZiel = z.ziele.map { ($0, Fortschritt.zeit(ziel: $0.id, in: z, von: von, bis: bis)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        let habits = HabitRechnung.quote(alle: z.habits, von: von, bis: bis, heute: T)
        let erledigt = z.aufgaben.filter { a in a.erledigtAm.map { let d = Tag($0, kalender: speicher.kalender); return d >= von && d <= bis } == true }.count
        let proTag = (0..<7).map { i in woche.filter { $0.tag == von.plus(tage: i) }.reduce(0) { $0 + $1.sekunden } / 3600 }

        Seite(titel: "Rückblick", info: .rueckblick) {
            HStack {
                Button { versatz -= 1 } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Woche zurück")
                Text("\(kurz(von)) – \(kurz(bis))").font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text)
                Button { versatz += 1 } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("Woche vor")
                Spacer()
                if versatz != 0 { Button("Diese Woche") { versatz = 0 }.font(.kompass(.subheadline, .bold)) }
            }
            .foregroundStyle(Farbe.akzent)
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                Verlaufskarte(farben: Farbe.indigo) {
                    KartenLabel(text: "Fokuszeit")
                    Text(Zahl.dauer(gesamt)).font(.grosseZahl)
                    Text("Ø \(Zahl.dauer(gesamt / Double(tage))) pro Tag · \(gesamt > 0 ? Int((fuerZiele / gesamt * 100).rounded()) : 0) % für Ziele")
                        .font(.unterzeile).opacity(0.9)
                    Kurve(werte: zwoelf).frame(height: 70).padding(.top, 8)
                }
                Verlaufskarte(farben: Farbe.violett) {
                    KartenLabel(text: "Zeit pro Ziel")
                    if jeZiel.isEmpty {
                        Text("Noch keine Fokuszeit diese Woche.").font(.unterzeile)
                    } else {
                        HStack(spacing: 16) {
                            Chart(jeZiel, id: \.0.id) { g, s in
                                SectorMark(angle: .value("Zeit", s), innerRadius: .ratio(0.62), angularInset: 1.5)
                                    .foregroundStyle(Color(hex: g.farbe).mix(with: .white, by: 0.25))
                            }
                            .frame(width: 92, height: 92)
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(jeZiel.prefix(4), id: \.0.id) { g, s in
                                    HStack(spacing: 6) {
                                        Circle().fill(Color(hex: g.farbe).mix(with: .white, by: 0.25)).frame(width: 8, height: 8)
                                        Text(g.titel).font(.klein).lineLimit(1)
                                        Spacer(minLength: 4)
                                        Text(Zahl.dauer(s)).font(.klein).monospacedDigit()
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                Verlaufskarte(farben: Farbe.gruen) {
                    KartenLabel(text: "Habits")
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habits.geplant > 0 ? Zahl.prozent(Double(habits.erledigt) / Double(habits.geplant)) : "0 %").font(.grosseZahl)
                            Text("\(habits.erledigt) von \(habits.geplant) · \(erledigt) Aufgaben erledigt").font(.unterzeile).opacity(0.9)
                        }
                        Spacer()
                        MiniSaeulen(werte: proTag, hoehe: 52, hervor: versatz == 0 ? T.wochentag - 1 : nil)
                    }
                }
                PfeilZeile(symbol: "moon", text: z.reflexionen["woche:\(von.text)"] == nil ? "Wochenreflexion · 3 Fragen" : "Wochenreflexion ✓") {
                    nav.blatt = .reflexion(woche: true)
                }
            }
        }
    }

    private func kurz(_ t: Tag) -> String {
        t.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
    }
}

/// Tagesabschluss oder Wochenreflexion: drei Fragen, gespeichert je Tag bzw. Woche.
struct ReflexionBlatt: View {
    var woche: Bool
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var antworten: [String: String] = [:]

    private var fragen: [(String, String)] {
        woche ? [("fortschritt", "Wo bin ich meinen Zielen nähergekommen?"), ("lernen", "Was würde ich anders machen?"), ("fokus", "Worauf lege ich nächste Woche den Fokus?")]
              : [("gut", "Was lief heute gut?"), ("ablenkung", "Was hat mich abgelenkt?"), ("morgen", "Was ist morgen das Wichtigste?")]
    }

    private var schluessel: String { woche ? "woche:\(speicher.heute.montag.text)" : "tag:\(speicher.heute.text)" }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(fragen, id: \.0) { k, frage in
                    Section(frage) {
                        TextField("Antwort", text: Binding(get: { antworten[k] ?? "" }, set: { antworten[k] = $0 }), axis: .vertical)
                    }
                }
            }
            .navigationTitle(woche ? "Wochenreflexion" : "Tagesabschluss")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let k = schluessel, a = antworten
                        speicher.aendern { $0.reflexionen[k] = Reflexion(antworten: a) }
                        dismiss()
                    }
                }
            }
            .onAppear { antworten = speicher.zustand.reflexionen[schluessel]?.antworten ?? [:] }
        }
    }
}
