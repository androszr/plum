import Foundation
import simd

public struct OrbitCamera: Equatable, Sendable {
    public var target: SIMD3<Double>
    public var distance: Double
    /// Radians, wrapped into [0, 2pi). Yaw 0 puts the camera on +Z looking towards -Z.
    public var yaw: Double
    /// Radians above the horizon.
    public var pitch: Double

    public static let minDistance = 4.0
    public static let maxDistance = 80.0
    public static let minPitch = 20.0 * .pi / 180
    public static let maxPitch = 80.0 * .pi / 180

    public init(target: SIMD3<Double>, distance: Double, yaw: Double, pitch: Double) {
        self.target = target
        self.distance = min(max(distance, Self.minDistance), Self.maxDistance)
        self.yaw = Self.wrap(yaw)
        self.pitch = min(max(pitch, Self.minPitch), Self.maxPitch)
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
    }

    public mutating func zoom(by factor: Double) {
        distance = min(max(distance * factor, Self.minDistance), Self.maxDistance)
    }

    public mutating func rotate(by angle: Double) { yaw = Self.wrap(yaw + angle) }

    public mutating func tilt(by angle: Double) {
        pitch = min(max(pitch + angle, Self.minPitch), Self.maxPitch)
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

    /// 1 below 30 degrees of pitch, 0 above 50, linear between.
    public var roofOpacity: Double {
        let deg = pitch * 180 / .pi
        return min(max((50 - deg) / 20, 0), 1)
    }
}
