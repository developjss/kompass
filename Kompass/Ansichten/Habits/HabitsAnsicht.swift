import SwiftUI

/// Habits: Kopfkarte „Heute x von y“, darunter je Habit die Woche zum Abhaken, Serie und Quote.
struct HabitsAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let faellig = z.habits.filter { HabitRechnung.geplant($0, am: T) }
        let erledigt = faellig.filter { $0.erledigt.contains(T) }
        let schnitt = z.habits.isEmpty ? 0 : z.habits.map { HabitRechnung.quote($0, heute: T) }.reduce(0, +) / Double(z.habits.count)
        let beste = z.habits.map { HabitRechnung.serie($0, heute: T) }.max() ?? 0
        let wochen = (0..<8).map { k -> Double in
            let start = T.montag.plus(tage: -7 * (7 - k))
            let q = HabitRechnung.quote(alle: z.habits, von: start, bis: start.plus(tage: 6), heute: T)
            return q.geplant > 0 ? Double(q.erledigt) / Double(q.geplant) : 0
        }

        Seite(titel: "Habits", info: .habits, neu: .habit) {
            if !z.habits.isEmpty {
                Verlaufskarte(farben: Farbe.gruen) {
                    HStack(alignment: .bottom, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            KartenLabel(text: "Heute")
                            Text("\(erledigt.count) von \(faellig.count)").font(.grosseZahl).contentTransition(.numericText())
                            Text("\(Zahl.prozent(schnitt)) in 30 Tagen · Serie \(beste)").font(.unterzeile).opacity(0.9)
                        }
                        Spacer()
                        MiniSaeulen(werte: wochen, hoehe: 52, hervor: 7)
                    }
                }
                .accessibilityElement(children: .combine)
            }

            AbschnittKopf(titel: "Diese Woche")
            GruppierteListe {
                if z.habits.isEmpty { LeerZeile(text: "Noch keine Habits. Oben auf „+ Neu“.") }
                ForEach(z.habits) { HabitZeile(habit: $0) }
            }
        }
    }
}

private struct HabitZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    private let namen = ["M", "D", "M", "D", "F", "S", "S"]
    private let lang = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: habit.farbe)
        HStack(spacing: 10) {
            SymbolKachel(symbol: habit.symbol, farbe: c)
            VStack(alignment: .leading, spacing: 6) {
                Button { nav.blatt = .habit(habit.id) } label: {
                    Text(habit.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                }
                .buttonStyle(.plain)
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { i in
                        let d = T.montag.plus(tage: i)
                        let an = habit.erledigt.contains(d)
                        let geplant = HabitRechnung.geplant(habit, am: d)
                        Button { speicher.aendern { $0.habitUmschalten(habit.id, am: d) } } label: {
                            Text(namen[i]).font(.kompass(.caption, .bold))
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(an ? c : (geplant ? c.opacity(0.12) : Color.clear)))
                                .overlay(Circle().strokeBorder(d == T ? c : .clear, lineWidth: 1.5))
                                .foregroundStyle(an ? .white : (geplant ? c : Farbe.pfeil))
                                .frame(width: 30, height: 44)
                        }
                        .buttonStyle(.plain)
                        .disabled(d > T)
                        .opacity(d > T ? 0.4 : 1)
                        .accessibilityLabel("\(habit.titel), \(lang[i])")
                        .accessibilityValue(an ? "erledigt" : (geplant ? "offen" : "nicht geplant"))
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 2) {
                Label("\(HabitRechnung.serie(habit, heute: T))", systemImage: "flame.fill").font(.kompass(.subheadline, .bold))
                Text(Zahl.prozent(HabitRechnung.quote(habit, heute: T))).font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
            .fixedSize()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Serie \(HabitRechnung.serie(habit, heute: T)), Quote \(Zahl.prozent(HabitRechnung.quote(habit, heute: T)))")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

/// Details eines Habits: Serie, beste Serie, Quote, Häufigkeit, Ziel; Löschen.
struct HabitBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let h = speicher.zustand.habit(id) {
                let T = speicher.heute
                List {
                    Section {
                        LabeledContent("Serie", value: "\(HabitRechnung.serie(h, heute: T)) Tage")
                        LabeledContent("Beste Serie", value: "\(HabitRechnung.besteSerie(h, heute: T)) Tage")
                        LabeledContent("Quote 30 Tage", value: Zahl.prozent(HabitRechnung.quote(h, heute: T)))
                        LabeledContent("Wann", value: HabitRechnung.haeufigkeit(h))
                        if let g = speicher.zustand.ziel(h.zielID) { LabeledContent("Ziel", value: g.titel) }
                    }
                    Section {
                        Button("Habit löschen", role: .destructive) {
                            speicher.aendern { s in
                                s.habits.removeAll { $0.id == id }
                            }
                            dismiss()
                        }
                    }
                }
                .navigationTitle(h.titel)
                .navigationBarTitleDisplayMode(.inline)
                .schliessenKnopf()
            } else {
                ContentUnavailableView("Habit nicht gefunden", systemImage: "questionmark")
            }
        }
        .presentationDetents([.medium, .large])
    }
}
