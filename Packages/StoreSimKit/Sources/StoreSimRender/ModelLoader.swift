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

    /// Each file is read from disk once; every caller gets its own deep copy of that entity.
    private static var loaded: [URL: Entity] = [:]

    private func raw(_ name: AssetName) throws -> Entity {
        guard case let .model(url) = catalogue.resolve(name) else { throw ModelLoaderError(name: name) }
        if let cached = Self.loaded[url] { return cached.clone(recursive: true) }
        let entity = try Entity.load(contentsOf: url)
        Self.loaded[url] = entity
        return entity.clone(recursive: true)
    }

    public func load(_ name: AssetName, variant: Int = 0) throws -> Entity {
        let entity = try raw(name)
        let fitted = ModelFit.apply(to: entity, for: name)
        ModelVariants.apply(variant: variant, to: fitted, for: name)
        return fitted
    }

    /// The per-axis stretch a sourced file needs to reach its brief size, before the fit is applied.
    /// Nil for generated assets. Tests use it to refuse a visibly squashed model.
    public func rawFitFactors(_ name: AssetName) throws -> SIMD3<Double>? {
        return ModelFit.factors(for: try raw(name), name: name)
    }

    public func texture(_ name: AssetName) throws -> TextureResource {
        guard case let .texture(url) = catalogue.resolve(name) else { throw Error.notInCatalogue(name) }
        return try TextureResource.load(contentsOf: url)
    }
}
