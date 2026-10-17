import Testing
@testable import StoreSimKit

@Suite struct BrandTests {
    @Test func paletteColoursAreDistinct() {
        let all = Brand.palette.all
        #expect(Set(all).count == all.count)
    }

    @Test func nameIsOneEnglishWord() {
        #expect(!Brand.name.isEmpty)
        #expect(!Brand.name.contains(" "))
        #expect(Brand.name.allSatisfy { $0.isASCII && $0.isLetter })
    }

    @Test func hexIsSixUppercaseDigits() {
        for c in Brand.palette.all {
            #expect(c.hex.count == 6)
            #expect(c.hex.allSatisfy { $0.isHexDigit && !$0.isLowercase })
        }
    }
}
