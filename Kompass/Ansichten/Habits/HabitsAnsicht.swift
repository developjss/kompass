import SwiftUI

/// Habits (Tab Fortschritt): Kopfkarte mit einer Aussage, dann Heute (abhaken/eintragen), Diese Woche, Alle Habits.
/// Aufbau nach habits-v2.md §3 – Zeilen wie in Gapless: Kachel · Titel + eine Unterzeile · Wert rechts.
struct HabitsAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let heute = z.habits.filter { HabitRechnung.geplant($0, am: T) }
        let offen = heute.filter { !$0.voll(am: T) }
        let geschafft = heute.filter { $0.voll(am: T) }

        Seite(titel: "Fortschritt", info: .habits, neu: .habit, oben: AnyView(FortschrittWahl())) {
            if z.habits.isEmpty {
                GruppierteListe {
                    LeerZeile(text: "Noch keine Habits. Oben auf „+ Neu“ – zum Beispiel „20 Minuten lesen“.")
                    PlusZeile(text: "Habit") { nav.blatt = .neu(.habit) }
                }
            } else {
                HabitsKopf(heute: heute, offen: offen)

                AbschnittKopf(titel: "Heute") {
                    Text(offen.isEmpty ? "alles geschafft" : "\(offen.count) offen").foregroundStyle(Farbe.zweitrangig)
                }
                GruppierteListe {
                    if heute.isEmpty { LeerZeile(text: "Heute ist kein Habit geplant.") }
                    ForEach(offen) { HeuteZeile(habit: $0) }
                    ForEach(geschafft) { HeuteZeile(habit: $0) }
                }

                AbschnittKopf(titel: "Diese Woche") { Text(wochenText(T)).foregroundStyle(Farbe.zweitrangig) }
                GruppierteListe {
                    ForEach(z.habits.sorted { wochenReihenfolge($0) < wochenReihenfolge($1) }) { WochenZeile(habit: $0) }
                }

                AbschnittKopf(titel: "Alle Habits") { Text("\(z.habits.count)").foregroundStyle(Farbe.zweitrangig) }
                GruppierteListe {
                    ForEach(z.habits) { AlleZeile(habit: $0) }
                    PlusZeile(text: "Habit") { nav.blatt = .neu(.habit) }
                }
            }
        }
    }

    private func wochenText(_ T: Tag) -> String {
        let m = T.montag, s = m.plus(tage: 6)
        return "\(m.tag).\(m.monat). – \(s.tag).\(s.monat)."
    }

    private func wochenReihenfolge(_ h: Habit) -> Int { if case .proWoche = h.rhythmus { return 0 } else { return 1 } }
}

// MARK: Kopfkarte

private struct HabitsKopf: View {
    var heute: [Habit]
    var offen: [Habit]
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let tage = (0..<7).map { i -> Double in
            let d = T.plus(tage: -(6 - i))
            let q = HabitRechnung.quote(alle: z.habits, von: d, bis: d, heute: T)
            return q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0
        }
        let beste = z.habits.map { HabitRechnung.serie($0, heute: T) }.max() ?? 0
        let geschafft = heute.count - offen.count
        Verlaufskarte(farben: Farbe.gruen) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    KartenLabel(text: "Heute")
                    Text(heute.isEmpty ? "Nichts geplant" : "\(geschafft) von \(heute.count) geschafft")
                        .font(.kompass(.title, .heavy)).contentTransition(.numericText())
                    Text(unterzeile(beste: beste)).font(.unterzeile).opacity(0.9).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                MiniSaeulen(werte: tage, hoehe: 52, hervor: 6).padding(.top, 8)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Eine Zeile, ein Fakt: was noch offen ist (höchstens zwei Namen), sonst die längste Serie.
    private func unterzeile(beste: Int) -> String {
        if offen.isEmpty { return heute.isEmpty ? "Heute ist frei." : (beste > 0 ? "Alles abgehakt · längste Serie \(beste)" : "Alles abgehakt") }
        let namen = offen.prefix(2).map { $0.titel.count > 22 ? String($0.titel.prefix(21)) + "…" : $0.titel }
        var t = "Noch offen: " + namen.joined(separator: ", ")
        if offen.count > 2 { t += " +\(offen.count - 2)" }
        return t
    }
}

// MARK: Zeilen

