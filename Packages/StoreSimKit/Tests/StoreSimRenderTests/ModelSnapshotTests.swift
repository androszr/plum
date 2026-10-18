import CoreGraphics
import Foundation
import ImageIO
import Metal
import RealityKit
import Testing
import UniformTypeIdentifiers
import StoreSimKit
@testable import StoreSimRender

/// Mean absolute per-channel difference, 0...1. Never tune this above 0.15:
/// a miss means the model is wrong, not the threshold.
let maxMeanDifference = 0.12

@MainActor
@Suite struct ModelSnapshotTests {
    /// The `variant`-th fixture of `kind` in layout order, so its derived variant index is `variant`; the first one
    /// stands in for a variant the layout does not place (the van drives past but is never parked).
    private static func fixture(_ kind: FixtureKind, variant: Int) -> Fixture {
        let all = StoreLayout.plumCorner.fixtures.filter { $0.kind == kind }
        return all[min(variant, all.count - 1)]
    }

    private static func camera(extent: Double, height: Double) -> OrbitCamera {
        let limits = CameraLimits(distance: 0.2...200, pitch: (5 * .pi / 180)...(80 * .pi / 180))
        return OrbitCamera(target: SIMD3(0, height / 2, 0), distance: 2.2 * extent,
                           yaw: .pi / 4, pitch: 35 * .pi / 180, limits: limits)
    }

    private static func lit(_ subject: Entity) -> Entity {
        let root = Entity()
        root.addChild(subject)
        let sun = SceneNode(name: "sun", shape: .light(.sun(intensity: 2800, direction: SIMD3(-0.5, -1, -0.6))))
        let fill = SceneNode(name: "sky_fill", shape: .light(.fill(intensity: 900, direction: SIMD3(0.6, -0.5, 0.5))))
        let lights = SceneNode(name: "lighting", children: [sun, fill])
        root.addChild(EntityBuilder.entity(for: lights, loader: ModelLoader(catalogue: .empty)))
        return root
    }

    private static func grounded(_ entity: Entity) -> Entity {
        let bounds = entity.visualBounds(relativeTo: nil)
        entity.position.y -= bounds.min.y
        return entity
    }

    private static func write(_ image: CGImage, _ name: String) throws -> URL {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("storesim-snapshots").appendingPathComponent("models")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
        print("SNAPSHOT \(url.path)")
        return url
    }

    private static func rgba(_ image: CGImage) -> [UInt8] {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return data
    }

    private static func distinct(_ image: CGImage) -> Int {
        let data = rgba(image)
        var seen = Set<UInt32>()
        for i in stride(from: 0, to: data.count, by: 4) {
            seen.insert(UInt32(data[i]) << 16 | UInt32(data[i + 1]) << 8 | UInt32(data[i + 2]))
        }
        return seen.count
    }

    private static func meanDifference(_ a: CGImage, _ b: CGImage) -> Double {
        let pa = rgba(a), pb = rgba(b)
        var sum = 0.0
        let n = min(pa.count, pb.count)
        var i = 0
        var samples = 0
        while i + 2 < n {
            sum += abs(Double(pa[i]) - Double(pb[i])) / 255
            sum += abs(Double(pa[i + 1]) - Double(pb[i + 1])) / 255
            sum += abs(Double(pa[i + 2]) - Double(pb[i + 2])) / 255
            samples += 3
            i += 4
        }
        return samples == 0 ? 1 : sum / Double(samples)
    }

