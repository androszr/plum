// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "StoreSimKit",
    platforms: [.macOS(.v26), .iOS(.v26)],
    products: [
        .library(name: "StoreSimKit", targets: ["StoreSimKit"]),
        .library(name: "StoreSimRender", targets: ["StoreSimRender"]),
    ],
    targets: [
        // Pure scene logic: Foundation + simd only (enforced by Scripts/lint.sh).
        .target(name: "StoreSimKit"),
        // RealityKit side: turns the pure scene tree into entities.
        .target(name: "StoreSimRender", dependencies: ["StoreSimKit"]),
        .testTarget(name: "StoreSimKitTests", dependencies: ["StoreSimKit"]),
        .testTarget(name: "StoreSimRenderTests", dependencies: ["StoreSimKit", "StoreSimRender"]),
    ],
    swiftLanguageModes: [.v6]
)
