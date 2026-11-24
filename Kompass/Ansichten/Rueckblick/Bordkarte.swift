import SwiftUI

/// Rückblick als Bordkarte (Gadget, design.md §7): oben eine Bordkarte der Woche. Den goldenen Abschnitt abreißen
/// (ziehen oder antippen) – dahinter liegt die Aussage der Woche. Abgerissen bleibt abgerissen (je Woche gemerkt).
struct Bordkarte<Inhalt: View>: View {
    /// Montag der Woche („2026-11-23“), Schlüssel fürs Merken
    var woche: String
    var kw: Int
    var von: Tag
    var bis: Tag
    var fokus: TimeInterval
    var ziele: Int
    @ViewBuilder var inhalt: Inhalt

    @AppStorage("rueckblick.abgerissen") private var abgerissen = ""
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var zug: CGFloat = 0
    @State private var reisst = false

    var body: some View {
        if Self.istAbgerissen(abgerissen, woche: woche) {
            inhalt.transition(.move(edge: .top).combined(with: .opacity))
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    haupt
                    abschnitt
                }
                .fixedSize(horizontal: false, vertical: true)
                .compositingGroup()
                .shadow(color: .black.opacity(0.22), radius: 12, y: 8)
                Text("Goldenen Abschnitt abreißen – dahinter liegt deine Woche.")
                    .font(.klein).foregroundStyle(Farbe.zweitrangig).multilineTextAlignment(.center)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: reisst)
        }
    }

    // MARK: Teile

    private var haupt: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                feld("Bordkarte", "Woche \(kw)")
                Spacer()
                feld("Flug", String(format: "KMP %03d", kw), rechts: true)
            }
            HStack(spacing: 6) {
                Text("MO").font(.system(size: 30, weight: .semibold, design: .serif))
                ZStack {
                    Rectangle().fill(.clear).frame(height: 1)
                        .overlay(Line().stroke(Color(roh: "#9A8F6E"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])))
                    Image(systemName: "airplane").font(.system(size: 14, weight: .bold)).foregroundStyle(Color(roh: "#A27711"))
                        .padding(.horizontal, 4).background(Color(roh: "#F2EAD6"))
                }
                Text("SO").font(.system(size: 30, weight: .semibold, design: .serif))
            }
            HStack {
                feld("Von", kurz(von))
                Spacer()
                feld("Nach", kurz(bis))
                Spacer()
                feld("Gate", ziele == 1 ? "1 Ziel" : "\(ziele) Ziele")
                Spacer()
                feld("Fokus", Zahl.dauer(fokus))
            }
        }
        .foregroundStyle(Color(roh: "#0B1325"))
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(roh: "#F6F1E4"), Color(roh: "#EDE3C8")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bordkarte Woche \(kw), \(kurz(von)) bis \(kurz(bis)), \(ziele) Ziele, Fokus \(Zahl.dauer(fokus))")
    }

    private var abschnitt: some View {
        VStack(spacing: 10) {
            Text("ABREISSEN ›").font(.system(size: 10, weight: .heavy)).tracking(1)
                .fixedSize().rotationEffect(.degrees(-90)).frame(width: 20, height: 92)
            Strichcode().frame(width: 52, height: 54)
        }
        .foregroundStyle(Color(roh: "#0B1325"))
        .frame(width: 84)
        .frame(maxHeight: .infinity)
        .background(LinearGradient(colors: [Farbe.gold, Color(roh: "#D79A20")], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: UnevenRoundedRectangle(bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous))
        .overlay(alignment: .leading) {
            Line(senkrecht: true).stroke(Color(roh: "#0B1325").opacity(0.45), style: StrokeStyle(lineWidth: 2, dash: [5, 4])).frame(width: 2).padding(.vertical, 12)
        }
        .rotationEffect(.degrees(reisst ? 38 : Double(min(zug / 6, 14))), anchor: .topLeading)
        .offset(x: reisst ? 60 : zug * 0.6, y: reisst ? 320 : 0)
        .opacity(reisst ? 0 : 1)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { zug = max(0, $0.translation.width) }
                .onEnded { _ in if zug > 60 { reissen() } else { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { zug = 0 } } }
        )
        .onTapGesture { reissen() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bordkarte abreißen")
        .accessibilityHint("Zeigt den Bericht der Woche")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { reissen() }
    }

    private func feld(_ titel: String, _ wert: String, rechts: Bool = false) -> some View {
        VStack(alignment: rechts ? .trailing : .leading, spacing: 1) {
            Text(titel.uppercased()).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(Color(roh: "#6B6A5E"))
            Text(wert).font(.system(size: 13, weight: .bold, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func reissen() {
        guard !reisst else { return }
        if ruhig {
            reisst = true
            abgerissen = Self.merken(abgerissen, woche: woche)
            return
        }
        withAnimation(.easeIn(duration: 0.45)) { reisst = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { abgerissen = Self.merken(abgerissen, woche: woche) }
        }
    }

    private func kurz(_ t: Tag) -> String {
        t.datum().formatted(.dateTime.day(.twoDigits).month(.twoDigits).locale(Locale(identifier: "de_DE")))
    }

    // MARK: Merken (je Woche, höchstens 26)

    nonisolated static func istAbgerissen(_ liste: String, woche: String) -> Bool {
        liste.split(separator: ",").contains { $0 == woche }
    }

    nonisolated static func merken(_ liste: String, woche: String) -> String {
        var l = liste.split(separator: ",").map(String.init).filter { $0 != woche }
        l.append(woche)
        return l.suffix(26).joined(separator: ",")
    }
}

/// Gerade Linie (waagerecht oder senkrecht) für gestrichelte Perforation und Route.
private struct Line: Shape {
    var senkrecht = false
    func path(in r: CGRect) -> Path {
        Path { p in
            if senkrecht { p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)) }
            else { p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)) }
        }
    }
}

private struct Strichcode: View {
    private let breiten: [CGFloat] = [2, 1, 3, 1, 2, 2, 1, 3, 1, 1, 2, 3, 1, 2, 1, 2]
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(breiten.indices, id: \.self) { i in Rectangle().frame(width: breiten[i]) }
        }
        .opacity(0.85)
        .accessibilityHidden(true)
    }
}
