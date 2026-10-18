import Foundation
import simd

public struct OrbitCamera: Equatable, Sendable {
    public var target: SIMD3<Double>
    public var distance: Double
    /// Radians, wrapped into [0, 2pi). Yaw 0 puts the camera on +Z looking towards -Z.
    public var yaw: Double
    /// Radians above the horizon.
    public var pitch: Double

    /// The clamps this camera obeys; Outside by default.
    public var limits: CameraLimits

    public static let minDistance = CameraLimits.outside.distance.lowerBound
    public static let maxDistance = CameraLimits.outside.distance.upperBound
    public static let minPitch = CameraLimits.outside.pitch.lowerBound
    public static let maxPitch = CameraLimits.outside.pitch.upperBound

    /// One turn-button step: 45 degrees.
    public static let rotateStep = Double.pi / 4

    public init(target: SIMD3<Double>, distance: Double, yaw: Double, pitch: Double,
                limits: CameraLimits = .outside) {
        self.limits = limits
        self.target = target
        self.distance = min(max(distance, limits.distance.lowerBound), limits.distance.upperBound)
        self.yaw = Self.wrap(yaw)
        self.pitch = min(max(pitch, limits.pitch.lowerBound), limits.pitch.upperBound)
    }

    /// A copy turned by whole 45 degree steps; positive steps turn the view left.
    public func turned(by steps: Int) -> OrbitCamera {
        var c = self
        c.rotate(by: Double(steps) * Self.rotateStep)
        return c
    }

    /// Frames the whole lot from the front-right at an isometric-style angle.
    public static func framing(lot: Lot) -> OrbitCamera {
        let c = lot.centreMetres
        let lotW = Double(lot.size.w) * cellSize, lotD = Double(lot.size.d) * cellSize
        let diag = (lotW * lotW + lotD * lotD).squareRoot()
        return OrbitCamera(target: SIMD3(c.x, 0, c.y), distance: diag * 1.15,
                           yaw: .pi / 4, pitch: 40.0 * .pi / 180)
    }

    public static var isoPreset: OrbitCamera { framing(lot: StoreLayout.plumCorner.lot) }

    static func wrap(_ a: Double) -> Double {
        let t = 2 * Double.pi
        let r = a.truncatingRemainder(dividingBy: t)
        return r < 0 ? r + t : r
    }

    /// Slides the target along the ground in the camera's own axes: x is right, y is forward.
    public mutating func pan(by delta: SIMD2<Double>) {
        let right = SIMD3(cos(yaw), 0, -sin(yaw))
        let forward = SIMD3(-sin(yaw), 0, -cos(yaw))
        target += right * delta.x + forward * delta.y
        if let r = limits.targetX { target.x = min(max(target.x, r.lowerBound), r.upperBound) }
        if let r = limits.targetZ { target.z = min(max(target.z, r.lowerBound), r.upperBound) }
    }

    public mutating func zoom(by factor: Double) {
        distance = min(max(distance * factor, limits.distance.lowerBound), limits.distance.upperBound)
    }

    public mutating func rotate(by angle: Double) { yaw = Self.wrap(yaw + angle) }

    public mutating func tilt(by angle: Double) {
        pitch = min(max(pitch + angle, limits.pitch.lowerBound), limits.pitch.upperBound)
    }

    public var position: SIMD3<Double> {
        target + distance * SIMD3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
    }

    /// Camera-to-world transform looking at the target with +Y up.
    public var lookTransform: simd_double4x4 {
        let eye = position
        let f = simd_normalize(target - eye)
        let r = simd_normalize(simd_cross(f, SIMD3(0, 1, 0)))
        let u = simd_cross(r, f)
        return simd_double4x4(columns: (
            SIMD4(r, 0), SIMD4(u, 0), SIMD4(-f, 0), SIMD4(eye, 1)
        ))
    }

    public var pose: CameraPose { CameraPose(eye: position, target: target) }

    /// 1 below 30 degrees of pitch, 0 above 50, linear between.
    public var roofOpacity: Double {
        let deg = pitch * 180 / .pi
        return min(max((50 - deg) / 20, 0), 1)
    }
}
