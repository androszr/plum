import Foundation
import simd

/// Per-model correction for the sourced street props. Their files arrive at an arbitrary size
/// and facing, and the project has no modelling program to fix them by hand, so the loader
/// turns, stretches and grounds them. Pure: the measuring happens in `StoreSimRender.ModelFit`.
public enum SourcedModelFit {
    public struct Fit: Equatable, Sendable {
        /// Quarter turns about +Y applied to the loaded root before measuring.
        public var yawQuarterTurns: Int
        /// Target width (x), height (y), depth (z) in metres.
        public var size: SIMD3<Double>

        public init(yawQuarterTurns: Int, size: SIMD3<Double>) {
            self.yawQuarterTurns = yawQuarterTurns
            self.size = size
        }
    }

    private static let carSize = SIMD3<Double>(4.5, 1.5, 2.0)
    private static let treeSize = SIMD3<Double>(1.4, 4.0, 1.4)

    /// Nil for generated assets.
    public static func fit(for name: AssetName) -> Fit? {
        switch name {
        case .parkedCarHatchback: Fit(yawQuarterTurns: 2, size: carSize)
        case .parkedCarSaloon: Fit(yawQuarterTurns: 2, size: carSize)
        case .parkedCarVan: Fit(yawQuarterTurns: 2, size: carSize)
        case .treeLinden: Fit(yawQuarterTurns: 0, size: treeSize)
        case .treeMaple: Fit(yawQuarterTurns: 0, size: treeSize)
        default: nil
        }
    }

    /// Per-axis scale that takes `raw` to `target`. An empty axis scales by 1.
    public static func scaleFactors(raw: SIMD3<Double>, target: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3(raw.x > 1e-9 ? target.x / raw.x : 1,
              raw.y > 1e-9 ? target.y / raw.y : 1,
              raw.z > 1e-9 ? target.z / raw.z : 1)
    }

    /// Largest factor over smallest: 1 for a uniform scale, larger the more the model is squashed.
    public static func anisotropy(_ factors: SIMD3<Double>) -> Double {
        let hi = max(factors.x, max(factors.y, factors.z))
        let lo = min(factors.x, min(factors.y, factors.z))
        guard lo > 0 else { return .infinity }
        return hi / lo
    }
}
