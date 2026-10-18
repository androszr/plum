import simd
import Testing
@testable import StoreSimKit

@Suite struct OrbitCameraTests {
    static func camera(pitchDeg: Double = 35) -> OrbitCamera {
        OrbitCamera(target: .zero, distance: 20, yaw: 0, pitch: pitchDeg * .pi / 180)
    }

    @Test func zoomClampsBothEnds() {
        var c = Self.camera()
        c.zoom(by: 1000)
        #expect(c.distance == OrbitCamera.maxDistance)
        c.zoom(by: 0.0001)
        #expect(c.distance == OrbitCamera.minDistance)
    }

    @Test func tiltClamps() {
        var c = Self.camera()
        c.tilt(by: 5)
        #expect(c.pitch == OrbitCamera.maxPitch)
        c.tilt(by: -5)
        #expect(c.pitch == OrbitCamera.minPitch)
    }

    @Test func yawWrapsIntoOneTurn() {
        var c = Self.camera()
        c.rotate(by: 3 * .pi)
        #expect(c.yaw >= 0 && c.yaw < 2 * .pi)
        c.rotate(by: -10 * .pi)
        #expect(c.yaw >= 0 && c.yaw < 2 * .pi)
    }

    @Test func panFollowsTheCameraGroundAxes() {
        var c = Self.camera()
        c.pan(by: SIMD2(1, 0))
        #expect(abs(c.target.x - 1) < 1e-9 && abs(c.target.z) < 1e-9)
        c.pan(by: SIMD2(0, 2))
        #expect(abs(c.target.z + 2) < 1e-9)
        var turned = OrbitCamera(target: .zero, distance: 20, yaw: .pi / 2, pitch: 0.6)
        turned.pan(by: SIMD2(0, 1))
        #expect(abs(turned.target.x + 1) < 1e-9)
    }

    @Test func roofOpacityRule() {
        #expect(Self.camera(pitchDeg: 25).roofOpacity == 1)
        #expect(Self.camera(pitchDeg: 55).roofOpacity == 0)
        #expect(abs(Self.camera(pitchDeg: 40).roofOpacity - 0.5) < 1e-9)
    }

    @Test func isoPresetLooksAtTheLotCentre() {
        let lot = StoreLayout.plumCorner.lot
        let c = OrbitCamera.isoPreset
        #expect(abs(c.target.x - Double(lot.size.w) * cellSize / 2) < 1e-9)
        #expect(abs(c.target.z - Double(lot.size.d) * cellSize / 2) < 1e-9)
        #expect(c.position.y > 0)
    }

    @Test func positionSitsAtTheOrbitDistance() {
        let c = Self.camera()
        let offset = c.position - c.target
        let len = (offset * offset).sum().squareRoot()
        #expect(abs(len - 20) < 1e-9)
    }

    @Test func draggingKeepsTheGrabbedGroundUnderThePointer() throws {
        let view = SIMD2(1200.0, 800.0)
        var c = OrbitCamera.isoPreset
        let from = SIMD2(500.0, 520.0), to = SIMD2(640.0, 450.0)
        let grabbed = try #require(WalkCamera.floorPoint(pose: c.pose, tap: from, viewSize: view))
        let moved = c.drag(from: from, to: to, viewSize: view)
        #expect(moved)
        let under = try #require(WalkCamera.floorPoint(pose: c.pose, tap: to, viewSize: view))
        #expect(simd_length(under - grabbed) < 1e-6, "ground under the pointer moved from \(grabbed) to \(under)")
    }

    @Test func draggingRightMovesTheCameraLeftSoTheLotFollowsTheHand() {
        let view = SIMD2(1200.0, 800.0)
        var c = Self.camera()
        let right = SIMD3(cos(c.yaw), 0, -sin(c.yaw))
        let before = c.target
        c.drag(from: SIMD2(600, 500), to: SIMD2(700, 500), viewSize: view)
        #expect(simd_dot(c.target - before, right) < 0)
    }

    @Test func draggingAboveTheHorizonMovesNothing() {
        let view = SIMD2(1200.0, 800.0)
        var c = Self.camera(pitchDeg: 10)
        let before = c
        let moved = c.drag(from: SIMD2(600, 5), to: SIMD2(650, 5), viewSize: view)
        #expect(!moved)
        #expect(c == before)
    }
}
