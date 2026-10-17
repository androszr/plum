import Foundation
import Testing
@testable import StoreSimKit

@Suite struct ModelVariantTests {
    static let layout = StoreLayout.plumCorner

    static func variant(_ id: String) -> Int {
        ModelVariant.index(of: layout.fixtures.first { $0.id == id }!, in: layout)
    }

    @Test func threePostersGetThreeDifferentPanels() {
        let posters = Self.layout.fixtures.filter { $0.kind == .windowPoster }
        #expect(Set(posters.map { ModelVariant.index(of: $0, in: Self.layout) }) == [0, 1, 2])
    }

    @Test func gondolaRunCountsUp() {
        #expect(Self.variant("gondola_a1") == 0)
        #expect(Self.variant("gondola_a2") == 1)
        #expect(Self.variant("gondola_a3") == 2)
        #expect(Self.variant("gondola_b1") == 0)
    }

    @Test func singleVariantKindsAreZero() {
        for f in Self.layout.fixtures where ModelVariant.count(for: f.kind) == 1 {
            #expect(ModelVariant.index(of: f, in: Self.layout) == 0, "\(f.id)")
        }
    }

    @Test func absentFixtureIsZero() {
        let ghost = Fixture(id: "ghost", kind: .windowPoster, cell: GridCell(x: 0, z: 0))
        #expect(ModelVariant.index(of: ghost, in: Self.layout) == 0)
    }

    @Test func colourWindowsDiffer() {
        let all = ProductRows.colours()
        let windows = (0..<3).map { ModelVariant.productColours($0) }
        for w in windows {
            #expect(w.count == 7)
            #expect(w.allSatisfy { all.contains($0) })
        }
        #expect(Set(windows[0]) != Set(windows[1]))
        #expect(Set(windows[1]) != Set(windows[2]))
        #expect(Set(windows[0]) != Set(windows[2]))
    }

    @Test func productColourIsDeterministic() {
        #expect(ModelVariant.productColour(variant: 1, shelf: 2, facing: 3) == ModelVariant.productColour(variant: 1, shelf: 2, facing: 3))
        #expect(ModelVariant.productColour(variant: 0, shelf: 0, facing: 0) != ModelVariant.productColour(variant: 1, shelf: 0, facing: 0))
    }

    @Test func headlinesMatchTheBrief() {
        #expect(ModelVariant.posterHeadlines == ["Hot coffee?", "Hungry?", "Open 6-23"])
        #expect(Set(ModelVariant.posterTints).count == 3)
    }

    @Test func parserSkipsNonProductParts() {
        let shelving = ModelVariant.productPartStems(for: .gondolaShelf)
        let a = ModelVariant.parseProductPart("product_2_5", stems: shelving)
        #expect(a?.shelf == 2 && a?.facing == 5)
        let b = ModelVariant.parseProductPart("product_back_1_0", stems: shelving)
        #expect(b?.shelf == 1 && b?.facing == 0)
        #expect(ModelVariant.parseProductPart("product_0_3_neck", stems: shelving) == nil)
        #expect(ModelVariant.parseProductPart("upright_left", stems: shelving) == nil)
        #expect(ModelVariant.parseProductPart("bottle_1_2", stems: shelving) == nil)
    }
}
