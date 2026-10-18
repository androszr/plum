import Foundation
import RealityKit
import simd
import StoreSimKit

/// Marks an entity that follows a route; `elapsed` is the clock the route is read at.
public struct MoverComponent: Component {
    public var mover: Mover
    public var elapsed: Double
    public init(mover: Mover, elapsed: Double = 0) {
        self.mover = mover
        self.elapsed = elapsed
    }
}

/// Advances every mover's clock by the frame time and places it. Runs on both shells.
public struct TrafficSystem: System {
    private static let query = EntityQuery(where: .has(MoverComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let dt = context.deltaTime
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var component = entity.components[MoverComponent.self] else { continue }
            component.elapsed += dt
            entity.components.set(component)
            TrafficDriver.place(entity, at: component.elapsed)
        }
    }
}

@MainActor
public enum TrafficDriver {
    private static var registered = false

    /// Registers the component and the system. Safe to call twice; call it before the scene is populated.
    public static func register() {
        guard !registered else { return }
        registered = true
        MoverComponent.registerComponent()
        TrafficSystem.registerSystem()
    }

    /// Moves one entity to where its route puts it at `time`. Does nothing without a `MoverComponent`.
    public static func place(_ entity: Entity, at time: Double) {
        guard let component = entity.components[MoverComponent.self] else { return }
        let pose = Traffic.pose(of: component.mover, at: time)
        entity.position = SIMD3<Float>(pose.position)
        entity.orientation = simd_quatf(angle: Float(pose.yaw), axis: SIMD3(0, 1, 0))
    }

    /// Places every mover below `root` and sets its clock to `time`.
    public static func place(in root: Entity, at time: Double) {
        for entity in movers(in: root) {
            if var component = entity.components[MoverComponent.self] {
                component.elapsed = time
                entity.components.set(component)
            }
            place(entity, at: time)
        }
    }

    /// Starts the built-in walk cycle on every walker whose model carries one; returns how many started.
    /// It plays the longest clip on the shallowest entity that has any (the file's root).
    @discardableResult
    public static func startWalkCycles(in root: Entity) -> Int {
        var started = 0
        for entity in movers(in: root) {
            guard let mover = entity.components[MoverComponent.self]?.mover, mover.kind == .pedestrian,
                  let animated = firstAnimated(entity),
                  let animation = animated.availableAnimations.max(by: { $0.definition.duration < $1.definition.duration })
            else { continue }
            let playback = animated.playAnimation(animation.repeat(), transitionDuration: 0)
            playback.time = Traffic.walkCyclePhase(of: mover, clipLength: animation.definition.duration)
            started += 1
        }
        return started
    }

    private static func movers(in root: Entity) -> [Entity] {
        var out: [Entity] = []
        func walk(_ e: Entity) {
            if e.components[MoverComponent.self] != nil { out.append(e) }
            for child in e.children { walk(child) }
        }
        walk(root)
        return out
    }

    private static func firstAnimated(_ e: Entity) -> Entity? {
        if !e.availableAnimations.isEmpty { return e }
        for child in e.children { if let found = firstAnimated(child) { return found } }
        return nil
    }
}
