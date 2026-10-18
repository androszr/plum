import Foundation

/// The clamps a camera obeys. The Outside numbers; the Inside walk has its own limits in `WalkCamera`.
public struct CameraLimits: Equatable, Sendable {
    public var distance: ClosedRange<Double>
    /// Radians.
    public var pitch: ClosedRange<Double>
    public var targetX: ClosedRange<Double>?
    public var targetZ: ClosedRange<Double>?

    public init(distance: ClosedRange<Double>, pitch: ClosedRange<Double>,
                targetX: ClosedRange<Double>? = nil, targetZ: ClosedRange<Double>? = nil) {
        self.distance = distance
        self.pitch = pitch
        self.targetX = targetX
        self.targetZ = targetZ
    }

    public static let outside = CameraLimits(distance: 4...80, pitch: (20.0 * .pi / 180)...(80.0 * .pi / 180))
}
