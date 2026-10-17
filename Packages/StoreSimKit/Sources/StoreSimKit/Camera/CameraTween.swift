import Foundation
import simd

/// A pure in-between calculator from one camera to another.
public struct CameraTween: Sendable {
    public var from: OrbitCamera
    public var to: OrbitCamera
    public var duration: Double

    public init(from: OrbitCamera, to: OrbitCamera, duration: Double) {
        self.from = from
        self.to = to
        self.duration = duration
    }

    /// Smoothstep-eased camera after `elapsed` seconds. Values are written straight into the
    /// stored properties (no re-clamping), so a glide between two limit sets never snaps.
    public func value(at elapsed: Double) -> OrbitCamera {
        guard duration > 0, elapsed < duration else { return to }
        let x = min(max(elapsed / duration, 0), 1)
        let t = x * x * (3 - 2 * x)
        var c = to
        c.target = from.target + (to.target - from.target) * t
        c.distance = from.distance + (to.distance - from.distance) * t
        c.pitch = from.pitch + (to.pitch - from.pitch) * t
        var delta = (to.yaw - from.yaw).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta <= -.pi { delta += 2 * .pi }
        c.yaw = OrbitCamera.wrap(from.yaw + delta * t)
        return c
    }
}
