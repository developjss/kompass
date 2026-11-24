import SwiftUI

/// Ziel im Detail – minimal und geführt: oben, wie weit du bist (Analyse im Rückblick), darunter die wichtigsten
/// Einstellungen als Kacheln (Bis wann · Warum · Name · Verfeinern), darunter die Meilensteine mit ihrem Anteil am Ziel.
struct ZielDetail: View {
    var id: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        if let g = z.ziel(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZielStandKarte(ziel: g)
                    WichtigsteEinstellungen(ziel: g)
                    MeilensteinListe(ziel: g)
                }
                .padding(Mass.rand)
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(g.titel)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target", description: Text("Es wurde vielleicht gelöscht."))
        }
    }
}

// MARK: Stand – minimal

/// Wie weit du bist, in einem Blick: Ring, Prozent, Lage, Restzeit, was als Nächstes zählt. Die Analyse steht im Rückblick.
private struct ZielStandKarte: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let kurs = Kurs.aufKurs(ziel, in: z, heute: T)
        let naechster = Fortschritt.naechsterSchritt(ziel, in: z, heute: T)
        Verlaufskarte(farben: Farbe.verlauf(ziel.farbe)) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 8)
                    Circle().trim(from: 0, to: max(0.001, kurs.fortschritt)).stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    Image(systemName: ziel.symbol).font(.system(size: 22, weight: .bold))
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Zahl.prozent(kurs.fortschritt)).font(.grosseZahl).contentTransition(.numericText())
                    Text("\(kurs.lage.text.prefix(1).uppercased() + kurs.lage.text.dropFirst()) · \(Kurs.bisText(ziel.faellig, heute: T))")
                        .font(.unterzeile).opacity(0.92).lineLimit(2)
                }
                Spacer(minLength: 0)
                Button { nav.blatt = .rechnung(ziel.id) } label: { Image(systemName: "info.circle").font(.title3).opacity(0.85) }
                    .accessibilityLabel("So wird gerechnet")
            }
            if ziel.status == .erreicht {
                Text("Geschafft – dieses Ziel ist erreicht.").font(.unterzeile.weight(.semibold)).padding(.top, 10)
            } else if let n = naechster {
                Text("Als Nächstes: \(n.aufgabe?.titel ?? n.schritt.titel)").font(.unterzeile.weight(.semibold)).lineLimit(1).padding(.top, 10)
            }
            Button { nav.bereich = .rueckblick } label: {
                HStack(spacing: 6) {
                    Text("Analyse im Rückblick")
                    Image(systemName: "arrow.right")
                }
                .font(.kompass(.subheadline, .bold)).foregroundStyle(Color(hex: ziel.farbe))
                .padding(.horizontal, 14).frame(minHeight: 40)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
        }
    }
}

// MARK: Die wichtigsten Einstellungen

/// Vier Kacheln wie Konten-Kacheln in Gapless: Bis wann · Warum · Name · Verfeinern (hervorgehoben).
private struct WichtigsteEinstellungen: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let c = Color(hex: ziel.farbe)
        AbschnittKopf(titel: "Einstellungen")
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            EinstellKachel(symbol: "calendar", titel: "Bis wann", wert: ziel.faellig.datum().formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "de_DE"))),
                           unter: Kurs.bisText(ziel.faellig, heute: T), farbe: c) { nav.blatt = .zielBearbeiten(ziel.id, .faellig) }
            EinstellKachel(symbol: "heart.fill", titel: "Warum", wert: ziel.warum.isEmpty ? "Noch offen" : ziel.warum,
                           unter: ziel.warum.isEmpty ? "Hilft beim Dranbleiben" : nil, farbe: c, hinweis: ziel.warum.isEmpty) { nav.blatt = .zielBearbeiten(ziel.id, .warum) }
            EinstellKachel(symbol: "textformat", titel: "Name", wert: ziel.titel, unter: ziel.bereich, farbe: c) { nav.blatt = .zielBearbeiten(ziel.id, .titel) }
            NavigationLink(value: ZielTeilAuswahl(id: ziel.id, teil: .verfeinern)) {
                EinstellKachelInhalt(symbol: "slider.horizontal.3", titel: "Verfeinern", wert: "Meilensteine, Aufgaben …", unter: "geführt", farbe: c, hervor: true)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("ziel.verfeinern")
        }
    }
}

