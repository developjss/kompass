import SwiftUI

/// Kalender (Struktur v3 §4, v5): oben „Als Nächstes“ als Stapel, dann Tag · Woche · Monat · Jahr, darunter „Empfehlung“ zum Hineinziehen.
struct KalenderAnsicht: View {
    private func empfehlungsBereich(_ m: KalenderModus) -> Empfehlung.Bereich? {
        switch m {
        case .tag: nil   // Tagesansicht: kompakte Leiste direkt über der Zeitleiste
        case .woche: .woche
        case .monat: .monat
        case .jahr: nil
        }
    }

    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        let T = speicher.heute
        let tag = nav.kalenderTag ?? T
        let naechster = Tagesplan.naechste(zustand: speicher.zustand, heute: T, jetzt: speicher.jetztMinuten, termine: speicher.termine(am:), anzahl: 1).first

        BuehnenSeite(hoehe: Mass.buehneKurz, wort: Self.wort(tag: tag, heute: T, jetzt: speicher.jetztMinuten, naechster: naechster), objekt: .bordkarte, platz: .kalender, marke: {
            MarkenTitel(text: "Kalender")
            Spacer(minLength: 8)
            RahmenKnopf(symbol: "info", beschriftung: "Erklärung") { nav.blatt = .info(.kalender) }
            RahmenKnopf(symbol: "plus", beschriftung: "Neuer Termin") { nav.blatt = .neu(.termin) }
        }) {
            VornKarte(abstand: 10) {
                ModusWahl(modus: $nav.kalenderModus)
                if nav.kalenderModus != .jahr {
                    Wochenleiste(gewaehlt: tag, heute: T) { nav.kalenderTag = $0; if nav.kalenderModus == .monat { nav.kalenderModus = .tag } }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                if nav.kalenderModus != .tag {
                    KopfZeile(tag: tag, modus: nav.kalenderModus) { nav.kalenderTag = $0 }
                } else {
                    TagKopf(tag: tag)
                }

                switch nav.kalenderModus {
                case .tag:
                    EmpfehlungLeiste(tag: tag)
                    TagZeitleiste(tag: tag)
                case .woche: WochenRaster(tag: tag)
                case .monat:
                    MonatsRaster(tag: tag)
                    TagesListe(tag: tag)
                    Button { withAnimation(.snappy(duration: 0.2)) { nav.kalenderModus = .jahr } } label: { Label("Jahr ansehen", systemImage: "calendar") }
                        .buttonStyle(.leise)
                case .jahr: JahresRaster(tag: tag)
                }

                if let b = empfehlungsBereich(nav.kalenderModus) { EmpfehlungStapel(bereich: b, tag: tag).padding(.top, Mass.abschnitt - 8) }

                if !(speicher.zustand.einstellungen.googleBeispiel || speicher.zustand.einstellungen.appleBeispiel || speicher.zustand.einstellungen.appleKalender) {
                    PfeilZeile(symbol: "calendar.badge.plus", text: "Apple- oder Google-Kalender verbinden") { nav.blatt = .einstellungen }
                        .padding(.top, Mass.abschnitt)
                }
            }
            .padding(.horizontal, Mass.rand)
            .padding(.top, 12)
        }
    }

    /// Das Wort: heute das Nächste („In 57 Min · Fahrstunde.“), sonst der gewählte Tag.
    nonisolated static func wort(tag: Tag, heute T: Tag, jetzt: Int, naechster: Tagesplan.Block?) -> Wort {
        if tag == T {
            if let b = naechster, b.tag == T {
                let m = b.start - jetzt
                let titel = b.titel.count > 14 ? String(b.titel.prefix(13)).trimmingCharacters(in: .whitespaces) + "…" : b.titel
                if m <= 0 { return Wort(zeilen: ["Jetzt"], akzent: "\(titel).", groesse: Wort.kleinGroesse) }
                if m < 60 { return Wort(zeilen: ["In \(m) Min"], akzent: "\(titel).", groesse: Wort.kleinGroesse) }
                return Wort(zeilen: ["Um \(Tagesplan.uhr(b.start))"], akzent: "\(titel).", groesse: Wort.kleinGroesse)
            }
            return Wort(zeilen: ["Heute"], akzent: "frei.", groesse: Wort.kleinGroesse)
        }
        let de = Locale(identifier: "de_DE")
        return Wort(zeilen: [tag.datum().formatted(.dateTime.weekday(.wide).locale(de))], akzent: tag.datum().formatted(.dateTime.day().month(.abbreviated).locale(de)) + ".", groesse: Wort.kleinGroesse)
    }
}

