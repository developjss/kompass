import SwiftUI

/// „Dein Tag“ als Reel (wie „Your November ahead“ in Gapless): wenige Slides, eine Aussage je Slide, Fortschritt oben,
/// Weiter unten. Zahlen kommen aus `Tagesplan`, `HomeRechnung` und `Kurs` – hier wird nur gezeigt.
struct TagReelKarte: View {
    var slides: Int
    var teaser: String
    var oeffnen: () -> Void

    var body: some View {
        Button(action: oeffnen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<slides, id: \.self) { i in Capsule().fill(i == 0 ? Farbe.akzent : Farbe.akzentWeich).frame(height: 4) }
                }
                .frame(maxWidth: 160)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dein Tag im Blick").font(.kompass(.title3, .bold)).foregroundStyle(Farbe.text)
                        Text(teaser).font(.unterzeile).foregroundStyle(Farbe.zweitrangig).lineLimit(2)
                        Label("Start", systemImage: "play.fill").font(.kompass(.subheadline, .bold))
                            .padding(.horizontal, 16).frame(minHeight: 40)
                            .background(Farbe.handlung, in: Capsule()).foregroundStyle(Farbe.aufFarbe)
                            .padding(.top, 4)
                    }
                    Spacer(minLength: 8)
                    MiniSlides()
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Farbe.karte, in: RoundedRectangle(cornerRadius: Mass.karte, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dein Tag im Blick, \(slides) Slides. \(teaser)")
        .accessibilityAddTraits(.isButton)
    }

    /// Gefächerte Mini-Slides in den Reel-Farben (gezeichnet, keine Bilder)
    private struct MiniSlides: View {
        var body: some View {
            ZStack {
                ForEach(Array([Farbe.gruen, Farbe.violett, Farbe.indigo].enumerated()), id: \.offset) { i, f in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: f, startPoint: .bottom, endPoint: .top))
                        .frame(width: 44, height: 62)
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 4) {
                                Circle().fill(.white.opacity(0.8)).frame(width: 8, height: 8)
                                Capsule().fill(.white.opacity(0.7)).frame(width: 22, height: 3)
                                Capsule().fill(.white.opacity(0.5)).frame(width: 14, height: 3)
                            }
                            .padding(6)
                        }
                        .rotationEffect(.degrees(Double(i - 1) * 12))
                        .offset(x: CGFloat(i - 1) * 14, y: CGFloat(abs(i - 1)) * 4)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                }
            }
            .frame(width: 90, height: 74)
            .accessibilityHidden(true)
        }
    }
}