private struct EinstellKachel: View {
    var symbol: String
    var titel: String
    var wert: String
    var unter: String?
    var farbe: Color
    var hinweis = false
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) { EinstellKachelInhalt(symbol: symbol, titel: titel, wert: wert, unter: unter, farbe: farbe, hinweis: hinweis) }
            .buttonStyle(.plain)
    }
}

private struct EinstellKachelInhalt: View {
    var symbol: String
    var titel: String
    var wert: String
    var unter: String?
    var farbe: Color
    var hinweis = false
    var hervor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: symbol).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 36, height: 36).background(farbe.gradient, in: Circle())
                Spacer()
                if hinweis {
                    Image(systemName: "exclamationmark").font(.caption.weight(.heavy)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Farbe.warnung, in: Circle())
                }
            }
            Spacer(minLength: 6)
            Text(titel).font(.kompass(.subheadline, .heavy)).foregroundStyle(Farbe.text)
            Text(wert).font(.unterzeile).foregroundStyle(Farbe.text).lineLimit(1)
            if let unter { Text(unter).font(.klein).foregroundStyle(Farbe.zweitrangig).lineLimit(1) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(hervor ? farbe : .clear, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
}

// MARK: Verfeinern – alles Weitere auf eigenen Seiten

/// Teile der Ziel-Seite, die nur bei Bedarf geöffnet werden.
enum ZielTeil: String, Hashable, CaseIterable {
    case verfeinern, aufgaben, habits, termine, einsatz, details

    /// Die Teile, die unter „Verfeinern“ als Zeilen stehen
    static let mehr: [ZielTeil] = [.aufgaben, .habits, .termine, .einsatz, .details]

    var titel: String {
        switch self {
        case .verfeinern: "Verfeinern"
        case .aufgaben: "Aufgaben"
        case .habits: "Habits"
        case .termine: "Termine"
        case .einsatz: "Einsatz"
        case .details: "Details"
        }
    }
    var symbol: String {
        switch self {
        case .verfeinern: "slider.horizontal.3"
        case .aufgaben: "checklist"
        case .habits: "repeat"
        case .termine: "calendar"
        case .einsatz: "clock"
        case .details: "slider.horizontal.3"
        }
    }
    /// Ein Satz: was hier passiert und warum
    var erklaerung: String {
        switch self {
        case .verfeinern: "Alles geführt: Kompass fragt, du antwortest."
        case .aufgaben: "Aufgaben mit diesem Ziel fallen in den nächsten offenen Meilenstein. Ohne passenden Meilenstein zählen sie als Einsatz."
        case .habits: "Ein Habit zählt in die Prozente, wenn ein Meilenstein ihn misst – sonst als Einsatz."
        case .termine: "Termin-Serien aus dem Kalender: jeder stattgefundene Termin zählt in einen Zahl- oder Zeit-Meilenstein oder als Einsatz."
        case .einsatz: "Fokuszeit und Termine für dieses Ziel. Einsatz zeigt, was du investierst – die Prozente ändert er nicht."
        case .details: "Titel, Frist, Bereich, Warum und Aussehen. Hier markierst du das Ziel auch als erreicht oder löschst es."
        }
    }
}

/// Für NavigationLink(value:) auf einen Teil eines Ziels
struct ZielTeilAuswahl: Hashable { var id: UUID; var teil: ZielTeil }

/// Verfeinern: Meilensteine verwalten (mit Anteilen und geführtem Anlegen), darunter weitere Teile des Ziels.
private struct VerfeinernInhalt: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let c = Color(hex: ziel.farbe)
        let anteile = Fortschritt.anteile(ziel.schritte.map(Fortschritt.gewicht))
        AbschnittKopf(titel: "Meilensteine") { Text("\(ziel.schritte.count)").foregroundStyle(Farbe.zweitrangig) }
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "wand.and.stars").foregroundStyle(c).frame(width: 24)
                Text("Jeder Meilenstein macht einen Teil deines Ziels aus – je wichtiger, desto mehr. Kommt einer dazu oder fällt einer weg, rechnet Kompass neu.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(zip(ziel.schritte, anteile)), id: \.0.id) { s, a in
                Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: s.id) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: s.art.symbol).foregroundStyle(c).frame(width: 22)
                            Text(s.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(1)
                            Spacer()
                            Text(Zahl.prozent(a)).font(.kompass(.subheadline, .heavy)).monospacedDigit().foregroundStyle(c)
                            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                        }
                        Balken(anteil: a, farbe: c, spur: Farbe.linie)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(s.titel), macht \(Zahl.prozent(a)) des Ziels aus")
            }
            Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: nil) } label: {
                Label("Meilenstein hinzufügen – geführt", systemImage: "plus").font(.kompass(.headline, .bold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Farbe.akzent, in: Capsule()).foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))

        AbschnittKopf(titel: "Mehr")
        GruppierteListe {
            ForEach(ZielTeil.mehr, id: \.self) { t in
                NavigationLink(value: ZielTeilAuswahl(id: ziel.id, teil: t)) {
                    HStack(spacing: 12) {
                        Image(systemName: t.symbol).font(.body.weight(.semibold)).foregroundStyle(c).frame(width: 32)
                        Text(t.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Spacer(minLength: 8)
                        Text(wert(t)).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                        Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                    }
                    .padding(.horizontal, 14).frame(minHeight: Mass.zeileKompakt).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(t.titel), \(wert(t))")
            }
        }
    }

    private func wert(_ t: ZielTeil) -> String {
        let z = speicher.zustand, T = speicher.heute
        switch t {
        case .verfeinern: return ""
        case .aufgaben:
            let offen = z.aufgaben.filter { $0.zielID == ziel.id && !$0.erledigt }.count
            return offen == 0 ? "keine offen" : "\(offen) offen"
        case .habits:
            let n = z.habits.filter { h in h.zielID == ziel.id || ziel.schritte.contains { $0.habitID == h.id } }.count
            return n == 0 ? "keine" : "\(n)"
        case .termine:
            let n = z.termine.filter { $0.zielID == ziel.id }.count
            return n == 0 ? "keine" : "\(n) Serie\(n == 1 ? "" : "n")"
        case .einsatz: return "\(Zahl.dauer(Fortschritt.zeit(ziel: ziel.id, in: z, von: T.montag, bis: T))) diese Woche"
        case .details: return "Aussehen, erreicht, löschen"
        }
    }
}

