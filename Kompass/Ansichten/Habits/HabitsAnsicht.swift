import SwiftUI

/// Habits (Tab Fortschritt): zwei Kacheln „Heute“ und „Alle Habits“ (senkrechter Verlauf, große Zahl – bewusst anders
/// als die diagonalen Ziel-Kacheln), darunter die gewählte Liste. Analyse steht im Rückblick.
struct HabitsAnsicht: View {
    enum Ansicht: String { case heute, alle }
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @AppStorage("habits.ansicht") private var ansichtRoh = Ansicht.heute.rawValue
    @State private var erledigteZeigen = false

    private var ansicht: Ansicht { .init(rawValue: ansichtRoh) ?? .heute }

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let heute = z.habits.filter { HabitRechnung.geplant($0, am: T) }
        let offen = heute.filter { !$0.voll(am: T) }
        let geschafft = heute.filter { $0.voll(am: T) }
        let woche = (0..<7).map { i -> Double in
            let d = T.montag.plus(tage: i)
            guard d <= T else { return -1 }
            let q = HabitRechnung.quote(alle: z.habits, von: d, bis: d, heute: T)
            return q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0
        }

        VStack(alignment: .leading, spacing: 0) {
            if z.habits.isEmpty {
                GruppierteListe {
                    LeerZeile(text: "Noch keine Habits. Oben auf „+ Neu“ – zum Beispiel „20 Minuten lesen“.")
                    PlusZeile(text: "Habit") { nav.blatt = .neu(.habit) }
                }
            } else {
                HStack(spacing: 12) {
                    HabitKachel(titel: "Heute", farbe: Farbe.TonArt.gruen.farbe, an: ansicht == .heute,
                                zahl: heute.isEmpty ? "frei" : "\(geschafft.count)/\(heute.count)",
                                unter: heute.isEmpty ? "nichts geplant" : (offen.isEmpty ? "alles geschafft" : "\(offen.count) offen"),
                                anteil: heute.isEmpty ? nil : Double(geschafft.count) / Double(heute.count), woche: nil) {
                        withAnimation(ruhig ? nil : .snappy) { ansichtRoh = Ansicht.heute.rawValue }
                    }
                    HabitKachel(titel: "Alle Habits", farbe: Farbe.TonArt.wein.farbe, an: ansicht == .alle,
                                zahl: "\(z.habits.count)", unter: "diese Woche", anteil: nil, woche: woche) {
                        withAnimation(ruhig ? nil : .snappy) { ansichtRoh = Ansicht.alle.rawValue }
                    }
                }

                if ansicht == .heute {
                    AbschnittKopf(titel: "Heute") {
                        Text(offen.isEmpty ? (heute.isEmpty ? "frei" : "alles geschafft") : "\(offen.count) offen").foregroundStyle(Farbe.zweitrangig)
                    }
                    GruppierteListe {
                        if heute.isEmpty { LeerZeile(text: "Heute ist kein Habit geplant.") }
                        if offen.isEmpty && !heute.isEmpty { LeerZeile(text: "Alles abgehakt – gut gemacht.") }
                        ForEach(offen) { HeuteZeile(habit: $0) }
                        if !geschafft.isEmpty {
                            Button { withAnimation(.snappy(duration: 0.2)) { erledigteZeigen.toggle() } } label: {
                                HStack {
                                    Text("\(geschafft.count) erledigt").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                                    Spacer()
                                    Image(systemName: erledigteZeigen ? "chevron.up" : "chevron.down").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                                }
                                .padding(.horizontal, 16).frame(minHeight: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(erledigteZeigen ? "Erledigte ausblenden" : "\(geschafft.count) erledigte zeigen")
                            if erledigteZeigen { ForEach(geschafft) { HeuteZeile(habit: $0) } }
                        }
                    }
                } else {
                    AbschnittKopf(titel: "Alle Habits") { Text("diese Woche").foregroundStyle(Farbe.zweitrangig) }
                    GruppierteListe {
                        ForEach(z.habits.sorted { wochenReihenfolge($0) < wochenReihenfolge($1) }) { WochenZeile(habit: $0) }
                        PlusZeile(text: "Habit") { nav.blatt = .neu(.habit) }
                    }
                }
            }
        }
    }

    private func wochenReihenfolge(_ h: Habit) -> Int { if case .proWoche = h.rhythmus { return 0 } else { return 1 } }
}

/// Habit-Kachel: senkrechter Verlauf Weiß → Farbe, große Zahl, darunter Ring (heute) oder Wochenpunkte (alle).
private struct HabitKachel: View {
    var titel: String
    var farbe: Color
    var an: Bool
    var zahl: String
    var unter: String
    /// Anteil für den Ring (heute), nil = kein Ring
    var anteil: Double?
    /// Mo–So: Anteil je Tag (−1 = Zukunft), nil = keine Punkte
    var woche: [Double]?
    var aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(titel).font(.kompass(.subheadline, .heavy)).foregroundStyle(Farbe.text)
                    Spacer()
                    if an { Image(systemName: "checkmark.circle.fill").font(.title3).symbolRenderingMode(.palette).foregroundStyle(.white, farbe) }
                }
                HStack(alignment: .center, spacing: 10) {
                    Text(zahl).font(.kompass(.largeTitle, .heavy)).foregroundStyle(Farbe.text).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                    if let anteil {
                        ZStack {
                            Circle().stroke(farbe.opacity(0.2), lineWidth: 5)
                            if anteil > 0 { Circle().trim(from: 0, to: anteil).stroke(farbe, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90)) }
                        }
                        .frame(width: 34, height: 34)
                    }
                }
                if let woche {
                    HStack(spacing: 5) {
                        ForEach(Array(woche.enumerated()), id: \.offset) { _, w in
                            Circle().fill(w < 0 ? farbe.opacity(0.12) : (w >= 1 ? farbe : farbe.opacity(0.25 + 0.5 * w)))
                                .frame(width: 10, height: 10)
                        }
                    }
                } else {
                    Text(unter).font(.klein).foregroundStyle(Farbe.text.opacity(0.7))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background {
                LinearGradient(stops: [.init(color: Farbe.karte, location: 0.2), .init(color: farbe.opacity(0.32), location: 1)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(an ? farbe : farbe.opacity(0.2), lineWidth: an ? 2.5 : 1))
            .shadow(color: farbe.opacity(an ? 0.25 : 0.1), radius: an ? 10 : 6, y: 4)
        }
        .buttonStyle(DruckStil())
        .accessibilityLabel("\(titel), \(zahl), \(unter)")
        .accessibilityAddTraits(an ? [.isButton, .isSelected] : .isButton)
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
        if habit.menge != nil { nav.blatt = .habitMenge(habit.id, tag: speicher.heute.text) } else { nav.oeffneHabit(habit.id) }
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
        Button { nav.oeffneHabit(habit.id) } label: {
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
