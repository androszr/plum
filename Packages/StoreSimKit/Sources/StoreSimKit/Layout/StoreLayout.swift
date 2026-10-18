import Foundation

public struct StoreLayout: Codable, Sendable {
    public var lot: Lot
    public var fixtures: [Fixture]

    public init(lot: Lot, fixtures: [Fixture]) {
        self.lot = lot
        self.fixtures = fixtures
    }

    private enum CodingKeys: String, CodingKey { case lot, fixtures }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lot = try c.decode(Lot.self, forKey: .lot)
        // A fixture of a kind this build has never heard of is skipped, not fatal.
        let lenient = try c.decodeIfPresent([LenientFixture].self, forKey: .fixtures) ?? []
        fixtures = lenient.compactMap(\.fixture)
    }
}

/// Decodes one fixture, or nothing when it cannot be read (for example an unknown kind).
private struct LenientFixture: Decodable {
    let fixture: Fixture?
    init(from decoder: Decoder) throws {
        fixture = try? Fixture(from: decoder)
    }
}

extension StoreLayout {
    /// Interior origin (cell) of the shop floor.
    public static let interiorOrigin = GridCell(x: 17, z: 2)

    /// The shipped corner shop: a 28 m x 21 m lot, 56 x 42 cells.
    public static let plumCorner: StoreLayout = {
        let lot = Lot(
            size: GridSize(w: 56, d: 42),
            zones: [
                Zone(id: "facade", kind: .facadeStrip, rect: GridRect(x: 0, z: 0, w: 56, d: 2)),
                Zone(id: "shop", kind: .storeInterior, rect: GridRect(x: 17, z: 2, w: 22, d: 14)),
                Zone(id: "backroom", kind: .backRoom, rect: GridRect(x: 11, z: 2, w: 6, d: 6)),
                Zone(id: "sidewalk", kind: .sidewalk, rect: GridRect(x: 0, z: 16, w: 56, d: 6)),
                Zone(id: "parking", kind: .parkingLane, rect: GridRect(x: 0, z: 22, w: 56, d: 4)),
                Zone(id: "street", kind: .street, rect: GridRect(x: 0, z: 26, w: 56, d: 12)),
                Zone(id: "far_sidewalk", kind: .farSidewalk, rect: GridRect(x: 0, z: 38, w: 56, d: 4)),
            ],
            entrance: GridCell(x: 27, z: 15)
        )

        var out: [Fixture] = []
        // Shop-local helper: u, v are cells inside the interior.
        func shop(_ id: String, _ kind: FixtureKind, _ u: Int, _ v: Int, _ turn: Int = 0, label: String? = nil) {
            out.append(Fixture(id: id, kind: kind, cell: GridCell(x: 17 + u, z: 2 + v), rotation: QuarterTurn(turn), label: label))
        }
        func lotFixture(_ id: String, _ kind: FixtureKind, _ x: Int, _ z: Int, _ turn: Int = 0, label: String? = nil) {
            out.append(Fixture(id: id, kind: kind, cell: GridCell(x: x, z: z), rotation: QuarterTurn(turn), label: label))
        }

        // Left wall: the dairy wall, around the back room door.
        shop("dairy_chiller_1", .dairyChiller, 0, 0, 1, label: "Milk")
        shop("back_room_door_1", .backRoomDoor, 0, 3, 1)
        shop("dairy_chiller_2", .dairyChiller, 0, 5, 1, label: "Yoghurt")
        shop("dairy_chiller_3", .dairyChiller, 0, 8, 1, label: "Cheese")
        shop("dairy_chiller_4", .dairyChiller, 0, 11, 1, label: "Butter & eggs")

        // Right wall: the drinks wall, the cafe corner and the tobacco cabinet.
        shop("wall_fridge_1", .wallFridge, 20, 0, 3, label: "Cold drinks")
        shop("wall_fridge_2", .wallFridge, 20, 2, 3, label: "Soft drinks")
        shop("wall_fridge_3", .wallFridge, 20, 4, 3, label: "Water & juice")
        shop("hot_food_counter_1", .hotFoodCounter, 20, 6, 3)
        shop("menu_screen_1", .menuScreen, 21, 6, 3)
        shop("cigarette_cabinet_1", .cigaretteCabinet, 21, 11, 3)

        // Back-right corner: beer.
        shop("wall_fridge_4", .wallFridge, 16, 0, label: "Beer")
        shop("wall_fridge_5", .wallFridge, 18, 0, label: "Beer")

        // Back wall: labelled product blocks and a loyalty end cap.
        let backBlocks = ["Bread", "Fruit & veg", "Ready meals", "Cold cuts", "Household", "Pet food"]
        for (i, label) in backBlocks.enumerated() { shop("wall_shelf_\(i + 1)", .wallShelf, 2 + i * 2, 0, label: label) }
        shop("end_cap_3", .endCap, 14, 0, label: "Rewards")

        // The island: five double-sided shelves with an end cap at each end.
        let island = ["Snacks", "Crisps", "Sweets", "Biscuits", "Tea & coffee"]
        for (i, label) in island.enumerated() { shop("gondola_\(i + 1)", .gondolaShelf, 5 + i * 2, 5, label: label) }
        shop("end_cap_1", .endCap, 4, 5, 3, label: "Half price")
        shop("end_cap_2", .endCap, 15, 5, 1, label: "This week")

        // Front of shop: two tills, a one-cell cashier lane behind them, the alcohol wall across the lane;
        // the tobacco cabinet on the right wall opens onto the lane's end.
        shop("checkout_1", .checkoutCounter, 12, 10, 2)
        shop("checkout_2", .checkoutCounter, 16, 10, 2)
        shop("alcohol_wall_1", .alcoholWall, 12, 13, 2, label: "Wine & spirits")
        shop("alcohol_wall_2", .alcoholWall, 16, 13, 2, label: "Vodka & whisky")
        shop("self_checkout_1", .selfCheckout, 10, 11)
        shop("basket_stack_1", .basketStack, 9, 11)
        shop("coffee_machine_1", .coffeeMachine, 8, 13, 2)

        // Window seating and the entrance.
        shop("window_ledge_1", .windowLedge, 2, 13, 2)
        shop("high_stool_1", .highStool, 2, 12)
        shop("high_stool_2", .highStool, 5, 12)
        shop("entrance_door_1", .entranceDoor, 9, 13)
        shop("window_poster_1", .windowPoster, 2, 13)
        shop("window_poster_2", .windowPoster, 4, 13)
        shop("window_poster_3", .windowPoster, 6, 13)

        // Ceiling pendants over the loop around the island.
        for (i, p) in [(3, 3), (9, 3), (15, 3), (3, 6), (17, 6), (3, 8), (9, 8), (15, 8)].enumerated() {
            shop("pendant_lamp_\(i + 1)", .pendantLamp, p.0, p.1)
        }

        // Sidewalk.
        lotFixture("atm_locker_1", .atmLocker, 40, 16)
        lotFixture("a_frame_sign_1", .aFrameSign, 24, 18)
        lotFixture("litter_bin_1", .litterBin, 14, 17)
        lotFixture("litter_bin_2", .litterBin, 42, 18)
        lotFixture("bike_rack_1", .bikeRack, 46, 17)
        for (i, x) in [8, 24, 40, 52].enumerated() { lotFixture("street_lamp_\(i + 1)", .streetLamp, x, 21) }

        // Parking lane and far sidewalk.
        for (i, x) in [4, 20, 36].enumerated() { lotFixture("parked_car_\(i + 1)", .parkedCar, x, 22) }
        for (i, x) in [4, 14, 24, 34, 44, 52].enumerated() { lotFixture("tree_\(i + 1)", .tree, x, 39) }

        return StoreLayout(lot: lot, fixtures: out)
    }()
}
