import Testing
@testable import StoreSimKit

@Suite struct FixtureDetailTests {
    static func fixture(_ kind: FixtureKind) -> Fixture {
        StoreLayout.plumCorner.fixtures.first { $0.kind == kind } ?? Fixture(id: "test_\(kind.rawValue)", kind: kind, cell: GridCell(x: 0, z: 0))
    }

    // One reported test per kind per detail level (Swift Testing counts a
    // parameterised test once, so each case is spelled out and the list is
    // checked against `FixtureKind.allCases` below).
    func checkFull(_ kind: FixtureKind) {
        let node = FixtureBuilders.builder(for: kind).build(Self.fixture(kind), detail: .full)
        let parts = node.descendants
        #expect(parts.count >= FixtureBuilders.minimumPartCount[kind]!, "\(kind) has \(parts.count)")
        let names = parts.map(\.name)
        #expect(names.allSatisfy { !$0.isEmpty })
        #expect(Set(names).count == names.count, "duplicate part names in \(kind)")
    }

    func checkReduced(_ kind: FixtureKind) {
        let f = Self.fixture(kind)
        let full = FixtureBuilders.builder(for: kind).build(f, detail: .full).descendants.count
        let reduced = FixtureBuilders.builder(for: kind).build(f, detail: .reduced).descendants.count
        #expect(reduced <= full)
        #expect(reduced >= FixtureBuilders.minimumPartCount[kind]! / 2)
    }

    @Test func everyKindIsCovered() {
        #expect(Set(FixtureKind.allCases) == Set([.gondolaShelf, .wallShelf, .endCap, .wallFridge, .dairyChiller, .checkoutCounter, .cigaretteCabinet, .hotFoodCounter, .coffeeMachine, .menuScreen, .windowLedge, .highStool, .basketStack, .backRoomDoor, .pendantLamp, .entranceDoor, .windowPoster, .atmLocker, .aFrameSign, .litterBin, .bikeRack, .streetLamp, .tree, .parkedCar, .selfCheckout, .alcoholWall]))
    }

    @Test func gondolaShelf_full() { checkFull(.gondolaShelf) }
    @Test func gondolaShelf_reduced() { checkReduced(.gondolaShelf) }
    @Test func wallShelf_full() { checkFull(.wallShelf) }
    @Test func wallShelf_reduced() { checkReduced(.wallShelf) }
    @Test func endCap_full() { checkFull(.endCap) }
    @Test func endCap_reduced() { checkReduced(.endCap) }
    @Test func wallFridge_full() { checkFull(.wallFridge) }
    @Test func wallFridge_reduced() { checkReduced(.wallFridge) }
    @Test func dairyChiller_full() { checkFull(.dairyChiller) }
    @Test func dairyChiller_reduced() { checkReduced(.dairyChiller) }
    @Test func checkoutCounter_full() { checkFull(.checkoutCounter) }
    @Test func checkoutCounter_reduced() { checkReduced(.checkoutCounter) }
    @Test func cigaretteCabinet_full() { checkFull(.cigaretteCabinet) }
    @Test func cigaretteCabinet_reduced() { checkReduced(.cigaretteCabinet) }
    @Test func hotFoodCounter_full() { checkFull(.hotFoodCounter) }
    @Test func hotFoodCounter_reduced() { checkReduced(.hotFoodCounter) }
    @Test func coffeeMachine_full() { checkFull(.coffeeMachine) }
    @Test func coffeeMachine_reduced() { checkReduced(.coffeeMachine) }
    @Test func menuScreen_full() { checkFull(.menuScreen) }
    @Test func menuScreen_reduced() { checkReduced(.menuScreen) }
    @Test func windowLedge_full() { checkFull(.windowLedge) }
    @Test func windowLedge_reduced() { checkReduced(.windowLedge) }
    @Test func highStool_full() { checkFull(.highStool) }
    @Test func highStool_reduced() { checkReduced(.highStool) }
    @Test func basketStack_full() { checkFull(.basketStack) }
    @Test func basketStack_reduced() { checkReduced(.basketStack) }
    @Test func backRoomDoor_full() { checkFull(.backRoomDoor) }
    @Test func backRoomDoor_reduced() { checkReduced(.backRoomDoor) }
    @Test func pendantLamp_full() { checkFull(.pendantLamp) }
    @Test func pendantLamp_reduced() { checkReduced(.pendantLamp) }
    @Test func entranceDoor_full() { checkFull(.entranceDoor) }
    @Test func entranceDoor_reduced() { checkReduced(.entranceDoor) }
    @Test func windowPoster_full() { checkFull(.windowPoster) }
    @Test func windowPoster_reduced() { checkReduced(.windowPoster) }
    @Test func atmLocker_full() { checkFull(.atmLocker) }
    @Test func atmLocker_reduced() { checkReduced(.atmLocker) }
    @Test func aFrameSign_full() { checkFull(.aFrameSign) }
    @Test func aFrameSign_reduced() { checkReduced(.aFrameSign) }
    @Test func litterBin_full() { checkFull(.litterBin) }
    @Test func litterBin_reduced() { checkReduced(.litterBin) }
    @Test func bikeRack_full() { checkFull(.bikeRack) }
    @Test func bikeRack_reduced() { checkReduced(.bikeRack) }
    @Test func streetLamp_full() { checkFull(.streetLamp) }
    @Test func streetLamp_reduced() { checkReduced(.streetLamp) }
    @Test func tree_full() { checkFull(.tree) }
    @Test func tree_reduced() { checkReduced(.tree) }
    @Test func parkedCar_full() { checkFull(.parkedCar) }
    @Test func parkedCar_reduced() { checkReduced(.parkedCar) }

