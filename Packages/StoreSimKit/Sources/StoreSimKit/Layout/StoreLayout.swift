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
        fixtures = try c.decodeIfPresent([Fixture].self, forKey: .fixtures) ?? []
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

        // Back wall: one wall of coolers, dairy, the hot-food counter and coffee.
        for i in 0..<4 { shop("wall_fridge_\(i + 1)", .wallFridge, i * 2, 0, label: "Drinks cooler \(i + 1)") }
        shop("dairy_chiller_1", .dairyChiller, 8, 0)
        shop("hot_food_counter_1", .hotFoodCounter, 14, 0)
        shop("coffee_machine_1", .coffeeMachine, 19, 0)
        shop("menu_screen_1", .menuScreen, 14, 0)

        // Left wall: back room door and wall shelves facing the shop.
        shop("back_room_door_1", .backRoomDoor, 0, 2, 1)
        shop("wall_shelf_1", .wallShelf, 0, 4, 1, label: "Bread")
        shop("wall_shelf_2", .wallShelf, 0, 6, 1, label: "Spices")
        shop("wall_shelf_3", .wallShelf, 0, 8, 1, label: "Cleaning")
        shop("wall_shelf_4", .wallShelf, 21, 4, 3, label: "Sweets")
        shop("cigarette_cabinet_1", .cigaretteCabinet, 21, 6, 3)

        // Gondola runs.
        let runA = ["Snacks", "Crisps", "Biscuits"]
        let runB = ["Pasta", "Tins", "Sauces"]
        let runC = ["Cereal", "Tea", "Baking"]
        for (i, label) in runA.enumerated() { shop("gondola_a\(i + 1)", .gondolaShelf, 3 + i * 2, 4, label: label) }
        for (i, label) in runB.enumerated() { shop("gondola_b\(i + 1)", .gondolaShelf, 3 + i * 2, 8, label: label) }
        for (i, label) in runC.enumerated() { shop("gondola_c\(i + 1)", .gondolaShelf, 12 + i * 2, 4, label: label) }
        shop("end_cap_1", .endCap, 9, 4, 1, label: "Offers")
        shop("end_cap_2", .endCap, 9, 8, 1, label: "Seasonal")
        shop("end_cap_3", .endCap, 18, 4, 1, label: "Drinks deal")

        // Front of shop: checkout, window seating, baskets, entrance.
        shop("checkout_1", .checkoutCounter, 15, 10)
                shop("window_ledge_1", .windowLedge, 2, 13, 2)
        shop("high_stool_1", .highStool, 2, 12)
        shop("high_stool_2", .highStool, 5, 12)
        shop("basket_stack_1", .basketStack, 12, 13)
        shop("entrance_door_1", .entranceDoor, 9, 13)
        shop("window_poster_1", .windowPoster, 6, 13)
        shop("window_poster_2", .windowPoster, 13, 13)

        // Ceiling pendants.
        for (i, p) in [(5, 3), (12, 3), (18, 3), (5, 9), (12, 9), (18, 9)].enumerated() {
            shop("pendant_lamp_\(i + 1)", .pendantLamp, p.0, p.1)
        }

        // Sidewalk.
        lotFixture("atm_locker_1", .atmLocker, 40, 16)
        lotFixture("a_frame_sign_1", .aFrameSign, 24, 18)
        lotFixture("litter_bin_1", .litterBin, 14, 17)
        lotFixture("litter_bin_2", .litterBin, 42, 19)
        lotFixture("bike_rack_1", .bikeRack, 46, 17)
        for (i, x) in [8, 24, 40, 52].enumerated() { lotFixture("street_lamp_\(i + 1)", .streetLamp, x, 21) }

        // Parking lane and far sidewalk.
        for (i, x) in [4, 20, 36].enumerated() { lotFixture("parked_car_\(i + 1)", .parkedCar, x, 22) }
        for (i, x) in [4, 14, 24, 34, 44, 52].enumerated() { lotFixture("tree_\(i + 1)", .tree, x, 39) }

        return StoreLayout(lot: lot, fixtures: out)
    }()
}
