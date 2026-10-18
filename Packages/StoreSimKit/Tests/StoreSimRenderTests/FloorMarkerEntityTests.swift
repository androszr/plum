import Foundation
import RealityKit
import Testing
import StoreSimKit
@testable import StoreSimRender

@MainActor
@Suite struct FloorMarkerEntityTests {
    @Test func markerShowsAtThePointWithTheGivenOpacity() {
        let marker = FloorMarkerEntity()
        #expect(!marker.isEnabled)
        marker.show(at: SIMD3(3, 0.01, 4), opacity: 0.4)
        #expect(marker.isEnabled)
        #expect(abs(marker.position.x - 3) < 1e-5 && abs(marker.position.y - 0.01) < 1e-5 && abs(marker.position.z - 4) < 1e-5)
        #expect(abs((marker.components[OpacityComponent.self]?.opacity ?? -1) - 0.4) < 1e-5)
        marker.hide()
        #expect(!marker.isEnabled)
    }

    @Test func markerNeverTakesClicks() {
        let marker = FloorMarkerEntity()
        #expect(marker.name == "tap_marker")
        func check(_ e: Entity) {
            #expect(e.components[CollisionComponent.self] == nil)
            #expect(e.components[InputTargetComponent.self] == nil)
            e.children.forEach(check)
        }
        check(marker)
    }
}
