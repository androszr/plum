import CoreGraphics
import Foundation
import Metal
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

    /// The first time on a quarter-second grid when `mover` is fully shown, and still is `after` seconds later.
    static func shownTime(of mover: Mover, after: Double = 0) -> Double? {
        stride(from: 0.0, through: 900.0, by: 0.25).first {
            Traffic.pose(of: mover, at: $0).visibility == 1 && Traffic.pose(of: mover, at: $0 + after).visibility == 1
        }
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
        let t0 = try #require(Self.shownTime(of: mover, after: 3))
        for t in [t0, t0 + 3] {
            TrafficDriver.place(entity, at: t)
            let pose = Traffic.pose(of: mover, at: t)
            #expect(entity.position == SIMD3<Float>(pose.position))
            let expected = simd_quatf(angle: Float(pose.yaw), axis: SIMD3(0, 1, 0))
            #expect(abs(simd_dot(entity.orientation, expected)) > 0.9999)
        }
        #expect(Traffic.pose(of: mover, at: t0).position != Traffic.pose(of: mover, at: t0 + 3).position)
    }

    @Test func placeShrinksAWaitingMoverAndFadesItAtTheEdge() throws {
        let mover = try #require(Traffic.movers(for: Self.layout, detail: .full).first)
        let entity = Self.entity(for: mover)
        let times = Array(stride(from: 0.0, through: 900.0, by: 0.05))
        let hidden = try #require(times.first { Traffic.pose(of: mover, at: $0).visibility == 0 })
        TrafficDriver.place(entity, at: hidden)
        #expect(entity.scale == SIMD3(repeating: TrafficDriver.hiddenScale))
        #expect(entity.isEnabled, "a disabled walker's clip would stop")
        let fading = try #require(times.first { (0.1...0.9).contains(Traffic.pose(of: mover, at: $0).visibility) })
        TrafficDriver.place(entity, at: fading)
        #expect(entity.scale == SIMD3(repeating: 1))
        let opacity = try #require(entity.components[OpacityComponent.self]).opacity
        #expect(abs(Double(opacity) - Traffic.pose(of: mover, at: fading).visibility) < 1e-6)
        let shown = try #require(Self.shownTime(of: mover))
        TrafficDriver.place(entity, at: shown)
        #expect(!entity.components.has(OpacityComponent.self))
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
        #expect(entity.components[MoverComponent.self]?.elapsed == 0)
        // Start the clock where the mover is on the road, so one frame visibly moves it.
        let t0 = try #require(Self.shownTime(of: mover, after: 2))
        TrafficDriver.place(in: root, at: t0)
        let before = entity.position
        _ = try await OffscreenRenderer().render(root: root, camera: .isoPreset, size: (64, 64))
        let elapsed = try #require(entity.components[MoverComponent.self]).elapsed
        #expect(elapsed > t0, "TrafficSystem.update never ran")
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
        // On the road, the clip runs at the walker's own pace so the planted foot does not slide.
        let walk = try #require(tagged.components[MoverComponent.self]?.walk, "the started clip is kept for pacing")
        let t = try #require(Self.shownTime(of: route))
        TrafficDriver.place(tagged, at: t)
        #expect(abs(Double(walk.speed) - Traffic.walkCycleRate(at: Traffic.pose(of: route, at: t).speed)) < 1e-6)
    }

    /// Half a second of play is half a stride: the legs swap. A clip whose samples sit on fractional time codes
    /// (1 code per second) plays about thirty times too slowly in RealityKit, a near-frozen figure sliding along.
    @Test(.enabled(if: hasGPU))
    func walkCycleSwingsTheLegsAtClipSpeed() async throws {
        let catalogue = try Self.characterCatalogue()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let traffic = try #require(node.node(named: "traffic"))
        let device = try #require(MTLCreateSystemDefaultDevice())
        for asset in AssetName.characterNames.sorted(by: { $0.rawValue < $1.rawValue }) {
            var walker = try #require(traffic.children.first { $0.mover?.asset == asset })
            let route = try #require(walker.mover)
            walker.mover = nil
            let root = Entity()
            root.addChild(EntityBuilder.entity(for: walker, loader: ModelLoader(catalogue: catalogue)))
            root.components.set(MoverComponent(mover: route))
            #expect(TrafficDriver.startWalkCycles(in: root) == 1)
            root.components.remove(MoverComponent.self)
            func skin(_ e: Entity) -> ModelEntity? {
                if let m = e as? ModelEntity, !m.jointNames.isEmpty { return m }
                return e.children.lazy.compactMap(skin).first
            }
            let body = try #require(skin(root))
            // One renderer for every frame, as in the app: the clip's clock runs on in its scene.
            let renderer = try RealityRenderer()
            renderer.entities.append(root)
            let camera = PerspectiveCamera()
            camera.look(at: SIMD3(0, 0.9, 0), from: SIMD3(0, 1, 3), relativeTo: nil as Entity?)
            renderer.entities.append(camera)
            renderer.activeCamera = camera
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 16, height: 16, mipmapped: false)
            desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
            desc.storageMode = .shared
            let texture = try #require(device.makeTexture(descriptor: desc))
            let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: texture))
            func frames(_ n: Int) async throws {
                for _ in 0..<n {
                    try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                        do {
                            try renderer.updateAndRender(deltaTime: 1.0 / 30, cameraOutput: output, whenScheduled: nil,
                                                         onComplete: { _ in cont.resume() })
                        } catch { cont.resume(throwing: error) }
                    }
                }
            }
            try await frames(1)
            let before = body.jointTransforms.map(\.rotation)
            try await frames(15)
            let turned = zip(before, body.jointTransforms.map(\.rotation)).map { a, b in
                2 * acos(min(1, abs(simd_dot(a.vector, b.vector))))
            }.max() ?? 0
            #expect(turned > 0.35, "\(asset.rawValue): no joint turned more than \(turned) rad in half a second of walking")
        }
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

    /// Rows of the frame the figure covers: pixels that differ from the background corner.
    static func coveredRows(_ image: CGImage) -> Int {
        let p = SnapshotRenderTests.pixels(image)
        var top = Int.max, bottom = -1
        for i in Swift.stride(from: 0, to: p.count, by: 4) where p[i] != p[0] || p[i + 1] != p[1] || p[i + 2] != p[2] {
            let y = i / 4 / image.width
            top = min(top, y)
            bottom = max(bottom, y)
        }
        return bottom >= top ? bottom - top + 1 : 0
    }

    /// The skinned body is drawn at the size it measures: a skeleton in other units than its mesh renders a giant
    /// (or nothing) while `visualBounds` still reports 1.75 m. Compared against the code-built stand-in, mid-stride.
    @Test(.enabled(if: hasGPU))
    func walkingCharacterIsDrawnAtPersonHeight() async throws {
        let catalogue = try Self.characterCatalogue()
        let node = SceneComposer.compose(layout: Self.layout, detail: .full, catalogue: catalogue)
        let traffic = try #require(node.node(named: "traffic"))
        let camera = OrbitCamera(target: SIMD3(0, 0.9, 0), distance: 6, yaw: .pi / 2, pitch: 0.35)
        for asset in AssetName.characterNames.sorted(by: { $0.rawValue < $1.rawValue }) {
            var walker = try #require(traffic.children.first { $0.mover?.asset == asset })
            walker.position = .zero
            walker.yaw = 0
            let route = try #require(walker.mover)
            walker.mover = nil
            let standIn = Entity()
            standIn.addChild(EntityBuilder.entity(for: walker, loader: ModelLoader(catalogue: .empty)))
            let reference = Self.coveredRows(try await OffscreenRenderer().render(root: standIn, camera: camera, size: (256, 256)))
            let moving = Entity()
            moving.addChild(EntityBuilder.entity(for: walker, loader: ModelLoader(catalogue: catalogue)))
            moving.components.set(MoverComponent(mover: route))
            #expect(TrafficDriver.startWalkCycles(in: moving) == 1)
            moving.components.remove(MoverComponent.self)
            let drawn = Self.coveredRows(try await OffscreenRenderer().render(root: moving, camera: camera, size: (256, 256), frameDelta: 0.25))
            #expect(reference > 40, "the stand-in should fill a fair part of the frame")
            #expect(Double(drawn) > Double(reference) * 0.75 && Double(drawn) < Double(reference) * 1.25,
                    "\(asset.rawValue): drawn \(drawn) rows tall mid-stride, the 1.75 m stand-in is \(reference)")
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
