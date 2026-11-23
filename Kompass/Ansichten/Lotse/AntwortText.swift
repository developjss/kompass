import SwiftUI

/// Antwort des Assistenten mit einfachem Markdown: Absätze (Leerzeile), Listen („- “, „• “, „1. “), **fett**, *kursiv*.
/// Überschriften (#) werden zu fettem Text. Nur SwiftUI – keine Abhängigkeit.
struct AntwortText: View {
    var text: String
    var farbe: Color = Farbe.text

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(AntwortText.bloecke(text).enumerated()), id: \.offset) { _, b in
                switch b {
                case .absatz(let t):
                    Text(AntwortText.inline(t)).fixedSize(horizontal: false, vertical: true)
                case .punkt(let zeichen, let t):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(zeichen).monospacedDigit().foregroundStyle(Farbe.akzent).fontWeight(.bold)
                        Text(AntwortText.inline(t)).fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 2)
                }
            }
        }
        .foregroundStyle(farbe)
    }

    nonisolated enum Block: Equatable, Sendable {
        case absatz(String)
        case punkt(String, String)
    }

    /// Zerlegt den Text in Absätze und Listenpunkte (getrennt testbar).
    nonisolated static func bloecke(_ text: String) -> [Block] {
        var out: [Block] = []
        var absatz: [String] = []
        func abschliessen() {
            if !absatz.isEmpty { out.append(.absatz(absatz.joined(separator: "\n"))); absatz = [] }
        }
        for roh in text.components(separatedBy: "\n") {
            let z = roh.trimmingCharacters(in: .whitespaces)
            if z.isEmpty { abschliessen(); continue }
            if let r = z.range(of: #"^[-•*]\s+"#, options: .regularExpression) {
                abschliessen(); out.append(.punkt("•", String(z[r.upperBound...])))
            } else if let r = z.range(of: #"^\d{1,2}[.)]\s+"#, options: .regularExpression) {
                abschliessen()
                let nummer = z[..<r.upperBound].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ")", with: ".")
                out.append(.punkt(nummer, String(z[r.upperBound...])))
            } else if z.hasPrefix("#") {
                abschliessen(); out.append(.absatz("**" + z.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces) + "**"))
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
        t.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "__", with: "")
    }
}
