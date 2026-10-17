import Foundation
import RealityKit
import Testing
import StoreSimKit
@testable import StoreSimRender

@MainActor
@Suite struct EntityBuilderTests {
    static let layout = StoreLayout.plumCorner

    static func root(catalogue: AssetCatalogue = .empty) -> Entity {
        let node = SceneComposer.compose(layout: layout, detail: .reduced, catalogue: catalogue)
        return EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
    }

    @Test func everyFixtureHasAnEntity() {
        let root = Self.root()
        for f in Self.layout.fixtures {
            #expect(root.findEntity(named: f.id) != nil, "missing \(f.id)")
        }
    }

    @Test func selectableEntitiesCarryCollisionAndInputTarget() {
        let root = Self.root()
        for f in Self.layout.fixtures {
            guard let e = root.findEntity(named: f.id) else { continue }
            #expect(e.components[CollisionComponent.self] != nil, "\(f.id) has no collision")
            #expect(e.components[InputTargetComponent.self] != nil)
            #expect(e.components[SelectableComponent.self]?.displayName.isEmpty == false)
        }
    }

    @Test func roofFadesButNeverBlocksClicks() {
        let roof = Self.root().findEntity(named: "store_roof")
        #expect(roof?.components[OpacityComponent.self] != nil)
        #expect(roof?.components[CollisionComponent.self] == nil)
        #expect(roof?.components[InputTargetComponent.self] == nil)
    }

    @Test func missingModelFallsBackToTheCodeShape() {
        // The catalogue says a model exists, but the file is not there: the loader throws.
        let cat = AssetCatalogue(modelURLs: [URL(fileURLWithPath: "/nonexistent").appendingPathComponent("gondola_shelf").appendingPathExtension("usdz")])
        let root = Self.root(catalogue: cat)
        let g = root.findEntity(named: "gondola_a1")
        #expect(g != nil)
        #expect(g?.findEntity(named: "upright_left") != nil)
    }

    @Test func nameTagSitsAboveTheBoundsAndFacesTheCamera() {
        let tag = NameTagEntity()
        let bounds = BoundingBox(min: SIMD3(0, 0, 0), max: SIMD3(2, 1.5, 2))
        tag.show(over: bounds, text: "Shelf", cameraYaw: .pi / 2)
        #expect(tag.isEnabled)
        #expect(tag.position.y > 1.5)
        #expect(abs(tag.position.x - 1) < 1e-5 && abs(tag.position.z - 1) < 1e-5)
        let forward = tag.orientation.act(SIMD3<Float>(0, 0, 1))
        #expect(abs(forward.x - 1) < 1e-4)
        tag.hide()
        #expect(!tag.isEnabled)
    }

    @Test func opaqueShellTakesClicksWithoutBeingSelectable() {
        let root = Self.root()
        for name in ["store_wall_back", "store_wall_left", "store_wall_right", "facade", "neighbour_left", "neighbour_right"] {
            let e = root.findEntity(named: name)
            #expect(e?.components[CollisionComponent.self] != nil, "\(name) has no collision")
            #expect(e?.components[InputTargetComponent.self] != nil)
            #expect(e?.components[SelectableComponent.self] == nil, "\(name) must not be selectable")
        }
    }

    @Test func nameTagBuildsMeshesOnlyWhenTheTextChanges() {
        let tag = NameTagEntity()
        let bounds = BoundingBox(min: .zero, max: SIMD3(1, 1, 1))
        tag.show(over: bounds, text: "Shelf", cameraYaw: 0)
        tag.show(over: bounds, text: "Shelf", cameraYaw: 1)
        tag.show(over: bounds, text: "Shelf", cameraYaw: 2)
        #expect(tag.meshBuilds == 1)
        tag.show(over: bounds, text: "Fridge", cameraYaw: 2)
        #expect(tag.meshBuilds == 2)
    }

    @Test func missingPosterModelFallsBackWithItsVariant() {
        let cat = AssetCatalogue(modelURLs: [URL(fileURLWithPath: "/nonexistent").appendingPathComponent("window_poster").appendingPathExtension("usdz")])
        let root = Self.root(catalogue: cat)
        var tints: [SimpleMaterial.Color] = []
        for i in 1...3 {
            let poster = root.findEntity(named: "window_poster_\(i)")?.findEntity(named: "poster") as? ModelEntity
            #expect(poster != nil)
            if let m = poster?.model?.materials.first as? SimpleMaterial { tints.append(m.color.tint) }
        }
        #expect(tints.count == 3)
        #expect(Set(tints.map { "\($0)" }).count == 3)
    }
}