    private func names(_ kind: FixtureKind) -> Set<String> {
        Set(FixtureBuilders.builder(for: kind).build(Self.fixture(kind), detail: .full).allNodes().map(\.name))
    }

    @Test func gondolaHasItsNamedParts() {
        let n = names(.gondolaShelf)
        for want in ["base", "upright_left", "upright_right", "back_panel", "slot_row_0", "slot_row_back_2",
                     "header_sign", "header_text", "header_text_back"] {
            #expect(n.contains(want), "missing \(want)")
        }
        // The shelf is a carcass: its shelves, rails and goods are the merchandise layer.
        #expect(!n.contains { $0.hasPrefix("shelf_") || $0.hasPrefix("price_rail_") || $0.hasPrefix("product_") })
    }

    @Test func wallFridgeHasItsNamedParts() {
        let n = names(.wallFridge)
        for want in ["frame", "frame_side_left", "plinth", "door_left", "door_right", "handle_left", "handle_right",
                     "interior_glow", "header", "compressor_vent"] {
            #expect(n.contains(want), "missing \(want)")
        }
        #expect(!n.contains { $0.hasPrefix("shelf_") || $0.hasPrefix("bottle_") })
    }

    @Test func hotFoodCounterHasItsNamedParts() {
        let n = names(.hotFoodCounter)
        for want in ["counter", "counter_top", "roller_grill", "roller_0", "roller_5", "sausage_0", "sausage_3",
                     "heated_case", "pastry_0", "pastry_2", "baguette_0", "baguette_1", "bun_warmer",
                     "condiment_station", "pump_0", "pump_2", "napkin_box", "tile_wall"] {
            #expect(n.contains(want), "missing \(want)")
        }
    }

    @Test func checkoutHasItsNamedParts() {
        let n = names(.checkoutCounter)
        for want in ["counter", "counter_top", "till", "till_screen", "card_terminal", "bag_dispenser", "receipt_printer"] {
            #expect(n.contains(want), "missing \(want)")
        }
        // The impulse rack is the merchandise layer now.
        #expect(!n.contains { $0.hasPrefix("impulse") || $0 == "rack_frame" })
    }

    @Test func cigaretteCabinetHasPlainDoorsAndBoards() {
        let node = FixtureBuilders.builder(for: .cigaretteCabinet).build(Self.fixture(.cigaretteCabinet), detail: .full)
        let n = Set(node.allNodes().map(\.name))
        for want in ["cabinet", "door_left", "door_right", "price_board_left", "price_board_right", "lottery_screen", "scratchcard_rack"] {
            #expect(n.contains(want), "missing \(want)")
        }
        #expect(!n.contains { $0.hasPrefix("shelf_") })
        for door in ["door_left", "door_right"] {
            if case .glass = node.node(named: door)!.material { Issue.record("\(door) is see-through") }
        }
    }

    @Test func productRowsAreDeterministicAndDifferByFixture() {
        func rows(_ id: String) -> [String] {
            let f = Fixture(id: id, kind: .gondolaShelf, cell: GridCell(x: 0, z: 0))
            return Merchandiser.build(f, detail: .full, variant: 0).descendants.compactMap { n in
                guard n.name.hasPrefix("product_") else { return nil }
                if case let .solid(c, _) = n.material { return "\(n.name):\(c.hex):\(n.size.y)" }
                return nil
            }
        }
        #expect(rows("gondola_a1") == rows("gondola_a1"))
        #expect(rows("gondola_a1") != rows("gondola_a2"))
    }

    @Test func gondolaProductsUseManyColours() {
        let f = Self.fixture(.gondolaShelf)
        let colours = Set(Merchandiser.build(Self.unlabelled(f), detail: .full, variant: 0).descendants.compactMap { n -> BrandColor? in
            guard n.name.hasPrefix("product_"), case let .solid(c, _) = n.material else { return nil }
            return c
        })
        #expect(colours.count >= 6)
    }

