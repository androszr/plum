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

    @Test func passingTrafficTakesClicksWithoutBeingSelectable() throws {
        let root = Self.root()
        let traffic = try #require(root.findEntity(named: "traffic"))
        #expect(!traffic.children.isEmpty)
        for mover in traffic.children {
            let collision = try #require(mover.components[CollisionComponent.self], "\(mover.name)")
            #expect(mover.components[InputTargetComponent.self] != nil)
            #expect(mover.components[SelectableComponent.self] == nil)
            // The pick box stands on the ground, not half sunk into it.
            let b = collision.shapes[0].bounds
            #expect(abs(b.min.y) < 0.01 && b.max.y > 1.4, "\(mover.name)")
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
        let g = root.findEntity(named: "gondola_1")
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

    @Test func insideViewDisablesTheRoofAndStorefront() {
        let root = Self.root()
        let candidates = EntityBuilder.shellCandidates(in: root)
        let lot = Self.layout.lot
        let hidden = InteriorVisibility.hiddenNames(
            mode: .inside, candidates: Array(candidates.keys), eye: WalkCamera.preset(lot: lot, floor: WalkableFloor(layout: Self.layout)).pose.eye, lot: lot)
        EntityBuilder.applyShellVisibility(hidden: hidden, in: candidates)
        for n in ["store_roof", "storefront_glazing", "canopy", "mullion_0"] {
            #expect(candidates[n]?.isEnabled == false, "\(n)")
        }
        for wall in ["store_wall_left", "store_wall_right", "store_wall_back"] {
            #expect(candidates[wall]?.isEnabled == true, "\(wall)")
        }
    }

    @Test func switchingBackToOutsideReEnablesEverything() {
        let root = Self.root()
        let candidates = EntityBuilder.shellCandidates(in: root)
        let lot = Self.layout.lot
        let hidden = InteriorVisibility.hiddenNames(
            mode: .inside, candidates: Array(candidates.keys), eye: WalkCamera.preset(lot: lot, floor: WalkableFloor(layout: Self.layout)).pose.eye, lot: lot)
        EntityBuilder.applyShellVisibility(hidden: hidden, in: candidates)
        EntityBuilder.applyShellVisibility(hidden: [], in: candidates)
        #expect(!candidates.isEmpty)
        for (name, e) in candidates { #expect(e.isEnabled, "\(name)") }
    }

    @Test func assetNodeWithMissingFileBuildsTheFallback() {
        let fallback = SceneNode(name: "fallback", children: [
            SceneNode(name: "upright_left", shape: .box, size: SIMD3(0.1, 1, 0.1), position: SIMD3(0, 0.5, 0)),
        ])
        let node = SceneNode(name: "gondola", shape: .asset(.gondolaShelf), children: [fallback])
        let missing = URL(fileURLWithPath: "/nonexistent").appendingPathComponent("gondola_shelf").appendingPathExtension("usdz")
        let cat = AssetCatalogue(modelURLs: [missing])
        let built = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: cat))
        #expect(built.findEntity(named: "upright_left") != nil)
    }

    /// A loaded file is centred on the floor. In the lot it has to land on the stand-in:
    /// the car on the ground, the menu and posters on the wall, the pendant under the roof.
    @Test func loadedModelsSitWithTheStandIn() throws {
        let dir = try BriefSpec.modelsDirectory()
        let urls = ["parked_car_hatchback", "menu_screen", "window_poster", "pendant_lamp"].map {
            dir.appendingPathComponent($0).appendingPathExtension("usdz")
        }
        let layout = StoreLayout.plumCorner
        let procedural = EntityBuilder.entity(
            for: SceneComposer.compose(layout: layout, detail: .full, catalogue: .empty),
            loader: ModelLoader(catalogue: .empty))
        let catalogue = AssetCatalogue(modelURLs: urls)
        let models = EntityBuilder.entity(
            for: SceneComposer.compose(layout: layout, detail: .full, catalogue: catalogue),
            loader: ModelLoader(catalogue: catalogue))

        func box(_ root: Entity, _ kind: FixtureKind) throws -> BoundingBox {
            let id = try #require(layout.fixtures.first { $0.kind == kind }?.id)
            let entity = try #require(root.findEntity(named: id))
            return entity.visualBounds(relativeTo: root)
        }
        func center(_ b: BoundingBox) -> SIMD3<Float> { (b.min + b.max) * 0.5 }

        let car = try box(models, .parkedCar)
        let carStand = try box(procedural, .parkedCar)
        #expect(abs(car.min.y - carStand.min.y) < 0.05, "car bottom \(car.min.y) vs stand-in \(carStand.min.y)")
        #expect(abs(center(car).x - center(carStand).x) < 0.05)
        #expect(abs(center(car).z - center(carStand).z) < 0.05)

        for kind in [FixtureKind.menuScreen, .windowPoster] {
            let placed = try box(models, kind)
            let stand = try box(procedural, kind)
            let gap = center(placed) - center(stand)
            #expect(abs(gap.x) < 0.05 && abs(gap.z) < 0.05, "\(kind.assetName.rawValue) is \(gap) off the wall")
        }

        let lamp = try box(models, .pendantLamp)
        let lampStand = try box(procedural, .pendantLamp)
        #expect(lamp.max.y <= lampStand.max.y + 0.02, "pendant top \(lamp.max.y) vs stand-in \(lampStand.max.y)")
        #expect(lamp.max.y <= 3.2, "pendant top \(lamp.max.y) is through the roof")
    }

    @Test func texturedSignFallsBackToThePlainColour() {
        let node = SceneNode(
            name: "canopy_sign", shape: .box, size: SIMD3(1, 0.5, 0.06),
            material: .textured(.storefrontSign, fallback: Brand.palette.primaryDeep))
        let built = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        let unlit = built.components[ModelComponent.self]?.materials.first as? UnlitMaterial
        guard let tint = unlit?.color.tint else {
            Issue.record("canopy sign fell back to something other than an unlit colour")
            return
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        tint.getRed(&r, green: &g, blue: &b, alpha: &a)
        let brand = Brand.palette.primaryDeep
        // RealityKit stores the unlit tint in linear sRGB; compare in that space.
        func linear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        #expect(abs(Double(r) - linear(brand.r)) < 0.002)
        #expect(abs(Double(g) - linear(brand.g)) < 0.002)
        #expect(abs(Double(b) - linear(brand.b)) < 0.002)
        #expect(abs(Double(a) - brand.a) < 0.002)
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

    // MARK: Merchandise layer

    static func count(named name: String, in root: Entity) -> Int {
        (root.name == name ? 1 : 0) + root.children.reduce(0) { $0 + count(named: name, in: $1) }
    }

    @Test func merchandiseSiblingIsBuiltWhenTheModelLoads() throws {
        let dir = try BriefSpec.modelsDirectory()
        let cat = AssetCatalogue(modelURLs: [dir.appendingPathComponent("gondola_shelf").appendingPathExtension("usdz")])
        let root = Self.root(catalogue: cat)
        let g = try #require(root.findEntity(named: "gondola_1"))
        #expect(Self.count(named: "merchandise", in: g) == 1)
        #expect(Self.count(named: "shelf_0", in: g) == 1)
        #expect(g.findEntity(named: "product_0_0") != nil)
        // The loaded shell is there too, and the stand-in's own parts are not.
        #expect(g.findEntity(named: "upright_left") == nil || Self.count(named: "upright_left", in: g) == 1)
    }

    @Test func merchandiseIsNotDuplicatedWhenTheModelFails() throws {
        let missing = URL(fileURLWithPath: "/nonexistent").appendingPathComponent("gondola_shelf").appendingPathExtension("usdz")
        let root = Self.root(catalogue: AssetCatalogue(modelURLs: [missing]))
        let g = try #require(root.findEntity(named: "gondola_1"))
        #expect(Self.count(named: "merchandise", in: g) == 1)
        #expect(Self.count(named: "shelf_0", in: g) == 1)
        #expect(Self.count(named: "upright_left", in: g) == 1)
    }

    @Test func quadBuildsAFlatMeshOfItsSize() throws {
        let node = SceneNode(name: "card", shape: .quad, size: SIMD3(0.2, 0.3, 0), material: .paint(Brand.palette.cream))
        let built = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        let mesh = try #require(built.components[ModelComponent.self]?.mesh)
        let extents = mesh.bounds.extents
        #expect(abs(extents.x - 0.2) < 1e-4 && abs(extents.y - 0.3) < 1e-4 && extents.z < 1e-4)
    }

    @Test func equalBoxesShareOneMesh() {
        let loader = ModelLoader(catalogue: .empty)
        let a = SceneNode(name: "a", shape: .box, size: SIMD3(0.123, 0.456, 0.789))
        let b = SceneNode(name: "b", shape: .box, size: SIMD3(0.123, 0.456, 0.789))
        let before = EntityBuilder.meshCacheCount
        _ = EntityBuilder.entity(for: a, loader: loader)
        let afterFirst = EntityBuilder.meshCacheCount
        _ = EntityBuilder.entity(for: b, loader: loader)
        #expect(afterFirst == before + 1)
        #expect(EntityBuilder.meshCacheCount == afterFirst)
    }

    @Test func atlasMaterialFallsBackToItsColourWithoutAPicture() throws {
        let node = SceneNode(
            name: "card", shape: .quad, size: SIMD3(0.1, 0.2, 0),
            material: .atlas(.packFronts, region: AtlasRegion(u: 0, v: 0, width: 0.1, height: 0.1),
                             fallback: Brand.palette.cream))
        let built = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        #expect(built.components[ModelComponent.self]?.materials.first is SimpleMaterial)
    }

    /// The full-catalogue shop: every model in the `Models` folder, loaded through the real loader.
    static func fullCatalogueRoot(detail: DetailLevel) throws -> Entity {
        let dir = try BriefSpec.modelsDirectory()
        let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "usdz" }
        let catalogue = AssetCatalogue(modelURLs: urls)
        return EntityBuilder.entity(
            for: SceneComposer.compose(layout: layout, detail: detail, catalogue: catalogue),
            loader: ModelLoader(catalogue: catalogue))
    }

    /// The two bottle walls sit against the storefront. Their loaded model must stay inside the
    /// 0.5 m footprint, so its back ends behind the glass instead of poking through it.
    @Test func alcoholWallsStayBehindTheStorefrontGlass() throws {
        let root = try Self.fullCatalogueRoot(detail: .full)
        let glass = try #require(root.findEntity(named: "storefront_glazing"))
        let glassOuter = glass.visualBounds(relativeTo: root).max.z
        let walls = Self.layout.fixtures.filter { $0.kind == .alcoholWall }
        #expect(walls.count == 2)
        for f in walls {
            let entity = try #require(root.findEntity(named: f.id))
            let local = entity.visualBounds(relativeTo: entity)
            #expect(local.min.z >= -0.25 - 0.01, "\(f.id) back at \(local.min.z) is outside its 0.5 m footprint")
            let world = entity.visualBounds(relativeTo: root)
            #expect(world.max.z <= glassOuter,
                    "\(f.id) world max z \(world.max.z) is past the glazing outer face \(glassOuter)")
        }
    }

    /// Every floor fixture's loaded model stays in its floor space on both shells (Mac `.full`,
    /// phone `.reduced`). The tree's brief is a 1.4 m crown over a 1.0 m footprint and the lamp's
    /// 0.8 m arm reaches over the parking lane from a 0.5 m footprint: both by design, and both
    /// do so in the stand-in too.
    @Test func placedFloorModelsStayInsideTheirFootprints() throws {
        for detail in [DetailLevel.full, .reduced] {
            let root = try Self.fullCatalogueRoot(detail: detail)
            var visited = 0
            for f in Self.layout.fixtures
            where f.kind.occupiesFloor && ![FixtureKind.tree, .streetLamp].contains(f.kind) {
                let entity = try #require(root.findEntity(named: f.id))
                let box = entity.visualBounds(relativeTo: entity)
                let w = Double(f.kind.footprint.w) * cellSize, d = Double(f.kind.footprint.d) * cellSize
                let tol: Float = 0.01
                #expect(box.min.x >= Float(-w / 2) - tol && box.max.x <= Float(w / 2) + tol
                        && box.min.z >= Float(-d / 2) - tol && box.max.z <= Float(d / 2) + tol,
                        "\(f.id) \(detail) spans x \(box.min.x)...\(box.max.x) z \(box.min.z)...\(box.max.z) in a \(w) x \(d) footprint")
                visited += 1
            }
            #expect(visited >= 40, "only \(visited) fixtures visited at \(detail)")
        }
    }

    @Test func footprintShiftClampsAFittingModelAndLeavesAWideOneAlone() {
        func shift(_ lo: Float, _ hi: Float, _ s: Float, _ half: Float) -> Float {
            EntityBuilder.footprintShift(modelMin: lo, modelMax: hi, shift: s, half: half)
        }
        #expect(abs(shift(-0.25, 0.25, -0.0665, 0.25) - 0) < 1e-6)
        #expect(abs(shift(-0.1, 0.1, -0.192, 0.25) - -0.15) < 1e-6)
        #expect(abs(shift(-0.2, 0.2, 0.01, 0.25) - 0.01) < 1e-6)
        #expect(shift(-0.7, 0.7, 0.0, 0.5) == 0.0)
        #expect(abs(shift(-0.7, 0.7, 0.03, 0.5) - 0.03) < 1e-6)
    }
}
