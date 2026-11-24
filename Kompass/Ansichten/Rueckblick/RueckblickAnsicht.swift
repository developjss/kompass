import Charts
import SwiftUI

/// Rückblick einer Woche (Struktur v3 §5): eine Aussage oben, darunter weiße Karten – Plan, Fokuszeit, Zeit je Ziel, Habits, Auslastung.
struct RueckblickAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var versatz = 0

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let von = T.montag.plus(tage: 7 * versatz), bis = von.plus(tage: 6)
        let bilanz = Tagesplan.woche(zustand: z, montag: von, heute: T, termine: speicher.termine(am:))
        let woche = z.sitzungen.filter { $0.tag >= von && $0.tag <= bis }
        let gesamt = woche.reduce(0) { $0 + $1.sekunden }
        let fuerZiele = woche.filter { $0.zielID != nil }.reduce(0) { $0 + $1.sekunden }
        let tage = max(1, (0..<7).filter { von.plus(tage: $0) <= T }.count)
        let zwoelf = (0..<12).map { k -> Double in
            let a = von.plus(tage: -7 * (11 - k))
            return z.sitzungen.filter { $0.tag >= a && $0.tag <= a.plus(tage: 6) }.reduce(0) { $0 + $1.sekunden } / 3600
        }
        let jeZiel = z.ziele.map { ($0, Fortschritt.zeit(ziel: $0.id, in: z, von: von, bis: bis)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        let habitQuote = bilanz.habitsGeplant > 0 ? bilanz.habitsErledigt / Double(bilanz.habitsGeplant) : 0

        Seite(titel: "Rückblick", info: .rueckblick) {
            HStack {
                Button { versatz -= 1 } label: { Image(systemName: "chevron.left").font(.body.weight(.semibold)).frame(width: 44, height: 44) }.accessibilityLabel("Woche zurück")
                Text("\(kurz(von)) – \(kurz(bis))").font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text)
                Button { versatz += 1 } label: { Image(systemName: "chevron.right").font(.body.weight(.semibold)).frame(width: 44, height: 44) }.accessibilityLabel("Woche vor")
                    .disabled(versatz >= 0)
                Spacer()
                if versatz != 0 { Button("Diese Woche") { versatz = 0 }.font(.kompass(.subheadline, .bold)) }
            }
            .foregroundStyle(Farbe.akzent)
            .padding(.bottom, 8)

            // Aussage
            Verlaufskarte(farben: Farbe.indigo) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        KartenLabel(text: versatz == 0 ? "Diese Woche bisher" : "Diese Woche")
                        Text(Zahl.prozent(bilanz.quote)).font(.grosseZahl).contentTransition(.numericText())
                        Text("deiner Pläne geschafft").font(.unterzeile).opacity(0.9)
                    }
                    Spacer()
                    MiniSaeulen(werte: (0..<7).map { i in bilanz.geplantJeTag[i] > 0 ? bilanz.erledigtJeTag[i] / bilanz.geplantJeTag[i] : 0 },
                                hoehe: 56, hervor: versatz == 0 ? T.wochentag - 1 : nil)
                        .padding(.top, 10)
                }
                Text("\(bilanz.aufgabenErledigt) von \(bilanz.aufgabenGeplant) Aufgaben · Habits \(Zahl.prozent(habitQuote)) · \(bilanz.termine) Termine")
                    .font(.klein).opacity(0.9).padding(.top, 6)
            }

            VStack(spacing: 12) {
                WeisseKarte(titel: "Fokuszeit", wert: Zahl.dauer(gesamt),
                            unter: "Ø \(Zahl.dauer(gesamt / Double(tage))) pro Tag · \(gesamt > 0 ? Int((fuerZiele / gesamt * 100).rounded()) : 0) % für Ziele") {
                    Kurve(werte: zwoelf, farbe: Farbe.akzent).frame(height: 64)
                    HStack { Text("vor 12 Wochen"); Spacer(); Text("jetzt") }.font(.caption2).foregroundStyle(Farbe.zweitrangig)
                }

                let aktiv = z.ziele.filter { $0.status == .aktiv }
                if !aktiv.isEmpty {
                    WeisseKarte(titel: "Ziele", wert: "\(aktiv.count)", unter: "Antippen für Verlauf, Prognose und Einsatz") {
                        VStack(spacing: 8) {
                            ForEach(aktiv) { g in
                                let k = Kurs.aufKurs(g, in: z, heute: T)
                                Button { nav.zeigeAnalyse(ziel: g.id) } label: {
                                    HStack(spacing: 8) {
                                        Text(g.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(width: 120, alignment: .leading)
                                        Balken(anteil: k.fortschritt, farbe: Color(hex: g.farbe), spur: Farbe.linie, hoehe: 6)
                                        Text(k.lage.text).font(.klein).foregroundStyle(Farbe.zweitrangig).frame(width: 74, alignment: .trailing)
                                        Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
                                    }
                                    .frame(minHeight: 32).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(g.titel), \(Zahl.prozent(k.fortschritt)), \(k.lage.text)")
                                .accessibilityHint("Analyse öffnen")
                            }
                        }
                    }
                }

                WeisseKarte(titel: "Zeit je Ziel", wert: jeZiel.isEmpty ? "–" : Zahl.dauer(jeZiel.reduce(0) { $0 + $1.1 }),
                            unter: jeZiel.isEmpty ? "Noch keine Zeit für Ziele in dieser Woche." : "Fokus und zugeordnete Termine") {
                    if !jeZiel.isEmpty {
                        HStack(spacing: 16) {
                            Chart(jeZiel, id: \.0.id) { g, s in
                                SectorMark(angle: .value("Zeit", s), innerRadius: .ratio(0.62), angularInset: 1.5)
                                    .foregroundStyle(Color(hex: g.farbe))
                            }
                            .frame(width: 84, height: 84)
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(jeZiel.prefix(4), id: \.0.id) { g, s in
                                    Button { nav.oeffneZiel(g.id) } label: {
                                        HStack(spacing: 6) {
                                            Circle().fill(Color(hex: g.farbe)).frame(width: 8, height: 8)
                                            Text(g.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1)
                                            Spacer(minLength: 4)
                                            Text(Zahl.dauer(s)).font(.klein).monospacedDigit().foregroundStyle(Farbe.zweitrangig)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                WeisseKarte(titel: "Habits", wert: Zahl.prozent(habitQuote),
                            unter: "\(Zahl.text(bilanz.habitsErledigt, stellen: 1)) von \(bilanz.habitsGeplant) geplanten Tagen", pfeil: { nav.zeige(.habits) }) {
                    VStack(spacing: 8) {
                        ForEach(z.habits) { h in
                            let q = HabitRechnung.quote(alle: [h], von: von, bis: bis, heute: T)
                            Button { nav.zeigeAnalyse(habit: h.id) } label: { HStack(spacing: 8) {
                                Text(h.titel).font(.klein).foregroundStyle(Farbe.text).lineLimit(1).frame(width: 120, alignment: .leading)
                                Balken(anteil: q.geplant > 0 ? q.erledigt / Double(q.geplant) : 0, farbe: Color(hex: h.farbe), spur: Farbe.linie, hoehe: 6)
                                Text(q.geplant > 0 ? Zahl.prozent(q.erledigt / Double(q.geplant)) : "–").font(.klein).monospacedDigit()
                                    .lineLimit(1).minimumScaleFactor(0.8).foregroundStyle(Farbe.zweitrangig).frame(width: 50, alignment: .trailing)
                                Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(Farbe.pfeil)
                            }
                            .frame(minHeight: 32).contentShape(Rectangle()) }
                            .buttonStyle(.plain)
                            .accessibilityHint("Analyse öffnen")
                        }
                    }
                }

                WeisseKarte(titel: "Auslastung", wert: Zahl.dauer(TimeInterval(bilanz.verplant.reduce(0, +) * 60)),
                            unter: "verplant (7–22 Uhr) · Linie = enger Tag", pfeil: { nav.oeffneKalender(von, modus: .woche) }) {
                    AuslastungsBalken(verplant: bilanz.verplant, heute: versatz == 0 ? T.wochentag - 1 : nil)
                }

                PfeilZeile(symbol: "moon", text: z.reflexionen["woche:\(von.text)"] == nil ? "Wochenreflexion · 3 Fragen" : "Wochenreflexion ✓") {
                    nav.blatt = .reflexion(woche: true)
                }
            }
            .padding(.top, 12)
        }
    }

    private func kurz(_ t: Tag) -> String {
        t.datum().formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
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