    /// box, cylinder, or cylinder with a neck, per `product_` node, in tree order.
    static func shapeClasses(_ node: SceneNode) -> [String] {
        let all = node.descendants
        let names = Set(all.map(\.name))
        return all.compactMap { n -> String? in
            guard n.name.hasPrefix("product_"), !n.name.hasSuffix("_neck") else { return nil }
            if case .box = n.shape { return "box" }
            return names.contains("\(n.name)_neck") ? "bottle" : "can"
        }
    }

    /// A fixture with no label has no planogram, so it gets the generic rows.
    static func unlabelled(_ f: Fixture) -> Fixture {
        Fixture(id: f.id, kind: f.kind, cell: f.cell, rotation: f.rotation, label: nil)
    }

    @Test func gondolaVariantsChangeTheShapes() {
        let f = Self.unlabelled(Self.fixture(.gondolaShelf))
        let v0 = Merchandiser.build(f, detail: .full, variant: 0)
        let v1 = Merchandiser.build(f, detail: .full, variant: 1)
        #expect(Self.shapeClasses(v0) != Self.shapeClasses(v1))
        let first = v0.node(named: "product_0_0")
        if case .box? = first?.shape {} else { Issue.record("product_0_0 at variant 0 is not a box") }
        #expect(v0.node(named: "product_0_0_neck") == nil)
    }

    @Test func wallAndEndCapFollowTheSameShape() {
        for kind in [FixtureKind.wallShelf, .endCap] {
            let f = Self.fixture(kind)
            let v0 = FixtureBuilders.builder(for: kind).build(f, detail: .full, variant: 0)
            let v1 = FixtureBuilders.builder(for: kind).build(f, detail: .full, variant: 1)
            if case .box? = v0.node(named: "product_0_0")?.shape {} else { Issue.record("\(kind) variant 0 is not a box") }
            if case .cylinder? = v1.node(named: "product_0_0")?.shape {} else { Issue.record("\(kind) variant 1 is not a cylinder") }
            #expect(v1.node(named: "product_0_0_neck") == nil)
        }
    }

    @Test func windowPosterVariantsDiffer() {
        let f = Self.fixture(.windowPoster)
        var tints: [BrandColor] = []
        var headlines: [String] = []
        for variant in 0..<3 {
            let node = WindowPosterBuilder.build(f, detail: .full, variant: variant)
            if case let .solid(c, _)? = node.node(named: "poster")?.material { tints.append(c) }
            if case let .text(s)? = node.node(named: "headline_text")?.shape { headlines.append(s) }
        }
        #expect(Set(tints).count == 3)
        #expect(headlines == ModelVariant.posterHeadlines)
    }

    @Test func gondolaVariantsChangeTheColourMix() {
        let f = Self.unlabelled(Self.fixture(.gondolaShelf))
        func colours(_ variant: Int) -> Set<BrandColor> {
            Set(Merchandiser.build(f, detail: .full, variant: variant).descendants.compactMap { n -> BrandColor? in
                guard n.name.hasPrefix("product_"), case let .solid(c, _) = n.material else { return nil }
                return c
            })
        }
        #expect(colours(0) != colours(1))
        #expect(colours(0).count >= 6 && colours(1).count >= 6)
    }
    @Test func selfCheckout_full() { checkFull(.selfCheckout) }
    @Test func selfCheckout_reduced() { checkReduced(.selfCheckout) }
    @Test func alcoholWall_full() { checkFull(.alcoholWall) }
    @Test func alcoholWall_reduced() { checkReduced(.alcoholWall) }

    @Test func selfCheckoutHasItsNamedParts() {
        let names = Set(FixtureBuilders.builder(for: .selfCheckout).build(Self.fixture(.selfCheckout), detail: .full).descendants.map(\.name))
        for want in ["screen_left", "screen_right", "scanner_left", "bagging_shelf_right", "beacon_left"] {
            #expect(names.contains(want), "missing \(want)")
        }
    }

    @Test func alcoholWallHasItsNamedParts() {
        let names = FixtureBuilders.builder(for: .alcoholWall).build(Self.fixture(.alcoholWall), detail: .full).descendants.map(\.name)
        for want in ["base", "upright_left", "upright_right", "back_panel", "header_sign", "header_text"] {
            #expect(names.contains(want), "missing \(want)")
        }
        // An empty frame: shelves, rails and bottles are the merchandise layer.
        #expect(!names.contains { $0.hasPrefix("shelf_") || $0.hasPrefix("price_rail_") || $0.hasPrefix("bottle_") })
    }
}