/// Heute: Kachel · Titel · Stand („12 von 20 min · 21:00“) · Haken rechts. Tipp auf die Zeile = Menge eintragen.
private struct HeuteZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: habit.farbe)
        let voll = habit.voll(am: T)
        let anteil = habit.anteil(am: T)
        HStack(spacing: 12) {
            Button { tippen() } label: {
                HStack(spacing: 12) {
                    SymbolKachel(symbol: habit.symbol, farbe: c)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.titel).font(.zeile).foregroundStyle(voll ? Farbe.zweitrangig : Farbe.text).lineLimit(1)
                        Text(stand(T)).font(.unterzeile).foregroundStyle(voll ? Farbe.freude : Farbe.zweitrangig).lineLimit(1)
                        if habit.menge != nil, anteil > 0, !voll {
                            Balken(anteil: anteil, farbe: c, spur: Farbe.linie, hoehe: 3).padding(.top, 2).padding(.trailing, 8)
                        }
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(habit.menge == nil ? "Öffnet den Habit" : "Menge eintragen")
            Haken(an: voll, farbe: c, beschriftung: habit.titel) {
                speicher.aendern { $0.habitUmschalten(habit.id, am: T) }
            }
            .padding(.trailing, 4)
        }
        .padding(.leading, 12)
        .frame(minHeight: Mass.zeile)
    }

    private func stand(_ T: Tag) -> String {
        var teile: [String] = []
        if habit.menge != nil { teile.append(HabitRechnung.mengenText(habit, am: T)) }
        else { teile.append(habit.voll(am: T) ? "erledigt" : "offen") }
        if !habit.voll(am: T), let e = habit.erinnerung { teile.append(Beispieltermine.uhrzeit(e)) }
        if habit.voll(am: T) { let s = HabitRechnung.serie(habit, heute: T); if s > 1 { teile.append("Serie \(s)") } }
        return teile.prefix(2).joined(separator: " · ")
    }

    private func tippen() {
        if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: speicher.heute.text) } else { nav.blatt = .habit(habit.id) }
    }
}

/// Diese Woche: Wochen-Habits mit Segment-Balken („2 von 3 · noch 2 Tage“), Tages-Habits mit sieben Punkten (heute mit Ring).
private struct WochenZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    private let kurz = ["M", "D", "M", "D", "F", "S", "S"]

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: habit.farbe)
        let w = HabitRechnung.woche(habit, montag: T.montag, seit: habit.angelegt, heute: T)
        Button { nav.blatt = .habit(habit.id) } label: {
            HStack(spacing: 12) {
                SymbolKachel(symbol: habit.symbol, farbe: c)
                VStack(alignment: .leading, spacing: 6) {
                    Text(habit.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    if case .proWoche(let n) = habit.rhythmus {
                        HStack(spacing: 10) {
                            HStack(spacing: 3) {
                                ForEach(0..<n, id: \.self) { i in
                                    Capsule().fill(Double(i) < w.erledigt ? c : Farbe.linie).frame(height: 6)
                                }
                            }
                            .frame(maxWidth: 120)
                            Text(wochenText(w, n: n, T: T)).font(.unterzeile).foregroundStyle(w.erfuellt ? Farbe.freude : Farbe.zweitrangig).lineLimit(1)
                        }
                    } else {
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { i in
                                let d = T.montag.plus(tage: i)
                                let geplant = HabitRechnung.geplant(habit, am: d)
                                let a = habit.anteil(am: d)
                                ZStack {
                                    Circle().fill(a >= 1 ? c : (geplant ? c.opacity(0.14) : Color.clear)).frame(width: 18, height: 18)
                                    if a > 0, a < 1 { Circle().trim(from: 0, to: a).stroke(c, lineWidth: 2.5).rotationEffect(.degrees(-90)).frame(width: 15, height: 15) }
                                    if d == T { Circle().strokeBorder(c, lineWidth: 1.5).frame(width: 22, height: 22) }
                                    Text(kurz[i]).font(.system(size: 9, weight: .bold)).foregroundStyle(a >= 1 ? .white : (geplant ? c : Farbe.pfeil))
                                }
                                .frame(width: 22, height: 22)
                                .opacity(d > T && !geplant ? 0.3 : 1)
                            }
                            Spacer(minLength: 0)
                            Text(w.geplant > 0 ? "\(Zahl.text(w.erledigt, stellen: 1)) von \(w.geplant)" : "–")
                                .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).monospacedDigit()
                        }
                    }
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: Mass.zeile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.titel), diese Woche \(Zahl.text(w.erledigt, stellen: 1)) von \(w.geplant)")
        .accessibilityAddTraits(.isButton)
    }

    private func wochenText(_ w: (geplant: Int, erledigt: Double, erfuellt: Bool), n: Int, T: Tag) -> String {
        if w.erfuellt { return "Woche geschafft" }
        let rest = 7 - T.wochentag
        return "\(Zahl.text(w.erledigt, stellen: 1)) von \(n)" + (rest > 0 ? " · noch \(rest) Tag\(rest == 1 ? "" : "e")" : "")
    }
}

/// Alle Habits: Titel · „20 min · täglich“ · rechts Quote und Serie · Chevron.
private struct AlleZeile: View {
    var habit: Habit
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let serie = HabitRechnung.serie(habit, heute: T)
        let wochen: Bool = { if case .proWoche = habit.rhythmus { return true } else { return false } }()
        Button { nav.blatt = .habit(habit.id) } label: {
            HStack(spacing: 12) {
                SymbolKachel(symbol: habit.symbol, farbe: Color(hex: habit.farbe))
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                    Text(HabitRechnung.sollText(habit) + (habit.erinnerung.map { " · \(Beispieltermine.uhrzeit($0))" } ?? ""))
                        .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(2)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Zahl.prozent(HabitRechnung.quote(habit, heute: T))).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).monospacedDigit()
                    Text(serie > 0 ? "Serie \(serie)\(wochen ? " Wo." : "")" : "keine Serie").font(.klein).foregroundStyle(Farbe.zweitrangig)
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Farbe.pfeil)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: Mass.zeile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: Menge eintragen

