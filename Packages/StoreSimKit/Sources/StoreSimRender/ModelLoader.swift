import Foundation
import RealityKit
import StoreSimKit

public struct ModelLoaderError: Error { public let name: AssetName }

/// The only file that loads a model or a texture from disk.
@MainActor
public struct ModelLoader {
    public enum Error: Swift.Error {
        case notInCatalogue(AssetName)
    }

    public let catalogue: AssetCatalogue

    public init(catalogue: AssetCatalogue) { self.catalogue = catalogue }

    public func load(_ name: AssetName, variant: Int = 0) throws -> Entity {
        guard case let .model(url) = catalogue.resolve(name) else { throw ModelLoaderError(name: name) }
        let entity = try Entity.load(contentsOf: url)
        ModelVariants.apply(variant: variant, to: entity, for: name)
        return entity
    }

    public func texture(_ name: AssetName) throws -> TextureResource {
        guard case let .texture(url) = catalogue.resolve(name) else { throw Error.notInCatalogue(name) }
        return try TextureResource.load(contentsOf: url)
    }
}