/// Die Slides: Jetzt · Als Nächstes · Hinweise · Heute offen · Ziele · Los.
struct TagReel: View {
    @Environment(Speicher.self) private var speicher
    @Environment(Navigation.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var index = 0

    struct Slide: Identifiable {
        var id: Int
        var farben: [Color]
        var symbol: String
        var label: String
        var titel: String
        var zeilen: [String]
        var knopf: (String, () -> Void)?
    }

    var body: some View {
        let slides = inhalte()
        ZStack(alignment: .top) {
            TabView(selection: $index) {
                ForEach(slides) { s in
                    SlideAnsicht(slide: s, letzte: s.id == slides.count - 1, weiter: { weiter(slides.count) })
                        .tag(s.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<slides.count, id: \.self) { i in Capsule().fill(.white.opacity(i <= index ? 0.95 : 0.35)).frame(height: 4) }
                }
                HStack {
                    Text("Dein Tag").font(.klein).foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.body.weight(.bold)).frame(width: 40, height: 40)
                            .background(.white.opacity(0.2), in: Circle()).foregroundStyle(.white)
                    }
                    .accessibilityLabel("Schließen")
                }
            }
            .padding(.horizontal, Mass.rand).padding(.top, 8)
        }
        .animation(ruhig ? nil : .snappy(duration: 0.3), value: index)
        .accessibilityElement(children: .contain)
    }

    private func weiter(_ anzahl: Int) {
        if index < anzahl - 1 { index += 1 } else { dismiss() }
    }

    // MARK: Inhalte (nur lesen)

    private func inhalte() -> [Slide] {
        let z = speicher.zustand, T = speicher.heute, jetzt = speicher.jetztMinuten
        let naechste = Tagesplan.naechste(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:), anzahl: 4)
        let fokus = HomeRechnung.fokus(zustand: z, heute: T, jetzt: jetzt, naechste: naechste)
        let hinweise = Tagesplan.hinweise(zustand: z, heute: T, jetzt: jetzt, termine: speicher.termine(am:))
        let ohne = Tagesplan.ohneZeit(am: T, zustand: z)
        let offenA = ohne.aufgaben.filter { !$0.erledigt }, offenH = ohne.habits.filter { !$0.voll(am: T) }
        let bloecke = Tagesplan.bloecke(am: T, zustand: z, termine: speicher.termine(am: T))
        let a = Tagesplan.auslastung(bloecke, ab: max(jetzt, Tagesplan.wachVon))
        let ziele = z.ziele.filter { $0.status == .aktiv }.sorted { $0.faellig < $1.faellig }
        var out: [Slide] = []

        // 1 Jetzt
        let jetztTitel = fokus.block?.titel ?? fokus.aufgabe?.titel ?? fokus.habit?.titel ?? "Für heute ist nichts mehr offen."
        var jetztZeilen: [String] = []
        if let b = fokus.block { jetztZeilen.append(Tagesplan.laeuft(b, heute: T, jetzt: jetzt) ? "Läuft gerade · noch \(b.ende - jetzt) Min" : Tagesplan.wannText(b, heute: T, jetzt: jetzt)) }
        if fokus.gesamt > 0 { jetztZeilen.append("\(fokus.geschafft) von \(fokus.gesamt) heute geschafft") }
        let jetztKnopf: (String, () -> Void)? = {
            if let id = fokus.block?.aufgabeID ?? fokus.aufgabe?.id { return ("Fokus starten", { dismiss(); nav.blatt = .fokus(id) }) }
            if let h = fokus.block?.art == .habit ? fokus.block?.habitID : fokus.habit?.id { return ("Habit öffnen", { dismiss(); nav.oeffneHabit(h) }) }
            return nil
        }()
        out.append(Slide(id: 0, farben: Farbe.indigo, symbol: "scope", label: fokus.block != nil ? "Als Nächstes" : "Jetzt dran", titel: jetztTitel, zeilen: jetztZeilen, knopf: jetztKnopf))

        // 2 Als Nächstes
        let rest = naechste.filter { $0.id != fokus.block?.id }.prefix(3)
        out.append(Slide(id: 1, farben: [Color(hex: "#0E5A8A"), Color(hex: "#2F8FD6")], symbol: "calendar", label: "Danach",
                         titel: rest.isEmpty ? "Nichts mehr mit Uhrzeit" : "\(rest.count) Einträge mit Uhrzeit",
                         zeilen: rest.isEmpty ? ["Zieh im Kalender eine Aufgabe in den Tag."] : rest.map { "\(Tagesplan.wannText($0, heute: T, jetzt: jetzt)) · \($0.titel)" },
                         knopf: ("Zum Kalender", { dismiss(); nav.oeffneKalender(nil) })))

        // 3 Wie voll ist der Tag
        let frei = Tagesplan.freiAb(bloecke, ab: jetzt)
        let heuteHinweise = hinweise.filter { $0.tag == T }
        out.append(Slide(id: 2, farben: a.eng ? [Color(hex: "#8A5300"), Color(hex: "#E0A030")] : Farbe.gruen, symbol: a.eng ? "gauge.with.dots.needle.67percent" : "leaf.fill",
                         label: "Dein Tag",
                         titel: a.eng ? "Heute ist es eng" : "Noch \(Zahl.dauer(TimeInterval(frei * 60))) frei",
                         zeilen: heuteHinweise.isEmpty ? [a.eng ? "Lieber nichts Neues dazu nehmen." : "Platz für Offenes – oder für Pause."] : heuteHinweise.prefix(3).map(\.text),
                         knopf: nil))

        // 4 Heute offen
        let offenZeilen = offenH.prefix(2).map { "\($0.titel) · \(HabitRechnung.mengenText($0, am: T))" } + offenA.prefix(3).map { "\($0.titel) · \($0.dauer) Min" }
        out.append(Slide(id: 3, farben: Farbe.violett, symbol: "checklist", label: "Heute offen",
                         titel: offenA.isEmpty && offenH.isEmpty ? "Alles erledigt" : "\(offenA.count + offenH.count) offen",
                         zeilen: offenZeilen.isEmpty ? ["Stark. Der Rest des Tages gehört dir."] : offenZeilen, knopf: nil))

        // 5 Ziele
        if !ziele.isEmpty {
            let hinten = ziele.filter { [.hinterher, .ueberfaellig].contains(Kurs.aufKurs($0, in: z, heute: T).lage) }
            out.append(Slide(id: 4, farben: [Color(hex: "#0E8580"), Color(hex: "#3FBDB5")], symbol: "target", label: "Ziele",
                             titel: hinten.isEmpty ? "Alle Ziele auf Kurs" : "\(hinten.count) Ziel\(hinten.count == 1 ? "" : "e") hinterher",
                             zeilen: ziele.prefix(3).map { g in
                                 let k = Kurs.aufKurs(g, in: z, heute: T)
                                 return "\(g.titel) · \(Zahl.prozent(k.fortschritt)) · \(k.lage.text)"
                             },
                             knopf: ("Zu den Zielen", { dismiss(); nav.zeige(.ziele) })))
        }

        // 6 Los
        out.append(Slide(id: out.count, farben: Farbe.indigo, symbol: "sparkles", label: "Los geht's",
                         titel: fokus.gesamt > 0 ? "Ein Schritt nach dem anderen." : "Heute ist frei.",
                         zeilen: ["Der Assistent hilft, wenn du nicht weißt, womit du anfängst."],
                         knopf: ("Assistenten fragen", { dismiss(); nav.bereich = .lotse })))
        return out
    }
}

