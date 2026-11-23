// Gibt den Text jeder PDF-Seite als JSON aus (für pruefen.py). Aufruf: swift seiten.swift datei.pdf
import PDFKit
import Foundation
let doc = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
var pages: [String] = []
for i in 0..<doc.pageCount { pages.append(doc.page(at: i)?.string ?? "") }
print(String(data: try! JSONSerialization.data(withJSONObject: pages), encoding: .utf8)!)
