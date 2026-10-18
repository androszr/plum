import Foundation
import RealityKit
import simd
import StoreSimKit

/// A flat ring on the floor where an Inside tap will stop the walk. It takes no clicks,
/// so a tap on it falls through to the ground like a tap on bare floor.
@MainActor
public final class FloorMarkerEntity: Entity {
    private let disc = ModelEntity()

    public required init() {
        super.init()
        name = "tap_marker"
        let size = Float(2 * FloorMarker.radius)
        disc.model = ModelComponent(
            mesh: .generatePlane(width: size, depth: size, cornerRadius: Float(FloorMarker.radius)),
            materials: [UnlitMaterial(color: Materials.platformColor(Brand.palette.accentMint))])
        addChild(disc)
        components.set(OpacityComponent(opacity: 1))
        isEnabled = false
    }

    public func show(at position: SIMD3<Double>, opacity: Double) {
        self.position = SIMD3<Float>(position)
        components.set(OpacityComponent(opacity: Float(opacity)))
        isEnabled = true
    }

    public func hide() { isEnabled = false }
}
