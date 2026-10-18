import Testing
import simd
@testable import StoreSimKit

@Suite struct CameraPoseTests {
    @Test func orbitPoseMatchesPositionAndTarget() {
        let c = OrbitCamera.isoPreset
        #expect(c.pose.eye == c.position && c.pose.target == c.target)
    }

    @Test func walkPoseHeadingEqualsItsYaw() {
        for yaw in [0.0, 0.7, 2.0, 4.0, 6.0] {
            let c = WalkCamera(position: SIMD2(10, 5), yaw: yaw, pitch: 0.3)
            #expect(abs(c.pose.heading - c.yaw) < 1e-9, "\(yaw)")
        }
    }

    @Test func poseTweenEndsExactlyOnTheDestination() {
        let a = OrbitCamera.isoPreset.pose
        let b = WalkCamera(position: SIMD2(10, 5), yaw: 1).pose
        let t = PoseTween(from: a, to: b, duration: 0.6)
        #expect(t.value(at: 0.6) == b)
        #expect(t.value(at: 5) == b)
        #expect(t.value(at: 0) == a)
    }

    @Test func poseTweenMidpointLiesBetweenTheEndpoints() {
        let a = CameraPose(eye: SIMD3(0, 0, 0), target: SIMD3(0, 0, -1))
        let b = CameraPose(eye: SIMD3(10, 2, 0), target: SIMD3(10, 2, -1))
        let mid = PoseTween(from: a, to: b, duration: 1).value(at: 0.5)
        #expect(abs(mid.eye.x - 5) < 1e-9 && abs(mid.eye.y - 1) < 1e-9)
    }
}
