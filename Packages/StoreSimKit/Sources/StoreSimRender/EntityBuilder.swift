import Foundation
import RealityKit
import simd
import StoreSimKit

/// Marks an entity the player can click; the name tag reads `displayName`.
public struct SelectableComponent: Component {
    public var displayName: String
    public var nodeName: String
    public init(displayName: String, nodeName: String) {
        self.displayName = displayName
        self.nodeName = nodeName
    }
}

@MainActor
public enum EntityBuilder {
    public static func entity(for node: SceneNode, loader: ModelLoader) -> Entity {
        let entity = baseEntity(for: node, loader: loader)
        entity.name = node.name
        entity.position = SIMD3<Float>(node.position)
        var q = simd_quatf(angle: Float(node.yaw), axis: SIMD3(0, 1, 0))
        if node.pitch != 0 { q = q * simd_quatf(angle: Float(node.pitch), axis: SIMD3(1, 0, 0)) }
        if node.roll != 0 { q = q * simd_quatf(angle: Float(node.roll), axis: SIMD3(0, 0, 1)) }
        // Lights carry their aim in the base entity's orientation; compose with the node's own turn.
        entity.orientation = q * entity.orientation

        if node.selectable, let b = node.bounds {
            let size = SIMD3<Float>(b.size)
            let shape = ShapeResource.generateBox(size: size).offsetBy(translation: SIMD3<Float>(b.center))
            entity.components.set(CollisionComponent(shapes: [shape]))
            entity.components.set(InputTargetComponent())
            entity.components.set(SelectableComponent(displayName: node.displayName ?? node.name, nodeName: node.name))
        }
        if node.blocksPicking, !node.selectable {
            // Takes clicks but has no SelectableComponent, so a click here clears the selection.
            // A pick box in `bounds` wins over the node's size (movers stand on their origin).
            let shape = node.bounds.map {
                ShapeResource.generateBox(size: SIMD3<Float>($0.size)).offsetBy(translation: SIMD3<Float>($0.center))
            } ?? ShapeResource.generateBox(size: size3(node.size))
            entity.components.set(CollisionComponent(shapes: [shape]))
            entity.components.set(InputTargetComponent())
        }
        if let mover = node.mover {
            entity.components.set(MoverComponent(mover: mover))
        }
        if node.name == "store_roof" {
            entity.components.set(OpacityComponent(opacity: 1))
        }

        if case .asset = node.shape {
            // The `fallback` child is the procedural stand-in, handled in baseEntity. Any other child is a
            // layer that goes on top of the shell whether it came from the model or the stand-in
            // (the merchandise).
            for child in node.children where child.name != Self.fallbackName {
                entity.addChild(self.entity(for: child, loader: loader))
            }
            return entity
        }
        for child in node.children {
            entity.addChild(self.entity(for: child, loader: loader))
        }
        return entity
    }

    /// Sets the roof's opacity from the camera pitch so the shop interior shows from above.
    public static func applyRoofOpacity(root: Entity, camera: OrbitCamera) {
        root.findEntity(named: "store_roof")?.components.set(OpacityComponent(opacity: Float(camera.roofOpacity)))
    }

    private static let shellNames: Set<String> = [
        "store_roof", "storefront_glazing", "canopy", "canopy_sign", "canopy_sign_text",
        "store_wall_back", "store_wall_left", "store_wall_right", "tile_wall", "wood_accent",
    ]

    /// The building pieces the Inside view may hide, by name.
    public static func shellCandidates(in root: Entity) -> [String: Entity] {
        var out: [String: Entity] = [:]
        guard let building = root.findEntity(named: "building") else { return out }
        for child in building.children where shellNames.contains(child.name) || child.name.hasPrefix("mullion_") {
            out[child.name] = child
        }
        return out
    }

    /// Disables the hidden pieces and enables the rest. A disabled wall also stops taking clicks.
    public static func applyShellVisibility(hidden: Set<String>, in candidates: [String: Entity]) {
        for (name, entity) in candidates {
            let on = !hidden.contains(name)
            if entity.isEnabled != on { entity.isEnabled = on }
        }
    }

    static let fallbackName = "fallback"

    private static var meshes: [String: MeshResource] = [:]

    /// Equal shapes at equal sizes (to the millimetre) share one mesh.
    private static func cachedMesh(_ key: String, _ make: () -> MeshResource) -> MeshResource {
        if let hit = meshes[key] { return hit }
        let mesh = make()
        meshes[key] = mesh
        return mesh
    }

    /// Number of distinct meshes built so far (tests).
    static var meshCacheCount: Int { meshes.count }

    private static func mm(_ v: Float) -> Int { Int((v * 1000).rounded()) }

    private static func size3(_ s: SIMD3<Double>) -> SIMD3<Float> { SIMD3<Float>(s) }

