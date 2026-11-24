import Charts
import SwiftUI

/// Analyse eines Habits oder Ziels im Rückblick. Nur Anzeige – gerechnet wird in `HabitRechnung`, `Kurs` und `Fortschritt`.
struct AnalyseAuswahl: Hashable {
    enum Art: Hashable { case habit, ziel }
    var art: Art
    var id: UUID
}

struct AnalyseSeite: View {
    var auswahl: AnalyseAuswahl
    var body: some View {
        switch auswahl.art {
        case .habit: HabitAnalyse(id: auswahl.id)
        case .ziel: ZielAnalyse(id: auswahl.id)
        }
    }
}

// MARK: Habit

struct HabitAnalyse: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let h = z.habit(id) {
            let c = Color(hex: h.farbe)
            let q30 = HabitRechnung.quote(h, heute: T, tage: 30)
            let serie = HabitRechnung.serie(h, heute: T)
            let beste = HabitRechnung.besteSerie(h, heute: T)
            let einheit: String = { if case .proWoche = h.rhythmus { return "Wochen" }; return "Tage" }()
            // abgeschlossene Wochen seit Anlage (die laufende Woche wäre wegen kommender Tage zu niedrig)
            let wochen = (1...12).compactMap { k -> (Tag, Double)? in
                let m = T.montag.plus(tage: -7 * (13 - k))
                guard m.plus(tage: 6) >= h.angelegt else { return nil }
                let w = HabitRechnung.woche(h, montag: m, seit: h.angelegt, heute: T)
                return w.geplant > 0 ? (m, min(1, w.erledigt / Double(w.geplant))) : nil
            }
            let leer = h.eintraege.isEmpty
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Verlaufskarte(farben: Farbe.verlauf(h.farbe)) {
                        HStack(spacing: 14) {
                            Image(systemName: h.symbol).font(.system(size: 22, weight: .bold))
                                .frame(width: 52, height: 52).background(.white.opacity(0.2), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Zahl.prozent(q30)).font(.grosseZahl)
                                Text("geschafft in den letzten 30 Tagen").font(.unterzeile).opacity(0.92)
                            }
                            Spacer(minLength: 0)
                        }
                        HStack(spacing: 10) {
                            Fakt(wert: "\(serie)", text: "\(einheit) Serie")
                            Fakt(wert: "\(beste)", text: "Beste Serie")
                            Fakt(wert: Zahl.prozent(HabitRechnung.quote(h, heute: T, tage: 90)), text: "90 Tage")
                        }
                        .padding(.top, 12)
                    }

                    if leer {
                        Hinweis(text: "Noch keine Einträge. Nach ein paar Tagen siehst du hier Muster.", symbol: "chart.bar")
                    } else {
                        WeisseKarte(titel: "Letzte 12 Wochen", wert: Zahl.prozent(HabitRechnung.quote(h, heute: T, tage: 84)),
                                    unter: "Jedes Kästchen ein Tag · kräftig = geschafft") {
                            TageRaster(habit: h, heute: T, farbe: c)
                        }
                        WeisseKarte(titel: "Je Woche", wert: wochen.last.map { Zahl.prozent($0.1) } ?? "–", unter: "letzte volle Woche · Linie = alles geschafft") {
                            Chart(wochen, id: \.0) { m, a in
                                BarMark(x: .value("Woche", m.datum(), unit: .weekOfYear), y: .value("Anteil", a))
                                    .foregroundStyle(c.gradient).cornerRadius(3)
                                RuleMark(y: .value("Soll", 1)).foregroundStyle(Farbe.linie).lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            }
                            .chartYScale(domain: 0...1)
                            .chartYAxis(.hidden)
                            .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 4)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                            .frame(height: 120)
                            .accessibilityLabel("Anteil je Woche, letzte 12 Wochen")
                        }
                    }

                    VStack(spacing: 0) {
                        Zeile(titel: "Rhythmus", wert: HabitRechnung.haeufigkeit(h))
                        Zeile(titel: "Seit", wert: h.angelegt.datum().formatted(.dateTime.day().month(.abbreviated).year()))
                        Zeile(titel: "Insgesamt", wert: "\(Zahl.text(HabitRechnung.summe(h, von: h.angelegt, bis: T), stellen: 1)) Mal geschafft")
                        if let g = z.ziel(h.zielID) {
                            Button { nav.zeigeAnalyse(ziel: g.id) } label: { Zeile(titel: "Zählt für", wert: g.titel, pfeil: true) }.buttonStyle(.plain)
                        }
                    }
                    .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button { nav.oeffneHabit(h.id) } label: {
                        Label("Zum Habit", systemImage: "arrow.right").font(.kompass(.subheadline, .bold))
                            .frame(maxWidth: .infinity, minHeight: 48).foregroundStyle(c)
                            .background(c.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(DruckStil())
                }
                .padding(Mass.rand).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(h.titel)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Habit nicht gefunden", systemImage: "questionmark", description: Text("Er wurde vielleicht gelöscht."))
        }
    }
}

