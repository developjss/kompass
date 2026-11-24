import SwiftUI

/// Ein Termin als Seite – geführt wie Habit- und Ziel-Seite: oben Zeit und Herkunft, darunter Kacheln
/// „Zählt für“ · „Zählt in“ · „Erfüllt Habit“ · Bearbeiten. Gilt für jeden Termin, auch aus Apple oder Google
/// (dort zählt die ganze Serie über `TerminVerknuepfung`, §3). Gerechnet wird wie bisher in `Fortschritt`.
struct TerminSeite: View {
    var serie: String
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        let z = speicher.zustand
        NavigationStack {
            Group {
                if let t = speicher.termine(am: tag).first(where: { Kalenderquelle.serie($0) == serie }) {
                    let eigener = t.eigenID.flatMap { z.eigenerTermin($0) }
                    let link = Kalenderquelle.verknuepfung(serie: serie, in: z)
                    let zid = eigener?.zielID ?? link?.zielID
                    let sid = eigener?.schrittID ?? link?.schrittID
                    let g = z.ziel(zid)
                    let s = g.flatMap { gg in gg.schritte.first { $0.id == sid } }
                    let farbe = g?.farbe ?? t.kalenderFarbe ?? t.quelle.farbe
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Verlaufskarte(farben: Farbe.verlauf(farbe)) {
                                HStack(spacing: 14) {
                                    Image(systemName: eigener == nil ? "calendar" : "calendar.badge.clock").font(.system(size: 22, weight: .bold))
                                        .frame(width: 52, height: 52).background(.white.opacity(0.2), in: Circle())
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.titel).font(.kompass(.title3, .heavy)).lineLimit(2)
                                        Text(wann(t)).font(.unterzeile).opacity(0.92)
                                    }
                                    Spacer(minLength: 0)
                                }
                                Text(herkunft(t, eigener)).font(.klein).opacity(0.85).padding(.top, 10)
                            }

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
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
                                    Button { nav.blatt = .termin(e.id, tag: tag.text, start: nil) } label: {
                                        EinstellKachelInhalt(symbol: "pencil", titel: "Bearbeiten", wert: "Zeit, Titel, Wiederholung", farbe: Color(hex: farbe), verlauf: true)
                                    }
                                    .buttonStyle(DruckStil())
                                } else {
                                    EinstellKachelInhalt(symbol: "arrow.up.forward.app", titel: "Ändern", wert: "im \(t.quelle.name)-Kalender",
                                                         unter: "Zeit und Titel kommen von dort", farbe: Color(hex: farbe), verlauf: true)
                                }
                            }
                            .foregroundStyle(Farbe.text)

                            Text(erklaerung(g, s, eigener == nil, habit: z.habit(eigener?.habitID)?.titel))
                                .font(.klein).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)

                            if let g, link != nil || eigener?.zielID != nil {
                                Button { dismiss(); nav.zeigeAnalyse(ziel: g.id) } label: {
                                    Label("Ziel-Analyse", systemImage: "chart.line.uptrend.xyaxis").font(.kompass(.subheadline, .bold))
                                        .frame(maxWidth: .infinity, minHeight: 48).foregroundStyle(Color(hex: farbe))
                                        .background(Color(hex: farbe).opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(DruckStil())
                            }
                            if eigener != nil {
                                Button("Termin löschen", role: .destructive) { loeschenFragen = true }
                                    .font(.kompass(.subheadline, .bold)).frame(maxWidth: .infinity, minHeight: 44)
                            }
                        }
                        .padding(Mass.rand).padding(.bottom, 24)
                    }
                    .confirmationDialog("Termin löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                        Button("Löschen", role: .destructive) {
                            if let id = eigener?.id { speicher.aendern { $0.terminLoeschen(id) } }
                            dismiss()
                        }
                    } message: { Text(eigener?.wiederholung == .nie ? "" : "Die ganze Serie wird gelöscht.") }
                } else {
                    ContentUnavailableView("Termin nicht gefunden", systemImage: "calendar", description: Text("Er wurde vielleicht verschoben oder gelöscht."))
                }
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle("Termin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func wann(_ t: Termin) -> String {
        let d = tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))
        guard let s = t.start, let e = t.ende else { return "\(d) · ganztägig" }
        return "\(d) · \(Tagesplan.uhr(s))–\(Tagesplan.uhr(e))"
    }

    private func herkunft(_ t: Termin, _ e: EigenerTermin?) -> String {
        if let e { return e.wiederholung == .nie ? "Kompass-Termin" : "Kompass-Termin · wiederholt sich \(e.wiederholung.name.lowercased())" }
        return "Aus deinem \(t.quelle.name)-Kalender"
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

/// Freie Stunde angetippt: neuer Termin (geführt, Zeit vorbelegt) – oder etwas Offenes genau hierhin legen.
struct StundeBlatt: View {
    var tag: Tag
    var start: Int
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var eingeplant = 0

    var body: some View {
        let v = Empfehlung.fuer(.tag, tag: tag, zustand: speicher.zustand, heute: speicher.heute, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:))
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Button { nav.blatt = .neuTermin(tag: tag.text, start: start) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.plus").font(.system(size: 20, weight: .bold)).foregroundStyle(Farbe.aufFarbe)
                                .frame(width: 48, height: 48).background(LinearGradient(colors: [Color(hex: "#0E5A8A"), Color(hex: "#2F8FD6")], startPoint: .bottomTrailing, endPoint: .topLeading), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Neuer Termin um \(Tagesplan.uhr(start))").font(.zeile).foregroundStyle(Farbe.text)
                                Text("Geführt – mit Ziel und Habit").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        .padding(14).background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(DruckStil())
                    .accessibilityIdentifier("stunde.termin")

                    Text("Oder Offenes hierhin legen").font(.kompass(.headline, .bold)).foregroundStyle(Farbe.text).padding(.top, 6)
                    if v.isEmpty {
                        Text("Nichts Offenes für diesen Tag.").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(v.prefix(8)) { e in
                                Button { einplanen(e) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: e.symbol).font(.system(size: 14, weight: .bold)).foregroundStyle(Farbe.aufFarbe)
                                            .frame(width: 34, height: 34).background(Color(hex: e.farbe).gradient, in: Circle())
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(e.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                                            Text(e.art == .habit ? e.grund : "Aufgabe · \(e.grund)").font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                                        }
                                        Spacer()
                                        Text(Tagesplan.uhr(start)).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
                                    }
                                    .padding(.horizontal, 14).frame(minHeight: 56).contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Um \(Tagesplan.uhr(start)) einplanen")
                            }
                        }
                        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(Mass.rand)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle("Was um \(Tagesplan.uhr(start))?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .sensoryFeedback(.success, trigger: eingeplant)
    }

    private func einplanen(_ e: Empfehlung.Vorschlag) {
        if KalenderAktion.ablegen([e.nutzlast], tag: tag, uhrzeit: start, speicher: speicher) { eingeplant += 1 }
        dismiss()
    }
}
