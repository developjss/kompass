import SwiftUI

/// Fokus-Timer (Easter Egg 2, design.md §7): der echte 747 fliegt die geplante Dauer der Aufgabe ab – ohne ein Flugwort.
/// Pause/Weiter, „Fertig“ bucht die Zeit wie bisher (an Mitternacht geteilt, höchstens 4 h). Nach der Landung läuft der Timer weiter.
struct FokusBlatt: View {
    var aufgabeID: UUID
    @Environment(Speicher.self) private var speicher
    @Environment(\.dismiss) private var dismiss
    @State private var meldung: String?

    var body: some View {
        let z = speicher.zustand
        let a = z.aufgabe(aufgabeID)
        let ziel = z.ziel(a?.zielID)
        let laeuft = z.timer?.aufgabeID == aufgabeID && z.timer?.laeuftSeit != nil
        let dauer = a?.dauer ?? 60
        TimelineView(.periodic(from: .now, by: 1)) { kontext in
            FlugAnzeige(titel: a?.titel ?? "Aufgabe", ziel: ziel?.titel, dauer: dauer, laeuft: laeuft, jetzt: kontext.date,
                        sekunden: z.timer?.aufgabeID == aufgabeID ? z.timerSekunden(jetzt: kontext.date) : 0,
                        meldung: meldung, umschalten: umschalten, fertig: fertig, schliessen: { dismiss() })
        }
        .foregroundStyle(Farbe.wort)
        .padding(.horizontal, 20).padding(.bottom, 16)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Color(roh: "#0B1017"), Color(roh: "#141C27"), Color(roh: "#1E2A39")], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .onAppear {
            if a != nil, z.timer?.aufgabeID != aufgabeID || z.timer?.laeuftSeit == nil {
                speicher.aendern { $0.timerStarten(aufgabeID, jetzt: speicher.jetzt()) }
            }
        }
    }

    private func umschalten() {
        let laeuft = speicher.zustand.timer?.aufgabeID == aufgabeID && speicher.zustand.timer?.laeuftSeit != nil
        speicher.aendern { s in
            if laeuft { s.timerPausieren(jetzt: speicher.jetzt()) } else { s.timerStarten(aufgabeID, jetzt: speicher.jetzt()) }
        }
    }

    private func fertig() {
        var buchung: FokusRechnung.Buchung?
        speicher.aendern { buchung = $0.timerStoppen(jetzt: speicher.jetzt()) }
        if buchung?.gekappt == true { meldung = "Timer lief über 4 Stunden – gezählt werden 4 Stunden." } else { dismiss() }
    }
}

/// Inhalt des Fokus-Flugs für einen Zeitpunkt (eigene View, damit der Compiler es schnell prüft).
private struct FlugAnzeige: View {
    var titel: String
    var ziel: String?
    var dauer: Int
    var laeuft: Bool
    var jetzt: Date
    var sekunden: TimeInterval
    var meldung: String?
    var umschalten: () -> Void
    var fertig: () -> Void
    var schliessen: () -> Void

    private var strecke: Double { FlugRechnung.strecke(sekunden: sekunden, dauerMinuten: dauer) }
    private var phase: FlugRechnung.Phase { FlugRechnung.phase(strecke: strecke, sekunden: sekunden, laeuft: laeuft) }
    private var rest: Int { FlugRechnung.restMinuten(sekunden: sekunden, dauerMinuten: dauer) }
    private var prozent: Int { Int((strecke * 100).rounded()) }

    var body: some View {
        VStack(spacing: 16) {
            kopf
            himmel
            Text(uhr(sekunden)).font(.system(size: 56, weight: .semibold, design: .serif)).monospacedDigit()
                .accessibilityLabel("Fokuszeit " + uhr(sekunden))
            Text(phase.text).font(.kompass(.subheadline, .bold)).foregroundStyle(Farbe.wortAkzent)
            instrumente
            if let meldung { Text(meldung).font(.unterzeile).multilineTextAlignment(.center) }
            knoepfe
            Spacer(minLength: 0)
            Button("Schließen – Timer läuft weiter", action: schliessen).font(.unterzeile).opacity(0.8)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: phase, condition: Self.spuerbar)
    }

