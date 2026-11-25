import SwiftUI

/// Ein Termin als Seite (Blattwerk): kurze Bühne mit Uhrzeit und Titel als Wort, Karte vorn mit Tag · Zeit · Herkunft
/// und Bearbeiten, darunter Kacheln „Zählt für“ · „Zählt in“ · „Erfüllt Habit“ · Bearbeiten. Gilt für jeden Termin, auch
/// aus Apple oder Google (dort zählt die ganze Serie über `TerminVerknuepfung`, §3). Gerechnet wird wie bisher in `Fortschritt`.
struct TerminSeite: View {
    var serie: String
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        let z = speicher.zustand
        Group {
            if let t = speicher.termine(am: tag).first(where: { Kalenderquelle.serie($0) == serie }) {
                let eigener = t.eigenID.flatMap { z.eigenerTermin($0) }
                let link = Kalenderquelle.verknuepfung(serie: serie, in: z)
                let zid = eigener?.zielID ?? link?.zielID
                let sid = eigener?.schrittID ?? link?.schrittID
                let g = z.ziel(zid)
                let s = g.flatMap { gg in gg.schritte.first { $0.id == sid } }
                let farbe = g?.farbe ?? t.kalenderFarbe ?? t.quelle.farbe
                let externID = KalenderAktion.externeID(serie)
                let bearbeitbar = eigener != nil || (externID.map { AppleKalender.aktiv.bearbeitbar($0, am: tag, kalender: speicher.kalender) } ?? false)

                BuehnenSeite(hoehe: Mass.buehneKurz, wort: wort(t), marke: {
                    RahmenKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }
                    MarkenTitel(text: "Termin")
                    Spacer(minLength: 8)
                    MarkenHinweis(text: eigener == nil ? t.quelle.name : "Kompass")
                }) {
                    VornKarte {
                        Etikett(text: wann(t) + (eigener.map { $0.wiederholung == .nie ? "" : " · \($0.wiederholung.name)" } ?? ""))
                        Text(t.titel).font(.karteTitel).foregroundStyle(Farbe.text).lineLimit(3).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            if let e = eigener {
                                Button { nav.blatt = .termin(e.id, tag: tag.text, start: nil) } label: { Label("Bearbeiten", systemImage: "pencil") }.buttonStyle(.haupt)
                            } else if let id = externID, bearbeitbar {
                                Button { nav.blatt = .externTermin(id: id, tag: tag.text) } label: { Label("Bearbeiten", systemImage: "pencil") }.buttonStyle(.haupt)
                            } else {
                                Label("Nur lesen", systemImage: "lock").font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.zweitrangig)
                            }
                            if let g, link != nil || eigener?.zielID != nil {
                                Button { dismiss(); nav.zeigeAnalyse(ziel: g.id) } label: { Label("Analyse", systemImage: "chart.line.uptrend.xyaxis") }.buttonStyle(.leise)
                            }
                        }
                        .padding(.top, 4)
                        Text(herkunft(t, eigener)).font(.klein).foregroundStyle(Farbe.zweitrangig)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            Menu {
                                Button("Kein Ziel") { setze(t, eigener, ziel: nil, schritt: nil) }
                                ForEach(z.ziele.filter { $0.status == .aktiv }) { ziel in
                                    Button(ziel.titel) {
                                        setze(t, eigener, ziel: ziel.id, schritt: ziel.schritte.first { $0.art == .zeit || $0.art == .zahl }?.id)
                                    }
                                }
                            } label: {
                                EinstellKachelInhalt(symbol: g?.symbol ?? "target", titel: "Zählt für", wert: g?.titel ?? "kein Ziel",
                                                     unter: g == nil ? "antippen zum Wählen" : nil, farbe: Color(hex: farbe), verlauf: true)
                            }
                            .accessibilityIdentifier("termin.ziel")
                            if let g {
                                let passend = g.schritte.filter { $0.art == .zeit || $0.art == .zahl }
                                Menu {
                                    Button("Nur Einsatz") { setze(t, eigener, ziel: g.id, schritt: nil) }
                                    ForEach(passend) { p in Button("\(p.titel) · \(p.art == .zeit ? "Dauer" : "je 1")") { setze(t, eigener, ziel: g.id, schritt: p.id) } }
                                } label: {
                                    EinstellKachelInhalt(symbol: "flag.fill", titel: "Zählt in", wert: s?.titel ?? "Nur Einsatz",
                                                         unter: s == nil ? "ändert die Prozente nicht" : (s?.art == .zeit ? "die Dauer zählt" : "jeder Termin zählt 1"),
                                                         farbe: Color(hex: farbe), hinweis: passend.isEmpty, verlauf: true)
                                }
                            }
                            if let e = eigener {
                                Menu {
                                    Button("Keinen") { var x = e; x.habitID = nil; speicher.aendern { $0.terminSpeichern(x) } }
                                    ForEach(z.habits) { h in Button(h.titel) { var x = e; x.habitID = h.id; speicher.aendern { $0.terminSpeichern(x) } } }
                                } label: {
                                    EinstellKachelInhalt(symbol: "repeat", titel: "Erfüllt Habit", wert: z.habit(e.habitID)?.titel ?? "keinen",
                                                         unter: e.habitID == nil ? nil : "abgehakt, wenn vorbei", farbe: Color(hex: farbe), verlauf: true)
                                }
                            }
                        }
                        .foregroundStyle(Farbe.text)

