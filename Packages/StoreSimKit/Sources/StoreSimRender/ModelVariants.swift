import Foundation
import RealityKit
import StoreSimKit

/// Applies a placed copy's derived variant to a freshly loaded model. Never loads a file.
@MainActor
public enum ModelVariants {
    public static func apply(variant: Int, to root: Entity, for name: AssetName,
                             replacementTexture: TextureResource? = nil) {
        let count = ModelVariant.count(for: name)
        guard count > 1 else { return }
        let v = ModelVariant.wrap(variant, count: count)

        if name == .windowPoster {
            guard let poster = root.findEntity(named: "poster"),
                  var model = poster.components[ModelComponent.self] else { return }
            let offset = SIMD2<Float>(Float(v) / Float(count), 0)
            model.materials = model.materials.map { material in
                if var pbr = material as? PhysicallyBasedMaterial {
                    pbr.textureCoordinateTransform.offset = offset
                    return pbr
                }
                if var unlit = material as? UnlitMaterial {
                    unlit.textureCoordinateTransform.offset = offset
                    return unlit
                }
                if let texture = replacementTexture {
                    var unlit = UnlitMaterial()
                    unlit.color = .init(tint: .white, texture: .init(texture))
                    unlit.textureCoordinateTransform.offset = offset
                    return unlit
                }
                return material
            }
            poster.components.set(model)
            return
        }

        let stems = ModelVariant.productPartStems(for: name)
        guard !stems.isEmpty else { return }
        retint(root, variant: v, stems: stems)
    }

    private static func retint(_ entity: Entity, variant: Int, stems: Set<String>) {
        if let part = ModelVariant.parseProductPart(entity.name, stems: stems),
           var model = entity.components[ModelComponent.self] {
            let tint = Materials.platformColor(
                ModelVariant.productColour(variant: variant, shelf: part.shelf, facing: part.facing))
            model.materials = model.materials.map { material in
                if var pbr = material as? PhysicallyBasedMaterial {
                    pbr.baseColor = .init(tint: tint)
                    return pbr
                }
                if var unlit = material as? UnlitMaterial {
                    unlit.color = .init(tint: tint)
                    return unlit
                }
                return material
            }
            entity.components.set(model)
            // A shape-suffixed mesh is one of three at its spot: show the one this variant picks.
            if let shape = part.shape {
                entity.isEnabled = shape == ModelVariant.visibleShape(
                    variant: variant, shelf: part.shelf, facing: part.facing)
            }
        }
        for child in entity.children { retint(child, variant: variant, stems: stems) }
    }
}
