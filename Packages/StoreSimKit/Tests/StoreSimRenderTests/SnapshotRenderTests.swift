import CoreGraphics
import Foundation
import ImageIO
import Metal
import RealityKit
import simd
import Testing
import UniformTypeIdentifiers
import StoreSimKit
@testable import StoreSimRender

/// Free of the main actor so the `.enabled(if:)` trait can read it.
let hasGPU = MTLCreateSystemDefaultDevice() != nil

@MainActor
@Suite struct SnapshotRenderTests {
    static func render(detail: DetailLevel, size: (Int, Int), name: String) async throws -> CGImage {
        let catalogue = AssetCatalogue.empty
        let node = SceneComposer.compose(layout: .plumCorner, detail: detail, catalogue: catalogue)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
        EntityBuilder.applyRoofOpacity(root: root, camera: .isoPreset)
        let image = try await OffscreenRenderer().render(root: root, camera: .isoPreset, size: size)
        try write(image, name: name)
        return image
    }

    static func write(_ image: CGImage, name: String) throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("storesim-snapshots")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(name)
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw CocoaError(.fileWriteUnknown) }
        print("SNAPSHOT \(url.path)")
    }

    /// Distinct colours and the centre/corner pixels (RGBA8).
    static func stats(_ image: CGImage) -> (distinct: Int, centre: [UInt8], corner: [UInt8]) {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var seen = Set<UInt32>()
        for i in stride(from: 0, to: data.count, by: 4) {
            seen.insert(UInt32(data[i]) << 16 | UInt32(data[i + 1]) << 8 | UInt32(data[i + 2]))
        }
        func px(_ x: Int, _ y: Int) -> [UInt8] { let o = (y * w + x) * 4; return Array(data[o..<o + 3]) }
        return (seen.count, px(w / 2, h / 2), px(2, 2))
    }

    @Test(.enabled(if: hasGPU))
    func fullDetailDesktopSnapshot() async throws {
        let image = try await Self.render(detail: .full, size: (512, 512), name: "desktop-full-512x512.png")
        #expect(image.width == 512 && image.height == 512)
        let s = Self.stats(image)
        #expect(s.distinct >= 16)
        #expect(s.centre != s.corner)
    }

    @Test(.enabled(if: hasGPU))
    func reducedDetailPhoneSnapshot() async throws {
        let image = try await Self.render(detail: .reduced, size: (390, 844), name: "phone-reduced-390x844.png")
        #expect(image.width == 390 && image.height == 844)
        let s = Self.stats(image)
        #expect(s.distinct >= 16)
        #expect(s.centre != s.corner)
    }

    /// The success criterion: two frames two seconds apart differ where the traffic is, and the parked cars' pixels do not.
    @Test(.enabled(if: hasGPU))
    func trafficMovesBetweenTwoFrames() async throws {
        let catalogue = AssetCatalogue.empty
        let node = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: catalogue)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
        EntityBuilder.applyRoofOpacity(root: root, camera: .isoPreset)
        let movers = Traffic.movers(for: .plumCorner, detail: .full)
        // Once another test has registered `TrafficSystem`, a render would also step the movers by its frame
        // time; taking their clocks away for the render keeps each frame exactly at `t`.
        func render(at t: Double) async throws -> CGImage {
            TrafficDriver.place(in: root, at: t)
            var clocks: [(Entity, MoverComponent)] = []
            for m in movers {
                if let e = root.findEntity(named: m.id), let c = e.components[MoverComponent.self] {
                    clocks.append((e, c))
                    e.components.remove(MoverComponent.self)
                }
            }
            defer { for (e, c) in clocks { e.components.set(c) } }
            return try await OffscreenRenderer().render(root: root, camera: .isoPreset, size: (512, 512))
        }
        // A moment when a car is fully on the road at both frames; the timetable leaves the road empty at times.
        let t0 = try #require(stride(from: 0.0, through: 900.0, by: 0.25).first { t in
            movers.contains { $0.kind == .car && Traffic.pose(of: $0, at: t).visibility == 1 && Traffic.pose(of: $0, at: t + 2).visibility == 1 }
        })
        let first = try await render(at: t0)
        try Self.write(first, name: "traffic-t0-512x512.png")
        let second = try await render(at: t0 + 2)
        try Self.write(second, name: "traffic-t2-512x512.png")
        let a = Self.pixels(first), b = Self.pixels(second)
        #expect(a.count == b.count && !a.isEmpty)
        var differing = 0
        for i in stride(from: 0, to: min(a.count, b.count), by: 4)
        where a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2] { differing += 1 }
        #expect(differing >= 50, "only \(differing) pixels changed")
        // The parked cars' pixels stay the same, except where a passing car or walker covers them in either frame.
        let pose = OrbitCamera.isoPreset.pose
        var covered: [Rect] = []
        for t in [t0, t0 + 2] {
            for m in movers {
                let at = Traffic.pose(of: m, at: t).position
                // A metre round each mover on the ground covers its shadow too.
                let half = (m.kind == .car ? SIMD3(Traffic.carLength / 2, 0, 1.0) : SIMD3(0.2, 0, 0.2)) + SIMD3(1, 0, 1)
                let top = m.kind == .car ? 1.5 : Traffic.walkerHeight
                if let r = Self.screenRect(min: at - half, max: at + half + SIMD3(0, top, 0), pose: pose, size: 512) {
                    covered.append(r.inset(by: -6))
                }
            }
        }
        var checked = 0
        for car in StoreLayout.plumCorner.fixtures where car.kind == .parkedCar {
            let m = car.occupiedRect.centreMetres
            let centre = SIMD3(m.x, 0, m.y)
            let r = try #require(Self.screenRect(min: centre - SIMD3(2.25, 0, 1), max: centre + SIMD3(2.25, 1.5, 1),
                                                pose: pose, size: 512), "\(car.id) off screen")
            var changed = 0
            for y in r.y0..<r.y1 {
                for x in r.x0..<r.x1 where !covered.contains(where: { $0.contains(x, y) }) {
                    let i = (y * 512 + x) * 4
                    checked += 1
                    if a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2] { changed += 1 }
                }
            }
            #expect(changed == 0, "\(changed) pixels of \(car.id) changed")
        }
        #expect(checked >= 200, "only \(checked) parked-car pixels were clear of traffic")
    }

    struct Rect {
        var x0, y0, x1, y1: Int
        func contains(_ x: Int, _ y: Int) -> Bool { x >= x0 && x < x1 && y >= y0 && y < y1 }
        func inset(by d: Int) -> Rect { Rect(x0: x0 + d, y0: y0 + d, x1: x1 - d, y1: y1 - d) }
    }

    /// The pixel rectangle (row 0 at the top) a world box covers in a square frame from the renderer's
    /// 45 degree camera at `pose`, clipped to the frame; nil when it falls outside.
    static func screenRect(min lo: SIMD3<Double>, max hi: SIMD3<Double>, pose: CameraPose, size: Int) -> Rect? {
        let f = simd_normalize(pose.target - pose.eye)
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)
        let t = tan(45.0 / 2 * Double.pi / 180)
        var xs: [Double] = [], ys: [Double] = []
        for cx in [lo.x, hi.x] { for cy in [lo.y, hi.y] { for cz in [lo.z, hi.z] {
            let d = SIMD3(cx, cy, cz) - pose.eye
            let z = simd_dot(d, f)
            guard z > 0.1 else { return nil }
            xs.append((simd_dot(d, r) / z / t + 1) / 2 * Double(size))
            ys.append((1 - simd_dot(d, u) / z / t) / 2 * Double(size))
        } } }
        let rect = Rect(x0: Swift.max(0, Int(xs.min()!)), y0: Swift.max(0, Int(ys.min()!)),
                        x1: Swift.min(size, Int(xs.max()!.rounded(.up))), y1: Swift.min(size, Int(ys.max()!.rounded(.up))))
        return rect.x0 < rect.x1 && rect.y0 < rect.y1 ? rect : nil
    }

    static func pixels(_ image: CGImage) -> [UInt8] {
        let w = image.width, h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return data
    }

    @Test(.enabled(if: hasGPU))
    func insideViewSnapshot() async throws {
        let catalogue = AssetCatalogue.empty
        let lot = StoreLayout.plumCorner.lot
        let node = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: catalogue)
        let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
        let pose = WalkCamera.preset(lot: lot, floor: WalkableFloor(layout: .plumCorner)).pose
        let candidates = EntityBuilder.shellCandidates(in: root)
        let hidden = InteriorVisibility.hiddenNames(
            mode: .inside, candidates: Array(candidates.keys), eye: pose.eye, lot: lot)
        EntityBuilder.applyShellVisibility(hidden: hidden, in: candidates)
        let image = try await OffscreenRenderer().render(root: root, pose: pose, size: (512, 512))
        try Self.write(image, name: "inside-walk-512x512.png")
        #expect(image.width == 512 && image.height == 512)
        let s = Self.stats(image)
        #expect(s.distinct >= 16)
        #expect(s.centre != s.corner)
    }
}
