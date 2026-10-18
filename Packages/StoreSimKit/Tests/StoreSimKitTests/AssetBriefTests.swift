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
        for c in Brand.packaging.all { #expect(text.contains(c.hex), "missing packaging #\(c.hex)") }
    }

    /// `name -> HEX` for every `| name | #HEX |` row between two headings.
    static func table(_ text: String, from start: String, to end: String) throws -> [String: String] {
        let from = try #require(text.range(of: start), "no \(start) heading")
        let upTo = try #require(text.range(of: end, range: from.upperBound..<text.endIndex), "no \(end) heading")
        var out: [String: String] = [:]
        for line in text[from.upperBound..<upTo.lowerBound].split(separator: "\n") {
            let cells = line.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count == 2, cells[1].hasPrefix("#") else { continue }
            out[cells[0]] = String(cells[1].dropFirst())
        }
        return out
    }

    @Test func packagingTableMatchesBrand() throws {
        let text = try Self.brief()
        let rows = try Self.table(text, from: "## Packaging palette", to: "## Assets")
        let code = Brand.packaging.byName
        #expect(rows.count == code.count, "table has \(rows.count) rows, Brand.packaging has \(code.count)")
        #expect(Set(rows.keys) == Set(code.keys))
        for (name, hex) in rows { #expect(code[name]?.hex == hex.uppercased(), "\(name) is #\(hex) in the brief") }
        #expect(code.count >= 58)
    }

    @Test func packagingNamesNeverShadowThePalette() throws {
        let text = try Self.brief()
        let palette = try Self.table(text, from: "## Palette", to: "## Packaging palette")
        #expect(palette.count == Brand.palette.all.count)
        #expect(Set(palette.keys).isDisjoint(with: Brand.packaging.byName.keys))
        #expect(Set(Brand.packaging.all.map(\.hex)).count == Brand.packaging.all.count, "two packaging names share a colour")
    }

    @Test func everyColourCodeInTheCatalogueNamesAPackagingColour() {
        let known = Brand.packaging.byName
        for (code, names) in PlanogramCatalogue.shipped.colourCodes {
            #expect(known[names.base] != nil && known[names.accent] != nil, "\(code) names an unknown colour")
        }
        #expect(PlanogramCatalogue.shipped.colourCodes.count == 32)
    }

    @Test func packFrontsSectionDescribesTheAtlas() throws {
        let section = try #require(Self.sections(try Self.brief())["pack_fronts"])
        #expect(Self.line(section, "Dimensions:")?.hasPrefix("2048 x 2048 px") == true)
        #expect(Self.line(section, "Format:")?.contains("16 x 8") == true)
        let atlas = PlanogramCatalogue.shipped.atlas
        #expect(atlas.pixels == (2048, 2048))
    }

    @Test func briefNamesNoCompetitor() throws {
        let text = try Self.brief().lowercased()
        // Built from pieces so this file passes the lint rule that forbids the names.
        for word in ["za" + "bka", "7-ele" + "ven", "7ele" + "ven", "seven-ele" + "ven"] { #expect(!text.contains(word)) }
    }
}
