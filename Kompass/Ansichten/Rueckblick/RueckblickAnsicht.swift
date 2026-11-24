import Charts
import SwiftUI

/// Rückblick (Konzept `rueckblick-analysen.md`, Entwurf 4 nach Hick’s Law): Zeitraum oben, dann fünf Karten –
/// Flugbericht · Tower · Flugplan · Logbuch · Debriefing; acht weitere hinter „Details“. Jede Zahl hat ein Warum-Blatt.
struct RueckblickAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @AppStorage("rueckblick.zeitraum") private var zeitraumRoh = Rueckblick.Zeitraum.woche.rawValue
    @State private var versatz = 0
    @State private var details = false
    @State private var warum: Warum?
    @State private var gezeigt = ""

    private var zeitraum: Rueckblick.Zeitraum { Rueckblick.Zeitraum(rawValue: zeitraumRoh) ?? .woche }

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let (von, bis) = Rueckblick.spanne(zeitraum, versatz: versatz, heute: T)
        let k = Rueckblick.kennzahlen(zustand: z, von: von, bis: bis, heute: T, termine: speicher.termine(am:))
        let verlauf = Rueckblick.wochenVerlauf(zustand: z, heute: T, termine: speicher.termine(am:))
        let reife = Rueckblick.reifeWochen(zustand: z, heute: T)
        let planNormal = reife >= 4 ? Rueckblick.normal(verlauf.map(\.planQuote)) : nil
        let zielNormal = reife >= 4 ? Rueckblick.normal(verlauf.map(\.zielAnteil)) : nil
        let fokusNormal = reife >= 4 ? Rueckblick.normal(verlauf.map(\.fokus)) : nil
        let laufendeWoche = Rueckblick.kennzahlen(zustand: z, von: T.montag, bis: T.montag.plus(tage: 6), heute: T, termine: speicher.termine(am:))
        let tower = Rueckblick.tower(Rueckblick.muster(zustand: z, heute: T, woche: laufendeWoche, verlauf: verlauf, reife: reife, termine: speicher.termine(am:)),
                                     lernen: z.lernen.rueckblick, heute: T)
        let aktiv = z.ziele.filter { $0.status == .aktiv }

        Seite(titel: "Rückblick", info: .rueckblick, oben: AnyView(zeitraumWahl(von: von, bis: bis))) {
            VStack(spacing: 12) {
                // 1 Flugbericht (in der Woche hinter der Bordkarte)
                if zeitraum == .woche {
                    // Vergleich mit gleichem Stand der Vorwoche (Mo–heute gegen Mo–gleicher Wochentag)
                    let vorherBis = versatz == 0 ? von.plus(tage: -7 + T.wochentag - 1) : von.plus(tage: -1)
                    let vorher = Rueckblick.kennzahlen(zustand: z, von: von.plus(tage: -7), bis: vorherBis, heute: T, termine: speicher.termine(am:))
                    Bordkarte(woche: von.text, kw: von.kalenderwoche, von: von, bis: bis, fokus: k.fokus, ziele: aktiv.count) {
                        flugbericht(k, planNormal: planNormal, zielNormal: zielNormal, vorher: vorher, laufend: versatz == 0)
                    }
                    .id(von.text)
                } else {
                    flugbericht(k, planNormal: planNormal, zielNormal: zielNormal, vorher: nil, laufend: versatz == 0)
                }

                // 2 Tower
                if reife < 4 {
                    LerntNoch(titel: "Tower", text: "Ab 4 Wochen meldet der Tower, was auffällt.", anteil: Double(reife) / 4, rest: "noch \(max(1, 28 - reife * 7)) Tage")
                } else if !tower.isEmpty {
                    Label("Tower · fällt auf", systemImage: "antenna.radiowaves.left.and.right").labelStil()
                    ForEach(tower) { h in towerKarte(h) }
                }

                // 3 Flugplan
                if !aktiv.isEmpty { flugplan(aktiv, von: von, bis: bis, T: T) }

                // Details (8 Karten)
                Button { withAnimation(.snappy) { details.toggle() } } label: {
                    Label(details ? "Details ausblenden" : "Details ansehen", systemImage: details ? "chevron.up" : "chevron.down")
                        .font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                        .frame(maxWidth: .infinity, minHeight: 44).background(Farbe.akzentWeich, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("rueckblick.details")
                if details {
                    treibstoff(aktiv, k: k, von: von, bis: bis, T: T)
                    flugzeit(k)
                    checkliste(k, reife: reife)
                    habits(von: von, bis: bis, T: T, reife: reife)
                    if reife >= 8 { LerntNoch(titel: "Radar · deine starke Zeit", text: "Kompass sammelt ab jetzt die Uhrzeiten deiner Fokuszeit.", anteil: 0, rest: "ab dem nächsten Fokus") }
                    else { LerntNoch(titel: "Radar · deine starke Zeit", text: "Ab 8 Wochen: wann du am meisten schaffst.", anteil: Double(reife) / 8, rest: "noch \(max(1, 8 - reife)) Wochen") }
                    LerntNoch(titel: "ETA · Zeitgefühl", text: "Ab 5 Aufgaben mit Fokus: wie lange Aufgaben wirklich dauern.", anteil: min(1, Double(z.aufgaben.filter { $0.erledigt && $0.fokusSekunden >= 300 }.count) / 5), rest: nil)
                    if let f = fokusNormal { normalKarte("Fokus", wert: Zahl.dauer(k.fokus), normal: f, lage: f.lage(k.fokus), text: { Zahl.dauer($0) }) }
                }

                // 4 Logbuch
                logbuch(von: von, bis: bis, T: T, z: z)

                // 5 Debriefing (Woche)
                if zeitraum == .woche {
                    let fertig = z.reflexionen["woche:\(von.text)"] != nil
                    PfeilZeile(symbol: fertig ? "checkmark.seal" : "headphones", text: fertig ? "Debriefing ✓" : "Debriefing · 3 Fragen") { nav.blatt = .reflexion(woche: true) }
                }
            }
            .padding(.top, 4)
        }
        .sheet(item: $warum) { w in WarumBlatt(w: w) { hilfreich in
            let m = w.muster, T = speicher.heute
            if let m { speicher.aendern { $0.rueckblickRueckmeldung(muster: m, hilfreich: hilfreich, heute: T) } }
        } }
        .onChange(of: zeitraumRoh) { versatz = 0; details = false }
        .onAppear {
            let ids = tower.map(\.muster).joined(separator: ",")
            if ids != gezeigt, !ids.isEmpty { gezeigt = ids; speicher.aendern { $0.rueckblickGezeigt(tower.map(\.muster)) } }
        }
    }

    // MARK: Zeitraum

    private func zeitraumWahl(von: Tag, bis: Tag) -> some View {
        VStack(spacing: 8) {
            Picker("Zeitraum", selection: $zeitraumRoh) {
                ForEach(Rueckblick.Zeitraum.allCases, id: \.rawValue) { Text($0.name).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("rueckblick.zeitraum")
            HStack {
                Button { versatz -= 1 } label: { Image(systemName: "chevron.left").font(.body.weight(.semibold)).frame(width: 44, height: 44) }.accessibilityLabel("Zurück")
                Spacer()
                Text(spannenText(von, bis)).font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text)
                Spacer()
                Button { versatz += 1 } label: { Image(systemName: "chevron.right").font(.body.weight(.semibold)).frame(width: 44, height: 44) }.accessibilityLabel("Vor").disabled(versatz >= 0)
            }
            .foregroundStyle(Farbe.akzent)
        }
    }

    private func spannenText(_ von: Tag, _ bis: Tag) -> String {
        let de = Locale(identifier: "de_DE")
        switch zeitraum {
        case .woche: return "KW \(von.kalenderwoche) · \(von.datum().formatted(.dateTime.day().month(.abbreviated).locale(de))) – \(bis.datum().formatted(.dateTime.day().month(.abbreviated).locale(de)))"
        case .monat: return von.datum().formatted(.dateTime.month(.wide).year().locale(de))
        case .jahr: return "\(von.jahr)"
        }
    }

    // MARK: Karten

    private func flugbericht(_ k: Rueckblick.Kennzahlen, planNormal: Rueckblick.Normal?, zielNormal: Rueckblick.Normal?, vorher: Rueckblick.Kennzahlen?, laufend: Bool) -> some View {
        Verlaufskarte(farben: Farbe.indigo) {
            HStack {
                Label("Flugbericht", systemImage: "airplane.departure").font(.klein).opacity(0.85)
                Spacer()
                warumKnopf(Warum(titel: "Flugbericht", satz: "Zwei Zahlen: was du dir vorgenommen und geschafft hast – und wie viel deiner Zeit an Ziele ging.",
                                 zahlen: [("Plan geschafft", "\(Zahl.text(k.planGeschafft, stellen: 0)) von \(k.planGeplant)"), ("Zeit für Ziele", Zahl.prozent(k.zielAnteil))]
                                 + (planNormal.map { [("Dein Normal (Plan)", "\(Zahl.prozent($0.unten))–\(Zahl.prozent($0.oben))")] } ?? [])
                                 + (zielNormal.map { [("Dein Normal (Ziele)", "\(Zahl.prozent($0.unten))–\(Zahl.prozent($0.oben))")] } ?? []),
                                 rechnung: "Plan geschafft = erledigte Aufgaben + Habit-Anteile ÷ geplante. Zeit für Ziele = Zeit mit Ziel ÷ erfasste Zeit (Fokus, Termine, Habits; Überlappungen zählen einmal). Dein Normal = Median der letzten 8 Wochen ± 1,5 × übliche Abweichung.",
                                 sicher: planNormal == nil ? 1 : 3, muster: nil), hell: true)
            }
            Text(Rueckblick.satz(k, planNormal: planNormal, zielNormal: zielNormal, zeitraum: zeitraum, laufend: laufend))
                .font(.system(.title3, design: .serif, weight: .medium)).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                kennzahl("Plan geschafft", "\(Zahl.text(k.planGeschafft, stellen: 0)) von \(k.planGeplant)", wert: k.planQuote, normal: planNormal,
                         delta: vorher.map { d in let x = Int(k.planGeschafft - d.planGeschafft); return x == 0 ? "wie Vorwoche" : "\(x > 0 ? "↑" : "↓") \(abs(x)) ggü. Vorwoche" })
                kennzahl("Zeit für Ziele", Zahl.prozent(k.zielAnteil), wert: k.zielAnteil, normal: zielNormal,
                         delta: vorher.map { d in let x = Int(((k.zielAnteil - d.zielAnteil) * 100).rounded()); return x == 0 ? "wie Vorwoche" : "\(x > 0 ? "↑" : "↓") \(abs(x)) Punkte" })
            }
            .padding(.top, 8)
        }
    }

    private func kennzahl(_ titel: String, _ text: String, wert: Double, normal: Rueckblick.Normal?, delta: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titel).font(.klein).opacity(0.85)
            Text(text).font(.system(.title2, design: .serif, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
            if let n = normal { NormalBand(wert: wert, normal: n, hell: true) }
            if let delta { Text(delta).font(.klein).foregroundStyle(Farbe.seladon) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func towerKarte(_ h: Rueckblick.Hinweis) -> some View {
        let farbe: Color = h.familie == .ziele ? Farbe.TonArt.seladonTief.farbe : h.familie == .planen ? Farbe.gold : Farbe.akzent
        return VStack(alignment: .leading, spacing: 8) {
            Text(h.satz).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                if let a = h.handlung {
                    Button { handlung(h) } label: {
                        Text(a).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.aufFarbe).padding(.horizontal, 14).frame(minHeight: 36).background(Farbe.akzent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                warumKnopf(Warum(titel: h.titel, satz: h.satz, zahlen: h.zahlen, rechnung: h.rechnung, sicher: h.sicher, muster: h.muster), hell: false)
                Spacer()
                Sicher(stufe: h.sicher)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .leading) { RoundedRectangle(cornerRadius: 2).fill(farbe).frame(width: 4).padding(.vertical, 12) }
        .accessibilityElement(children: .contain)
    }

    private func handlung(_ h: Rueckblick.Hinweis) {
        switch h.muster {
        case "zielRuht": if let g = h.zielID { nav.oeffneZiel(g) }
        case "habitWackelt": if let id = h.habitID { nav.blatt = .habitBearbeiten(id, .menge) }
        case "zuVielGeplant": nav.oeffneKalender(speicher.heute, modus: .woche)
        default: break
        }
    }

    private func flugplan(_ ziele: [Ziel], von: Tag, bis: Tag, T: Tag) -> some View {
        let z = speicher.zustand
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Flugplan · Ziele", systemImage: "point.topleft.down.to.point.bottomright.curvepath").labelStil()
                Spacer()
                warumKnopf(Warum(titel: "Flugplan", satz: "Jede Route: KMP → Ziel. Das Flugzeug steht beim Fortschritt, der leuchtende Teil kam in diesem Zeitraum dazu.",
                                 zahlen: ziele.map { ($0.titel, Zahl.prozent(Fortschritt.ziel($0, in: z, heute: T))) },
                                 rechnung: "Zuwachs = Fortschritt am Ende − am Anfang des Zeitraums (täglicher Verlauf). Lage nach §4, voraussichtlich fertig nach §5.", sicher: 3, muster: nil), hell: false)
            }
            ForEach(ziele.sorted { a, b in Kurs.aufKurs(a, in: z, heute: T).lage == .hinterher && Kurs.aufKurs(b, in: z, heute: T).lage != .hinterher }) { g in
                Route(ziel: g, von: von, bis: bis, T: T) { nav.oeffneZiel(g.id) }
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func treibstoff(_ ziele: [Ziel], k: Rueckblick.Kennzahlen, von: Tag, bis: Tag, T: Tag) -> some View {
        let z = speicher.zustand
        let wochen = max(1.0, Double(max(1, von.tage(bis: bis) + 1)) / 7)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Treibstoff · nötig pro Woche", systemImage: "fuelpump").labelStil()
            ForEach(ziele) { g in
                let zeit = ziele.isEmpty ? 0 : (k.jeZiel[g.id] ?? 0) / 3600
                let offen = g.schritte.filter { $0.art == .zeit && !$0.geschafft }.reduce(0.0) { $0 + max(0, ($1.soll ?? 0) - Fortschritt.stunden(von: $1, in: z, heute: T)) }
                let restWochen = max(1.0, Double(T.tage(bis: g.faellig)) / 7)
                let noetig = offen > 0 ? offen / restWochen * wochen * LernRechnung.zeitfaktor(z.lernen.zeitVerhaeltnisse) : nil
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(g.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1); Spacer()
                        Text(noetig.map { "\(Zahl.text(zeit, stellen: 1)) h / nötig \(Zahl.text($0, stellen: 1)) h\(zeit >= $0 ? " ✓" : "")" } ?? "\(Zahl.text(zeit, stellen: 1)) h · kein Soll").font(.klein).foregroundStyle(Farbe.zweitrangig) }
                    GeometryReader { gr in
                        let skala = max(zeit, noetig ?? 0, 0.1) * 1.25
                        ZStack(alignment: .leading) {
                            Capsule().fill(Farbe.linie)
                            Capsule().fill(Color(hex: g.farbe)).frame(width: gr.size.width * zeit / skala)
                            if let n = noetig { Rectangle().fill(Farbe.text).frame(width: 2, height: 16).offset(x: gr.size.width * n / skala) }
                        }
                    }
                    .frame(height: 10)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func flugzeit(_ k: Rueckblick.Kennzahlen) -> some View {
        let z = speicher.zustand
        let teile = k.jeZiel.compactMap { id, s in z.ziel(id).map { ($0, s) } }.sorted { $0.1 > $1.1 }
        let ohne = k.ohneZiel.sorted { $0.value > $1.value }.first
        return VStack(alignment: .leading, spacing: 10) {
            HStack { Label("Flugzeit · Zeit für Ziele", systemImage: "timer").labelStil(); Spacer()
                Text("\(Zahl.prozent(k.zielAnteil)) von \(Zahl.dauer(k.zeitErfasst))").font(.klein).foregroundStyle(Farbe.zweitrangig) }
            if k.zeitErfasst > 0 {
                GeometryReader { gr in
                    HStack(spacing: 2) {
                        ForEach(teile, id: \.0.id) { g, s in Rectangle().fill(Color(hex: g.farbe)).frame(width: max(2, gr.size.width * s / k.zeitErfasst * (k.zeitFuerZiele / max(1, teile.reduce(0) { $0 + $1.1 })))) }
                        Rectangle().fill(Farbe.linie)
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 14)
                FliessLayout(abstand: 8) {
                    ForEach(teile, id: \.0.id) { g, s in Label(Zahl.dauer(s), systemImage: "circle.fill").font(.klein).foregroundStyle(Color(hex: g.farbe)).labelStyle(.titleAndIcon) }
                    if let ohne { Text("ohne Ziel \(Zahl.dauer(ohne.value)) · \(ohne.key)").font(.klein).foregroundStyle(Farbe.zweitrangig) }
                }
            } else {
                Text("Noch keine Zeit erfasst. Fokus starten oder Termine mit einem Ziel verbinden.").font(.klein).foregroundStyle(Farbe.zweitrangig)
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func checkliste(_ k: Rueckblick.Kennzahlen, reife: Int) -> some View {
        let geplant = k.planGeplant - k.habitsGeplant
        let geschafft = Int(k.planGeschafft - k.habitsErledigt)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Checkliste · Plan und Wirklichkeit", systemImage: "checklist").labelStil()
            HStack(spacing: 6) {
                zahlKachel("\(geplant)", "Aufgaben"); zahlKachel("\(geschafft)", "geschafft"); zahlKachel("\(max(0, geplant - geschafft))", "offen")
                zahlKachel("\(k.habitsGeplant > 0 ? Zahl.prozent(k.habitsErledigt / Double(k.habitsGeplant)) : "–")", "Habits")
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func zahlKachel(_ w: String, _ t: String) -> some View {
        VStack(spacing: 2) {
            Text(w).font(.system(.title3, design: .serif, weight: .semibold)).foregroundStyle(Farbe.text).lineLimit(1).minimumScaleFactor(0.7)
            Text(t).font(.system(size: 10, weight: .bold)).foregroundStyle(Farbe.zweitrangig)
        }
        .frame(maxWidth: .infinity, minHeight: 56).background(Farbe.grund, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func habits(von: Tag, bis: Tag, T: Tag, reife: Int) -> some View {
        let z = speicher.zustand
        return VStack(alignment: .leading, spacing: 8) {
            Label("Habits", systemImage: "repeat").labelStil()
            if z.habits.isEmpty { Text("Noch keine Habits.").font(.klein).foregroundStyle(Farbe.zweitrangig) }
            ForEach(z.habits) { h in
                let q = HabitRechnung.quote(alle: [h], von: von, bis: bis, heute: T)
                let trend = (1...4).reversed().map { i -> Double in let m = T.montag.plus(tage: -7 * i); let w = HabitRechnung.quote(alle: [h], von: m, bis: m.plus(tage: 6), heute: T); return w.geplant > 0 ? w.erledigt / Double(w.geplant) : 0 }
                Button { nav.zeigeAnalyse(habit: h.id) } label: {
                    HStack(spacing: 8) {
                        Text(h.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                        Sparkline(werte: trend, farbe: Color(hex: h.farbe)).frame(width: 52, height: 18)
                        Text(q.geplant > 0 ? Zahl.prozent(q.erledigt / Double(q.geplant)) : "–").font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig).frame(width: 44, alignment: .trailing)
                        Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
                    }
                    .frame(minHeight: 32).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(h.titel), \(q.geplant > 0 ? Zahl.prozent(q.erledigt / Double(q.geplant)) : "ohne Daten")")
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func normalKarte(_ titel: String, wert: String, normal: Rueckblick.Normal, lage: Rueckblick.Normal.Lage, text: (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Label(titel, systemImage: "gauge.with.needle").labelStil(); Spacer(); Text(wert).font(.system(.title3, design: .serif, weight: .semibold)).foregroundStyle(Farbe.text) }
            NormalBand(wert: 0, normal: normal, hell: false, roh: true)
            Text("Dein Normal \(text(normal.unten))–\(text(normal.oben)) · \(lage == .ueber ? "darüber" : lage == .unter ? "darunter" : "mittendrin")").font(.klein).foregroundStyle(Farbe.zweitrangig)
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func logbuch(von: Tag, bis: Tag, T: Tag, z: Zustand) -> some View {
        let k = speicher.kalender
        let erledigt = z.aufgaben.filter { a in a.erledigt && a.erledigtAm.map { Tag($0, kalender: k) >= von && Tag($0, kalender: k) <= bis } == true }
        let meilensteine = z.ziele.flatMap { g in g.schritte.filter(\.geschafft).map { (g, $0) } }
        let serien = z.habits.map { ($0, HabitRechnung.serie($0, heute: T)) }.filter { $0.1 >= 3 }.sorted { $0.1 > $1.1 }
        return VStack(alignment: .leading, spacing: 10) {
            HStack { Label("Logbuch · geschafft", systemImage: "book.closed").labelStil(); Spacer(); Text("\(erledigt.count) Aufgaben").font(.klein).foregroundStyle(Farbe.zweitrangig) }
            HStack(spacing: 8) {
                if let (g, s) = meilensteine.last { Stempel(oben: "⚑", text: s.titel, farbe: Color(hex: g.farbe)) }
                if let (h, n) = serien.first { Stempel(oben: "🔥 \(n)", text: h.titel, farbe: Color(hex: h.farbe)) }
                if let a = erledigt.last { Stempel(oben: "✓", text: a.titel, farbe: Farbe.akzent) }
                if meilensteine.isEmpty && serien.isEmpty && erledigt.isEmpty { Text("Noch nichts eingetragen.").font(.klein).foregroundStyle(Farbe.zweitrangig) }
            }
        }
        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Warum

    struct Warum: Identifiable {
        var id: String { titel + (muster ?? "") }
        var titel: String
        var satz: String
        var zahlen: [(String, String)]
        var rechnung: String
        var sicher: Int
        var muster: String?
    }

    private func warumKnopf(_ w: Warum, hell: Bool) -> some View {
        Button { warum = w } label: {
            Text("i").font(.system(.caption, design: .rounded, weight: .heavy))
                .frame(width: 26, height: 26)
                .background(hell ? .white.opacity(0.18) : Farbe.akzentWeich, in: Circle())
                .foregroundStyle(hell ? .white : Farbe.akzent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Warum sehe ich das?")
    }
}

// MARK: Bausteine

private extension Label where Title == Text, Icon == Image {
    func labelStil() -> some View { self.font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Farbe.zweitrangig).textCase(.uppercase).tracking(1) }
}

/// Band „dein Normal“ mit dem aktuellen Wert als Punkt.
private struct NormalBand: View {
    var wert: Double
    var normal: Rueckblick.Normal
    var hell: Bool
    var roh = false
    var body: some View {
        GeometryReader { g in
            let lo = min(normal.unten, wert) * 0.9, hi = max(normal.oben, wert) * 1.1 + 0.0001
            let x: (Double) -> CGFloat = { CGFloat(($0 - lo) / (hi - lo)) * g.size.width }
            ZStack(alignment: .leading) {
                Capsule().fill(hell ? .white.opacity(0.12) : Farbe.linie)
                Capsule().fill(hell ? Farbe.seladon.opacity(0.35) : Farbe.akzentWeich).frame(width: max(4, x(normal.oben) - x(normal.unten))).offset(x: x(normal.unten))
                if !roh { Circle().fill(Farbe.gold).frame(width: 14, height: 14).overlay(Circle().stroke(hell ? Color(roh: "#0F1A35") : Farbe.karte, lineWidth: 2)).offset(x: x(wert) - 7, y: -3) }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

private struct Sicher: View {
    var stufe: Int
    var body: some View {
        HStack(spacing: 2) { ForEach(1...3, id: \.self) { i in RoundedRectangle(cornerRadius: 1).fill(i <= stufe ? Farbe.akzent : Farbe.linie).frame(width: 5, height: 10) } }
            .accessibilityLabel(["erster Hinweis", "ziemlich sicher", "sicher"][stufe - 1])
    }
}

private struct Sparkline: View {
    var werte: [Double]
    var farbe: Color
    var body: some View {
        GeometryReader { g in
            Path { p in
                for (i, w) in werte.enumerated() {
                    let pt = CGPoint(x: g.size.width * CGFloat(i) / CGFloat(max(1, werte.count - 1)), y: g.size.height * (1 - CGFloat(w)))
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
            }
            .stroke(farbe, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

private struct Stempel: View {
    var oben: String
    var text: String
    var farbe: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(oben).font(.system(.headline, design: .serif, weight: .semibold)).foregroundStyle(farbe)
            Text(text).font(.system(size: 10, weight: .bold)).foregroundStyle(Farbe.text).lineLimit(2).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 60).padding(6)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Farbe.gold.opacity(0.55), lineWidth: 1.5))
        .rotationEffect(.degrees(-2))
        .accessibilityElement(children: .combine)
    }
}

private struct LerntNoch: View {
    var titel: String
    var text: String
    var anteil: Double
    var rest: String?
    var body: some View {
        VStack(spacing: 6) {
            Text(titel).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text)
            Text(text).font(.klein).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.center)
            Capsule().fill(Farbe.linie).frame(height: 6).overlay(alignment: .leading) { GeometryReader { g in Capsule().fill(Farbe.akzent).frame(width: g.size.width * min(1, anteil)) } }
            if let rest { Text(rest).font(.klein).foregroundStyle(Farbe.zweitrangig) }
        }
        .padding(14).frame(maxWidth: .infinity)
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Farbe.linie, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
        .accessibilityElement(children: .combine)
    }
}

/// Ein Ziel als Route KMP → Kürzel: Flugzeug beim Fortschritt, der Zuwachs im Zeitraum leuchtet.
private struct Route: View {
    var ziel: Ziel
    var von: Tag
    var bis: Tag
    var T: Tag
    var oeffnen: () -> Void
    @Environment(Speicher.self) private var speicher
    var body: some View {
        let z = speicher.zustand
        let p = Fortschritt.ziel(ziel, in: z, heute: T)
        let verlauf = (z.verlauf[ziel.id] ?? []).sorted { $0.tag < $1.tag }
        let anfang = verlauf.last { $0.tag < von }?.wert ?? verlauf.first?.wert ?? p
        let zuwachs = max(0, p - anfang)
        let kurs = Kurs.aufKurs(ziel, in: z, heute: T)
        let prognose = Kurs.prognose(verlauf: verlauf, fortschritt: p, heute: T)
        let c = Color(hex: ziel.farbe)
        Button(action: oeffnen) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("KMP").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Farbe.zweitrangig)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Farbe.linie).frame(height: 1).frame(maxHeight: .infinity)
                            Capsule().fill(c.opacity(0.5)).frame(width: g.size.width * p, height: 3)
                            Capsule().fill(c).frame(width: g.size.width * zuwachs, height: 3).offset(x: g.size.width * (p - zuwachs)).shadow(color: c, radius: 4)
                            Image(systemName: "airplane").font(.system(size: 13, weight: .bold)).foregroundStyle(Farbe.text).offset(x: g.size.width * p - 7)
                        }
                    }
                    .frame(height: 20)
                    Text(FlugRechnung.kuerzel(ziel.titel)).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Farbe.goldText)
                }
                HStack {
                    Text(ziel.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1)
                    Spacer()
                    Text(kurs.lage.text).font(.system(size: 10, weight: .heavy)).padding(.horizontal, 6).frame(minHeight: 18)
                        .background(kurs.lage == .hinterher || kurs.lage == .ueberfaellig ? Farbe.warnungGrund : Farbe.akzentWeich, in: Capsule())
                        .foregroundStyle(kurs.lage == .hinterher || kurs.lage == .ueberfaellig ? Farbe.goldText : Farbe.akzent)
                    Text(zuwachs > 0 ? "+\(Int((zuwachs * 100).rounded())) Pkt" : "±0").font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig)
                    if case .datum(let d, _, _) = prognose { Text(d.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))).font(.klein).foregroundStyle(Farbe.zweitrangig) }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ziel.titel), \(Zahl.prozent(p)), \(kurs.lage.text), Zuwachs \(Int((zuwachs * 100).rounded())) Punkte")
    }
}

/// „Warum sehe ich das?“ – Zahlen, Rechnung, wie sicher; Hilfreich / Passt nicht.
private struct WarumBlatt: View {
    var w: RueckblickAnsicht.Warum
    var rueckmeldung: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(w.satz).font(.unterzeile).foregroundStyle(Farbe.text).fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 0) {
                        ForEach(Array(w.zahlen.enumerated()), id: \.offset) { _, z in
                            HStack { Text(z.0).font(.klein).foregroundStyle(Farbe.zweitrangig); Spacer(); Text(z.1).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).monospacedDigit() }
                                .padding(.horizontal, 14).frame(minHeight: 40)
                        }
                    }
                    .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("So wird gerechnet").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text)
                        Text(w.rechnung).font(.klein).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    HStack(spacing: 6) { Sicher(stufe: w.sicher); Text(["Erster Hinweis", "Ziemlich sicher", "Sicher"][w.sicher - 1]).font(.klein).foregroundStyle(Farbe.zweitrangig) }
                    if w.muster != nil {
                        HStack(spacing: 10) {
                            Button { rueckmeldung(true); dismiss() } label: { Text("Hilfreich").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.aufFarbe).frame(maxWidth: .infinity, minHeight: 44).background(Farbe.akzent, in: Capsule()) }
                            Button { rueckmeldung(false); dismiss() } label: { Text("Passt nicht").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.text).frame(maxWidth: .infinity, minHeight: 44).overlay(Capsule().strokeBorder(Farbe.linie)) }
                        }
                        .buttonStyle(.plain)
                        Text("„Passt nicht“ blendet den Hinweis 8 Wochen aus.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                    }
                }
                .padding(Mass.rand)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(w.titel)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}

/// Weiße Karte im Gapless-Stil: Titel (fett) + Pfeil, große Zahl, eine Unterzeile, Inhalt.
struct WeisseKarte<Inhalt: View>: View {
    var titel: String
    var wert: String
    var unter: String
    var pfeil: (() -> Void)? = nil
    @ViewBuilder var inhalt: Inhalt

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(titel).font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
                Spacer()
                if let pfeil {
                    Button(action: pfeil) { Image(systemName: "chevron.right").font(.body.weight(.semibold)).foregroundStyle(Farbe.pfeil).frame(width: 44, height: 32) }
                        .accessibilityLabel("\(titel) öffnen")
                }
            }
            Text(wert).font(.kompass(.title, .heavy)).foregroundStyle(Farbe.text).monospacedDigit().contentTransition(.numericText())
            Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            inhalt.padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
    }
}

/// Säulen je Wochentag: verplante Stunden, gestrichelte Linie bei 75 % (enger Tag).
private struct AuslastungsBalken: View {
    var verplant: [Int]
    var heute: Int?
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private let wach = Double(Tagesplan.wachBis - Tagesplan.wachVon)

    var body: some View {
        let h: CGFloat = 90
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<7, id: \.self) { i in
                    let a = min(1, Double(verplant[i]) / wach)
                    VStack(spacing: 4) {
                        Capsule().fill(a >= 0.75 ? Farbe.warnung : (heute == i ? Farbe.akzent : Farbe.akzent.opacity(0.45)))
                            .frame(height: max(4, h * a))
                            .frame(height: h, alignment: .bottom)
                        Text(namen[i]).font(.caption2.weight(.semibold)).foregroundStyle(heute == i ? Farbe.akzent : Farbe.zweitrangig)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(namen[i]): \(verplant[i] / 60) Stunden verplant")
                }
            }
            Rectangle().fill(Farbe.warnung.opacity(0.6)).frame(height: 1)
                .offset(y: -(h * 0.75) - 18)
                .accessibilityHidden(true)
        }
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
