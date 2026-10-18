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
        #expect(Self.variant("gondola_1") == 0)
        #expect(Self.variant("gondola_2") == 1)
        #expect(Self.variant("gondola_3") == 2)
        #expect(Self.variant("gondola_4") == 0)
    }

    @Test func singleVariantKindsAreZero() {
        for f in Self.layout.fixtures where ModelVariant.count(for: f.kind) == 1 {
            #expect(ModelVariant.index(of: f, in: Self.layout) == 0, "\(f.id)")
        }
    }

    @Test func threeCarsGetThreeModels() {
        let cars = Self.layout.fixtures.filter { $0.kind == .parkedCar }
        let indices = cars.map { ModelVariant.index(of: $0, in: Self.layout) }
        #expect(indices == [0, 1, 2])
        #expect(indices.map { ModelVariant.assetName(for: .parkedCar, variant: $0) }
                == [.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan])
    }

    @Test func parkedCarsCountUpThroughTheirModels() {
        #expect(["parked_car_1", "parked_car_2", "parked_car_3"].map { Self.variant($0) } == [0, 1, 2])
    }

    @Test func movingCarsContinueAfterTheParkedOnes() {
        let cars = Traffic.movers(for: Self.layout, detail: .full).filter { $0.kind == .car }
        let indices = cars.map { ModelVariant.index(of: $0, in: Self.layout) }
        #expect(Array(indices.prefix(4)) == [0, 1, 2, 0])
        #expect(cars.first?.ordinal == 0)
        for m in Traffic.movers(for: Self.layout, detail: .full) where m.kind == .pedestrian {
            #expect(ModelVariant.index(of: m, in: Self.layout) == 0)
        }
    }

    @Test func sixTreesAlternate() {
        let trees = Self.layout.fixtures.filter { $0.kind == .tree }
        let indices = trees.map { ModelVariant.index(of: $0, in: Self.layout) }
        #expect(indices == [0, 1, 0, 1, 0, 1])
        #expect(indices.map { ModelVariant.assetName(for: .tree, variant: $0) }
                == [.treeLinden, .treeMaple, .treeLinden, .treeMaple, .treeLinden, .treeMaple])
    }

    @Test func assetNameWrapsAndDefaults() {
        #expect(ModelVariant.assetName(for: .parkedCar, variant: 3) == .parkedCarHatchback)
        #expect(ModelVariant.assetName(for: .parkedCar, variant: -1) == .parkedCarVan)
        #expect(ModelVariant.assetName(for: .tree, variant: 5) == .treeMaple)
        #expect(ModelVariant.assetName(for: .streetLamp, variant: 7) == .streetLamp)
        #expect(ModelVariant.assetName(for: .windowPoster, variant: 2) == .windowPoster)
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
        let shelving = ModelVariant.productPartStems(for: .wallShelf)
        let a = ModelVariant.parseProductPart("product_2_5", stems: shelving)
        #expect(a?.shelf == 2 && a?.facing == 5 && a?.shape == nil)
        #expect(ModelVariant.parseProductPart("product_2_5_packet", stems: shelving)?.shape == .packet)
        #expect(ModelVariant.parseProductPart("product_back_1_0_can", stems: shelving)?.shape == .can)
        #expect(ModelVariant.parseProductPart("product_0_3_bottle_neck", stems: shelving) == nil)
        let b = ModelVariant.parseProductPart("product_back_1_0", stems: shelving)
        #expect(b?.shelf == 1 && b?.facing == 0)
        #expect(ModelVariant.parseProductPart("product_0_3_neck", stems: shelving) == nil)
        #expect(ModelVariant.parseProductPart("upright_left", stems: shelving) == nil)
        #expect(ModelVariant.parseProductPart("bottle_1_2", stems: shelving) == nil)
    }

    @Test func gondolaAndFridgeStemsAreEmpty() {
        // Their goods are drawn by the merchandiser from the planogram, never recoloured per copy.
        #expect(ModelVariant.productPartStems(for: .gondolaShelf).isEmpty)
        #expect(ModelVariant.productPartStems(for: .wallFridge).isEmpty)
        #expect(!ModelVariant.productPartStems(for: .wallShelf).isEmpty)
        #expect(!ModelVariant.productPartStems(for: .endCap).isEmpty)
        #expect(!ModelVariant.productPartStems(for: .dairyChiller).isEmpty)
    }

    @Test func visibleShapeWalksTheRow() {
        // (shelf, facing, variant)
        func shape(_ shelf: Int, _ facing: Int, _ variant: Int) -> ProductShape {
            ModelVariant.visibleShape(variant: variant, shelf: shelf, facing: facing)
        }
        #expect(shape(0, 0, 0) == .packet)
        #expect(shape(0, 0, 1) == .can)
        #expect(shape(0, 0, 2) == .bottle)
        #expect(shape(1, 0, 0) == .can)
        #expect(shape(2, 0, 0) == .bottle)
        #expect(shape(3, 0, 0) == .packet)
        #expect(shape(-1, 0, 0) == .bottle)
        #expect(shape(0, 1, 0) == .can)
        #expect(shape(1, 1, 1) == .packet)
    }
}