    private static func compare(_ kind: FixtureKind, variant wanted: Int = 0) async throws {
        let fixture = Self.fixture(kind, variant: wanted)
        let variant = wanted
        let assetName = ModelVariant.assetName(for: kind, variant: variant)
        let spec = try #require(BriefSpec.load()[assetName.rawValue])
        let dim = try #require(spec.dimensions)
        let proceduralNode = FixtureBuilders.builder(for: kind).build(fixture, detail: .full, variant: variant)
        let procedural = grounded(EntityBuilder.entity(for: proceduralNode, loader: ModelLoader(catalogue: .empty)))
        let urls = try FileManager.default.contentsOfDirectory(at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
        let model = grounded(try ModelLoader(catalogue: AssetCatalogue(modelURLs: urls)).load(assetName, variant: variant))
        let camera = camera(extent: max(dim.w, dim.d, dim.h), height: dim.h)
        let renderer = OffscreenRenderer()
        let left = try await renderer.render(root: lit(procedural), camera: camera, size: (256, 256))
        let right = try await renderer.render(root: lit(model), camera: camera, size: (256, 256))
        #expect(left.width == 256 && left.height == 256)
        #expect(right.width == 256 && right.height == 256)
        #expect(distinct(left) >= 8, "\(assetName.rawValue) procedural colours")
        #expect(distinct(right) >= 8, "\(assetName.rawValue) model colours")
        let diff = meanDifference(left, right)
        _ = try write(left, "\(assetName.rawValue)-procedural.png")
        _ = try write(right, "\(assetName.rawValue)-model.png")
        #expect(diff <= maxMeanDifference, "\(assetName.rawValue) mean difference \(diff)")
    }

    @Test(.enabled(if: hasGPU)) func shot_gondola_shelf() async throws { try await Self.compare(.gondolaShelf) }
    @Test(.enabled(if: hasGPU)) func shot_wall_shelf() async throws { try await Self.compare(.wallShelf) }
    @Test(.enabled(if: hasGPU)) func shot_end_cap() async throws { try await Self.compare(.endCap) }
    @Test(.enabled(if: hasGPU)) func shot_wall_fridge() async throws { try await Self.compare(.wallFridge) }
    @Test(.enabled(if: hasGPU)) func shot_dairy_chiller() async throws { try await Self.compare(.dairyChiller) }
    @Test(.enabled(if: hasGPU)) func shot_checkout_counter() async throws { try await Self.compare(.checkoutCounter) }
    @Test(.enabled(if: hasGPU)) func shot_cigarette_cabinet() async throws { try await Self.compare(.cigaretteCabinet) }
    @Test(.enabled(if: hasGPU)) func shot_hot_food_counter() async throws { try await Self.compare(.hotFoodCounter) }
    @Test(.enabled(if: hasGPU)) func shot_coffee_machine() async throws { try await Self.compare(.coffeeMachine) }
    @Test(.enabled(if: hasGPU)) func shot_menu_screen() async throws { try await Self.compare(.menuScreen) }
    @Test(.enabled(if: hasGPU)) func shot_window_ledge() async throws { try await Self.compare(.windowLedge) }
    @Test(.enabled(if: hasGPU)) func shot_high_stool() async throws { try await Self.compare(.highStool) }
    @Test(.enabled(if: hasGPU)) func shot_basket_stack() async throws { try await Self.compare(.basketStack) }
    @Test(.enabled(if: hasGPU)) func shot_back_room_door() async throws { try await Self.compare(.backRoomDoor) }
    @Test(.enabled(if: hasGPU)) func shot_pendant_lamp() async throws { try await Self.compare(.pendantLamp) }
    @Test(.enabled(if: hasGPU)) func shot_entrance_door() async throws { try await Self.compare(.entranceDoor) }
    @Test(.enabled(if: hasGPU)) func shot_window_poster() async throws { try await Self.compare(.windowPoster) }
    @Test(.enabled(if: hasGPU)) func shot_atm_locker() async throws { try await Self.compare(.atmLocker) }
    @Test(.enabled(if: hasGPU)) func shot_a_frame_sign() async throws { try await Self.compare(.aFrameSign) }
    @Test(.enabled(if: hasGPU)) func shot_litter_bin() async throws { try await Self.compare(.litterBin) }
    @Test(.enabled(if: hasGPU)) func shot_bike_rack() async throws { try await Self.compare(.bikeRack) }
    @Test(.enabled(if: hasGPU)) func shot_street_lamp() async throws { try await Self.compare(.streetLamp) }
    @Test(.enabled(if: hasGPU)) func shot_parked_car_hatchback() async throws { try await Self.compare(.parkedCar, variant: 0) }
    @Test(.enabled(if: hasGPU)) func shot_parked_car_saloon() async throws { try await Self.compare(.parkedCar, variant: 1) }
    @Test(.enabled(if: hasGPU)) func shot_parked_car_van() async throws { try await Self.compare(.parkedCar, variant: 2) }
    @Test(.enabled(if: hasGPU)) func shot_self_checkout() async throws { try await Self.compare(.selfCheckout) }
    @Test(.enabled(if: hasGPU)) func shot_alcohol_wall() async throws { try await Self.compare(.alcoholWall) }
    @Test(.enabled(if: hasGPU)) func shot_tree_linden() async throws { try await Self.compare(.tree, variant: 0) }
    @Test(.enabled(if: hasGPU)) func shot_tree_maple() async throws { try await Self.compare(.tree, variant: 1) }

    @Test(.enabled(if: hasGPU))
    func sceneResemblesProcedural() async throws {
        let urls = try FileManager.default.contentsOfDirectory(at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
        let proceduralNode = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: .empty)
        let modelNode = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: AssetCatalogue(modelURLs: urls))
        let procedural = EntityBuilder.entity(for: proceduralNode, loader: ModelLoader(catalogue: .empty))
        let models = EntityBuilder.entity(for: modelNode, loader: ModelLoader(catalogue: AssetCatalogue(modelURLs: urls)))
        let camera = OrbitCamera.isoPreset
        EntityBuilder.applyRoofOpacity(root: procedural, camera: camera)
        EntityBuilder.applyRoofOpacity(root: models, camera: camera)
        let renderer = OffscreenRenderer()
        let left = try await renderer.render(root: procedural, camera: camera, size: (512, 512))
        let right = try await renderer.render(root: models, camera: camera, size: (512, 512))
        _ = try Self.write(left, "scene-procedural.png")
        _ = try Self.write(right, "scene-models.png")
        let diff = Self.meanDifference(left, right)
        #expect(diff <= maxMeanDifference, "scene mean difference \(diff)")
    }
}
