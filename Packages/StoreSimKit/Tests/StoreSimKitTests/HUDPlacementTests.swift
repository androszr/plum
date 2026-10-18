import Testing
@testable import StoreSimKit

@Suite struct HUDPlacementTests {
    @Test func desktopKeepsEveryElementInItsOwnCorner() {
        let p = HUDPlacement(compact: false)
        #expect(p.brand == .topLeading && p.selection == .topTrailing && p.controls == .bottomTrailing)
        #expect(Set([p.brand, p.selection, p.controls]).count == 3)
    }

    @Test func compactStacksControlsAboveTheSelectionCard() {
        let p = HUDPlacement(compact: true)
        #expect(p.brand == .topLeading && p.selection == .bottom && p.controls == .bottom)
    }

    @Test func stickSitsBottomLeadingInBothShells() {
        #expect(HUDPlacement(compact: true).stick == .bottomLeading)
        let d = HUDPlacement(compact: false)
        #expect(d.stick == .bottomLeading && d.stick != d.controls)
    }
}