/// „Wie viel heute?“ – große Zahl, Einheit, Schnellwahl (halb · ganz · mehr), Tastatur. Speichert beim Sichern.
struct HabitMengeBlatt: View {
    var habitID: UUID
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var wert: Double = 0
    @State private var geladen = false
    @FocusState private var fokus: Bool

    var body: some View {
        NavigationStack {
            if let h = speicher.zustand.habit(habitID) {
                let soll = h.menge ?? 1
                let c = Color(hex: h.farbe)
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            TextField("0", value: $wert, format: .number.precision(.fractionLength(0...1)))
                                .keyboardType(.decimalPad).focused($fokus)
                                .font(.system(size: 56, weight: .heavy, design: .rounded)).multilineTextAlignment(.center)
                                .fixedSize().foregroundStyle(Farbe.text)
                            Text(h.einheit?.kurz ?? "×").font(.kompass(.title2, .bold)).foregroundStyle(Farbe.zweitrangig)
                        }
                        .padding(.top, 8)
                        Text("von \(Zahl.text(soll, stellen: 1)) \(h.einheit?.kurz ?? "") · \(Zahl.prozent(min(1, wert / soll)))")
                            .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                        Balken(anteil: min(1, wert / soll), farbe: c, spur: Farbe.linie, hoehe: 8).padding(.horizontal, 40)
                        HStack(spacing: 8) {
                            ForEach(HabitVorschlag.schnellwahl(soll: soll), id: \.self) { s in
                                Button { wert = s } label: {
                                    Text(s == soll ? "ganz" : Zahl.text(s, stellen: 1))
                                        .font(.kompass(.subheadline, .bold))
                                        .padding(.horizontal, 14).frame(minHeight: 40)
                                        .background(wert == s ? c : Farbe.karte, in: Capsule())
                                        .foregroundStyle(wert == s ? .white : Farbe.text)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(tag == speicher.heute ? "Heute" : tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
                            .font(.klein).foregroundStyle(Farbe.zweitrangig)
                    }
                    .padding(Mass.rand)
                }
                .background(Farbe.grund.ignoresSafeArea())
                .navigationTitle(h.titel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Sichern") {
                            let w = wert, id = habitID, t = tag
                            speicher.aendern { $0.habitEintragen(id, menge: w, am: t) }
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    guard !geladen else { return }
                    geladen = true
                    wert = h.eintraege[tag] ?? 0
                    fokus = wert == 0
                }
            } else {
                ContentUnavailableView("Habit nicht gefunden", systemImage: "questionmark")
            }
        }
        .presentationDetents([.medium])
    }
}

/// Details eines Habits: Soll, Rhythmus, Erinnerung, Ziel, Serie, Quote, Verlauf; Löschen.
/// [OFFEN] Bearbeiten je Zeile (habits-v2.md §7) – nächster Block.
struct HabitBlatt: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let h = speicher.zustand.habit(id) {
                let T = speicher.heute
                let wochen: Bool = { if case .proWoche = h.rhythmus { return true } else { return false } }()
                List {
                    Section {
                        LabeledContent("Soll", value: HabitRechnung.sollText(h))
                        LabeledContent("Erinnerung", value: h.erinnerung.map { Beispieltermine.uhrzeit($0) } ?? "aus")
                        if let g = speicher.zustand.ziel(h.zielID) { LabeledContent("Ziel", value: g.titel) }
                    }
                    Section {
                        LabeledContent("Heute", value: HabitRechnung.mengenText(h, am: T))
                        if h.menge != nil {
                            Button("Menge eintragen") { nav.blatt = .habitMenge(h.id, tag: T.text) }
                        }
                        Button(h.voll(am: T) ? "Heute wieder öffnen" : "Heute abhaken") { speicher.aendern { $0.habitUmschalten(h.id, am: T) } }
                    }
                    Section("Stand") {
                        LabeledContent("Serie", value: "\(HabitRechnung.serie(h, heute: T)) \(wochen ? "Wochen" : "Tage")")
                        LabeledContent("Beste Serie", value: "\(HabitRechnung.besteSerie(h, heute: T)) \(wochen ? "Wochen" : "Tage")")
                        LabeledContent("Quote 30 Tage", value: Zahl.prozent(HabitRechnung.quote(h, heute: T)))
                    }
                    Section("Letzte 14 Tage") {
                        ForEach(0..<14, id: \.self) { i in
                            let d = T.plus(tage: -i)
                            if HabitRechnung.geplant(h, am: d) || h.eintraege[d] != nil {
                                LabeledContent(d == T ? "Heute" : d.datum().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "de_DE")))) {
                                    Text(HabitRechnung.mengenText(h, am: d)).foregroundStyle(h.voll(am: d) ? Farbe.freude : .secondary)
                                }
                            }
                        }
                    }
                    Section {
                        Button("Habit löschen", role: .destructive) {
                            speicher.aendern { s in s.habits.removeAll { $0.id == id } }
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
