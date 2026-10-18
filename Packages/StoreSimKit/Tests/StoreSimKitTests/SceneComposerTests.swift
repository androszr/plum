import Foundation
import Testing
@testable import StoreSimKit

@Suite struct SceneComposerTests {
    static let layout = StoreLayout.plumCorner

    @Test func everyFixtureAppearsByNameAndIsSelectable() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let fixtures = root.node(named: "fixtures")!
        for f in Self.layout.fixtures {
            let n = fixtures.children.first { $0.name == f.id }
            #expect(n != nil, "missing \(f.id)")
            #expect(n?.selectable == true)
            #expect(n?.displayName?.isEmpty == false)
            #expect(n?.bounds != nil)
        }
        #expect(fixtures.children.count == Self.layout.fixtures.count)
    }

    @Test func roofAndShellArePresentButNotSelectable() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let roof = root.node(named: "store_roof")
        #expect(roof != nil)
        #expect(roof?.selectable == false)
        for name in ["store_floor", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text", "facade",
                     "ground", "sidewalk", "road", "kerb", "far_sidewalk"] {
            #expect(root.node(named: name) != nil, "missing \(name)")
        }
    }

    @Test func lightingHasSunFillLampsAndSignGlow() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        for name in ["sun", "sky_fill", "sign_glow"] { #expect(root.node(named: name) != nil) }
        for f in Self.layout.fixtures where f.kind == .pendantLamp {
            #expect(root.node(named: "lamp_\(f.id)_light") != nil)
        }
    }

    @Test func emptyCatalogueProducesNoAssetShapes() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let anyAsset = root.allNodes().contains { if case .asset = $0.shape { true } else { false } }
        #expect(!anyAsset)
    }

    @Test func droppedModelTakesOverAndKeepsFallback() {
        let cat = AssetCatalogue(modelURLs: [modelURL("gondola_shelf")])
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: cat)
        let gondolas = root.node(named: "fixtures")!.children.filter { $0.name.hasPrefix("gondola_") }
        #expect(!gondolas.isEmpty)
        for g in gondolas {
            guard case let .asset(name) = g.shape else { Issue.record("\(g.name) not an asset"); continue }
            #expect(name == .gondolaShelf)
            #expect(g.children.first?.name == "fallback")
        }
        // Other kinds stay procedural.
        let fridge = root.node(named: "wall_fridge_1")!
        if case .asset = fridge.shape { Issue.record("fridge should stay procedural") }
    }

    @Test func reducedDetailHasFewerNodes() {
        let full = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty).allNodes().count
        let reduced = SceneComposer.compose(layout: Self.layout, detail: .reduced, catalogue: .empty).allNodes().count
        #expect(reduced < full)
    }

    @Test func fixturesLandWhereTheGridSaysAndTurnWithTheirRotation() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let f = Self.layout.fixtures.first { $0.id == "back_room_door_1" }!
        let n = root.node(named: f.id)!
        let c = f.occupiedRect.centreMetres
        #expect(n.position.x == c.x && n.position.z == c.y)
        #expect(abs(n.yaw - .pi / 2) < 1e-9)
    }

    @Test func trafficGroupHoldsEveryMoverUnselectableAtItsStartPose() throws {
        for detail in [DetailLevel.full, .reduced] {
            let root = SceneComposer.compose(layout: Self.layout, detail: detail, catalogue: .empty)
            let traffic = try #require(root.node(named: "traffic"))
            let movers = Traffic.movers(for: Self.layout, detail: detail)
            #expect(traffic.children.count == movers.count)
            for (node, mover) in zip(traffic.children, movers) {
                let start = Traffic.pose(of: mover, at: 0)
                #expect(node.name == mover.id)
                #expect(!node.selectable)
                // Takes the click so nothing behind it is picked, without being selectable itself.
                #expect(node.blocksPicking)
                let box = try #require(node.bounds)
                #expect(box.size.y > 1.4 && box.center.y == box.size.y / 2)
                #expect(node.mover == mover)
                #expect(node.position == start.position)
                #expect(node.yaw == start.yaw)
            }
        }
    }

    @Test func carMoverUsesTheParkedCarModelAndKeepsItsFallback() throws {
        let urls = [AssetName.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan].map { modelURL($0.rawValue) }
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: AssetCatalogue(modelURLs: urls))
        let cars = try #require(root.node(named: "traffic")).children.filter { $0.mover?.kind == .car }
        #expect(!cars.isEmpty)
        for car in cars {
            guard case let .asset(name) = car.shape else { Issue.record("\(car.name) is not an asset"); continue }
            #expect(name == car.mover?.asset)
            #expect(car.children.first?.name == "fallback")
        }
    }

    @Test func walkerStandInIsProceduralWhenNoCharacterFileExists() throws {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let walkers = try #require(root.node(named: "traffic")).children.filter { $0.mover?.kind == .pedestrian }
        #expect(!walkers.isEmpty)
        for w in walkers {
            if case .asset = w.shape { Issue.record("\(w.name) is an asset without a file") }
            #expect(w.node(named: "torso") != nil)
        }
        let cat = AssetCatalogue(modelURLs: AssetName.characterNames.map { modelURL($0.rawValue) })
        let withFiles = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: cat)
        for w in try #require(withFiles.node(named: "traffic")).children where w.mover?.kind == .pedestrian {
            guard case .asset = w.shape else { Issue.record("\(w.name) ignored its file"); continue }
            #expect(w.children.first?.name == "fallback")
        }
    }

    @Test func nodeNamesDoNotClashWithFixtureIds() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let ids = Set(Self.layout.fixtures.map(\.id))
        let clashes = root.allNodes().filter { ids.contains($0.name) }
        #expect(clashes.count == ids.count)
    }

    @Test func everyNodeCarriesAVariantInRange() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        for f in Self.layout.fixtures {
            let n = root.node(named: f.id)!
            #expect(n.variant >= 0 && n.variant < ModelVariant.count(for: f.kind), "\(f.id) variant \(n.variant)")
        }
    }

    @Test func threePostersCarryThreeDistinctVariants() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let variants = (1...3).map { root.node(named: "window_poster_\($0)")!.variant }
        #expect(Set(variants).count == 3)
    }

    @Test func assetWrapperKeepsVariantAndFallbackUsesIt() {
        let cat = AssetCatalogue(modelURLs: [modelURL("window_poster")])
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: cat)
        for i in 1...3 {
            let n = root.node(named: "window_poster_\(i)")!
            guard case .asset = n.shape else { Issue.record("not an asset"); continue }
            let poster = n.children.first { $0.name == "fallback" }!.node(named: "poster")!
            guard case let .solid(c, _) = poster.material else { Issue.record("no solid"); continue }
            #expect(c == ModelVariant.posterTints[n.variant])
        }
    }
}
