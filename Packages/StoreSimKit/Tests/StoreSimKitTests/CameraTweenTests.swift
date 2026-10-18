import Testing
import simd
@testable import StoreSimKit

@Suite struct CameraTweenTests {
    static let lot = StoreLayout.plumCorner.lot
    static let deg = Double.pi / 180

    @Test func tweenEndsExactlyOnTheDestination() {
        let to = OrbitCamera.isoPreset.turned(by: 2)
        let tween = CameraTween(from: .isoPreset, to: to, duration: 0.6)
        #expect(tween.value(at: 0.6) == to)
        #expect(tween.value(at: 1.2) == to)
        #expect(tween.value(at: 0.6).limits == to.limits)
    }

    @Test func tweenMidpointLiesBetweenTheEndpoints() {
        let limits = CameraLimits(distance: 2.5...9, pitch: (3 * Self.deg)...(35 * Self.deg))
        let from = OrbitCamera(target: .zero, distance: 40, yaw: 0, pitch: 40 * Self.deg)
        let to = OrbitCamera(target: .zero, distance: 6, yaw: 0, pitch: 10 * Self.deg, limits: limits)
        let mid = CameraTween(from: from, to: to, duration: 1).value(at: 0.5)
        #expect(abs(mid.distance - 23) < 1e-9)
        #expect(abs(mid.pitch - 25 * Self.deg) < 1e-9)
    }

    @Test func yawTakesTheShortArcAcrossTheWrap() {
        let from = OrbitCamera(target: .zero, distance: 20, yaw: 0.1, pitch: 0.7)
        let to = from.turned(by: -1)
        let mid = CameraTween(from: from, to: to, duration: 1).value(at: 0.5)
        let expected = OrbitCamera.wrap(0.1 - .pi / 8)
        #expect(abs(mid.yaw - expected) < 1e-9)
    }

    @Test func turnedStepsExactlyFortyFiveDegrees() {
        let c = OrbitCamera(target: .zero, distance: 20, yaw: 0.3, pitch: 0.7)
        #expect(abs(c.turned(by: 1).yaw - c.yaw - .pi / 4) < 1e-9)
        #expect(abs(c.turned(by: 8).yaw - c.yaw) < 1e-9)
        let right = SIMD3(cos(c.yaw), 0, -sin(c.yaw))
        #expect(simd_dot(c.turned(by: 1).position - c.position, right) > 0)
    }
}
