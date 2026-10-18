import Foundation
import RealityKit
import Testing
import StoreSimKit
@testable import StoreSimRender

@MainActor
@Suite struct TrafficDriverTests {
    static let layout = StoreLayout.plumCorner

    /// The catalogue of the shipped `Characters/` folder.
    static func characterCatalogue() throws -> AssetCatalogue {
        let urls = try FileManager.default.contentsOfDirectory(
            at: BriefSpec.charactersDirectory(), includingPropertiesForKeys: nil)
        return AssetCatalogue(modelURLs: urls)
    }

    static func entity(for mover: Mover) -> Entity {
        let node = SceneNode(name: mover.id, mover: mover)
        return EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
    }

    @Test func placeMovesAnEntityToThePoseForTheTime() throws {
        TrafficDriver.register()
        TrafficDriver.register()
        let mover = try #require(Traffic.movers(for: Self.layout, detail: .full).first)
        let entity = Self.entity(for: mover)
        for t in [0.0, 3.0] {
            TrafficDriver.place(entity, at: t)
            let pose = Traffic.pose(of: mover, at: t)
            #expect(entity.position == SIMD3<Float>(pose.position))
            let expected = simd_quatf(angle: Float(pose.yaw), axis: SIMD3(0, 1, 0))
            #expect(abs(simd_dot(entity.orientation, expected)) > 0.9999)
        }
        #expect(Traffic.pose(of: mover, at: 0).position != Traffic.pose(of: mover, at: 3).position)
    }

    @Test func placeInRootTouchesOnlyMoverEntities() throws {
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        let fixtures = Self.layout.fixtures.compactMap { root.findEntity(named: $0.id) }
        let before = fixtures.map { $0.transform.matrix }
        let ground = root.findEntity(named: "ground")
        let groundBefore = ground?.transform.matrix
        TrafficDriver.place(in: root, at: 5)
        #expect(fixtures.map { $0.transform.matrix } == before)
        #expect(ground?.transform.matrix == groundBefore)
        for mover in Traffic.movers(for: Self.layout, detail: .full) {
            let e = try #require(root.findEntity(named: mover.id))
            #expect(e.position == SIMD3<Float>(Traffic.pose(of: mover, at: 5).position))
            #expect(e.components[MoverComponent.self]?.mover == mover)
        }
    }