/// Tagesansicht: Überschrift des Tags (Serif) – „Heute“ oder der Wochentag.
private struct TagKopf: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    var body: some View {
        let T = speicher.heute
        let de = Locale(identifier: "de_DE")
        HStack(alignment: .firstTextBaseline) {
            Text(tag == T ? "Heute" : tag == T.plus(tage: 1) ? "Morgen" : tag.datum().formatted(.dateTime.weekday(.wide).day().month(.abbreviated).locale(de)))
                .font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
            Spacer()
            if tag != T {
                Button("Heute") { nav.kalenderTag = T }.font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.akzent)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: Umschalter und Kopf

/// Tag · Woche · Monat (Hick: drei; das Jahr liegt im Monat). Gewählt = Weinrot mit Rosé-Schrift.
private struct ModusWahl: View {
    @Binding var modus: KalenderModus
    var body: some View {
        HStack(spacing: 4) {
            ForEach([KalenderModus.tag, .woche, .monat], id: \.self) { m in
                let an = modus == m || (m == .monat && modus == .jahr)
                Button { withAnimation(.snappy(duration: 0.2)) { modus = m } } label: {
                    Text(m.titel).font(.kompass(.subheadline, .bold)).lineLimit(1).minimumScaleFactor(0.6)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(an ? Farbe.wort : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                        .foregroundStyle(an ? Farbe.buehne : Farbe.zweitrangig)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(an ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Farbe.grund, in: Capsule())
        .overlay(Capsule().strokeBorder(Farbe.linie, lineWidth: 1))
    }
}

private struct KopfZeile: View {
    var tag: Tag
    var modus: KalenderModus
    var waehlen: (Tag) -> Void
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let T = speicher.heute
        HStack(spacing: 4) {
            Button { waehlen(schritt(-1)) } label: { Image(systemName: "chevron.left").font(.body.weight(.semibold)).frame(width: 44, height: 44) }
                .accessibilityLabel("Zurück")
            Text(titel).font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text).lineLimit(1).minimumScaleFactor(0.8)
            Button { waehlen(schritt(1)) } label: { Image(systemName: "chevron.right").font(.body.weight(.semibold)).frame(width: 44, height: 44) }
                .accessibilityLabel("Weiter")
            Spacer()
            if !istHeute(T) {
                Button("Heute") { waehlen(T) }.font(.kompass(.subheadline, .bold))
                    .padding(.horizontal, 14).frame(minHeight: 36).background(Farbe.akzentWeich, in: Capsule())
            }
        }
        .foregroundStyle(Farbe.akzent)
    }

    private var de: Locale { Locale(identifier: "de_DE") }

    private var titel: String {
        switch modus {
        case .tag: return tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(de))
        case .woche:
            let m = tag.montag, s = m.plus(tage: 6)
            return "\(m.tag).\(m.monat). – \(s.tag).\(s.monat).\(s.jahr)"
        case .monat: return tag.datum().formatted(.dateTime.month(.wide).year().locale(de))
        case .jahr: return String(tag.jahr)
        }
    }

    private func istHeute(_ T: Tag) -> Bool {
        switch modus {
        case .tag: tag == T
        case .woche: tag.montag == T.montag
        case .monat: tag.monat == T.monat && tag.jahr == T.jahr
        case .jahr: tag.jahr == T.jahr
        }
    }

    private func schritt(_ r: Int) -> Tag {
        switch modus {
        case .tag: tag.plus(tage: r)
        case .woche: tag.plus(tage: 7 * r)
        case .monat: KalenderMathe.monat(tag, plus: r)
        case .jahr: Tag(tag.jahr + r, 1, 1)
        }
    }
}

/// Kleine Datumshilfen für die Raster (nur Anzeige).
enum KalenderMathe {
    static func monat(_ t: Tag, plus r: Int) -> Tag {
        var m = t.monat + r, j = t.jahr
        while m > 12 { m -= 12; j += 1 }
        while m < 1 { m += 12; j -= 1 }
        return Tag(j, m, 1)
    }

    static func tageImMonat(_ t: Tag) -> Int {
        let erster = Tag(t.jahr, t.monat, 1)
        return erster.tage(bis: monat(erster, plus: 1))
    }

    /// Wochen (je 7 Tage ab Montag), die den Monat abdecken
    static func wochen(_ t: Tag) -> [Tag] {
        let erster = Tag(t.jahr, t.monat, 1)
        let letzter = erster.plus(tage: tageImMonat(t) - 1)
        var m = erster.montag, out: [Tag] = []
        while m <= letzter { out.append(m); m = m.plus(tage: 7) }
        return out
    }
}

// MARK: Wochenleiste

struct Wochenleiste: View {
    var gewaehlt: Tag
    var heute: Tag
    var waehlen: (Tag) -> Void
    @Environment(Speicher.self) private var speicher
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let d = gewaehlt.montag.plus(tage: i)
                let b = Tagesplan.bloecke(am: d, zustand: speicher.zustand, termine: speicher.termine(am: d))
                let an = d == gewaehlt
                Button { waehlen(d) } label: {
                    VStack(spacing: 4) {
                        Text(namen[i]).font(.klein).foregroundStyle(an ? Farbe.aufFarbe.opacity(0.8) : Farbe.zweitrangig)
                        Text("\(d.tag)").font(.system(.title3, design: .serif, weight: .regular)).foregroundStyle(an ? Farbe.aufFarbe : (d == heute ? Farbe.akzent : Farbe.text))
                            .lineLimit(1).minimumScaleFactor(0.6)
                        HStack(spacing: 2) {
                            ForEach(Array(b.prefix(3).enumerated()), id: \.offset) { _, x in
                                Circle().fill(an ? Farbe.aufFarbe : Color(hex: x.farbe)).frame(width: 5, height: 5)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(an ? Farbe.handlung : Farbe.grund, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(d == heute && !an ? Farbe.akzent.opacity(0.6) : (an ? .clear : Farbe.linie), lineWidth: d == heute && !an ? 1.5 : 1)
                    }
                }
                .buttonStyle(.plain)
                .ablagezone(ecken: 16) { items, _ in KalenderAktion.ablegen(items, tag: d, uhrzeit: nil, speicher: speicher) }
                .accessibilityLabel("\(d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))), \(b.count) Einträge")
                .accessibilityAddTraits(an ? .isSelected : [])
            }
        }
    }
}

// MARK: Tag – Zeitleiste

struct TagZeitleiste: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dynamicTypeSize) private var schrift
    private let von = 6, bis = 24
    /// Gerade gezogener Eintrag und Verschiebung (nach 0,3 s Halten)
    @State private var zug: (id: String, dy: CGFloat)?
    @State private var gegriffen = 0
    @State private var abgelegt = 0
    @State private var serie: SerienAuftrag?

    var body: some View {
        let z = speicher.zustand
        let termine = speicher.termine(am: tag)
        let ganztags = termine.filter { $0.start == nil }
        let bloecke = Tagesplan.bloecke(am: tag, zustand: z, termine: termine)
        let hoehe: CGFloat = schrift >= .accessibility1 ? 84 : 64
        let spalten = Self.spalten(bloecke)

        VStack(alignment: .leading, spacing: 8) {
            if !ganztags.isEmpty {
                FliessLayout(abstand: 6) {
                    ForEach(ganztags) { t in
                        Label(t.titel, systemImage: "sun.max").font(.klein).lineLimit(1)
                            .padding(.horizontal, 10).frame(minHeight: 28)
                            .background(Color(hex: t.kalenderFarbe ?? t.quelle.farbe).opacity(0.14), in: Capsule())
                            .foregroundStyle(Farbe.text)
                    }
                }
            }
            ScrollViewReader { leser in
                ScrollView(.vertical) {
                ZStack(alignment: .topLeading) {
                    // Stundenraster
                    VStack(spacing: 0) {
                        ForEach(von..<bis, id: \.self) { h in
                            HStack(alignment: .top, spacing: 8) {
                                Text(String(format: "%02d", h)).font(.system(size: 11, weight: .semibold).monospacedDigit()).foregroundStyle(Farbe.pfeil)
                                    .lineLimit(1).fixedSize()
                                    .frame(width: 22, alignment: .trailing).offset(y: -6)
                                Rectangle().fill(Farbe.linie).frame(height: 0.5)
                            }
                            .frame(height: hoehe, alignment: .top)
                            .contentShape(Rectangle())
                            .id(h)
                            .onTapGesture { nav.blatt = .stunde(tag: tag.text, start: h * 60) }
                        }
                    }
                    // Blöcke
                    GeometryReader { g in
                        let breite = g.size.width - 38
                        ForEach(bloecke) { b in
                            let (spalte, anzahl) = spalten[b.id] ?? (0, 1)
                            let w = breite / CGFloat(anzahl)
                            BlockKachel(block: b, kompakt: CGFloat(b.dauer) / 60 * hoehe < 46, schmal: anzahl > 1)
                                .frame(width: max(20, w - 3), height: max(22, CGFloat(b.dauer) / 60 * hoehe - 2))
                                .opacity(zug?.id == b.id ? 0.35 : 1)
                                .gesture(KalenderAktion.verschiebbar(b) ? ziehGeste(b, hoehe: hoehe) : nil)
                                .accessibilityAction(named: "15 Minuten später") { schieben(b, um: 15) }
                                .accessibilityAction(named: "15 Minuten früher") { schieben(b, um: -15) }
                                .offset(x: 34 + CGFloat(spalte) * w, y: CGFloat(b.start - von * 60) / 60 * hoehe + 1)
                        }
                        // Vorschau: genau dort, wo der gezogene Eintrag landet
                        if let zug, let b = bloecke.first(where: { $0.id == zug.id }) {
                            if Zeitraster.ueberRand(start: b.start, dy: zug.dy, hoehe: hoehe, von: von) && b.art != .termin {
                                Label("Loslassen = ohne Uhrzeit", systemImage: "tray.and.arrow.up").font(.kompass(.subheadline, .bold))
                                    .foregroundStyle(Farbe.aufFarbe).padding(.horizontal, 14).frame(minHeight: 36)
                                    .background(Farbe.handlung, in: Capsule())
                                    .offset(x: 34, y: max(0, CGFloat(b.start - von * 60) / 60 * hoehe + zug.dy))
                            } else {
                                let neu = Zeitraster.verschoben(start: b.start, dauer: b.dauer, dy: zug.dy, hoehe: hoehe, von: von, bis: bis)
                                ZiehGeist(titel: b.titel, farbe: b.farbe, start: neu, dauer: b.dauer)
                                    .frame(width: breite - 3, height: max(26, CGFloat(b.dauer) / 60 * hoehe - 2))
                                    .offset(x: 34, y: CGFloat(neu - von * 60) / 60 * hoehe + 1)
                            }
                        }
                        if tag == speicher.heute {
                            let y = CGFloat(speicher.jetztMinuten - von * 60) / 60 * hoehe
                            if y >= 0 {
                                HStack(spacing: 0) {
                                    Circle().fill(Farbe.kritisch).frame(width: 8, height: 8)
                                    Rectangle().fill(Farbe.kritisch).frame(height: 1.5)
                                }
                                .offset(x: 26, y: y - 4)
                                .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(bis - von) * hoehe)
                .padding(.vertical, 10).padding(.horizontal, 10)
                .zeitAblage(hoehe: hoehe, von: von, bis: bis, oben: 10, links: 44) { items, m in
                    KalenderAktion.ablegen(items, tag: tag, uhrzeit: m, speicher: speicher)
                }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: gegriffen)
                .sensoryFeedback(.success, trigger: abgelegt)
                .serienFrage($serie)
                .frame(height: min(CGFloat(bis - von) * hoehe + 20, hoehe * 10))
                .scrollIndicators(.hidden)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                .onAppear { leser.scrollTo(startStunde(bloecke), anchor: .top) }
                .onChange(of: tag) { _, _ in leser.scrollTo(startStunde(bloecke), anchor: .top) }
            }
            if bloecke.isEmpty && ganztags.isEmpty {
                Text("Frei. Tipp auf eine Stunde – oder zieh einen Vorschlag hinein.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            }
        }
    }

    /// Halten (0,3 s), dann ziehen: der Eintrag bleibt groß, die Vorschau zeigt die neue Uhrzeit.
    private func ziehGeste(_ b: Tagesplan.Block, hoehe: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { wert in
                guard case .second(true, let d) = wert else { return }
                if zug == nil { gegriffen += 1 }
                zug = (b.id, d?.translation.height ?? 0)
            }
            .onEnded { wert in
                defer { zug = nil }
                guard case .second(true, let d?) = wert else { return }
                if Zeitraster.ueberRand(start: b.start, dy: d.translation.height, hoehe: hoehe, von: von) {
                    if b.art != .termin, KalenderAktion.verschieben(b, tag: tag, start: nil, speicher: speicher) { abgelegt += 1 }
                    return
                }
                let neu = Zeitraster.verschoben(start: b.start, dauer: b.dauer, dy: d.translation.height, hoehe: hoehe, von: von, bis: bis)
                guard neu != b.start else { return }
                if b.art == .termin && b.wiederkehrend {
                    let t = tag
                    serie = SerienAuftrag.fuer(b) { nur in if KalenderAktion.verschieben(b, tag: t, start: neu, nurDieser: nur, speicher: speicher) { abgelegt += 1 } }
                } else if KalenderAktion.verschieben(b, tag: tag, start: neu, speicher: speicher) { abgelegt += 1 }
            }
    }

    private func schieben(_ b: Tagesplan.Block, um m: Int) {
        guard KalenderAktion.verschiebbar(b) else { return }
        KalenderAktion.verschieben(b, tag: tag, start: min(max(von * 60, b.start + m), bis * 60 - b.dauer), speicher: speicher)
    }

    /// Wo die Zeitleiste beginnt: heute eine Stunde vor jetzt, sonst beim ersten Block (frühestens 7 Uhr).
    private func startStunde(_ b: [Tagesplan.Block]) -> Int {
        if tag == speicher.heute { return max(von, min(bis - 9, speicher.jetztMinuten / 60 - 1)) }
        return max(von, min(bis - 9, (b.first?.start ?? 8 * 60) / 60))
    }

    /// Nebeneinander, wenn sich Blöcke überschneiden: Spalte und Anzahl je Gruppe.
    static func spalten(_ b: [Tagesplan.Block]) -> [String: (Int, Int)] {
        var out: [String: (Int, Int)] = [:]
        var gruppe: [Tagesplan.Block] = [], ende = -1
        func abschliessen() {
            var spaltenEnde: [Int] = []
            var zu: [String: Int] = [:]
            for x in gruppe {
                if let i = spaltenEnde.firstIndex(where: { $0 <= x.start }) { spaltenEnde[i] = x.ende; zu[x.id] = i }
                else { spaltenEnde.append(x.ende); zu[x.id] = spaltenEnde.count - 1 }
            }
            for x in gruppe { out[x.id] = (zu[x.id] ?? 0, max(1, spaltenEnde.count)) }
            gruppe = []
        }
        for x in b.sorted(by: { $0.start < $1.start }) {
            if x.start >= ende && !gruppe.isEmpty { abschliessen() }
            gruppe.append(x); ende = max(ende, x.ende)
        }
        if !gruppe.isEmpty { abschliessen() }
        return out
    }
}

/// Ein Block im Raster: farbige Fläche, Titel, Uhrzeit. Aufgaben und Habits lassen sich verschieben.
struct BlockKachel: View {
    var block: Tagesplan.Block
    var kompakt = false
    var mini = false
    /// Wochenansicht: schmale Spalte – Titel umbrechen statt kürzen, kein Haken
    var schmal = false
    @Environment(Navigation.self) private var nav
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let c = Color(hex: block.farbe)
        let ziel = speicher.zustand.ziel(block.zielID)
        let inhalt = HStack(alignment: .top, spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.titel)
                    .font(mini ? .system(size: 10, weight: .semibold, design: .rounded)
                          : schmal ? .system(size: 11, weight: .bold, design: .rounded) : .kompass(.subheadline, .bold))
                    .foregroundStyle(Farbe.text).strikethrough(block.erledigt)
                    .lineLimit(mini ? 1 : schmal ? (kompakt ? 2 : 4) : (kompakt ? 1 : 2))
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: schmal)
                    .minimumScaleFactor(schmal ? 0.8 : 1)
                if schmal && !kompakt {
                    Text("\(Tagesplan.uhr(block.start))–\(Tagesplan.uhr(block.ende))").font(.system(size: 9, weight: .medium)).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                } else if !kompakt && !mini {
                    Text(ziel.map { "\(block.unter) · \($0.titel)" } ?? block.unter).font(.footnote).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if !mini && !schmal {
                if let ziel {
                    // Zählt für ein Ziel: kleines Ziel-Zeichen
                    Image(systemName: ziel.symbol).font(.system(size: 8, weight: .bold)).foregroundStyle(Farbe.aufTon)
                        .frame(width: 16, height: 16).background(Color(hex: ziel.farbe), in: Circle())
                        .padding(.top, 1)
                        .accessibilityHidden(true)
                }
                if block.art != .termin {
                    // Abhaken direkt in der Zeitleiste
                    Button { KalenderAktion.abhaken(block, speicher: speicher) } label: {
                        Image(systemName: block.erledigt ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(block.erledigt ? c : Farbe.pfeil)
                            .frame(width: 28, height: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(block.erledigt ? "\(block.titel) zurücknehmen" : "\(block.titel) abhaken")
                }
            }
        }
        .padding(.vertical, mini ? 2 : (schmal ? 3 : 5)).padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(c.opacity(block.erledigt ? 0.08 : 0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { KalenderAktion.oeffnen(block, nav: nav) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(block.titel), \(block.unter)\(ziel.map { ", zählt für \($0.titel)" } ?? "")")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { KalenderAktion.oeffnen(block, nav: nav) }

        // Verschieben: Halten und Ziehen in der Zeitleiste (Ziehen.swift) – kein Systemziehen, damit die Größe bleibt
        inhalt
    }
}

// MARK: Woche

private struct WochenRaster: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dynamicTypeSize) private var schrift
    private let von = 6, bis = 24
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    @State private var zug: (id: String, dx: CGFloat, dy: CGFloat)?
    @State private var gegriffen = 0
    @State private var abgelegt = 0
    @State private var serie: SerienAuftrag?

    /// Lesbar wie in Kalender-Apps: breite Spalten (rund 3 Tage sichtbar), waagerecht wischen, Stunden links fest.
    var body: some View {
        let T = speicher.heute
        let hoehe: CGFloat = schrift >= .accessibility1 ? 60 : 44
        let breite: CGFloat = schrift >= .accessibility1 ? 150 : 112
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                Color.clear.frame(width: 24, height: 50)
                ForEach(von..<bis, id: \.self) { h in
                    Text(String(format: "%02d", h)).font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Farbe.pfeil).frame(width: 24, height: hoehe, alignment: .topTrailing).offset(y: -6)
                }
            }
            .frame(width: 24)
            ScrollViewReader { leser in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(0..<7, id: \.self) { i in
                            let d = tag.montag.plus(tage: i)
                            VStack(spacing: 4) {
                                kopf(d, i: i, T: T)
                                spalte(d, T: T, hoehe: hoehe, breite: breite)
                            }
                            .frame(width: breite)
                            .id(i)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.leading, 6).padding(.trailing, 10)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
                .onAppear { leser.scrollTo(startSpalte(T), anchor: .leading) }
                .onChange(of: tag) { _, _ in leser.scrollTo(startSpalte(T), anchor: .leading) }
            }
        }
        .padding(.vertical, 8)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        .sensoryFeedback(.impact(weight: .light), trigger: gegriffen)
        .sensoryFeedback(.success, trigger: abgelegt)
        .serienFrage($serie)
    }

    /// Ziel einer Verschiebung: Tag (innerhalb der Woche) und gerasteter Start.
    private func ziel(_ b: Tagesplan.Block, d: Tag, dx: CGFloat, dy: CGFloat, hoehe: CGFloat, breite: CGFloat) -> (Tag, Int) {
        let k = Zeitraster.tage(dx: dx, spalte: breite + 4)
        let i = min(max(0, d.wochentag - 1 + k), 6)
        return (tag.montag.plus(tage: i), Zeitraster.verschoben(start: b.start, dauer: b.dauer, dy: dy, hoehe: hoehe, von: von, bis: bis))
    }

    private func ziehGeste(_ b: Tagesplan.Block, d: Tag, hoehe: CGFloat, breite: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { wert in
                guard case .second(true, let g) = wert else { return }
                if zug == nil { gegriffen += 1 }
                zug = (b.id, g?.translation.width ?? 0, g?.translation.height ?? 0)
            }
            .onEnded { wert in
                defer { zug = nil }
                guard case .second(true, let g?) = wert else { return }
                let (neuTag, neu) = ziel(b, d: d, dx: g.translation.width, dy: g.translation.height, hoehe: hoehe, breite: breite)
                guard neuTag != d || neu != b.start else { return }
                if b.art == .termin, neuTag != d, speicher.zustand.eigenerTermin(b.eigenID ?? UUID())?.wiederholung != .nie { return }
                if b.art == .termin && b.wiederkehrend {
                    serie = SerienAuftrag.fuer(b) { nur in if KalenderAktion.verschieben(b, tag: neuTag, start: neu, nurDieser: nur, speicher: speicher) { abgelegt += 1 } }
                } else if KalenderAktion.verschieben(b, tag: neuTag, start: neu, speicher: speicher) { abgelegt += 1 }
            }
    }

    /// Erste sichtbare Spalte: heute (wenn in dieser Woche) bzw. der gewählte Tag, höchstens Freitag.
    private func startSpalte(_ T: Tag) -> Int {
        let d = tag.montag == T.montag ? T : tag
        return min(max(0, d.wochentag - 1), 4)
    }

    private func kopf(_ d: Tag, i: Int, T: Tag) -> some View {
        Button { nav.kalenderTag = d; nav.kalenderModus = .tag } label: {
            HStack(spacing: 6) {
                Text(namen[i]).font(.kompass(.subheadline, .semibold)).foregroundStyle(Farbe.zweitrangig)
                Text("\(d.tag)").font(.kompass(.headline, .bold))
                    .foregroundStyle(d == T ? Farbe.aufFarbe : Farbe.text)
                    .frame(width: 32, height: 32)
                    .background(d == T ? Farbe.handlung : .clear, in: Circle())
            }
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
    }

    private func spalte(_ d: Tag, T: Tag, hoehe: CGFloat, breite: CGFloat) -> some View {
        let b = Tagesplan.bloecke(am: d, zustand: speicher.zustand, termine: speicher.termine(am: d))
        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(von..<bis, id: \.self) { _ in
                    Rectangle().fill(Farbe.linie).frame(height: 0.5).frame(height: hoehe, alignment: .top)
                }
            }
            GeometryReader { g in
                let sp = TagZeitleiste.spalten(b)
                ForEach(b) { x in
                    let (spalte, anzahl) = sp[x.id] ?? (0, 1)
                    let w = g.size.width / CGFloat(anzahl)
                    let h = max(20, CGFloat(min(x.ende, bis * 60) - max(x.start, von * 60)) / 60 * hoehe - 2)
                    BlockKachel(block: x, kompakt: h < 36, schmal: true)
                        .frame(width: max(10, w - 2), height: h)
                        .opacity(zug?.id == x.id ? 0.35 : 1)
                        .gesture(KalenderAktion.verschiebbar(x) ? ziehGeste(x, d: d, hoehe: hoehe, breite: breite) : nil)
                        .offset(x: CGFloat(spalte) * w, y: CGFloat(max(x.start, von * 60) - von * 60) / 60 * hoehe + 1)
                        .opacity(x.ende <= von * 60 || x.start >= bis * 60 ? 0 : 1)
                }
                if let zug, let x = b.first(where: { $0.id == zug.id }) {
                    let (neuTag, neu) = ziel(x, d: d, dx: zug.dx, dy: zug.dy, hoehe: hoehe, breite: breite)
                    ZiehGeist(titel: x.titel, farbe: x.farbe, start: neu, dauer: x.dauer)
                        .frame(width: g.size.width - 2, height: max(26, CGFloat(x.dauer) / 60 * hoehe - 2))
                        .offset(x: CGFloat(neuTag.wochentag - d.wochentag) * (breite + 4), y: CGFloat(neu - von * 60) / 60 * hoehe + 1)
                        .zIndex(10)
                }
                if d == T {
                    let y = CGFloat(speicher.jetztMinuten - von * 60) / 60 * hoehe
                    if y >= 0 { Rectangle().fill(Farbe.kritisch).frame(height: 1.5).offset(y: y).accessibilityHidden(true) }
                }
            }
        }
        .frame(height: CGFloat(bis - von) * hoehe)
        .background(d == T ? Farbe.akzentWeich.opacity(0.35) : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .zIndex(zug.map { z in b.contains { $0.id == z.id } ? 1 : 0 } ?? 0)
        .zeitAblage(hoehe: hoehe, von: von, bis: bis) { items, m in
            KalenderAktion.ablegen(items, tag: d, uhrzeit: m, speicher: speicher)
        }
    }
}

// MARK: Monat

private struct MonatsRaster: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    private let namen = ["M", "D", "M", "D", "F", "S", "S"]

    var body: some View {
        let T = speicher.heute
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(namen[i]).font(.caption2.weight(.bold)).foregroundStyle(i >= 5 ? Farbe.pfeil : Farbe.zweitrangig).frame(maxWidth: .infinity)
                }
            }
            ForEach(KalenderMathe.wochen(tag), id: \.self) { montag in
                HStack(alignment: .top, spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        let d = montag.plus(tage: i)
                        MonatsZelle(tag: d, imMonat: d.monat == tag.monat, gewaehlt: d == tag, heute: d == T) {
                            if d == tag { nav.kalenderModus = .tag } else { nav.kalenderTag = d }
                        }
                    }
                }
                Rectangle().fill(Farbe.linie).frame(height: 0.5)
            }
        }
        .padding(10)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
    }
}