    private static func spuerbar(_ alt: FlugRechnung.Phase, _ neu: FlugRechnung.Phase) -> Bool {
        (alt == .boarding && neu == .steigflug) || neu == .gelandet
    }

    private var kopf: some View {
        VStack(spacing: 4) {
            Text("Fokus").font(.klein).foregroundStyle(Farbe.wort.opacity(0.75))
            Text(titel).font(.kompass(.title3, .heavy)).multilineTextAlignment(.center).lineLimit(2)
            if let ziel { Text(ziel).font(.unterzeile).opacity(0.8) }
        }
        .padding(.top, 12)
    }

    private var himmel: some View {
        let beschreibung = "\(prozent) Prozent der geplanten \(dauer) Minuten. " + phase.text
        return FlugHimmel(strecke: strecke, von: "Start", nach: "Ende")
            .frame(height: 240)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(beschreibung)
    }

    private var instrumente: some View {
        HStack(spacing: 8) {
            Instrument(wert: "\(dauer) min", titel: "Geplant")
            Instrument(wert: "\(prozent) %", titel: "Geschafft")
            Instrument(wert: ankunft(rest: rest), titel: rest == 0 ? "Fertig" : "Ende um")
        }
    }

    private var knoepfe: some View {
        HStack(spacing: 12) {
            Button(action: umschalten) {
                Label(laeuft ? "Pause" : "Weiter", systemImage: laeuft ? "pause.fill" : "play.fill")
                    .frame(minWidth: 120, minHeight: 50).background(Farbe.wort.opacity(0.14), in: Capsule())
                    .overlay(Capsule().strokeBorder(Farbe.wort.opacity(0.28)))
            }
            Button(action: fertig) {
                Label("Beenden", systemImage: "checkmark")
                    .frame(minWidth: 120, minHeight: 50).background(Farbe.wort, in: Capsule()).foregroundStyle(Farbe.nacht)
            }
            .accessibilityHint("Bucht die Fokuszeit")
        }
        .font(.kompass(.headline, .bold))
        .buttonStyle(.plain)
    }

    private func ankunft(rest: Int) -> String {
        guard rest > 0 else { return "✓" }
        guard laeuft else { return "in \(rest) Min" }
        return jetzt.addingTimeInterval(Double(rest) * 60).formatted(.dateTime.hour().minute().locale(Locale(identifier: "de_DE")))
    }

    private func uhr(_ s: TimeInterval) -> String {
        let n = Int(s)
        return n >= 3600 ? String(format: "%d:%02d:%02d", n / 3600, n / 60 % 60, n % 60) : String(format: "%02d:%02d", n / 60, n % 60)
    }
}

