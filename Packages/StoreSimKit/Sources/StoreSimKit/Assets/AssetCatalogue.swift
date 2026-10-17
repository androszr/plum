import Foundation

/// Knows which dropped model files replace which code shapes.
public struct AssetCatalogue: Sendable {
    public enum Resolution: Equatable, Sendable {
        case model(URL)
        case texture(URL)
        case procedural
    }

    private let models: [AssetName: URL]
    private let textures: [AssetName: URL]

    /// Keeps a `.usdz` whose basename is a fixture name, and a `.png` whose basename is a signage name.
    /// A picture named like a fixture, or a model named like signage, is ignored.
    public init(modelURLs: [URL]) {
        var foundModels: [AssetName: URL] = [:]
        var foundTextures: [AssetName: URL] = [:]
        for url in modelURLs {
            let base = url.deletingPathExtension().lastPathComponent
            guard let name = AssetName(rawValue: base) else { continue }
            if url.pathExtension == "usdz", AssetName.fixtureNames.contains(name) {
                foundModels[name] = url
            } else if url.pathExtension == "png", AssetName.signageNames.contains(name) {
                foundTextures[name] = url
            }
        }
        models = foundModels
        textures = foundTextures
    }

    public func resolve(_ name: AssetName) -> Resolution {
        if let url = models[name] { return .model(url) }
        if let url = textures[name] { return .texture(url) }
        return .procedural
    }

    public static let empty = AssetCatalogue(modelURLs: [])
}