private struct MonatsZelle: View {
    var tag: Tag
    var imMonat: Bool
    var gewaehlt: Bool
    var heute: Bool
    var waehlen: () -> Void
    @Environment(Speicher.self) private var speicher

    var body: some View {
        let z = speicher.zustand
        let termine = speicher.termine(am: tag)
        let b = Tagesplan.bloecke(am: tag, zustand: z, termine: termine)
        let ganztags = termine.filter { $0.start == nil }
        let ohne = z.aufgaben.filter { $0.datum == tag && $0.uhrzeit == nil && !$0.erledigt }
        let eintraege: [(String, String)] = ganztags.map { ($0.titel, $0.kalenderFarbe ?? $0.quelle.farbe) } + b.map { ($0.titel, $0.farbe) }
            + ohne.map { ($0.titel, Tagesplan.farbe(ziel: $0.zielID, kategorie: $0.kategorie, sonst: "#6B7285", in: z)) }
        Button(action: waehlen) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(tag.tag)").font(.kompass(.caption, .bold))
                    .foregroundStyle(heute ? .white : (imMonat ? Farbe.text : Farbe.pfeil))
                    .frame(width: 22, height: 22)
                    .background(heute ? Farbe.akzent : .clear, in: Circle())
                ForEach(Array(eintraege.prefix(3).enumerated()), id: \.offset) { _, e in
                    Text(e.0).font(.system(size: 9, weight: .semibold, design: .rounded)).lineLimit(1)
                        .padding(.horizontal, 3).frame(maxWidth: .infinity, alignment: .leading).frame(height: 14)
                        .background(Color(hex: e.1).opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(Farbe.text)
                }
                if eintraege.count > 3 { Text("+\(eintraege.count - 3)").font(.system(size: 9, weight: .bold)).foregroundStyle(Farbe.zweitrangig) }
                Spacer(minLength: 0)
            }
            .padding(3)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
            .background(gewaehlt ? Farbe.akzentWeich : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(imMonat ? 1 : 0.45)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ablagezone(ecken: 10) { items, _ in KalenderAktion.ablegen(items, tag: tag, uhrzeit: nil, speicher: speicher) }
        .accessibilityLabel("\(tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))), \(eintraege.count) Einträge")
        .accessibilityAddTraits(gewaehlt ? .isSelected : [])
    }
}

/// Liste eines Tages (unter dem Monat): Einträge mit Uhrzeit.
private struct TagesListe: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let termine = speicher.termine(am: tag)
        let b = Tagesplan.bloecke(am: tag, zustand: speicher.zustand, termine: termine)
        let ganz = termine.filter { $0.start == nil }
        AbschnittKopf(titel: tag == speicher.heute ? "Heute" : tag.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE")))) {
            Button("Tag ›") { nav.kalenderModus = .tag }
        }
        GruppierteListe {
            if b.isEmpty && ganz.isEmpty { LeerZeile(text: "Nichts mit Uhrzeit.") }
            ForEach(ganz) { t in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: t.kalenderFarbe ?? t.quelle.farbe)).frame(width: 4, height: 32).padding(.leading, 18)
                    Text(t.titel).font(.zeile).foregroundStyle(Farbe.text)
                    Spacer()
                    Text("ganztägig").font(.unterzeile).foregroundStyle(Farbe.zweitrangig).padding(.trailing, 16)
                }
                .frame(minHeight: Mass.zeileKompakt)
            }
            ForEach(b) { BlockZeile(block: $0) }
        }
    }
}

