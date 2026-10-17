import Foundation
import RealityKit
import Testing
import StoreSimKit
@testable import StoreSimRender

/// One test per asset file, one per fixture model, and one fallback. Swift Testing counts a
/// parameterised test once, so each case is its own function (29 + 24 + 1, plus the pending-kind check).
@MainActor
@Suite struct ModelSanityTests {
    private static func catalogue() throws -> AssetCatalogue {
        let urls = try FileManager.default.contentsOfDirectory(
            at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
        return AssetCatalogue(modelURLs: urls)
    }

    private static func assertPresent(_ name: AssetName) throws {
        let dir = try BriefSpec.modelsDirectory()
        for ext in name.expectedFileExtensions {
            let url = dir.appendingPathComponent(name.rawValue).appendingPathExtension(ext)
            #expect(FileManager.default.fileExists(atPath: url.path), "missing \(url.lastPathComponent)")
        }
    }

    private static func assertMatchesBrief(_ name: AssetName) throws {
        let spec = try #require(BriefSpec.load()[name.rawValue])
        let dim = try #require(spec.dimensions)
        let budget = try #require(spec.polyBudget)
        let entity = try ModelLoader(catalogue: catalogue()).load(name)
        let box = entity.visualBounds(relativeTo: nil)
        func axis(_ size: Float, _ span: Double, _ label: String) {
            let allowance = max(0.05 * span, 0.02)
            #expect(abs(Double(size) - span) <= allowance, "\(name.rawValue) \(label) \(size) vs \(span)")
        }
        axis(box.max.x - box.min.x, dim.w, "width")
        axis(box.max.z - box.min.z, dim.d, "depth")
        axis(box.max.y - box.min.y, dim.h, "height")
        #expect(abs(Double(box.min.y)) <= 0.01, "\(name.rawValue) bottom")
        #expect(abs(Double(box.min.x + box.max.x) / 2) <= 0.01, "\(name.rawValue) centre x")
        #expect(abs(Double(box.min.z + box.max.z) / 2) <= 0.01, "\(name.rawValue) centre z")
        let triangles = triangleCount(entity)
        #expect(triangles > 0)
        #expect(triangles <= budget, "\(name.rawValue) \(triangles) over \(budget)")
        for part in spec.parts {
            #expect(containsPart(entity, part), "\(name.rawValue) missing \(part)")
        }
    }

    private static func triangleCount(_ entity: Entity) -> Int {
        var total = 0
        if let model = entity.components[ModelComponent.self] {
            for meshModel in model.mesh.contents.models {
                for part in meshModel.parts {
                    if let indices = part.triangleIndices { total += indices.count / 3 }
                }
            }
        }
        for child in entity.children { total += triangleCount(child) }
        return total
    }

    private static func containsPart(_ entity: Entity, _ name: String) -> Bool {
        if entity.name == name || entity.name.hasSuffix("/" + name) { return true }
        return entity.children.contains { containsPart($0, name) }
    }

    @Test func file_gondola_shelf() throws { try Self.assertPresent(.gondolaShelf) }
    @Test func file_wall_shelf() throws { try Self.assertPresent(.wallShelf) }
    @Test func file_end_cap() throws { try Self.assertPresent(.endCap) }
    @Test func file_wall_fridge() throws { try Self.assertPresent(.wallFridge) }
    @Test func file_dairy_chiller() throws { try Self.assertPresent(.dairyChiller) }
    @Test func file_checkout_counter() throws { try Self.assertPresent(.checkoutCounter) }
    @Test func file_cigarette_cabinet() throws { try Self.assertPresent(.cigaretteCabinet) }
    @Test func file_hot_food_counter() throws { try Self.assertPresent(.hotFoodCounter) }
    @Test func file_coffee_machine() throws { try Self.assertPresent(.coffeeMachine) }
    @Test func file_menu_screen() throws { try Self.assertPresent(.menuScreen) }
    @Test func file_window_ledge() throws { try Self.assertPresent(.windowLedge) }
    @Test func file_high_stool() throws { try Self.assertPresent(.highStool) }
    @Test func file_basket_stack() throws { try Self.assertPresent(.basketStack) }
    @Test func file_back_room_door() throws { try Self.assertPresent(.backRoomDoor) }
    @Test func file_pendant_lamp() throws { try Self.assertPresent(.pendantLamp) }
    @Test func file_entrance_door() throws { try Self.assertPresent(.entranceDoor) }
    @Test func file_window_poster() throws { try Self.assertPresent(.windowPoster) }
    @Test func file_atm_locker() throws { try Self.assertPresent(.atmLocker) }
    @Test func file_a_frame_sign() throws { try Self.assertPresent(.aFrameSign) }
    @Test func file_litter_bin() throws { try Self.assertPresent(.litterBin) }
    @Test func file_bike_rack() throws { try Self.assertPresent(.bikeRack) }
    @Test func file_street_lamp() throws { try Self.assertPresent(.streetLamp) }
    @Test func file_tree() throws { try Self.assertPresent(.tree) }
    @Test func file_parked_car() throws { try Self.assertPresent(.parkedCar) }
    @Test func file_plum_mark() throws { try Self.assertPresent(.plumMark) }
    @Test func file_storefront_sign() throws { try Self.assertPresent(.storefrontSign) }
    @Test func file_price_strip() throws { try Self.assertPresent(.priceStrip) }
    @Test func file_window_poster_set() throws { try Self.assertPresent(.windowPosterSet) }
    @Test func file_menu_board_texture() throws { try Self.assertPresent(.menuBoardTexture) }

    @Test func model_gondola_shelf() throws { try Self.assertMatchesBrief(.gondolaShelf) }
    @Test func model_wall_shelf() throws { try Self.assertMatchesBrief(.wallShelf) }
    @Test func model_end_cap() throws { try Self.assertMatchesBrief(.endCap) }
    @Test func model_wall_fridge() throws { try Self.assertMatchesBrief(.wallFridge) }
    @Test func model_dairy_chiller() throws { try Self.assertMatchesBrief(.dairyChiller) }
    @Test func model_checkout_counter() throws { try Self.assertMatchesBrief(.checkoutCounter) }
    @Test func model_cigarette_cabinet() throws { try Self.assertMatchesBrief(.cigaretteCabinet) }
    @Test func model_hot_food_counter() throws { try Self.assertMatchesBrief(.hotFoodCounter) }
    @Test func model_coffee_machine() throws { try Self.assertMatchesBrief(.coffeeMachine) }
    @Test func model_menu_screen() throws { try Self.assertMatchesBrief(.menuScreen) }
    @Test func model_window_ledge() throws { try Self.assertMatchesBrief(.windowLedge) }
    @Test func model_high_stool() throws { try Self.assertMatchesBrief(.highStool) }
    @Test func model_basket_stack() throws { try Self.assertMatchesBrief(.basketStack) }
    @Test func model_back_room_door() throws { try Self.assertMatchesBrief(.backRoomDoor) }
    @Test func model_pendant_lamp() throws { try Self.assertMatchesBrief(.pendantLamp) }
    @Test func model_entrance_door() throws { try Self.assertMatchesBrief(.entranceDoor) }
    @Test func model_window_poster() throws { try Self.assertMatchesBrief(.windowPoster) }
    @Test func model_atm_locker() throws { try Self.assertMatchesBrief(.atmLocker) }
    @Test func model_a_frame_sign() throws { try Self.assertMatchesBrief(.aFrameSign) }
    @Test func model_litter_bin() throws { try Self.assertMatchesBrief(.litterBin) }
    @Test func model_bike_rack() throws { try Self.assertMatchesBrief(.bikeRack) }
    @Test func model_street_lamp() throws { try Self.assertMatchesBrief(.streetLamp) }
    @Test func model_tree() throws { try Self.assertMatchesBrief(.tree) }
    @Test func model_parked_car() throws { try Self.assertMatchesBrief(.parkedCar) }

    @Test func missingFileFallsBack() throws {
        let urls = try FileManager.default.contentsOfDirectory(
            at: BriefSpec.modelsDirectory(), includingPropertiesForKeys: nil)
            .filter { !($0.deletingPathExtension().lastPathComponent == "gondola_shelf" && $0.pathExtension == "usdz") }
        let catalogue = AssetCatalogue(modelURLs: urls)
        #expect(catalogue.resolve(.gondolaShelf) == .procedural)
        let root = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: catalogue)
        let fixture = try #require(StoreLayout.plumCorner.fixtures.first { $0.kind == .gondolaShelf })
        let node = try #require(root.node(named: fixture.id))
        if case .asset = node.shape {
            Issue.record("gondola kept an asset shape without its file")
        }
        #expect(node.node(named: "upright_left") != nil)
    }

