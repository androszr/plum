import Foundation
import simd

/// What the tap marker looks like right now.
public struct FloorMarkerPresentation: Equatable, Sendable {
    public var position: SIMD3<Double>
    public var opacity: Double

    public init(position: SIMD3<Double>, opacity: Double) {
        self.position = position
        self.opacity = opacity
    }
}

/// The ring on the floor where an Inside tap will stop the walk. It is a value: the
/// resolved target; how strong it shows comes from how far the walker still has to go.
public struct FloorMarker: Equatable, Sendable {
    public var target: SIMD2<Double>

    public init(target: SIMD2<Double>) { self.target = target }

    /// Ring radius in metres; smaller than half a cell, so it never pokes into a fixture.
    public static let radius = 0.18
    /// Height above the floor in metres, so the ring never flickers against it.
    public static let lift = 0.01
    /// The ring is full beyond this distance and thins out linearly inside it.
    public static let fadeDistance = 1.0

    /// 1 at or beyond `fadeDistance`, linear inside it, 0 at or below zero; 0 for nonsense.
    public static func opacity(remaining: Double, fadeDistance: Double = FloorMarker.fadeDistance) -> Double {
        guard remaining.isFinite, fadeDistance.isFinite, fadeDistance > 0 else { return 0 }
        return min(max(remaining / fadeDistance, 0), 1)
    }

    public func opacity(from position: SIMD2<Double>) -> Double {
        Self.opacity(remaining: simd_distance(position, target))
    }

    public var position: SIMD3<Double> { SIMD3(target.x, Self.lift, target.y) }

    /// Nil unless Inside with a stroll in progress: the one rule that decides visibility.
    public func presentation(camera: WalkCamera, mode: ViewMode) -> FloorMarkerPresentation? {
        guard mode == .inside, camera.isStrolling else { return nil }
        return FloorMarkerPresentation(position: position, opacity: opacity(from: camera.position))
    }

    /// The resolved destination of the stroll just started; nil when it was refused.
    public static func placed(after camera: WalkCamera) -> FloorMarker? {
        camera.route.last.map(FloorMarker.init(target:))
    }
}