/// Zeile für einen Block (Home, Monat): Farbstreifen · Titel · Zeit · Haken für Aufgaben/Habits.
struct BlockZeile: View {
    var block: Tagesplan.Block
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: block.farbe)).frame(width: 4, height: 36).padding(.leading, 18)
            Button { KalenderAktion.oeffnen(block, nav: nav) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.titel).font(.zeile).foregroundStyle(block.erledigt ? Farbe.zweitrangig : Farbe.text).strikethrough(block.erledigt).lineLimit(1)
                    Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if block.art != .termin {
                Haken(an: block.erledigt, farbe: Color(hex: block.farbe), beschriftung: block.titel) {
                    KalenderAktion.abhaken(block, speicher: speicher)
                }
                .padding(.trailing, 6)
            }
        }
        .frame(minHeight: Mass.zeileKompakt)
    }

    private var unter: String {
        let z = speicher.zustand
        var t = "\(Tagesplan.uhr(block.start))–\(Tagesplan.uhr(block.ende))"
        if let g = z.ziel(block.zielID) { t += " · \(g.titel)" }
        else if block.art == .habit { t += " · Habit" }
        return t
    }
}

// MARK: Jahr

private struct JahresRaster: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    private let monate = ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]

    var body: some View {
        let T = speicher.heute
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(1...12, id: \.self) { m in
                let erster = Tag(tag.jahr, m, 1)
                Button { nav.kalenderTag = erster; nav.kalenderModus = .monat } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(monate[m - 1]).font(.kompass(.subheadline, .bold))
                            .foregroundStyle(m == T.monat && tag.jahr == T.jahr ? Farbe.akzent : Farbe.text)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1.5), count: 7), spacing: 1.5) {
                            ForEach(0..<(erster.wochentag - 1), id: \.self) { _ in Color.clear.frame(height: 9) }
                            ForEach(0..<KalenderMathe.tageImMonat(erster), id: \.self) { i in
                                let d = erster.plus(tage: i)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(d == T ? Farbe.akzent : Farbe.akzent.opacity(0.08 + 0.7 * anteil(d)))
                                    .frame(height: 9)
                            }
                        }
                    }
                    .padding(8)
                    .background(Farbe.karte, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(monate[m - 1]) \(tag.jahr)")
            }
        }
        Text("Je dunkler, desto voller der Tag.").font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.top, 8)
    }

    private func anteil(_ d: Tag) -> Double {
        let b = Tagesplan.bloecke(am: d, zustand: speicher.zustand, termine: speicher.termine(am: d))
        return min(1, Tagesplan.auslastung(b).anteil)
    }
}

