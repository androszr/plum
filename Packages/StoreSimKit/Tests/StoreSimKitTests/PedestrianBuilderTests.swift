import Foundation
import Testing
@testable import StoreSimKit

@Suite struct PedestrianBuilderTests {
    static func top(_ n: SceneNode) -> Double { n.position.y + n.size.y / 2 }
    static func bottom(_ n: SceneNode) -> Double { n.position.y - n.size.y / 2 }

    @Test func fullDetailHasAtLeastSevenNamedParts() {
        let node = PedestrianBuilder.build(id: "w", asset: .pedestrianA, detail: .full)
        let names = node.children.map(\.name)
        #expect(names.count >= 7)
        #expect(Set(names).isSuperset(of: ["torso", "head", "leg_left", "leg_right", "arm_left", "arm_right", "bag"]))
        #expect(Set(names).count == names.count)
    }

    @Test func reducedHasNoMoreThanFull() {
        let full = PedestrianBuilder.build(id: "w", asset: .pedestrianB, detail: .full)
        let reduced = PedestrianBuilder.build(id: "w", asset: .pedestrianB, detail: .reduced)
        #expect(reduced.children.count <= full.children.count)
        #expect(reduced.children.count >= 4)
    }

    @Test func standsOnTheFloorAndIsOneSeventyFiveTall() {
        for detail in [DetailLevel.full, .reduced] {
            let node = PedestrianBuilder.build(id: "w", asset: .pedestrianC, detail: detail)
            for part in node.children { #expect(Self.bottom(part) >= -1e-9, "\(part.name)") }
            let highest = node.children.map(Self.top).max() ?? 0
            #expect(abs(highest - Traffic.walkerHeight) < 0.01)
            #expect(Traffic.walkerHeight == 1.75)
        }
    }

    @Test func threeAssetsThreeCoatColours() {
        let coats = [AssetName.pedestrianA, .pedestrianB, .pedestrianC].map { asset -> BrandColor? in
            let torso = PedestrianBuilder.build(id: "w", asset: asset, detail: .full).children.first { $0.name == "torso" }
            if case let .solid(colour, _)? = torso?.material { return colour }
            return nil
        }
        #expect(!coats.contains { $0 == nil })
        #expect(Set(coats.compactMap { $0 }).count == 3)
    }
}
