import Foundation
import RealityKit
import Testing
import StoreSimKit
@testable import StoreSimRender

@MainActor
@Suite struct ModelVariantsTests {
    static func part(_ name: String) -> ModelEntity {
        let e = ModelEntity(mesh: .generateBox(size: 0.1), materials: [PhysicallyBasedMaterial()])
        e.name = name
        return e
    }

    static func offset(_ e: Entity) -> SIMD2<Float>? {
        (e.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial)?.textureCoordinateTransform.offset
    }

    static func tint(_ e: Entity) -> PlatformColor? {
        (e.components[ModelComponent.self]?.materials.first as? PhysicallyBasedMaterial)?.baseColor.tint
    }

    static func tree(_ names: [String]) -> (Entity, [Entity]) {
        let root = Entity()
        let parts = names.map { part($0) }
        parts.forEach { root.addChild($0) }
        return (root, parts)
    }

    @Test func posterOffsetFollowsTheVariant() {
        let (root, parts) = Self.tree(["poster"])
        let scaleBefore = (parts[0].components[ModelComponent.self]!.materials.first as! PhysicallyBasedMaterial).textureCoordinateTransform.scale
        ModelVariants.apply(variant: 2, to: root, for: .windowPoster)
        #expect(abs((Self.offset(parts[0])?.x ?? -1) - 2.0 / 3.0) < 0.001)
        let scaleAfter = (parts[0].components[ModelComponent.self]!.materials.first as! PhysicallyBasedMaterial).textureCoordinateTransform.scale
        #expect(scaleBefore == scaleAfter)
    }

    @Test func productPartsAreRetinted() {
        let (root, parts) = Self.tree(["product_1_4", "upright_left"])
        let before = Self.tint(parts[1])
        ModelVariants.apply(variant: 1, to: root, for: .gondolaShelf)
        // Read back through a reference material so both sides share RealityKit's colour-space conversion.
        var reference = PhysicallyBasedMaterial()
        reference.baseColor = .init(tint: Materials.platformColor(ModelVariant.productColour(variant: 1, shelf: 1, facing: 4)))
        let want = reference.baseColor.tint
        #expect(Self.tint(parts[0]) == want)
        #expect(Self.tint(parts[1]) == before)
    }

    @Test func singleVariantAssetIsUntouched() {
        let (root, parts) = Self.tree(["product_1_4", "poster"])
        let t = Self.tint(parts[0]), o = Self.offset(parts[1])
        ModelVariants.apply(variant: 2, to: root, for: .streetLamp)
        #expect(Self.tint(parts[0]) == t)
        #expect(Self.offset(parts[1]) == o)
    }

    @Test func sourcedAssetIsUntouched() {
        // The saloon has three variants but no product or poster parts, so nothing changes.
        #expect(ModelVariant.count(for: AssetName.parkedCarSaloon) == 3)
        let (root, parts) = Self.tree(["product_1_4", "poster"])
        let t = Self.tint(parts[0]), o = Self.offset(parts[1])
        ModelVariants.apply(variant: 1, to: root, for: .parkedCarSaloon)
        #expect(Self.tint(parts[0]) == t)
        #expect(Self.offset(parts[1]) == o)
    }

    @Test func variantWraps() {
        let (r1, p1) = Self.tree(["poster"])
        let (r2, p2) = Self.tree(["poster"])
        ModelVariants.apply(variant: 4, to: r1, for: .windowPoster)
        ModelVariants.apply(variant: 1, to: r2, for: .windowPoster)
        #expect(Self.offset(p1[0]) == Self.offset(p2[0]))
    }
}