    /// Kinds whose brief section says `Status: stand-in only` ship no file and stay code-built.
    @Test func pendingKindsShipNoFileAndStayProcedural() throws {
        let specs = try BriefSpec.load()
        let catalogue = try Self.catalogue()
        let root = SceneComposer.compose(layout: .plumCorner, detail: .full, catalogue: catalogue)
        let cases: [(FixtureKind, AssetName, String)] = [
            (.selfCheckout, .selfCheckout, "screen_left"), (.alcoholWall, .alcoholWall, "shelf_4"),
        ]
        for (kind, name, part) in cases {
            #expect(specs[name.rawValue]?.pending == true, "\(name.rawValue) is not marked stand-in only")
            let file = try BriefSpec.modelsDirectory().appendingPathComponent(name.rawValue).appendingPathExtension("usdz")
            #expect(!FileManager.default.fileExists(atPath: file.path), "\(file.lastPathComponent) should not exist")
            #expect(catalogue.resolve(name) == .procedural)
            let fixture = try #require(StoreLayout.plumCorner.fixtures.first { $0.kind == kind })
            let node = try #require(root.node(named: fixture.id))
            if case .asset = node.shape { Issue.record("\(name.rawValue) became an asset shape without a file") }
            #expect(node.node(named: part) != nil, "\(name.rawValue) lacks \(part)")
        }
    }
}