                        Text(erklaerung(g, s, eigener == nil, habit: z.habit(eigener?.habitID)?.titel))
                            .font(.klein).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)

                        if eigener != nil {
                            Button("Termin löschen") { loeschenFragen = true }.buttonStyle(.rotBreit).padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, Mass.rand).padding(.top, 12)
                }
                .confirmationDialog("Termin löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                    if eigener?.wiederholung ?? .nie != .nie {
                        Button("Nur diesen Termin löschen", role: .destructive) {
                            if let id = eigener?.id { let d = tag; speicher.aendern { $0.terminAuslassen(id, am: d) } }
                            dismiss()
                        }
                        Button("Alle Termine der Serie löschen", role: .destructive) {
                            if let id = eigener?.id { speicher.aendern { $0.terminLoeschen(id) } }
                            dismiss()
                        }
                    } else {
                        Button("Löschen", role: .destructive) {
                            if let id = eigener?.id { speicher.aendern { $0.terminLoeschen(id) } }
                            dismiss()
                        }
                    }
                } message: { Text(eigener?.wiederholung ?? .nie == .nie ? "" : "Der Termin wiederholt sich.") }
            } else {
                ContentUnavailableView("Termin nicht gefunden", systemImage: "calendar", description: Text("Er wurde vielleicht verschoben oder gelöscht."))
                    .background(Farbe.grund.ignoresSafeArea())
            }
        }
        .presentationDetents([.large])
    }

    private func wort(_ t: Termin) -> Wort {
        let titel = t.titel.count > 14 ? String(t.titel.prefix(13)).trimmingCharacters(in: .whitespaces) + "…" : t.titel + "."
        guard let s = t.start else { return Wort(zeilen: ["Ganztags"], akzent: titel, groesse: Wort.kleinGroesse) }
        return Wort(zeilen: [Tagesplan.uhr(s)], akzent: titel, groesse: Wort.kleinGroesse)
    }

    private func wann(_ t: Termin) -> String {
        let T = speicher.heute
        let d = tag == T ? "Heute" : tag == T.plus(tage: 1) ? "Morgen" : tag.datum().formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(Locale(identifier: "de_DE")))
        guard let s = t.start, let e = t.ende else { return "\(d) · ganztägig" }
        return "\(d) · \(Tagesplan.uhr(s))–\(Tagesplan.uhr(e)) · \(e - s) Min"
    }

    private func herkunft(_ t: Termin, _ e: EigenerTermin?) -> String {
        if e != nil { return "Kompass-Termin – Änderungen gelten sofort." }
        return "Aus deinem \(t.quelle.name)-Kalender – Änderungen landen direkt dort."
    }

    /// Ein Satz, was die Auswahl bewirkt (Regel §3: jeder stattgefundene Termin der Serie zählt).
    private func erklaerung(_ g: Ziel?, _ s: Schritt?, _ extern: Bool, habit: String?) -> String {
        var teile: [String] = []
        if let g {
            teile.append(s.map { "Jeder stattgefundene Termin zählt in „\($0.titel)“." } ?? "Zählt als Einsatz für „\(g.titel)“, ändert die Prozente nicht.")
            if extern { teile.append("Gilt für alle Termine dieser Serie.") }
        } else {
            teile.append("Optional: Wähle ein Ziel, dann zählt der Termin dafür.")
        }
        if let habit { teile.append("„\(habit)“ ist erledigt, sobald der Termin vorbei ist.") }
        return teile.joined(separator: " ")
    }

    private func setze(_ t: Termin, _ e: EigenerTermin?, ziel: UUID?, schritt: UUID?) {
        if var x = e {
            x.zielID = ziel; x.schrittID = schritt
            let neu = x
            speicher.aendern { $0.terminSpeichern(neu) }
        } else {
            let seit = min(tag, speicher.heute), titel = t.titel, se = serie
            speicher.aendern { $0.terminSerieZaehlen(serie: se, titel: titel, ziel: ziel, schritt: schritt, seit: seit) }
        }
        speicher.termineAbgleichen()
    }
}

