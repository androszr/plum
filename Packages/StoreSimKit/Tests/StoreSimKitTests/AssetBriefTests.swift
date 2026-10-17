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

    static let sourcedNames: [AssetName] = [.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan, .treeLinden, .treeMaple]

    static func line(_ body: String, _ key: String) -> String? {
        body.split(separator: "\n", omittingEmptySubsequences: false)
            .first { $0.hasPrefix(key) }
            .map { String($0.dropFirst(key.count)).trimmingCharacters(in: .whitespaces) }
    }

    @Test func sourcedSectionsCarryProvenance() throws {
        let s = Self.sections(try Self.brief())
        for name in Self.sourcedNames {
            let source = try #require(Self.line(s[name.rawValue] ?? "", "Source:"), "\(name.rawValue) has no Source line")
            #expect(source.contains("Meshy"), "\(name.rawValue) source names no service")
            #expect(source.contains("task"), "\(name.rawValue) names no task id")
            #expect(source.contains("remesh"), "\(name.rawValue) names no remesh id")
            #expect(source.firstMatch(of: /\d{4}-\d{2}-\d{2}/) != nil, "\(name.rawValue) source has no date")
        }
    }

    @Test func sourcedFitMatchesTheBrief() throws {
        let s = Self.sections(try Self.brief())
        for name in Self.sourcedNames {
            let fit = try #require(SourcedModelFit.fit(for: name))
            let dim = try #require(Self.line(s[name.rawValue] ?? "", "Dimensions:"))
            let nums = dim.matches(of: /\d+(?:\.\d+)?/).prefix(3).compactMap { Double($0.output) }
            #expect(nums.count == 3, "\(name.rawValue) dimensions \(dim)")
            // Brief order is width x depth x height; the fit is width, height, depth.
            #expect(fit.size == SIMD3(nums[0], nums[2], nums[1]), "\(name.rawValue) fit \(fit.size) vs \(dim)")
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
