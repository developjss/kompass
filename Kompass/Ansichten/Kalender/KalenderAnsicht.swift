import SwiftUI

/// Kalender (Struktur v3 §4): oben „Als Nächstes“, dann Tag · Woche · Monat · Jahr, darunter Offenes zum Hineinziehen.
struct KalenderAnsicht: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        @Bindable var nav = nav
        let T = speicher.heute
        let tag = nav.kalenderTag ?? T

        Seite(titel: "Kalender", info: .kalender, neu: .termin) {
            NaechsteLeiste()

            ModusWahl(modus: $nav.kalenderModus).padding(.top, Mass.abschnitt - 8)

            KopfZeile(tag: tag, modus: nav.kalenderModus) { nav.kalenderTag = $0 }
                .padding(.top, 12).padding(.bottom, 8)

            switch nav.kalenderModus {
            case .tag:
                Wochenleiste(gewaehlt: tag, heute: T) { nav.kalenderTag = $0 }.padding(.bottom, 10)
                TagZeitleiste(tag: tag)
            case .woche: WochenRaster(tag: tag)
            case .monat:
                MonatsRaster(tag: tag)
                TagesListe(tag: tag)
            case .jahr: JahresRaster(tag: tag)
            }

            if nav.kalenderModus != .jahr { OffenesZumZiehen(tag: tag) }

            if !(speicher.zustand.einstellungen.googleBeispiel || speicher.zustand.einstellungen.appleBeispiel || speicher.zustand.einstellungen.appleKalender) {
                PfeilZeile(symbol: "calendar.badge.plus", text: "Apple- oder Google-Kalender verbinden") { nav.blatt = .einstellungen }
                    .padding(.top, Mass.abschnitt)
            }
        }
    }
}

// MARK: Als Nächstes

/// Die nächsten drei Einträge mit Uhrzeit: erste Karte im Verlauf, die anderen weiß.
struct NaechsteLeiste: View {
    var titel = "Als Nächstes"
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let T = speicher.heute
        let jetzt = speicher.jetztMinuten
        let n = Tagesplan.naechste(zustand: speicher.zustand, heute: T, jetzt: jetzt, termine: speicher.termine(am:))
        VStack(alignment: .leading, spacing: 10) {
            Text(titel).font(.abschnitt).foregroundStyle(Farbe.text).accessibilityAddTraits(.isHeader)
            if n.isEmpty {
                GruppierteListe { LeerZeile(text: "Nichts mit Uhrzeit in den nächsten 7 Tagen. Tipp auf „+ Neu“ oder zieh eine Aufgabe in den Tag.") }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(n.enumerated()), id: \.element.id) { i, b in
                        NaechsteKarte(block: b, erste: i == 0)
                    }
                    ForEach(0..<max(0, 3 - n.count), id: \.self) { _ in Color.clear.frame(maxWidth: .infinity) }
                }
            }
        }
    }
}

