import Foundation
import simd

public enum LightKind: Sendable {
    case sun(intensity: Double, direction: SIMD3<Double>)
    case fill(intensity: Double, direction: SIMD3<Double>)
    case point(color: BrandColor, intensity: Double, radius: Double)
    case spot(color: BrandColor, intensity: Double, radius: Double, direction: SIMD3<Double>)
}

public enum NodeShape: Sendable {
    case box
    case roundedBox(radius: Double)
    case cylinder
    case plane
    case text(String)
    case light(LightKind)
    case asset(AssetName)
    case group
}

public enum SurfaceMaterial: Sendable {
    case solid(BrandColor, roughness: Double)
    case glass(BrandColor, opacity: Double)
    case emissive(BrandColor)
    case none

    public static func paint(_ c: BrandColor) -> SurfaceMaterial { .solid(c, roughness: 0.6) }
}

/// A box in a node's local space used for picking.
public struct NodeBounds: Sendable {
    public var center: SIMD3<Double>
    public var size: SIMD3<Double>
    public init(center: SIMD3<Double>, size: SIMD3<Double>) {
        self.center = center
        self.size = size
    }
}

/// A platform-neutral scene tree. A box node's `position` is its centre.
public struct SceneNode: Sendable {
    public var name: String
    public var displayName: String?
    public var selectable: Bool
    public var shape: NodeShape
    public var size: SIMD3<Double>
    public var position: SIMD3<Double>
    public var yaw: Double
    /// Rotation about X then Z applied before yaw (lying cylinders).
    public var pitch: Double
    public var roll: Double
    public var material: SurfaceMaterial
    public var bounds: NodeBounds?
    /// Opaque shell parts take clicks (so they hide what is behind them) without being selectable.
    public var blocksPicking: Bool
    public var children: [SceneNode]
    /// Derived per-instance version (see `ModelVariant`); never persisted.
    public var variant: Int

    public init(
        name: String,
        displayName: String? = nil,
        selectable: Bool = false,
        shape: NodeShape = .group,
        size: SIMD3<Double> = .zero,
        position: SIMD3<Double> = .zero,
        yaw: Double = 0,
        pitch: Double = 0,
        roll: Double = 0,
        material: SurfaceMaterial = .none,
        bounds: NodeBounds? = nil,
        blocksPicking: Bool = false,
        children: [SceneNode] = [],
        variant: Int = 0
    ) {
        self.name = name
        self.displayName = displayName
        self.selectable = selectable
        self.shape = shape
        self.size = size
        self.position = position
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
        self.material = material
        self.bounds = bounds
        self.blocksPicking = blocksPicking
        self.children = children
        self.variant = variant
    }

    /// Depth-first, self first.
    public func allNodes() -> [SceneNode] {
        var out = [self]
        for c in children { out.append(contentsOf: c.allNodes()) }
        return out
    }

    public func node(named n: String) -> SceneNode? {
        if name == n { return self }
        for c in children { if let f = c.node(named: n) { return f } }
        return nil
    }

    /// Every node below this one.
    public var descendants: [SceneNode] { Array(allNodes().dropFirst()) }
}

/// Small helper for builders: parts are placed by (x, z) centre and y at the bottom.
struct Parts {
    var nodes: [SceneNode] = []

    mutating func add(_ node: SceneNode) { nodes.append(node) }

    mutating func box(_ name: String, _ x: Double, _ y: Double, _ z: Double,
                      _ w: Double, _ h: Double, _ d: Double, _ m: SurfaceMaterial, round: Double? = nil) {
        let shape: NodeShape = round.map { .roundedBox(radius: $0) } ?? .box
        nodes.append(SceneNode(name: name, shape: shape, size: SIMD3(w, h, d), position: SIMD3(x, y + h / 2, z), material: m))
    }

    mutating func cyl(_ name: String, _ x: Double, _ y: Double, _ z: Double,
                      _ radius: Double, _ h: Double, _ m: SurfaceMaterial) {
        nodes.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(radius * 2, h, radius * 2), position: SIMD3(x, y + h / 2, z), material: m))
    }

    /// A cylinder lying along the x axis, centred on (x, y + radius, z).
    mutating func cylX(_ name: String, _ x: Double, _ y: Double, _ z: Double,
                       _ radius: Double, _ length: Double, _ m: SurfaceMaterial) {
        nodes.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(radius * 2, length, radius * 2),
                               position: SIMD3(x, y + radius, z), roll: .pi / 2, material: m))
    }

    /// A cylinder lying along the z axis, centred on (x, y + radius, z).
    mutating func cylZ(_ name: String, _ x: Double, _ y: Double, _ z: Double,
                       _ radius: Double, _ length: Double, _ m: SurfaceMaterial) {
        nodes.append(SceneNode(name: name, shape: .cylinder, size: SIMD3(radius * 2, length, radius * 2),
                               position: SIMD3(x, y + radius, z), pitch: .pi / 2, material: m))
    }

    /// Text is centred on (x, y, z); `height` is the font size in metres.
    mutating func text(_ name: String, _ s: String, _ x: Double, _ y: Double, _ z: Double,
                       _ height: Double, _ m: SurfaceMaterial, yaw: Double = 0) {
        nodes.append(SceneNode(name: name, shape: .text(s), size: SIMD3(0, height, 0), position: SIMD3(x, y, z), yaw: yaw, material: m))
    }

    mutating func group(_ name: String, _ x: Double, _ y: Double, _ z: Double, _ build: (inout Parts) -> Void) {
        var p = Parts()
        build(&p)
        nodes.append(SceneNode(name: name, position: SIMD3(x, y, z), children: p.nodes))
    }
}
