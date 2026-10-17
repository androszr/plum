import Foundation
import Testing
@testable import StoreSimKit

@Suite struct SourcedModelFitTests {
    @Test func scaleFactorsFollowTheTurnedBox() {
        // A 2 x 1 x 4.5 box turned a quarter becomes 4.5 x 1 x 2; to reach 4.5 x 1.5 x 2 only y grows.
        let k = SourcedModelFit.scaleFactors(raw: SIMD3(4.5, 1, 2), target: SIMD3(4.5, 1.5, 2))
        #expect(k == SIMD3(1, 1.5, 1))
    }

    @Test func anisotropyOfUniformAndSquashedInput() {
        #expect(SourcedModelFit.anisotropy(SIMD3(2, 2, 2)) == 1)
        #expect(SourcedModelFit.anisotropy(SIMD3(1, 2, 1.5)) == 2)
        #expect(SourcedModelFit.anisotropy(SIMD3(0, 1, 1)) == .infinity)
    }

    @Test func emptyAxisScalesByOne() {
        #expect(SourcedModelFit.scaleFactors(raw: SIMD3(0, 2, 1), target: SIMD3(1, 4, 1)) == SIMD3(1, 2, 1))
    }

    @Test func fitExistsOnlyForSourcedNames() {
        #expect(SourcedModelFit.fit(for: .gondolaShelf) == nil)
        for name in [AssetName.parkedCarHatchback, .parkedCarSaloon, .parkedCarVan, .treeLinden, .treeMaple] {
            #expect(SourcedModelFit.fit(for: name) != nil, "\(name.rawValue)")
        }
    }
}
