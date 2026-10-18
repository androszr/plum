import Foundation
import simd

/// Where the eye is and what it looks at: all a renderer needs, whichever camera made it.
public struct CameraPose: Equatable, Sendable {
    public var eye: SIMD3<Double>
    public var target: SIMD3<Double>

    public init(eye: SIMD3<Double>, target: SIMD3<Double>) {
        self.eye = eye
        self.target = target
    }

    /// The yaw (orbit convention) whose ground forward points from the eye to the target.
    public var heading: Double {
        let d = target - eye
        return OrbitCamera.wrap(atan2(-d.x, -d.z))
    }

    public func distance(to point: SIMD3<Double>) -> Double { simd_length(point - eye) }
}

/// A smoothstep glide between two poses.
public struct PoseTween: Sendable {
    public var from: CameraPose
    public var to: CameraPose
    public var duration: Double

    public init(from: CameraPose, to: CameraPose, duration: Double) {
        self.from = from
        self.to = to
        self.duration = duration
    }

    public func value(at elapsed: Double) -> CameraPose {
        guard duration > 0, elapsed < duration else { return to }
        let x = min(max(elapsed / duration, 0), 1)
        let t = x * x * (3 - 2 * x)
        return CameraPose(eye: from.eye + (to.eye - from.eye) * t,
                          target: from.target + (to.target - from.target) * t)
    }
}