/// Eine Unterseite des Ziels: Satz oben (was und warum), dann genau ein Teil.
struct ZielTeilSeite: View {
    var id: UUID
    var teil: ZielTeil
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var loeschenFragen = false

    var body: some View {
        if let g = speicher.zustand.ziel(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: teil.symbol).font(.body.weight(.semibold)).foregroundStyle(Color(hex: g.farbe))
                            .frame(width: 36, height: 36).background(Color(hex: g.farbe).opacity(0.14), in: Circle())
                        Text(teil.erklaerung).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).fixedSize(horizontal: false, vertical: true)
                    }
                    switch teil {
                    case .verfeinern: VerfeinernInhalt(ziel: g)
                    case .aufgaben: ZielAufgaben(ziel: g)
                    case .habits: ZielHabits(ziel: g)
                    case .termine: ZielTermine(ziel: g)
                    case .einsatz: ZielEinsatz(ziel: g)
                    case .details: details(g)
                    }
                }
                .padding(Mass.rand).padding(.bottom, 24)
                .frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .background(Farbe.grund.ignoresSafeArea())
            .navigationTitle(teil.titel)
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Ziel wirklich löschen?", isPresented: $loeschenFragen, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    let zid = g.id
                    nav.fortschrittPfad = NavigationPath()
                    speicher.aendern { $0.zielLoeschen(zid) }
                }
            } message: { Text("Aufgaben, Habits und Termine bleiben erhalten.") }
        } else {
            ContentUnavailableView("Ziel nicht gefunden", systemImage: "target")
        }
    }

    @ViewBuilder private func details(_ g: Ziel) -> some View {
        AbschnittKopf(titel: "Fakten")
        GruppierteListe {
            FaktZeile("Titel", wert: g.titel) { nav.blatt = .zielBearbeiten(g.id, .titel) }
            FaktZeile("Bis wann", wert: g.faellig.datum().formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "de_DE")))) { nav.blatt = .zielBearbeiten(g.id, .faellig) }
            FaktZeile("Bereich", wert: g.bereich) { nav.blatt = .zielBearbeiten(g.id, .bereich) }
            FaktZeile("Warum", wert: g.warum.isEmpty ? "–" : g.warum) { nav.blatt = .zielBearbeiten(g.id, .warum) }
            FaktZeile(titel: "Aussehen", wert: {
                HStack(spacing: 8) {
                    Image(systemName: g.symbol).font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: g.farbe))
                    Circle().fill(Color(hex: g.farbe)).frame(width: 16, height: 16)
                }
            }) { nav.blatt = .zielBearbeiten(g.id, .aussehen) }
        }
        Button(g.status == .erreicht ? "Wieder aktiv setzen" : "Als erreicht markieren") {
            let zid = g.id, neu: ZielStatus = g.status == .erreicht ? .aktiv : .erreicht
            speicher.aendern { s in if let i = s.ziele.firstIndex(where: { $0.id == zid }) { s.ziele[i].status = neu } }
        }
        .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .padding(.top, Mass.abschnitt)
        Button("Ziel löschen", role: .destructive) { loeschenFragen = true }
            .font(.zeile).frame(maxWidth: .infinity, minHeight: 50)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
            .padding(.top, 12)
    }
}

