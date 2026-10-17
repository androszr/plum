import Foundation

/// The clamps a camera obeys. Outside is today's numbers; Inside is low and tight.
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

    /// Low orbit around the aisles; the orbit point stays inside the shop, half a metre from its walls.
    public static func inside(lot: Lot) -> CameraLimits {
        let pitch = (3.0 * .pi / 180)...(35.0 * .pi / 180)
        guard let shop = lot.zones(of: .storeInterior).first?.rect else {
            return CameraLimits(distance: 2.5...9, pitch: pitch)
        }
        let inset = 0.5
        let x = shop.xRangeMetres, z = shop.zRangeMetres
        return CameraLimits(distance: 2.5...9, pitch: pitch,
                            targetX: (x.lowerBound + inset)...(x.upperBound - inset),
                            targetZ: (z.lowerBound + inset)...(z.upperBound - inset))
    }
}