/// Eine Kennzahl: Wert (Mono), Titel klein.
private struct Instrument: View {
    var wert: String
    var titel: String
    var body: some View {
        VStack(spacing: 2) {
            Text(wert).font(.system(.subheadline, design: .monospaced, weight: .bold)).foregroundStyle(Farbe.wort).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(titel.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.8).opacity(0.65)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(Farbe.wort.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Farbe.wort.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }
}

/// Nachthimmel mit Sternen, ziehenden Wolken, gestrichelter Strecke und dem echten 747 an der aktuellen Stelle (das eine Flugbild der App).
struct FlugHimmel: View {
    var strecke: Double
    var von: String
    var nach: String
    @Environment(\.accessibilityReduceMotion) private var ruhig

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let p0 = CGPoint(x: w * 0.09, y: h * 0.76), p1 = CGPoint(x: w * 0.27, y: h * 0.12)
            let p2 = CGPoint(x: w * 0.73, y: h * 0.12), p3 = CGPoint(x: w * 0.91, y: h * 0.70)
            let route = Path { $0.move(to: p0); $0.addCurve(to: p3, control1: p1, control2: p2) }
            let t = strecke
            let pos = Self.punkt(t, p0, p1, p2, p3)
            let tang = Self.ableitung(min(max(t, 0.001), 0.999), p0, p1, p2, p3)
            let winkel = t >= 1 ? 0 : atan2(tang.y, tang.x)
            ZStack {
                LinearGradient(stops: [.init(color: Color(roh: "#0B1017"), location: 0), .init(color: Color(roh: "#18222E"), location: 0.55),
                                       .init(color: Color(roh: "#33475F"), location: 0.85), .init(color: Farbe.jetzt.opacity(0.30), location: 1.2)],
                               startPoint: .top, endPoint: .bottom)
                Canvas { c, s in
                    var zufall = UInt64(7)
                    for _ in 0..<34 {
                        zufall = zufall &* 6364136223846793005 &+ 1442695040888963407
                        let x = Double(zufall >> 33 & 0xFFFF) / 65535 * s.width
                        zufall = zufall &* 6364136223846793005 &+ 1442695040888963407
                        let y = Double(zufall >> 33 & 0xFFFF) / 65535 * s.height * 0.6
                        let r = 0.5 + Double(zufall >> 20 & 0xFF) / 255 * 1.0
                        c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.3 + r / 3)))
                    }
                }
                Wolken(ruhig: ruhig).frame(maxHeight: .infinity, alignment: .bottom)
                route.stroke(Farbe.wortAkzent.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                route.trimmedPath(from: 0, to: t).stroke(Farbe.jetzt, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .shadow(color: Farbe.jetzt.opacity(0.7), radius: 4)
                Circle().fill(Farbe.wortAkzent).frame(width: 8, height: 8).position(p0)
                Circle().fill(Farbe.jetzt).frame(width: 8, height: 8).position(p3)
                Text(von.uppercased()).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Farbe.wortAkzent).position(x: p0.x + 8, y: p0.y + 24)
                Text(nach.uppercased()).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Farbe.jetzt).position(x: p3.x - 6, y: p3.y + 24)
                Objekt.b747Abflug.bild.resizable().scaledToFit()
                    .frame(width: 64)
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 8)
                    .rotationEffect(.radians(winkel) + .degrees(8))
                    .position(pos)
                    .animation(ruhig ? nil : .easeInOut(duration: 0.9), value: strecke)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Farbe.wort.opacity(0.12)))
        }
    }

    static func punkt(_ t: Double, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x
        let y = u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y
        return CGPoint(x: x, y: y)
    }

    static func ableitung(_ t: Double, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGPoint {
        let u = 1 - t
        let x = 3 * u * u * (b.x - a.x) + 6 * u * t * (c.x - b.x) + 3 * t * t * (d.x - c.x)
        let y = 3 * u * u * (b.y - a.y) + 6 * u * t * (c.y - b.y) + 3 * t * t * (d.y - c.y)
        return CGPoint(x: x, y: y)
    }
}

/// Zwei Wolkenbänder, die langsam nach links ziehen (bei „Bewegung reduzieren“ stehen sie).
private struct Wolken: View {
    var ruhig: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: ruhig)) { k in
            let x = ruhig ? 0 : k.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) / 60
            Canvas { c, s in
                for (i, (y, b, a)) in [(0.82, 0.30, 0.10), (0.92, 0.42, 0.14)].enumerated() {
                    let versatz = (x * (i == 0 ? 1 : 1.6)).truncatingRemainder(dividingBy: 1) * s.width
                    for k in 0..<3 {
                        let cx = Double(k) * s.width * 0.55 - versatz + s.width * 0.2
                        let r = CGRect(x: cx.truncatingRemainder(dividingBy: s.width * 1.65) - s.width * 0.1, y: s.height * y - 10, width: s.width * b, height: 22)
                        c.fill(Path(ellipseIn: r), with: .color(.white.opacity(a)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