/// Zeile „+ …“ am Ende einer Liste
struct PlusZeile: View {
    var text: String
    var aktion: () -> Void
    var body: some View {
        Button(action: aktion) {
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.body.weight(.semibold)).frame(width: 44)
                Text(text).font(.zeile)
                Spacer()
            }
            .foregroundStyle(Farbe.akzent)
            .frame(minHeight: Mass.zeileKompakt)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: Meilensteine

private struct MeilensteinListe: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        AbschnittKopf(titel: "Meilensteine") {
            Button { nav.blatt = .rechnung(ziel.id) } label: { Image(systemName: "info.circle") }
                .accessibilityLabel("So wird gerechnet")
        }
        GruppierteListe {
            if ziel.schritte.isEmpty { LeerZeile(text: "Woran misst du das Ziel? Leg den ersten Meilenstein an – Kompass fragt dich durch.") }
            ForEach(ziel.schritte) { s in MeilensteinZeile(ziel: ziel, schritt: s) }
            PlusZeile(text: ziel.schritte.isEmpty ? "Ersten Meilenstein anlegen" : "Meilenstein") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: nil) }
        }
    }
}

private struct MeilensteinZeile: View {
    var ziel: Ziel
    var schritt: Schritt
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let st = Fortschritt.stand(schritt, in: z, heute: T)
        let c = Color(hex: ziel.farbe)
        HStack(spacing: 10) {
            Haken(an: schritt.geschafft, farbe: c, beschriftung: schritt.titel) {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id, heute: T) }
            }
            .padding(.leading, 4)
            Button { nav.blatt = .meilenstein(ziel: ziel.id, schritt: schritt.id) } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(schritt.titel).font(.zeile).foregroundStyle(Farbe.text).lineLimit(2)
                        Text(unterzeile(st)).font(.unterzeile).foregroundStyle(st.hinweis == nil ? Farbe.zweitrangig : Farbe.warnung).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text(Zahl.prozent(st.anteil)).font(.kompass(.subheadline, .bold)).foregroundStyle(st.anteil >= 1 ? Farbe.freude : Farbe.zweitrangig).monospacedDigit()
                    Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Bearbeiten")
            .padding(.trailing, 16)
        }
        .frame(minHeight: Mass.zeile)
        .contextMenu {
            Button("Bearbeiten", systemImage: "pencil") { nav.blatt = .meilenstein(ziel: ziel.id, schritt: schritt.id) }
            Button(schritt.geschafft ? "Wieder öffnen" : "Abhaken", systemImage: "checkmark") {
                speicher.aendern { $0.schrittUmschalten(ziel: ziel.id, schritt: schritt.id, heute: T) }
            }
            Button("Löschen", systemImage: "trash", role: .destructive) {
                speicher.aendern { $0.schrittLoeschen(ziel: ziel.id, schritt: schritt.id) }
            }
        }
    }

    private func unterzeile(_ st: Fortschritt.SchrittStand) -> String {
        if let h = st.hinweis { return h }
        var teile = [st.text]
        let erreicht = Fortschritt.erreichteSchwellen(schritt, in: speicher.zustand, heute: speicher.heute).count
        if let n = schritt.schwellen?.count, n > 0 { teile.append("\(erreicht) von \(n) Zwischenständen") }
        teile.append("\(Zahl.prozent(Fortschritt.anteilVorschau(ziel, gewicht: st.gewicht, ersetzt: schritt.id))) vom Ziel")
        return teile.joined(separator: " · ")
    }
}

// MARK: Aufgaben, Habits, Termine, Einsatz

