import Foundation
import RealityKit
import simd
import StoreSimKit

/// Marks an entity that follows a route; `elapsed` is the clock the route is read at.
public struct MoverComponent: Component {
    public var mover: Mover
    public var elapsed: Double
    /// The walk clip, once started, so its rate can follow the walker's speed.
    public var walk: AnimationPlaybackController?
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
    /// The scale of a mover waiting off the lot: too small to see, cast a shadow or catch a click.
    public static let hiddenScale: Float = 0.0001

    /// Registers the component and the system. Safe to call twice; call it before the scene is populated.
    public static func register() {
        guard !registered else { return }
        registered = true
        MoverComponent.registerComponent()
        TrafficSystem.registerSystem()
    }

    /// Moves one entity to where its route puts it at `time`, fades it at the lot edge, shrinks it away
    /// while it waits off the lot, and plays its walk at the rate of its speed. Does nothing without a
    /// `MoverComponent`. A waiting mover stays enabled: a disabled entity's walk clip stops.
    public static func place(_ entity: Entity, at time: Double) {
        guard let component = entity.components[MoverComponent.self] else { return }
        let pose = Traffic.pose(of: component.mover, at: time)
        entity.position = SIMD3<Float>(pose.position)
        entity.orientation = simd_quatf(angle: Float(pose.yaw), axis: SIMD3(0, 1, 0))
        if pose.visibility < 1 {
            entity.components.set(OpacityComponent(opacity: Float(pose.visibility)))
        } else if entity.components.has(OpacityComponent.self) {
            entity.components.remove(OpacityComponent.self)
        }
        entity.scale = SIMD3(repeating: pose.visibility > 0 ? 1 : hiddenScale)
        if let walk = component.walk, pose.speed > 0 {
            walk.speed = Float(Traffic.walkCycleRate(at: pose.speed))
        }
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
            if var component = entity.components[MoverComponent.self] {
                component.walk = playback
                entity.components.set(component)
            }
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
