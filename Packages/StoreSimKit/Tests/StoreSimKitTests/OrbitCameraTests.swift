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
}
