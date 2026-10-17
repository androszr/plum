import Foundation
import Testing
@testable import StoreSimKit

/// A file URL for a dropped model; the extension is added separately.
func modelURL(_ base: String, ext: String = "usdz", dir: String = "/m") -> URL {
    URL(fileURLWithPath: dir).appendingPathComponent(base).appendingPathExtension(ext)
}

@Suite struct AssetCatalogueTests {
    @Test func presentNameResolvesToModel() {
        let url = modelURL("gondola_shelf", dir: "/models")
        #expect(AssetCatalogue(modelURLs: [url]).resolve(.gondolaShelf) == .model(url))
    }

    @Test func absentNameIsProcedural() {
        #expect(AssetCatalogue.empty.resolve(.tree) == .procedural)
    }

    @Test func nonUsdzAndUnknownNamesAreIgnored() {
        let urls = [modelURL("wall_fridge", ext: "usd"), modelURL("wall_fridge", ext: "png"), modelURL("mystery_thing")]
        let cat = AssetCatalogue(modelURLs: urls)
        for name in AssetName.allCases { #expect(cat.resolve(name) == .procedural) }
    }

    @Test func matchingIsCaseExact() {
        let cat = AssetCatalogue(modelURLs: [modelURL("Gondola_Shelf")])
        #expect(cat.resolve(.gondolaShelf) == .procedural)
    }

    @Test func signagePngResolvesToTexture() {
        let url = modelURL("storefront_sign", ext: "png")
        #expect(AssetCatalogue(modelURLs: [url]).resolve(.storefrontSign) == .texture(url))
    }

    @Test func priceStripPngResolvesToTexture() {
        let url = modelURL("price_strip", ext: "png")
        #expect(AssetCatalogue(modelURLs: [url]).resolve(.priceStrip) == .texture(url))
    }

    @Test func fixturePngIsIgnored() {
        let url = modelURL("gondola_shelf", ext: "png")
        #expect(AssetCatalogue(modelURLs: [url]).resolve(.gondolaShelf) == .procedural)
    }

    @Test func signageUsdzIsIgnored() {
        let url = modelURL("price_strip")
        #expect(AssetCatalogue(modelURLs: [url]).resolve(.priceStrip) == .procedural)
    }

    @Test func fixtureAndSignageNamesPartitionTheCatalogue() {
        let fixtures = AssetName.fixtureNames
        let signage = AssetName.signageNames
        #expect(fixtures.union(signage) == Set(AssetName.allCases))
        #expect(fixtures.isDisjoint(with: signage))
    }

    @Test func everyFixtureKindHasAnAsset() {
        let names = Set(AssetName.allCases)
        for kind in FixtureKind.allCases { #expect(names.contains(kind.assetName)) }
        #expect(Set(FixtureKind.allCases.map { $0.assetName.rawValue }).count == FixtureKind.allCases.count)
    }
}