// MARK: Ablagezone (Ziehen & Ablegen)

/// Zielzone zum Ablegen: leuchtet beim Darüberziehen, vibriert kurz beim Ablegen.
private struct Ablagezone: ViewModifier {
    var ecken: CGFloat
    var aktion: ([String], CGPoint) -> Bool
    @State private var ziel = false
    @State private var abgelegt = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if ziel {
                    RoundedRectangle(cornerRadius: ecken, style: .continuous).fill(Farbe.akzent.opacity(0.10))
                        .overlay(RoundedRectangle(cornerRadius: ecken, style: .continuous).strokeBorder(Farbe.akzent, lineWidth: 2))
                        .allowsHitTesting(false)
                }
            }
            .dropDestination(for: String.self) { items, ort in
                let ok = aktion(items, ort)
                if ok { abgelegt += 1 }
                return ok
            } isTargeted: { ziel = $0 }
            .sensoryFeedback(.success, trigger: abgelegt)
            .animation(.snappy(duration: 0.15), value: ziel)
    }
}

extension View {
    func ablagezone(ecken: CGFloat = Mass.karte, _ aktion: @escaping ([String], CGPoint) -> Bool) -> some View {
        modifier(Ablagezone(ecken: ecken, aktion: aktion))
    }
}

enum KalenderAktion {
    static func nutzlast(_ b: Tagesplan.Block) -> String? {
        if let a = b.aufgabeID { return "aufgabe:\(a.uuidString)" }
        if let h = b.habitID, b.art == .habit { return "habit:\(h.uuidString)" }
        return nil
    }

