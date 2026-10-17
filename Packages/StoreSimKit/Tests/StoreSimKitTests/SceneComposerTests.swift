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
        let f = Self.layout.fixtures.first { $0.id == "wall_shelf_1" }!
        let n = root.node(named: f.id)!
        let c = f.occupiedRect.centreMetres
        #expect(n.position.x == c.x && n.position.z == c.y)
        #expect(abs(n.yaw - .pi / 2) < 1e-9)
    }

    @Test func nodeNamesDoNotClashWithFixtureIds() {
        let root = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let ids = Set(Self.layout.fixtures.map(\.id))
        let clashes = root.allNodes().filter { ids.contains($0.name) }
        #expect(clashes.count == ids.count)
    }
}
