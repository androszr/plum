import Foundation

public enum AssetName: String, CaseIterable, Sendable {
    case gondolaShelf = "gondola_shelf"
    case wallShelf = "wall_shelf"
    case endCap = "end_cap"
    case wallFridge = "wall_fridge"
    case dairyChiller = "dairy_chiller"
    case checkoutCounter = "checkout_counter"
    case cigaretteCabinet = "cigarette_cabinet"
    case hotFoodCounter = "hot_food_counter"
    case coffeeMachine = "coffee_machine"
    case menuScreen = "menu_screen"
    case windowLedge = "window_ledge"
    case highStool = "high_stool"
    case basketStack = "basket_stack"
    case backRoomDoor = "back_room_door"
    case pendantLamp = "pendant_lamp"
    case entranceDoor = "entrance_door"
    case windowPoster = "window_poster"
    case atmLocker = "atm_locker"
    case aFrameSign = "a_frame_sign"
    case litterBin = "litter_bin"
    case bikeRack = "bike_rack"
    case streetLamp = "street_lamp"
    case parkedCarHatchback = "parked_car_hatchback"
    case parkedCarSaloon = "parked_car_saloon"
    case parkedCarVan = "parked_car_van"
    case treeLinden = "tree_linden"
    case treeMaple = "tree_maple"
    case selfCheckout = "self_checkout"
    case alcoholWall = "alcohol_wall"
    case plumMark = "plum_mark"
    case storefrontSign = "storefront_sign"
    case priceStrip = "price_strip"
    case windowPosterSet = "window_poster_set"
    case menuBoardTexture = "menu_board_texture"
    case packFronts = "pack_fronts"

    /// Fixture kinds, one model file per kind and variant.
    public static var fixtureNames: Set<AssetName> {
        var names = Set<AssetName>()
        for kind in FixtureKind.allCases {
            for v in 0..<ModelVariant.count(for: kind) {
                names.insert(ModelVariant.assetName(for: kind, variant: v))
            }
        }
        return names
    }

    /// Pictures: the mark, the canopy, the price strip, the posters, the menu, the pack fronts.
    public static var signageNames: Set<AssetName> {
        Set(allCases).subtracting(fixtureNames)
    }

    /// Extensions the generator writes for this name. The mark is both a drawing and a picture.
    public var expectedFileExtensions: [String] {
        if self == .plumMark { return ["svg", "png"] }
        if Self.signageNames.contains(self) { return ["png"] }
        return ["usdz"]
    }
}