    @MainActor
    static func oeffnen(_ b: Tagesplan.Block, nav: Navigation) {
        switch b.art {
        case .aufgabe: if let a = b.aufgabeID { nav.blatt = .aufgabe(a) }
        case .habit: if let h = b.habitID { nav.oeffneHabit(h) }
        case .termin:
            if let s = b.serie { nav.blatt = .terminSeite(serie: s, tag: b.tag.text) }
            else if let e = b.eigenID { nav.blatt = .termin(e, tag: b.tag.text, start: nil) }
        }
    }

    /// Lässt sich der Eintrag in der Zeitleiste verschieben? Aufgaben, Habits und eigene Termine.
    static func verschiebbar(_ b: Tagesplan.Block) -> Bool {
        switch b.art {
        case .aufgabe: b.aufgabeID != nil
        case .habit: b.habitID != nil
        case .termin: b.eigenID != nil || externeID(b.serie) != nil
        }
    }

    /// Kennung im Apple-/Google-Kalender aus „apple:…“ bzw. „google:…“ (sonst nil, z. B. Kompass oder Beispiel).
    nonisolated static func externeID(_ serie: String?) -> String? {
        guard let s = serie, s.hasPrefix("apple:") || s.hasPrefix("google:") else { return nil }
        let id = String(s.drop(while: { $0 != ":" }).dropFirst())
        return id.contains(":") ? id : nil   // EventKit-Kennungen haben die Form „…:…“; Beispieltermine nicht
    }