/// Freie Stunde angetippt: „Was um 14:00?“ – drei Wege (Hick): neuer Termin, Offenes genau hierhin legen, Fokus starten.
struct StundeBlatt: View {
    var tag: Tag
    var start: Int
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var eingeplant = 0

    var body: some View {
        let v = Empfehlung.fuer(.tag, tag: tag, zustand: speicher.zustand, heute: speicher.heute, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:))
        let jetztDran = speicher.zustand.aufgaben.filter { $0.datum == speicher.heute && !$0.erledigt }
            .sorted { ($0.prio == .hoch ? 0 : 1, $0.reihenfolge) < ($1.prio == .hoch ? 0 : 1, $1.reihenfolge) }.first
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    (Text("Was um ") + Text("\(Tagesplan.uhr(start))?").foregroundStyle(Farbe.handlung))
                        .font(.system(size: 40, weight: .regular, design: .serif)).foregroundStyle(Farbe.text)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    RahmenKnopf(symbol: "xmark", beschriftung: "Schließen") { dismiss() }.foregroundStyle(Farbe.text)
                }
                .padding(.top, 8)

                GruppierteListe {
                    Button { nav.blatt = .neuTermin(tag: tag.text, start: start) } label: {
                        HStack(spacing: 12) {
                            ZeichenKreis(symbol: "calendar.badge.plus")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Neuer Termin um \(Tagesplan.uhr(start))").font(.zeile).foregroundStyle(Farbe.text)
                                Text("Geführt – mit Ziel und Habit").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .padding(.horizontal, 14).frame(minHeight: Mass.zeile).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("stunde.termin")
                    ForEach(v.prefix(3)) { e in
                        Button { einplanen(e) } label: {
                            HStack(spacing: 12) {
                                ZeichenKreis(symbol: e.symbol, gruen: true)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(e.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                                    Text(e.art == .habit ? "Habit hierhin legen" : "Aufgabe hierhin legen · \(e.dauer) Min").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                                }
                                Spacer()
                                Text(Tagesplan.uhr(start)).font(.zahlKlein).foregroundStyle(Farbe.text)
                            }
                            .padding(.horizontal, 14).frame(minHeight: Mass.zeile).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Um \(Tagesplan.uhr(start)) einplanen")
                    }
                    if let a = jetztDran, tag == speicher.heute {
                        Button { dismiss(); nav.blatt = .fokus(a.id) } label: {
                            HStack(spacing: 12) {
                                ZeichenKreis(symbol: "airplane.departure")
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Fokus starten").font(.zeile).foregroundStyle(Farbe.text)
                                    Text("Jetzt dran: \(a.titel)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Farbe.pfeil)
                            }
                            .padding(.horizontal, 14).frame(minHeight: Mass.zeile).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                if v.count > 3 {
                    Text("\(v.count - 3) weitere Vorschläge stehen im Kalender unter „alle“.").font(.klein).foregroundStyle(Farbe.zweitrangig)
                }
            }
            .padding(Mass.rand)
        }
        .background(Farbe.grund.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .sensoryFeedback(.success, trigger: eingeplant)
    }

    private func einplanen(_ e: Empfehlung.Vorschlag) {
        if KalenderAktion.ablegen([e.nutzlast], tag: tag, uhrzeit: start, speicher: speicher) { eingeplant += 1 }
        dismiss()
    }
}
