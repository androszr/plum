import Foundation
import RealityKit
import StoreSimKit

/// Turns, stretches and grounds a freshly loaded sourced model. Never loads a file.
@MainActor
public enum ModelFit {
    /// The per-axis scale a loaded model needs, after its quarter turns. Nil for generated assets.
    public static func factors(for entity: Entity, name: AssetName) -> SIMD3<Double>? {
        guard let fit = SourcedModelFit.fit(for: name) else { return nil }
        let probe = Entity()
        probe.addChild(entity.clone(recursive: true))
        probe.orientation = simd_quatf(angle: Float(fit.yawQuarterTurns) * .pi / 2, axis: SIMD3(0, 1, 0))
        let b = probe.visualBounds(relativeTo: nil)
        let raw = SIMD3<Double>(Double(b.max.x - b.min.x), Double(b.max.y - b.min.y), Double(b.max.z - b.min.z))
        return SourcedModelFit.scaleFactors(raw: raw, target: fit.size)
    }

    public static func apply(to entity: Entity, for name: AssetName) -> Entity {
        guard let fit = SourcedModelFit.fit(for: name) else { return entity }
        // holder -> scaler (per-axis scale in world axes) -> turned (quarter turns) -> loaded root.
        let turned = Entity()
        turned.addChild(entity)
        turned.orientation = simd_quatf(angle: Float(fit.yawQuarterTurns) * .pi / 2, axis: SIMD3(0, 1, 0))
        let b = turned.visualBounds(relativeTo: nil)
        guard b.min.x <= b.max.x else { return entity.parent === turned ? turned : entity }
        let raw = SIMD3<Double>(Double(b.max.x - b.min.x), Double(b.max.y - b.min.y), Double(b.max.z - b.min.z))
        let k = SourcedModelFit.scaleFactors(raw: raw, target: fit.size)
        let scaler = Entity()
        scaler.addChild(turned)
        scaler.scale = SIMD3<Float>(Float(k.x), Float(k.y), Float(k.z))
        let holder = Entity()
        holder.addChild(scaler)
        let m = holder.visualBounds(relativeTo: holder)
        let centre = (m.min + m.max) * 0.5
        scaler.position = SIMD3(-centre.x, -m.min.y, -centre.z)
        return holder
    }
}