private struct NaechsteKarte: View {
    var block: Tagesplan.Block
    var erste: Bool
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let c = Color(hex: block.farbe)
        let wann = Tagesplan.wannText(block, heute: speicher.heute, jetzt: speicher.jetztMinuten)
        Button { KalenderAktion.oeffnen(block, nav: nav) } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).font(.system(size: 13, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(erste ? .white.opacity(0.22) : c.opacity(0.14), in: Circle())
                    .foregroundStyle(erste ? .white : c)
                Text(wann).font(.klein).foregroundStyle(erste ? .white.opacity(0.9) : c).lineLimit(1).minimumScaleFactor(0.8)
                Text(block.titel).font(.kompass(.subheadline, .bold)).foregroundStyle(erste ? .white : Farbe.text)
                    .lineLimit(2).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background {
                if erste {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(colors: Farbe.verlauf(block.farbe), startPoint: .bottomTrailing, endPoint: .topLeading))
                        .shadow(color: c.opacity(0.35), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Farbe.karte)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(block.titel), \(wann)")
        .accessibilityAddTraits(.isButton)
    }

    private var symbol: String {
        switch block.art {
        case .termin: "calendar"
        case .aufgabe: "checkmark.circle"
        case .habit: "repeat"
        }
    }
}

// MARK: Umschalter und Kopf

private struct ModusWahl: View {
    @Binding var modus: KalenderModus
    var body: some View {
        HStack(spacing: 4) {
            ForEach(KalenderModus.allCases, id: \.self) { m in
                let an = modus == m
                Button { withAnimation(.snappy(duration: 0.2)) { modus = m } } label: {
                    Text(m.titel).font(.kompass(.subheadline, .bold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(an ? Farbe.karte : Color.clear, in: Capsule())
                        .foregroundStyle(an ? Farbe.text : Farbe.zweitrangig)
                        .shadow(color: an ? .black.opacity(0.06) : .clear, radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(an ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Farbe.akzentWeich.opacity(0.7), in: Capsule())
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
                        Text(namen[i]).font(.klein).foregroundStyle(an ? .white.opacity(0.85) : Farbe.zweitrangig)
                        Text("\(d.tag)").font(.kompass(.title3, .bold)).foregroundStyle(an ? .white : (d == heute ? Farbe.akzent : Farbe.text))
                        HStack(spacing: 2) {
                            ForEach(Array(b.prefix(3).enumerated()), id: \.offset) { _, x in
                                Circle().fill(an ? .white : Color(hex: x.farbe)).frame(width: 5, height: 5)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(an ? Farbe.akzent : Farbe.karte, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        if d == heute && !an { RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Farbe.akzent.opacity(0.5), lineWidth: 1.5) }
                    }
                }
                .buttonStyle(.plain)
                .dropDestination(for: String.self) { items, _ in KalenderAktion.ablegen(items, tag: d, uhrzeit: nil, speicher: speicher) }
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

    var body: some View {
        let z = speicher.zustand
        let termine = speicher.termine(am: tag)
        let ganztags = termine.filter { $0.start == nil }
        let bloecke = Tagesplan.bloecke(am: tag, zustand: z, termine: termine)
        let hoehe: CGFloat = schrift >= .accessibility1 ? 72 : 54
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
                                Text(String(format: "%02d", h)).font(.caption2.weight(.semibold).monospacedDigit()).foregroundStyle(Farbe.pfeil)
                                    .frame(width: 22, alignment: .trailing).offset(y: -6)
                                Rectangle().fill(Farbe.linie).frame(height: 0.5)
                            }
                            .frame(height: hoehe, alignment: .top)
                            .contentShape(Rectangle())
                            .id(h)
                            .onTapGesture { nav.blatt = .termin(nil, tag: tag.text, start: h * 60) }
                        }
                    }
                    // Blöcke
                    GeometryReader { g in
                        let breite = g.size.width - 38
                        ForEach(bloecke) { b in
                            let (spalte, anzahl) = spalten[b.id] ?? (0, 1)
                            let w = breite / CGFloat(anzahl)
                            BlockKachel(block: b, kompakt: CGFloat(b.dauer) / 60 * hoehe < 40)
                                .frame(width: max(20, w - 3), height: max(22, CGFloat(b.dauer) / 60 * hoehe - 2))
                                .offset(x: 34 + CGFloat(spalte) * w, y: CGFloat(b.start - von * 60) / 60 * hoehe + 1)
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
                .dropDestination(for: String.self) { items, ort in
                    let m = von * 60 + Int((ort.y - 10) / hoehe * 60)
                    return KalenderAktion.ablegen(items, tag: tag, uhrzeit: max(von * 60, (m / 15) * 15), speicher: speicher)
                }
                }
                .frame(height: min(CGFloat(bis - von) * hoehe + 20, hoehe * 9))
                .scrollIndicators(.hidden)
                .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
                .onAppear { leser.scrollTo(startStunde(bloecke), anchor: .top) }
                .onChange(of: tag) { _, _ in leser.scrollTo(startStunde(bloecke), anchor: .top) }
            }
            if bloecke.isEmpty && ganztags.isEmpty {
                Text("Frei. Tipp auf eine Stunde für einen Termin – oder zieh unten eine Aufgabe hinein.")
                    .font(.unterzeile).foregroundStyle(Farbe.zweitrangig)
            }
        }
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
    @Environment(Navigation.self) private var nav

    var body: some View {
        let c = Color(hex: block.farbe)
        let inhalt = HStack(alignment: .top, spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(block.titel).font(mini ? .system(size: 10, weight: .semibold, design: .rounded) : .kompass(.caption, .bold))
                    .foregroundStyle(Farbe.text).strikethrough(block.erledigt).lineLimit(mini ? 1 : (kompakt ? 1 : 2))
                    .truncationMode(.tail)
                if !kompakt && !mini {
                    Text(block.unter).font(.caption2).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, mini ? 2 : 4).padding(.trailing, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(c.opacity(block.erledigt ? 0.08 : 0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { KalenderAktion.oeffnen(block, nav: nav) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(block.titel), \(block.unter)")
        .accessibilityAddTraits(.isButton)

        if let p = KalenderAktion.nutzlast(block) {
            inhalt.draggable(p) { Text(block.titel).font(.kompass(.subheadline, .bold)).padding(8).background(c.opacity(0.2), in: Capsule()) }
        } else {
            inhalt
        }
    }
}

// MARK: Woche

private struct WochenRaster: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    private let von = 7, bis = 23, hoehe: CGFloat = 30
    private let namen = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    var body: some View {
        let T = speicher.heute
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                Color.clear.frame(width: 22)
                ForEach(0..<7, id: \.self) { i in
                    let d = tag.montag.plus(tage: i)
                    Button { nav.kalenderTag = d; nav.kalenderModus = .tag } label: {
                        VStack(spacing: 0) {
                            Text(namen[i]).font(.caption2.weight(.semibold)).foregroundStyle(Farbe.zweitrangig)
                            Text("\(d.tag)").font(.kompass(.subheadline, .bold))
                                .foregroundStyle(d == T ? .white : Farbe.text)
                                .frame(width: 28, height: 28)
                                .background(d == T ? Farbe.akzent : .clear, in: Circle())
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(d.datum().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "de_DE"))))
                }
            }
            HStack(alignment: .top, spacing: 2) {
                VStack(spacing: 0) {
                    ForEach(von..<bis, id: \.self) { h in
                        Text(h % 2 == 1 ? String(format: "%02d", h) : "").font(.system(size: 9, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Farbe.pfeil).frame(width: 22, height: hoehe, alignment: .topTrailing).offset(y: -5)
                    }
                }
                ForEach(0..<7, id: \.self) { i in
                    let d = tag.montag.plus(tage: i)
                    let b = Tagesplan.bloecke(am: d, zustand: speicher.zustand, termine: speicher.termine(am: d))
                    ZStack(alignment: .topLeading) {
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
                                BlockKachel(block: x, kompakt: true, mini: true)
                                    .frame(width: max(8, w - 1), height: max(16, CGFloat(min(x.ende, bis * 60) - max(x.start, von * 60)) / 60 * hoehe - 1))
                                    .offset(x: CGFloat(spalte) * w, y: CGFloat(max(x.start, von * 60) - von * 60) / 60 * hoehe)
                                    .opacity(x.ende <= von * 60 || x.start >= bis * 60 ? 0 : 1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: CGFloat(bis - von) * hoehe)
                    .background(d == T ? Farbe.akzentWeich.opacity(0.4) : .clear)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { items, ort in
                        let m = von * 60 + Int(ort.y / hoehe * 60)
                        return KalenderAktion.ablegen(items, tag: d, uhrzeit: max(von * 60, (m / 15) * 15), speicher: speicher)
                    }
                }
            }
        }
        .padding(10)
        .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
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
        .dropDestination(for: String.self) { items, _ in KalenderAktion.ablegen(items, tag: tag, uhrzeit: nil, speicher: speicher) }
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

// MARK: Offenes zum Hineinziehen

private struct OffenesZumZiehen: View {
    var tag: Tag
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav

    var body: some View {
        let z = speicher.zustand
        let ohne = Tagesplan.ohneZeit(am: tag, zustand: z)
        let eingang = z.aufgaben.filter { $0.datum == nil && !$0.erledigt }.sorted { $0.reihenfolge < $1.reihenfolge }
        let tagText = tag == speicher.heute ? "heute" : tag.datum().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "de_DE")))

        AbschnittKopf(titel: "Ohne Uhrzeit") { Text(tagText).foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            if ohne.aufgaben.isEmpty && ohne.habits.isEmpty { LeerZeile(text: "Alles hat eine Uhrzeit.") }
            ForEach(ohne.habits) { h in ZiehZeile(titel: h.titel, unter: HabitRechnung.mengenText(h, am: tag), farbe: h.farbe, symbol: h.symbol,
                                                  erledigt: h.voll(am: tag), nutzlast: "habit:\(h.id.uuidString)") {
                speicher.aendern { $0.habitUmschalten(h.id, am: tag) }
            } oeffnen: { nav.oeffneHabit(h.id) } }
            ForEach(ohne.aufgaben) { a in ZiehZeile(titel: a.titel, unter: "\(a.dauer) Min\(z.ziel(a.zielID).map { " · \($0.titel)" } ?? "")",
                                                   farbe: Tagesplan.farbe(ziel: a.zielID, kategorie: a.kategorie, sonst: "#6B7285", in: z), symbol: "checkmark.circle",
                                                   erledigt: a.erledigt, nutzlast: "aufgabe:\(a.id.uuidString)") {
                speicher.aendern { $0.umschalten(a.id, jetzt: speicher.jetzt()) }
            } oeffnen: { nav.blatt = .aufgabe(a.id) } }
            AufgabeHinzufuegen(platzhalter: "Aufgabe für \(tagText)", datum: tag, prio: .normal)
        }
        Text("Halten und in den Kalender ziehen gibt eine Uhrzeit.").font(.klein).foregroundStyle(Farbe.zweitrangig).padding(.top, 6)

        AbschnittKopf(titel: "Eingang") { Text("\(eingang.count)").foregroundStyle(Farbe.zweitrangig) }
        GruppierteListe {
            if eingang.isEmpty { LeerZeile(text: "Leer – gut so.") }
            ForEach(eingang) { a in ZiehZeile(titel: a.titel, unter: "ohne Tag\(z.ziel(a.zielID).map { " · \($0.titel)" } ?? "")",
                                             farbe: Tagesplan.farbe(ziel: a.zielID, kategorie: a.kategorie, sonst: "#6B7285", in: z), symbol: "tray",
                                             erledigt: false, nutzlast: "aufgabe:\(a.id.uuidString)") {
                speicher.aendern { $0.umschalten(a.id, jetzt: speicher.jetzt()) }
            } oeffnen: { nav.blatt = .aufgabe(a.id) } }
            AufgabeHinzufuegen(platzhalter: "Idee", datum: nil, prio: .normal)
        }
        .dropDestination(for: String.self) { items, _ in KalenderAktion.ablegen(items, tag: nil, uhrzeit: nil, speicher: speicher) }
    }
}

private struct ZiehZeile: View {
    var titel: String
    var unter: String
    var farbe: String
    var symbol: String
    var erledigt: Bool
    var nutzlast: String
    var abhaken: () -> Void
    var oeffnen: () -> Void

    var body: some View {
        let c = Color(hex: farbe)
        HStack(spacing: 10) {
            Haken(an: erledigt, farbe: c, beschriftung: titel, aktion: abhaken).padding(.leading, 4)
            Button(action: oeffnen) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel).font(.zeile).foregroundStyle(erledigt ? Farbe.zweitrangig : Farbe.text).strikethrough(erledigt).lineLimit(1)
                    Text(unter).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Image(systemName: "line.3.horizontal").font(.footnote.weight(.bold)).foregroundStyle(Farbe.pfeil).padding(.trailing, 16)
                .accessibilityHidden(true)
        }
        .frame(minHeight: Mass.zeileKompakt)
        .draggable(nutzlast) {
            Label(titel, systemImage: symbol).font(.kompass(.subheadline, .bold)).padding(.horizontal, 12).padding(.vertical, 8)
                .background(c.opacity(0.2), in: Capsule())
        }
        .accessibilityAction(named: "Öffnen", oeffnen)
    }
}

// MARK: Aktionen

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
        case .termin: if let e = b.eigenID { nav.blatt = .termin(e, tag: b.tag.text, start: nil) }
        }
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
