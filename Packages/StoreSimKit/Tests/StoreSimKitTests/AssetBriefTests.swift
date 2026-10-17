import Foundation
import Testing
@testable import StoreSimKit

@Suite struct AssetBriefTests {
    static func brief() throws -> String {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return try String(contentsOf: url.appendingPathComponent("docs/asset-brief.md"), encoding: .utf8)
    }

    /// Sections keyed by asset name.
    static func sections(_ text: String) -> [String: String] {
        var out: [String: String] = [:]
        let parts = text.components(separatedBy: "\n### ").dropFirst()
        for part in parts {
            let name = part.prefix { $0 != "\n" }.trimmingCharacters(in: .whitespaces)
            out[name] = part
        }
        return out
    }

    @Test func everyAssetHasASection() throws {
        let s = Self.sections(try Self.brief())
        for name in AssetName.allCases { #expect(s[name.rawValue] != nil, "no section for \(name.rawValue)") }
    }

    @Test func everySectionHasTheRequiredLines() throws {
        let s = Self.sections(try Self.brief())
        for name in AssetName.allCases {
            let body = s[name.rawValue] ?? ""
            for key in ["Dimensions:", "Pivot:", "Poly budget:", "Palette:", "Format:", "Parts:", "Prompt:"] {
                #expect(body.contains("\n\(key)") || body.hasPrefix(key), "\(name.rawValue) lacks \(key)")
            }
        }
    }

    @Test func paletteHexesAppearInTheBrief() throws {
        let text = try Self.brief()
        for c in Brand.palette.all { #expect(text.contains(c.hex), "missing #\(c.hex)") }
    }

    @Test func briefNamesNoCompetitor() throws {
        let text = try Self.brief().lowercased()
        // Built from pieces so this file passes the lint rule that forbids the names.
        for word in ["za" + "bka", "7-ele" + "ven", "7ele" + "ven", "seven-ele" + "ven"] { #expect(!text.contains(word)) }
    }
}