    /// Eintrag auf Tag und Uhrzeit legen (nil = ohne Uhrzeit, nur Aufgaben und Habits).
    @MainActor
    @discardableResult
    static func verschieben(_ b: Tagesplan.Block, tag: Tag, start: Int?, nurDieser: Bool = true, speicher: Speicher) -> Bool {
        switch b.art {
        case .aufgabe:
            guard let a = b.aufgabeID else { return false }
            speicher.aendern { $0.aufgabeEinplanen(a, tag: tag, uhrzeit: start) }
        case .habit:
            guard let h = b.habitID else { return false }
            if tag != b.tag { speicher.aendern { $0.habitEinplanen(h, tag: b.tag, uhrzeit: nil) } }
            speicher.aendern { $0.habitEinplanen(h, tag: tag, uhrzeit: start) }
        case .termin:
            guard let s = start else { return false }
            if let e = b.eigenID {
                let alt = b.tag
                speicher.aendern { $0.terminVerschieben(e, von: alt, tag: tag, start: s, nurDieser: nurDieser) }
            } else if let id = externeID(b.serie) {
                // Apple/Google: direkt im Kalender des Geräts (nur dieses Vorkommen)
                do { try AppleKalender.aktiv.verschieben(id, von: b.tag, nach: tag, start: s, alle: !nurDieser, kalender: speicher.kalender) } catch { return false }
                speicher.appleKalenderLesen()
            } else { return false }
        }
        return true
    }