    @Test func walkerModelIsScaledToTheBriefHeight() throws {
        let catalogue = try Self.characterCatalogue()
        let loader = ModelLoader(catalogue: catalogue)
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let traffic = try #require(node.node(named: "traffic"))
        for asset in AssetName.characterNames.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard case .model = catalogue.resolve(asset) else {
                Issue.record("\(asset.rawValue) has no file in Characters/")
                continue
            }
            let walker = try #require(traffic.children.first { $0.mover?.asset == asset })
            let entity = EntityBuilder.entity(for: walker, loader: loader)
            let box = entity.visualBounds(relativeTo: entity)
            let height = Double(box.max.y - box.min.y)
            #expect(abs(height - Traffic.walkerHeight) <= Traffic.walkerHeight * 0.05, "\(asset.rawValue) height \(height)")
            #expect(Double(box.min.y) <= 0.01, "\(asset.rawValue) bottom \(box.min.y)")
            #expect(abs(Double(box.min.x + box.max.x) / 2) <= 0.01, "\(asset.rawValue) centre x")
            #expect(abs(Double(box.min.z + box.max.z) / 2) <= 0.01, "\(asset.rawValue) centre z")
        }
    }

    private static func assertWalkAnimation(_ asset: AssetName) throws {
        let entity = try ModelLoader(catalogue: characterCatalogue()).load(asset)
        func hasAnimation(_ e: Entity) -> Bool {
            !e.availableAnimations.isEmpty || e.children.contains(where: hasAnimation)
        }
        #expect(hasAnimation(entity), "\(asset.rawValue) carries no animation")
    }

    @Test func characterFileCarriesAWalkAnimation_a() throws { try Self.assertWalkAnimation(.pedestrianA) }
    @Test func characterFileCarriesAWalkAnimation_b() throws { try Self.assertWalkAnimation(.pedestrianB) }
    @Test func characterFileCarriesAWalkAnimation_c() throws { try Self.assertWalkAnimation(.pedestrianC) }

    @Test func startWalkCyclesStartsOnePerWalker() throws {
        let catalogue = try Self.characterCatalogue()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
        let walkers = Traffic.movers(for: Self.layout, detail: .full).filter { $0.kind == .pedestrian }
        #expect(TrafficDriver.startWalkCycles(in: root) == walkers.count)
    }

    /// Nothing calls `place` here: the registered system has to run inside the renderer's frame update.
    @Test(.enabled(if: hasGPU))
    func trafficSystemRunsInTheFrameLoop() async throws {
        TrafficDriver.register()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        let mover = try #require(Traffic.movers(for: Self.layout, detail: .full).first)
        let entity = try #require(root.findEntity(named: mover.id))
        let before = entity.position
        #expect(entity.components[MoverComponent.self]?.elapsed == 0)
        _ = try await OffscreenRenderer().render(root: root, camera: .isoPreset, size: (64, 64))
        let elapsed = try #require(entity.components[MoverComponent.self]).elapsed
        #expect(elapsed > 0, "TrafficSystem.update never ran")
        #expect(entity.position != before)
        let pose = Traffic.pose(of: mover, at: elapsed)
        #expect(entity.position == SIMD3<Float>(pose.position))
    }

    /// The walk clip must move the joints: pose of a joint entity differs after the clip has run for a while.
    @Test(.enabled(if: hasGPU))
    func startedWalkCycleMovesTheJoints() async throws {
        let catalogue = try Self.characterCatalogue()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let traffic = try #require(node.node(named: "traffic"))
        let walker = try #require(traffic.children.first { $0.mover?.kind == .pedestrian })
        let route = try #require(walker.mover)
        var still = walker
        still.mover = nil
        let root = EntityBuilder.entity(for: still, loader: ModelLoader(catalogue: catalogue))
        func joints(_ e: Entity) -> [Transform] {
            var out: [Transform] = []
            if e.name == "Hips" || e.name == "LeftUpLeg" || e.name == "RightUpLeg" { out.append(e.transform) }
            for c in e.children { out.append(contentsOf: joints(c)) }
            return out
        }
        let rest = joints(root)
        #expect(!rest.isEmpty, "no joint entities in the character file")
        // The scene is walked into the clip through the renderer's frames (0.25 s twice).
        let tagged = Entity()
        tagged.components.set(MoverComponent(mover: route))
        tagged.addChild(root)
        #expect(TrafficDriver.startWalkCycles(in: tagged) == 1)
        _ = try await OffscreenRenderer().render(root: tagged, camera: .isoPreset, size: (64, 64), frameDelta: 0.25)
        let moved = joints(root)
        #expect(zip(rest, moved).contains { $0.matrix != $1.matrix }, "no joint moved after the walk cycle ran")
    }

    /// The picture itself: a walker caught mid-stride does not look like the same walker standing still.
    @Test(.enabled(if: hasGPU))
    func walkCycleBendsTheBodyOnScreen() async throws {
        let catalogue = try Self.characterCatalogue()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let traffic = try #require(node.node(named: "traffic"))
        let camera = OrbitCamera(target: SIMD3(0, 0.9, 0), distance: 4, yaw: .pi / 2, pitch: 0.35)
        for asset in AssetName.characterNames.sorted(by: { $0.rawValue < $1.rawValue }) {
            var walker = try #require(traffic.children.first { $0.mover?.asset == asset })
            walker.position = .zero
            walker.yaw = 0
            let route = try #require(walker.mover)
            walker.mover = nil
            func scene() -> Entity {
                let holder = Entity()
                holder.addChild(EntityBuilder.entity(for: walker, loader: ModelLoader(catalogue: catalogue)))
                return holder
            }
            let still = try await OffscreenRenderer().render(root: scene(), camera: camera, size: (256, 256))
            let moving = scene()
            moving.components.set(MoverComponent(mover: route))
            #expect(TrafficDriver.startWalkCycles(in: moving) == 1)
            // The tag only starts the clip; drop it so a registered TrafficSystem cannot drive the walker off
            // camera and make the pixels differ for the wrong reason. Only the bending is under test.
            moving.components.remove(MoverComponent.self)
            let stride = try await OffscreenRenderer().render(root: moving, camera: camera, size: (256, 256), frameDelta: 0.25)
            #expect(moving.position == .zero, "\(asset.rawValue): the holder moved, so the diff is not the bend")
            let a = SnapshotRenderTests.pixels(still), b = SnapshotRenderTests.pixels(stride)
            var differing = 0
            for i in Swift.stride(from: 0, to: a.count, by: 4) where a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2] {
                differing += 1
            }
            #expect(differing >= 200, "\(asset.rawValue): only \(differing) pixels differ between standing and mid-stride")
        }
    }

    /// Without a skin binding the legs stay still on screen while the joints move: refuse such a file.
    @Test func characterMeshIsSkinnedToItsSkeleton() throws {
        let catalogue = try Self.characterCatalogue()
        let loader = ModelLoader(catalogue: catalogue)
        for asset in AssetName.characterNames.sorted(by: { $0.rawValue < $1.rawValue }) {
            let entity = try loader.load(asset)
            func skinned(_ e: Entity) -> Bool {
                if let model = e.components[ModelComponent.self],
                   model.mesh.contents.models.contains(where: { $0.parts.contains { $0.skeletonID != nil } }) { return true }
                return e.children.contains(where: skinned)
            }
            #expect(skinned(entity), "\(asset.rawValue): no mesh part is skinned to a skeleton, so the walk cycle cannot bend the body")
        }
    }

    @Test func standInWalkersHaveNothingToAnimate() {
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: .empty)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: .empty))
        #expect(TrafficDriver.startWalkCycles(in: root) == 0)
    }
}
