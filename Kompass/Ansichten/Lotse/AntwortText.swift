import SwiftUI

/// Antwort des Assistenten mit einfachem Markdown – angelehnt an ChatGPT/Gemini:
/// Überschriften (#), Absätze (Leerzeile), Listen („- “, „• “, „1. “, eingerückt = Unterpunkt), Trennlinie (---),
/// **fett**, *kursiv*, [Links](url). Nur SwiftUI – keine Abhängigkeit.
struct AntwortText: View {
    var text: String
    var farbe: Color = Farbe.text

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(AntwortText.bloecke(text).enumerated()), id: \.offset) { i, b in
                switch b {
                case .absatz(let t):
                    Text(AntwortText.inline(t)).fixedSize(horizontal: false, vertical: true)
                case .ueberschrift(let t):
                    Text(AntwortText.inline(t)).font(.kompass(.headline, .heavy))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, i == 0 ? 0 : 6)
                        .accessibilityAddTraits(.isHeader)
                case .punkt(let zeichen, let t, let ebene):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(ebene > 0 ? "◦" : zeichen).monospacedDigit().foregroundStyle(Farbe.akzent).fontWeight(.bold)
                        Text(AntwortText.inline(t)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 2 + CGFloat(ebene) * 18)
                case .trenner:
                    Rectangle().fill(Farbe.linie).frame(height: 1).padding(.vertical, 4)
                }
            }
        }
        .foregroundStyle(farbe)
        .tint(Farbe.akzent)
    }

    nonisolated enum Block: Equatable, Sendable {
        case absatz(String)
        case ueberschrift(String)
        /// Zeichen („•“ oder „1.“), Text, Ebene (0 = oben, 1 = eingerückt)
        case punkt(String, String, Int)
        case trenner
    }

    /// Zerlegt den Text in Blöcke (getrennt testbar).
    nonisolated static func bloecke(_ text: String) -> [Block] {
        var out: [Block] = []
        var absatz: [String] = []
        func abschliessen() {
            if !absatz.isEmpty { out.append(.absatz(absatz.joined(separator: "\n"))); absatz = [] }
        }
        for roh in text.components(separatedBy: "\n") {
            let z = roh.trimmingCharacters(in: .whitespaces)
            let einzug = roh.prefix { $0 == " " || $0 == "\t" }.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
            let ebene = einzug >= 2 ? 1 : 0
            if z.isEmpty { abschliessen(); continue }
            if z.range(of: #"^(-{3,}|\*{3,}|_{3,})$"#, options: .regularExpression) != nil {
                abschliessen(); out.append(.trenner)
            } else if let r = z.range(of: #"^[-•*◦]\s+"#, options: .regularExpression) {
                abschliessen(); out.append(.punkt("•", String(z[r.upperBound...]), ebene))
            } else if let r = z.range(of: #"^\d{1,2}[.)]\s+"#, options: .regularExpression) {
                abschliessen()
                let nummer = z[..<r.upperBound].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ")", with: ".")
                out.append(.punkt(nummer, String(z[r.upperBound...]), ebene))
            } else if z.hasPrefix("#") {
                abschliessen(); out.append(.ueberschrift(z.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)))
            } else {
                absatz.append(z)
            }
        }
        abschliessen()
        return out
    }

    nonisolated static func inline(_ t: String) -> AttributedString {
        (try? AttributedString(markdown: t, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(t)
    }

    /// Für VoiceOver: ohne Markdown-Zeichen.
    nonisolated static func ohneZeichen(_ t: String) -> String {
        t.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "").replacingOccurrences(of: "#", with: "")
    }
}