    @MainActor
    static func abhaken(_ b: Tagesplan.Block, speicher: Speicher) {
        switch b.art {
        case .aufgabe: if let a = b.aufgabeID { speicher.aendern { $0.umschalten(a, jetzt: speicher.jetzt()) } }
        case .habit: if let h = b.habitID { let d = b.tag; speicher.aendern { $0.habitUmschalten(h, am: d) } }
        case .termin: break
        }
    }

    /// Ablegen: „aufgabe:<id>“ bekommt Tag (und Uhrzeit); „habit:<id>“ bekommt an dem Tag eine Uhrzeit. Tag nil = Eingang.
    @MainActor
    @discardableResult
    static func ablegen(_ items: [String], tag: Tag?, uhrzeit: Int?, speicher: Speicher) -> Bool {
        guard let p = items.first else { return false }
        let teile = p.split(separator: ":", maxSplits: 1).map(String.init)
        guard teile.count == 2, let id = UUID(uuidString: teile[1]) else { return false }
        switch teile[0] {
        case "aufgabe":
            speicher.aendern { $0.aufgabeEinplanen(id, tag: tag, uhrzeit: uhrzeit) }
            return true
        case "habit":
            guard let tag else { return false }
            speicher.aendern { $0.habitEinplanen(id, tag: tag, uhrzeit: uhrzeit) }
            return true
        default: return false
        }
    }
}
