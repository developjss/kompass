import SwiftUI

/// Statistik als Bordkarte (design.md §7): Papierkarte (`Farbe.papier`) – oben die Zahlen, unten der Abriss mit Perforation.
/// Nichts zum Ziehen (Entscheidung 25.11.2026): die Form ist die Erinnerung, die Karte liegt immer offen.
struct Bordkarte<Inhalt: View>: View {
    /// Schlüssel fürs Merken („2026-11-23“, „ziel:…“, „habit:…“)
    var schluessel: String
    /// Abriss: links die Bezeichnung („Bericht“), rechts der Wert („KW 48“)
    var links: String
    var rechts: String
    @ViewBuilder var inhalt: Inhalt

    @AppStorage("bordkarte.gezogen") private var gezogen = ""
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var zug: CGFloat = 0
    @State private var kommt = false

    /// Höhe des sichtbaren Abrisses, solange die Karte steckt
    static var abriss: CGFloat { 58 }

    private var draussen: Bool { true }

    var body: some View {
        ZStack(alignment: .bottom) {
            if draussen {
                karte
                    .transition(ruhig ? .opacity : .move(edge: .top).combined(with: .opacity))
            } else {
                karte
                    .offset(y: zug * 0.5)
                    .frame(height: Self.abriss + zug * 0.5, alignment: .bottom)
                    .clipped()
                    .overlay(alignment: .top) { schlitz }
            }
        }
        .animation(ruhig ? nil : .spring(response: 0.55, dampingFraction: 0.82), value: draussen)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: kommt)
    }

    // MARK: Teile

    private var karte: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) { inhalt }
                .padding(EdgeInsets(top: 18, leading: 16, bottom: 14, trailing: 16))
                .foregroundStyle(Farbe.text)
                .opacity(draussen ? 1 : 0)
            perforation
            abrissZeile
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Farbe.papier, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Farbe.schatten.opacity(draussen ? 0.10 : 0.18), radius: draussen ? 5 : 8, y: 4)
        .shadow(color: Farbe.schatten.opacity(draussen ? 0.28 : 0), radius: 24, y: 24)
    }

    /// Perforation: zwei Kreise in Grundfarbe an den Rändern, dazwischen eine gestrichelte Linie
    private var perforation: some View {
        ZStack {
            Line().stroke(Farbe.linie, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                .frame(height: 2).padding(.horizontal, 14)
            HStack { Circle().fill(Farbe.grund).frame(width: 20, height: 20).offset(x: -10); Spacer(); Circle().fill(Farbe.grund).frame(width: 20, height: 20).offset(x: 10) }
        }
        .frame(height: 20)
        .opacity(draussen ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var abrissZeile: some View {
        HStack(spacing: 10) {
            Text(links.uppercased())
            Spacer()
            if draussen {
                Text(rechts.uppercased()).foregroundStyle(Farbe.text)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down").font(.system(size: 11, weight: .heavy))
                        .offset(y: wippt ? 3 : 0)
                        .animation(ruhig ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: wippt)
                    Text("Herausziehen".uppercased())
                }
            }
        }
        .font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(1.3)
        .foregroundStyle(Farbe.zweitrangig)
        .padding(EdgeInsets(top: draussen ? 0 : 6, leading: 16, bottom: 15, trailing: 16))
        .frame(maxWidth: .infinity, minHeight: draussen ? nil : Self.abriss, alignment: .bottom)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { if !draussen { zug = max(0, min(160, $0.translation.height)) } }
                .onEnded { _ in if !draussen { if zug > 48 { herausziehen() } else { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { zug = 0 } } } }
        )
        .onTapGesture { if !draussen { herausziehen() } }
        .onAppear { wippt = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(draussen ? "\(links), \(rechts)" : "\(links) herausziehen")
        .accessibilityHint(draussen ? "" : "Zeigt die Zahlen")
        .accessibilityAddTraits(draussen ? [] : .isButton)
        .accessibilityAction { if !draussen { herausziehen() } }
    }

    @State private var wippt = false

    /// Der Schlitz: ein dunkler Spalt an der Oberkante, nur solange die Karte steckt
    private var schlitz: some View {
        Capsule().fill(Color.black.opacity(0.28)).frame(height: 5).padding(.horizontal, 14).padding(.top, 2)
            .accessibilityHidden(true)
    }

    private func herausziehen() {
        guard !draussen else { return }
        kommt = true
        zug = 0
        gezogen = Self.merken(gezogen, woche: schluessel)
    }

    // MARK: Merken (je Schlüssel, höchstens 26)

    nonisolated static func istAbgerissen(_ liste: String, woche: String) -> Bool {
        liste.split(separator: ",").contains { $0 == woche }
    }

    nonisolated static func merken(_ liste: String, woche: String) -> String {
        var l = liste.split(separator: ",").map(String.init).filter { $0 != woche }
        l.append(woche)
        return l.suffix(26).joined(separator: ",")
    }
}

/// Gerade Linie (waagerecht oder senkrecht) für die gestrichelte Perforation.
struct Line: Shape {
    var senkrecht = false
    func path(in r: CGRect) -> Path {
        Path { p in
            if senkrecht { p.move(to: CGPoint(x: r.midX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)) }
            else { p.move(to: CGPoint(x: r.minX, y: r.midY)); p.addLine(to: CGPoint(x: r.maxX, y: r.midY)) }
        }
    }
}