    private static func baseEntity(for node: SceneNode, loader: ModelLoader) -> Entity {
        let size = SIMD3<Float>(node.size)
        let material = Materials.make(node.material, loader: loader)
        func model(_ mesh: MeshResource) -> Entity {
            ModelEntity(mesh: mesh, materials: material.map { [$0] } ?? [])
        }
        switch node.shape {
        case .group:
            return Entity()
        case .box:
            let key = "box:\(mm(size.x)):\(mm(size.y)):\(mm(size.z))"
            return model(cachedMesh(key) { .generateBox(size: size) })
        case let .roundedBox(radius):
            let r = Float(min(radius, Double(min(size.x, min(size.y, size.z))) * 0.45))
            return model(.generateBox(width: size.x, height: size.y, depth: size.z, cornerRadius: r))
        case .cylinder:
            let key = "cyl:\(mm(size.x)):\(mm(size.y))"
            return model(cachedMesh(key) { .generateCylinder(height: size.y, radius: size.x / 2) })
        case .quad:
            let key = "quad:\(mm(size.x)):\(mm(size.y))"
            return model(cachedMesh(key) { .generatePlane(width: size.x, height: size.y) })
        case .plane:
            return model(.generatePlane(width: size.x, depth: size.z))
        case let .text(string):
            let mesh = MeshResource.generateText(
                string, extrusionDepth: 0.01,
                font: .systemFont(ofSize: CGFloat(node.size.y)),
                containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
            let holder = Entity()
            let child = ModelEntity(mesh: mesh, materials: material.map { [$0] } ?? [])
            child.position = -mesh.bounds.center
            holder.addChild(child)
            return holder
        case let .light(kind):
            return lightEntity(kind)
        case let .asset(name):
            if let loaded = try? loader.load(name, variant: node.variant) {
                // The file is centred and floor-pivoted. `entity(for:)` overwrites this node's
                // position, so the stand-in offset lives on the loaded child.
                align(loaded, toStandInOf: node, loader: loader)
                let holder = Entity()
                holder.addChild(loaded)
                return holder
            }
            // Loading failed: fall back to the procedural tree kept under `fallback`.
            let holder = Entity()
            for child in node.children where child.name == Self.fallbackName {
                holder.addChild(entity(for: child, loader: loader))
            }
            return holder
        }
    }

    /// Moves `loaded` so its visual bounds sit on the fallback's. Pitch and roll are in the
    /// built stand-in, which is what a lying wheel needs. Floor fixtures share the stand-in's
    /// bottom; anything above the floor shares its top, so a taller pendant stays under the roof.
    /// X and Z follow the stand-in's centre, which is where a wall-hung piece actually is.
    private static func align(_ loaded: Entity, toStandInOf node: SceneNode, loader: ModelLoader) {
        guard let fallback = node.children.first(where: { $0.name == "fallback" }) else { return }
        let standIn = entity(for: fallback, loader: loader)
        let stand = standIn.visualBounds(relativeTo: nil)
        var model = loaded.visualBounds(relativeTo: nil)
        guard stand.min.x <= stand.max.x, model.min.x <= model.max.x else { return }
        if case let .asset(name) = node.shape, AssetName.characterNames.contains(name) {
            // Meshy output is not metre-accurate: scale it uniformly to the stand-in's height first.
            let standHeight = stand.max.y - stand.min.y
            let modelHeight = model.max.y - model.min.y
            if standHeight > 0, modelHeight > 0 {
                loaded.scale *= SIMD3(repeating: standHeight / modelHeight)
                model = loaded.visualBounds(relativeTo: nil)
            }
        }
        let standCenter = (stand.min + stand.max) * 0.5
        let modelCenter = (model.min + model.max) * 0.5
        var shift = standCenter - modelCenter
        if stand.min.y <= 0.05 {
            shift.y = stand.min.y - model.min.y
        } else {
            shift.y = stand.max.y - model.max.y
        }
        loaded.position += shift
    }

    private static func lightEntity(_ kind: LightKind) -> Entity {
        let e = Entity()
        func aim(_ dir: SIMD3<Double>) {
            let d = simd_normalize(SIMD3<Float>(dir))
            e.orientation = simd_quatf(from: SIMD3<Float>(0, 0, -1), to: d)
        }
        switch kind {
        case let .sun(intensity, direction):
            var light = DirectionalLightComponent(color: Materials.platformColor(Brand.palette.cream),
                                                  intensity: Float(intensity), isRealWorldProxy: false)
            light.intensity = Float(intensity)
            e.components.set(light)
            e.components.set(DirectionalLightComponent.Shadow(maximumDistance: 80, depthBias: 6))
            aim(direction)
        case let .fill(intensity, direction):
            e.components.set(DirectionalLightComponent(color: Materials.platformColor(Brand.palette.skyPastel),
                                                       intensity: Float(intensity), isRealWorldProxy: false))
            aim(direction)
        case let .point(color, intensity, radius):
            e.components.set(PointLightComponent(color: Materials.platformColor(color),
                                                 intensity: Float(intensity), attenuationRadius: Float(radius)))
        case let .spot(color, intensity, radius, direction):
            e.components.set(SpotLightComponent(color: Materials.platformColor(color), intensity: Float(intensity),
                                                innerAngleInDegrees: 40, outerAngleInDegrees: 80,
                                                attenuationRadius: Float(radius)))
            aim(direction)
        }
        return e
    }
}