private struct ZielAufgaben: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @State private var alle = false

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let offen = z.aufgaben.filter { $0.zielID == ziel.id && !$0.erledigt }
            .sorted { ($0.datum ?? T.plus(tage: 99_999)) < ($1.datum ?? T.plus(tage: 99_999)) }
        let erledigt = z.aufgaben.filter { $0.zielID == ziel.id && $0.erledigt }.count
        AbschnittKopf(titel: "Aufgaben") { Text("\(erledigt) erledigt").foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            ForEach(alle ? offen : Array(offen.prefix(5))) { a in
                AufgabeZeile(aufgabe: a, datumZeigen: true)
                    .contextMenu {
                        Button("Vom Ziel lösen", systemImage: "link.badge.minus") {
                            speicher.aendern { $0.aufgabeZuordnen(a.id, ziel: nil, heute: T) }
                        }
                    }
            }
            if offen.count > 5 {
                Button(alle ? "Weniger" : "\(offen.count - 5) weitere") { alle.toggle() }.font(.unterzeile).frame(maxWidth: .infinity, minHeight: 44)
            }
            AufgabeHinzufuegen(platzhalter: "Neue Aufgabe", datum: nil, prio: .hoch, zielID: ziel.id)
            PlusZeile(text: "Bestehende Aufgabe") { nav.blatt = .aufgabeZuZiel(ziel.id) }
        }
    }
}

private struct ZielHabits: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let habits = z.habits.filter { h in h.zielID == ziel.id || ziel.schritte.contains { $0.habitID == h.id } }
        AbschnittKopf(titel: "Habits")
        GruppierteListe {
            ForEach(habits) { h in
                let zaehlt = ziel.schritte.contains { $0.art == .habit && $0.habitID == h.id }
                HStack(spacing: 10) {
                    Haken(an: h.voll(am: T), farbe: Color(hex: h.farbe), beschriftung: h.titel) {
                        speicher.aendern { $0.habitUmschalten(h.id, am: T) }
                    }
                    .padding(.leading, 4)
                    .disabled(!HabitRechnung.geplant(h, am: T))
                    .opacity(HabitRechnung.geplant(h, am: T) ? 1 : 0.4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Text("Serie \(HabitRechnung.serie(h, heute: T)) · \(Zahl.prozent(HabitRechnung.quote(h, heute: T))) · \(zaehlt ? "zählt" : "nur Einsatz")")
                            .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                    Spacer()
                }
                .frame(minHeight: Mass.zeile)
                .contentShape(Rectangle())
                .onTapGesture { nav.oeffneHabit(h.id) }
                .contextMenu {
                    Button("Vom Ziel lösen", systemImage: "link.badge.minus") { speicher.aendern { $0.habitLoesen(h.id, ziel: ziel.id) } }
                }
            }
            PlusZeile(text: "Habit") { nav.blatt = .habitZuZiel(ziel.id) }
        }
    }
}

private struct ZielTermine: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let links = z.termine.filter { $0.zielID == ziel.id }
        AbschnittKopf(titel: "Termine")
        GruppierteListe {
            ForEach(links) { l in
                let n = l.vorkommen.filter { $0.tag >= l.seit && $0.tag <= T }.count
                let wohin = z.schritt(l.schrittID, in: ziel.id).map { "zählt in „\($0.titel)“" } ?? "nur Einsatz"
                HStack(spacing: 12) {
                    Image(systemName: "calendar").foregroundStyle(Color(hex: ziel.farbe)).frame(width: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l.titel).font(.zeile).foregroundStyle(Farbe.text)
                        Text("\(n) stattgefunden · \(wohin)").font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
                    }
                    Spacer()
                }
                .frame(minHeight: Mass.zeile)
                .contextMenu {
                    Button("Vom Ziel lösen", systemImage: "link.badge.minus") { speicher.aendern { $0.terminLoesen(l.id) } }
                }
            }
            PlusZeile(text: "Termin-Serie") { nav.blatt = .terminZuZiel(ziel.id) }
        }
    }
}

private struct ZielEinsatz: View {
    var ziel: Ziel
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let T = speicher.heute
        let woche = Fortschritt.zeit(ziel: ziel.id, in: z, von: T.montag, bis: T)
        let gesamt = Fortschritt.zeit(ziel: ziel.id, in: z)
        AbschnittKopf(titel: "Einsatz")
        GruppierteListe {
            HStack {
                Text("Diese Woche").font(.zeile)
                Spacer()
                Text(Zahl.dauer(woche)).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
            HStack {
                Text("Seit Beginn").font(.zeile)
                Spacer()
                Text(Zahl.dauer(gesamt)).font(.zeile).foregroundStyle(Farbe.zweitrangig)
            }
            .padding(.horizontal, 16).frame(minHeight: Mass.zeileKompakt)
        }
    }
}