private struct SlideAnsicht: View {
    var slide: TagReel.Slide
    var letzte: Bool
    var weiter: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: slide.farben, startPoint: .bottomTrailing, endPoint: .topLeading).ignoresSafeArea()
            Circle().fill(.white.opacity(0.14)).frame(width: 320).blur(radius: 70).offset(x: -120, y: -220)
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 80)
                Image(systemName: slide.symbol).font(.system(size: 26, weight: .bold))
                    .frame(width: 64, height: 64).background(.white.opacity(0.2), in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
                Text(slide.label).font(.klein).opacity(0.85)
                Text(slide.titel).font(.kompass(.largeTitle, .heavy)).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(slide.zeilen, id: \.self) { z in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(.white.opacity(0.8)).frame(width: 6, height: 6).padding(.top, 8)
                            Text(z).font(.kompass(.body, .medium)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer()
                if let (text, aktion) = slide.knopf {
                    Button(action: aktion) {
                        Text(text).font(.kompass(.headline, .bold)).frame(maxWidth: .infinity, minHeight: 50)
                            .background(.white.opacity(0.2), in: Capsule()).overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Button(action: weiter) {
                    Text(letzte ? "Fertig" : "Weiter").font(.kompass(.headline, .bold)).frame(maxWidth: .infinity, minHeight: 54)
                        .background(Farbe.seladon, in: Capsule()).foregroundStyle(Farbe.nacht)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("reel.weiter")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Mass.rand).padding(.bottom, 24)
            .frame(maxWidth: 720)
        }
        .contentShape(Rectangle())
        .onTapGesture { location in if location.x > 120 { weiter() } }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(slide.label): \(slide.titel). \(slide.zeilen.joined(separator: ". "))")
    }
}
