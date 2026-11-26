import SwiftUI

/// Habits (eigener Tab, Blattwerk): Bühne mit dem Wort „x von y heute“ und der Bordkarte, Karte vorn mit den
/// heutigen Habits (ein Haken je Zeile, ein grüner Knopf für den offenen), darunter „Diese Woche“.
struct HabitsAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var erledigteZeigen = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let heute = z.habits.filter { HabitRechnung.geplant($0, am: T) }
        let offen = heute.filter { !$0.voll(am: T) }
        let geschafft = heute.filter { $0.voll(am: T) }

        BuehnenSeite(hoehe: Mass.buehneKurz, wort: Self.wort(geschafft: geschafft.count, geplant: heute.count), marke: {
            MarkenTitel(text: "Habits")
            Spacer(minLength: 8)
            RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.habits) }
        }) {
            VornKarte(abstand: 0) {
                if z.habits.isEmpty {
                    Etikett(text: "Heute")
                    Text("Noch keine Habits.").font(.karteTitel).foregroundStyle(Farbe.text)
                    Text("Zum Beispiel „20 Minuten lesen“.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    Button { nav.blatt = .neu(.habit) } label: { Label("Habit anlegen", systemImage: "plus") }.buttonStyle(.haupt).padding(.top, 8)
                } else if heute.isEmpty {
                    Etikett(text: "Heute")
                    Text("Heute ist kein Habit geplant.").font(.karteTitel).foregroundStyle(Farbe.text)
                } else {
                    ForEach(offen) { HeuteZeile(habit: $0) }
                    if !geschafft.isEmpty {
                        if !offen.isEmpty { Rectangle().fill(Farbe.linie).frame(height: 1) }
                        Button { withAnimation(ruhig ? nil : .snappy(duration: 0.2)) { erledigteZeigen.toggle() } } label: {
                            HStack {
                                Text("\(geschafft.count) erledigt").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                                Spacer()
                                Image(systemName: erledigteZeigen ? "chevron.up" : "chevron.down").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                            }
                            .frame(minHeight: 44).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(erledigteZeigen ? "Erledigte ausblenden" : "\(geschafft.count) erledigte zeigen")
                        if erledigteZeigen { ForEach(geschafft) { HeuteZeile(habit: $0) } }
                    }
                }
            }

            if !z.habits.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Diese Woche").font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text("\(z.habits.count) Habit\(z.habits.count == 1 ? "" : "s")").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig)
                    }
                    .padding(.top, 8)
                    HinzufuegenKarte(titel: "Habit hinzufügen", unter: "täglich, an Wochentagen oder n-mal pro Woche") { nav.blatt = .neu(.habit) }
                    GruppierteListe {
                        ForEach(z.habits.sorted { wochenReihenfolge($0) < wochenReihenfolge($1) }) { WochenZeile(habit: $0) }
                    }
                }
                .padding(.horizontal, Mass.rand).padding(.top, 12)
            }
        }
    }

    /// Das Wort: wie viele der heute geplanten Habits schon stehen.
    nonisolated static func wort(geschafft: Int, geplant: Int) -> Wort {
        if geplant == 0 { return Wort(zeilen: ["Heute"], akzent: "frei.", groesse: Wort.kleinGroesse) }
        if geschafft == geplant { return Wort(zeilen: ["Alle \(geplant)"], akzent: "geschafft.", groesse: Wort.kleinGroesse) }
        return Wort(zeilen: ["\(geschafft) von \(geplant)"], akzent: "heute.", groesse: Wort.kleinGroesse)
    }

    private func wochenReihenfolge(_ h: Habit) -> Int { if case .proWoche = h.rhythmus { return 0 } else { return 1 } }
}

// MARK: Zeilen

/// Heute: Kachel · Titel · Stand („12 von 20 min · 21:00“) · Haken rechts. Tipp auf die Zeile = Menge eintragen.
private struct HeuteZeile: View {
    var habit: Habit
    /// Nur der erste offene Habit bekommt den grünen Knopf (Hick: eine Hauptaktion)
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let voll = habit.voll(am: T)
        let anteil = habit.anteil(am: T)
        HStack(spacing: 12) {
            Button { tippen() } label: {
                HStack(spacing: 12) {
                    ZeichenKreis(symbol: habit.symbol, gruen: voll)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.titel).font(.zeile).foregroundStyle(voll ? Farbe.zweitrangig : Farbe.text).lineLimit(1)
                        Text(stand(T)).font(.unterzeile).foregroundStyle(voll ? Farbe.akzent : Farbe.zweitrangig).lineLimit(1)
                        if habit.menge != nil, anteil > 0, !voll {
                            Balken(anteil: anteil, farbe: Farbe.handlung, spur: Farbe.linie, hoehe: 3).padding(.top, 2).padding(.trailing, 8)
                        }
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(habit.menge == nil ? "Öffnet den Habit" : "Menge eintragen")
            Haken(an: voll, farbe: Farbe.handlung, beschriftung: habit.titel) {
                speicher.aendern { $0.habitUmschalten(habit.id, am: T) }
            }
        }
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
        let c = Farbe.handlung
        let w = HabitRechnung.woche(habit, montag: T.montag, seit: habit.angelegt, heute: T)
        Button { nav.oeffneHabit(habit.id) } label: {
            HStack(spacing: 12) {
                ZeichenKreis(symbol: habit.symbol).padding(.leading, 8)
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
                            Text(wochenText(w, n: n, T: T)).font(.unterzeile).foregroundStyle(w.erfuellt ? Farbe.akzent : Farbe.zweitrangig).lineLimit(1)
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
                                    Text(kurz[i]).font(.system(size: 9, weight: .bold)).foregroundStyle(a >= 1 ? Farbe.aufFarbe : (geplant ? Farbe.text : Farbe.pfeil))
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
            .padding(.trailing, 12)
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
                let c = Farbe.handlung
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
                                        .overlay(Capsule().strokeBorder(wert == s ? .clear : Farbe.linie, lineWidth: 1.5))
                                        .foregroundStyle(wert == s ? Farbe.aufFarbe : Farbe.text)
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