/// 12 Wochen × 7 Tage: Deckkraft = Anteil des Tages, grau = nicht geplant, leer = vor Anlage oder Zukunft.
private struct TageRaster: View {
    var habit: Habit
    var heute: Tag
    var farbe: Color
    var body: some View {
        let start = heute.montag.plus(tage: -7 * 11)
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { w in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { t in
                        let d = start.plus(tage: 7 * w + t)
                        let aktiv = d >= habit.angelegt && d <= heute
                        let a = habit.anteil(am: d)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(!aktiv ? Color.clear : a > 0 ? farbe.opacity(0.25 + 0.75 * a) : HabitRechnung.geplant(habit, am: d) ? Farbe.linie : Farbe.linie.opacity(0.4))
                            .overlay { if d == heute { RoundedRectangle(cornerRadius: 3).stroke(Farbe.text, lineWidth: 1.5) } }
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Tage der letzten 12 Wochen")
    }
}

// MARK: Ziel

struct ZielAnalyse: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        if let g = z.ziel(id) {
            let c = Color(hex: g.farbe)
            let kurs = Kurs.aufKurs(g, in: z, heute: T)
            let verlauf = (z.verlauf[g.id] ?? []).sorted { $0.tag < $1.tag }
            let prognose = Kurs.prognose(verlauf: verlauf, fortschritt: kurs.fortschritt, heute: T)
            let einsatz = (0..<8).map { k -> (Tag, Double) in
                let m = T.montag.plus(tage: -7 * (7 - k))
                return (m, Fortschritt.zeit(ziel: g.id, in: z, von: m, bis: m.plus(tage: 6)) / 3600)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Verlaufskarte(farben: Farbe.verlauf(g.farbe)) {
                        HStack(spacing: 14) {
                            Image(systemName: g.symbol).font(.system(size: 22, weight: .bold))
                                .frame(width: 52, height: 52).background(.white.opacity(0.2), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl)
                                Text("\(kurs.lage.text.prefix(1).uppercased() + kurs.lage.text.dropFirst()) · \(Kurs.bisText(g.faellig, heute: T))")
                                    .font(.unterzeile).opacity(0.92).lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Button { nav.blatt = .rechnung(g.id) } label: { Image(systemName: "info.circle").font(.title3).opacity(0.85) }
                                .accessibilityLabel("So wird gerechnet")
                        }
                        HStack(spacing: 10) {
                            Fakt(wert: Zahl.prozent(kurs.erwartet), text: "Plan heute")
                            Fakt(wert: Self.prognoseKurz(prognose), text: "Prognose")
                        }
                        .padding(.top, 12)
                    }

                    WeisseKarte(titel: "Verlauf", wert: Zahl.prozent(kurs.fortschritt), unter: Self.prognoseText(prognose, faellig: g.faellig)) {
                        if verlauf.count < 2 {
                            Text("Ab dem zweiten Tag siehst du hier die Kurve.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                        } else {
                            Chart {
                                ForEach(verlauf, id: \.tag) { p in
                                    LineMark(x: .value("Tag", p.tag.datum()), y: .value("Stand", p.wert), series: .value("Art", "Ist"))
                                        .foregroundStyle(c).interpolationMethod(.stepEnd)
                                }
                                LineMark(x: .value("Tag", g.angelegt.datum()), y: .value("Stand", 0.0), series: .value("Art", "Plan"))
                                    .foregroundStyle(Farbe.zweitrangig).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                LineMark(x: .value("Tag", g.faellig.datum()), y: .value("Stand", 1.0), series: .value("Art", "Plan"))
                                    .foregroundStyle(Farbe.zweitrangig).lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                RuleMark(x: .value("Heute", T.datum())).foregroundStyle(Farbe.linie)
                            }
                            .chartYScale(domain: 0...1)
                            .chartYAxis { AxisMarks(values: [0, 0.5, 1]) { v in AxisGridLine(); AxisValueLabel { Text("\(Int((v.as(Double.self) ?? 0) * 100)) %") } } }
                            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 3)) { AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits)) } }
                            .frame(height: 150)
                            .accessibilityLabel("Fortschritt über die Zeit, gestrichelt der Plan")
                        }
                    }

                    if !g.schritte.isEmpty {
                        WeisseKarte(titel: "Meilensteine", wert: "\(g.schritte.filter { Fortschritt.stand($0, in: z, heute: T).anteil >= 1 }.count) von \(g.schritte.count)",
                                    unter: "Stand · Anteil am Ziel") {
                            VStack(spacing: 10) {
                                ForEach(g.schritte) { s in
                                    let st = Fortschritt.stand(s, in: z, heute: T)
                                    HStack(spacing: 8) {
                                        Image(systemName: s.art.symbol).font(.caption.weight(.bold)).foregroundStyle(c).frame(width: 18)
                                        Text(s.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                                        Balken(anteil: st.anteil, farbe: c, spur: Farbe.linie, hoehe: 6).frame(width: 70)
                                        Text(Zahl.prozent(st.anteil)).font(.klein).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8).foregroundStyle(Farbe.zweitrangig).frame(width: 50, alignment: .trailing)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }

                    WeisseKarte(titel: "Einsatz", wert: Zahl.dauer(einsatz.reduce(0) { $0 + $1.1 } * 3600), unter: "letzte 8 Wochen · Fokus und Termine") {
                        Chart(einsatz, id: \.0) { m, h in
                            BarMark(x: .value("Woche", m.datum(), unit: .weekOfYear), y: .value("Stunden", h)).foregroundStyle(c.gradient).cornerRadius(3)
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { AxisValueLabel(format: .dateTime.day().month(.abbreviated)) } }
                        .frame(height: 100)
                        .accessibilityLabel("Stunden je Woche für dieses Ziel")
                    }

                    let habits = z.habits.filter { $0.zielID == g.id }
                    if !habits.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(habits) { h in
                                Button { nav.zeigeAnalyse(habit: h.id) } label: {
                                    Zeile(titel: h.titel, wert: "\(Zahl.prozent(HabitRechnung.quote(h, heute: T))) · 30 Tage", pfeil: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }

                    Button { nav.oeffneZiel(g.id) } label: {
                        Label("Zum Ziel", systemImage: "arrow.right").font(.kompass(.subheadline, .bold))
                            .frame(maxWidth: .infinity, minHeight: 48).foregroundStyle(c)
                            .background(c.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(DruckStil())
                }
                .padding(Mass.rand).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(g.titel)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "questionmark", description: Text("Es wurde vielleicht gelöscht."))
        }
    }

    /// Text zur Prognose (rechenregeln.md §5) – nur Formulierung, gerechnet wird in `Kurs.prognose`.
    nonisolated static func prognoseText(_ p: Kurs.Prognose, faellig: Tag) -> String {
        switch p {
        case .keine: return "Prognose ab 7 Tagen Verlauf"
        case .keinFortschritt(let t): return "Seit \(t) Tagen kein Fortschritt"
        case .datum(let d, _, _):
            let diff = d.tage(bis: faellig)
            let wann = d.datum().formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE")))
            if diff == 0 { return "Bei diesem Tempo fertig am \(wann) – genau zur Frist" }
            return diff > 0 ? "Bei diesem Tempo fertig am \(wann) – \(diff) Tage vor der Frist"
                            : "Bei diesem Tempo fertig am \(wann) – \(-diff) Tage nach der Frist"
        }
    }

    nonisolated static func prognoseKurz(_ p: Kurs.Prognose) -> String {
        switch p {
        case .keine: "–"
        case .keinFortschritt: "steht"
        case .datum(let d, _, _): d.datum().formatted(.dateTime.month(.abbreviated).year().locale(Locale(identifier: "de_DE")))
        }
    }
}

// MARK: Bausteine

private struct Fakt: View {
    var wert: String
    var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(wert).font(.kompass(.title3, .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(text).font(.klein).opacity(0.85).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10).background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct Zeile: View {
    var titel: String
    var wert: String
    var pfeil = false
    var body: some View {
        HStack {
            Text(titel).font(.unterzeile).foregroundStyle(Farbe.text)
            Spacer()
            Text(wert).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
            if pfeil { Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Farbe.pfeil) }
        }
        .padding(.horizontal, 16).frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

private struct Hinweis: View {
    var text: String
    var symbol: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Farbe.akzent)
            Text(text).font(.unterzeile).foregroundStyle(Farbe.text.opacity(0.8))
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
