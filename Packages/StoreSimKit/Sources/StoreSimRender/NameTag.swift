import Foundation
import RealityKit
import simd
import StoreSimKit

/// A floating label in the scene: a rounded plate with the name on it.
@MainActor
public final class NameTagEntity: Entity {
    private let plate = ModelEntity()
    private let label = ModelEntity()
    private var shownText: String?
    private var plateWidth: Float = 0
    /// How many times the meshes were built; they are cached per text, so moving the camera costs none.
    public private(set) var meshBuilds = 0

    public required init() {
        super.init()
        addChild(plate)
        addChild(label)
        isEnabled = false
    }

    /// Places the tag above `bounds`, turned to face a camera at `cameraYaw`.
    public func show(over bounds: BoundingBox, text: String, cameraYaw: Float, scale: Float = 1) {
        if text != shownText {
            let mesh = MeshResource.generateText(text, extrusionDepth: 0.01, font: .systemFont(ofSize: 0.16),
                                                 containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
            let tb = mesh.bounds
            label.model = ModelComponent(mesh: mesh, materials: [UnlitMaterial(color: Materials.platformColor(Brand.palette.cream))])
            label.position = SIMD3(-tb.center.x, -tb.center.y, 0.02)
            plate.model = ModelComponent(
                mesh: .generateBox(width: tb.extents.x + 0.24, height: tb.extents.y + 0.16, depth: 0.03, cornerRadius: 0.05),
                materials: [UnlitMaterial(color: Materials.platformColor(Brand.palette.primaryDeep))])
            shownText = text
            meshBuilds += 1
        }
        self.scale = SIMD3(repeating: scale)
        position = SIMD3(bounds.center.x, bounds.max.y + 0.35 * scale, bounds.center.z)
        orientation = simd_quatf(angle: cameraYaw, axis: SIMD3(0, 1, 0))
        isEnabled = true
    }

    public func hide() { isEnabled = false }
}
