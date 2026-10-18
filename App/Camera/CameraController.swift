import Foundation
import Observation
import RealityKit
import simd
import StoreSimKit
import StoreSimRender

struct Selection: Equatable {
    var nodeName: String
    var displayName: String
    var kindName: String
}

/// Turns gesture deltas into camera moves and keeps the entities in step with them.
@Observable
@MainActor
final class CameraController {
    /// Every change goes straight to the camera entity and the roof, so the view's
    /// update closure never has to be the thing that notices a camera move.
    var camera: OrbitCamera = .isoPreset {
        didSet { apply() }
    }
    /// The Inside camera: a first-person walk over the shop floor.
    var walk: WalkCamera = .preset(lot: StoreLayout.plumCorner.lot, floor: WalkableFloor(layout: .plumCorner)) {
        didSet { apply() }
    }
    var selection: Selection?
    /// The Picker binds to this; changing it glides the camera to that view's preset.
    var mode: ViewMode = .outside {
        didSet { if oldValue != mode { switchMode(from: oldValue) } }
    }

    @ObservationIgnored private var cameraEntity: PerspectiveCamera?
    @ObservationIgnored private var root: Entity?
    @ObservationIgnored private var tag: NameTagEntity?
    @ObservationIgnored private var selectedEntity: Entity?
    @ObservationIgnored private var shellCandidates: [String: Entity] = [:]
    @ObservationIgnored private var entranceDoor: Entity?
    @ObservationIgnored private var animation: Task<Void, Never>?
    @ObservationIgnored private var walkLoop: Task<Void, Never>?
    @ObservationIgnored private var glide: CameraPose?
    /// The mode whose shell visibility applies: the destination while a glide runs.
    @ObservationIgnored private var visibilityMode: ViewMode = .outside
    @ObservationIgnored private var heldKeys: Set<WalkKey> = []
    @ObservationIgnored private var stick: SIMD2<Double> = .zero
    @ObservationIgnored private var walkInput: SIMD2<Double> = .zero
    @ObservationIgnored let floor = WalkableFloor(layout: .plumCorner)

    enum WalkKey: Hashable { case forward, back, left, right }

    /// Where the eye is now, whichever camera is driving.
    var pose: CameraPose { glide ?? (mode == .inside ? walk.pose : camera.pose) }

    #if os(macOS)
    private let panFactor = 0.0016
    #else
    private let panFactor = 0.0022
    #endif

    func attach(camera entity: PerspectiveCamera, root: Entity, tag: NameTagEntity) {
        cameraEntity = entity
        self.root = root
        self.tag = tag
        shellCandidates = EntityBuilder.shellCandidates(in: root)
        entranceDoor = root.findEntity(named: "entrance_door_1")
        apply()
    }

    // MARK: Gestures (deltas, in points or ratios)

    /// A drag from `from` to `to` (view points, y down). Outside, the ground under the pointer stays under it;
    /// Inside, a sideways drag turns the view with the hand; the view stays level.
    func drag(from: CGPoint, to: CGPoint, viewSize: CGSize) {
        guard glide == nil else { return }
        cancelAnimation()
        let delta = CGSize(width: to.x - from.x, height: to.y - from.y)
        if mode == .inside {
            walk.look(by: Double(delta.width), viewSize: SIMD2(Double(viewSize.width), Double(viewSize.height)))
            return
        }
        let size = SIMD2(Double(viewSize.width), Double(viewSize.height))
        if size.x > 0, size.y > 0,
           camera.drag(from: SIMD2(Double(from.x), Double(from.y)), to: SIMD2(Double(to.x), Double(to.y)), viewSize: size) {
            return
        }
        // Above the horizon there is no ground to hold: slide by the distance instead, the same way round.
        let k = camera.distance * panFactor
        camera.pan(by: SIMD2(-Double(delta.width) * k, Double(delta.height) * k))
    }

    /// There is no zoom in a walk: pinch does nothing Inside.
    func zoom(by ratio: Double) {
        guard glide == nil else { return }
        cancelAnimation()
        if mode == .inside { return }
        guard ratio.isFinite, ratio > 0 else { return }
        camera.zoom(by: 1 / ratio)
    }

    /// Two fingers on a trackpad (`precise`) move the camera over the lot like a drag from the middle of the
    /// view; a mouse wheel, or any scroll with Command held, zooms. Inside, two fingers look around (sideways
    /// turns, up and down tilts) and never walk: walking is W, A, S, D.
    func scroll(dx: Double, dy: Double, precise: Bool, viewSize: CGSize) {
        guard glide == nil else { return }
        if mode == .inside {
            guard precise else { return }
            cancelAnimation()
            let size = SIMD2(Double(viewSize.width), Double(viewSize.height))
            walk.look(by: dx, viewSize: size)
            walk.tilt(by: dy, viewSize: size)
            return
        }
        if precise {
            let centre = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            drag(from: centre, to: CGPoint(x: centre.x + dx, y: centre.y + dy), viewSize: viewSize)
            return
        }
        cancelAnimation()
        camera.zoom(by: exp(-dy * 0.01))
    }

    func rotate(by radians: Double) {
        guard glide == nil else { return }
        cancelAnimation()
        if mode == .inside {
            walk.turn(by: -radians)
            return
        }
        camera.rotate(by: -radians)
    }

    func spin(by delta: CGSize) {
        guard glide == nil else { return }
        cancelAnimation()
        if mode == .inside {
            walk.turn(by: Double(delta.width) * 0.008)
            return
        }
        camera.rotate(by: -Double(delta.width) * 0.008)
        camera.tilt(by: Double(delta.height) * 0.005)
    }

    func tilt(by points: Double) {
        guard glide == nil else { return }
        cancelAnimation()
        // Inside the view stays level.
        if mode == .inside { return }
        camera.tilt(by: points * 0.005)
    }

    // MARK: Turning and view modes

    func turnLeft() { turn(steps: 1) }
    func turnRight() { turn(steps: -1) }

    private func turn(steps: Int) {
        guard glide == nil else { return }
        if mode == .inside {
            animateWalk(to: walk.turned(by: steps), duration: 0.35)
        } else {
            animate(to: camera.turned(by: steps), duration: 0.35)
        }
    }

    private func switchMode(from oldMode: ViewMode) {
        walkInput = .zero
        heldKeys = []
        stick = .zero
        walkLoop?.cancel()
        walkLoop = nil
        let lot = StoreLayout.plumCorner.lot
        let destinationWalk = WalkCamera.preset(lot: lot, floor: floor)
        let destinationOrbit = OrbitCamera.preset(for: .outside, lot: lot)
        let from = glide ?? (oldMode == .inside ? walk.pose : camera.pose)
        let to = mode == .inside ? destinationWalk.pose : destinationOrbit.pose
        let destinationMode = mode
        cancelAnimation()
        // Inside rules (roof and front hidden) hold for the whole glide, in either direction.
        visibilityMode = .inside
        glide = from
        apply()
        let tween = PoseTween(from: from, to: to, duration: 0.6)
        animation = Task { @MainActor [weak self] in
            let start = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled, let self else { return }
                let elapsed = (ContinuousClock.now - start) / .seconds(1)
                if elapsed >= tween.duration {
                    self.visibilityMode = destinationMode
                    self.glide = nil
                    self.animation = nil
                    if destinationMode == .inside { self.walk = destinationWalk } else { self.camera = destinationOrbit }
                    return
                }
                self.glide = tween.value(at: elapsed)
                self.apply()
            }
        }
    }

    func cancelAnimation() {
        animation?.cancel()
        animation = nil
    }

    /// Glides to `destination`. A turn pressed mid-swing starts from where the camera is now.
    private func animate(to destination: OrbitCamera, duration: Double) {
        cancelAnimation()
        let tween = CameraTween(from: camera, to: destination, duration: duration)
        animation = Task { @MainActor [weak self] in
            let start = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled, let self else { return }
                let elapsed = (ContinuousClock.now - start) / .seconds(1)
                if elapsed >= duration {
                    self.camera = tween.to
                    self.animation = nil
                    return
                }
                self.camera = tween.value(at: elapsed)
            }
        }
    }

    /// The same smoothstep swing for the walk camera; position and route are kept.
    private func animateWalk(to destination: WalkCamera, duration: Double) {
        cancelAnimation()
        let from = walk
        animation = Task { @MainActor [weak self] in
            let start = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled, let self else { return }
                let elapsed = (ContinuousClock.now - start) / .seconds(1)
                var next: WalkCamera
                if elapsed >= duration {
                    next = destination
                } else {
                    let x = elapsed / duration
                    next = from.interpolated(to: destination, t: x * x * (3 - 2 * x))
                }
                next.position = self.walk.position
                next.route = self.walk.route
                self.walk = next
                if elapsed >= duration {
                    self.animation = nil
                    return
                }
            }
        }
    }

    // MARK: Walking

    /// Drops every held key and the stick, e.g. when the window loses focus mid-press.
    func releaseAllInput() {
        heldKeys = []
        stick = .zero
        refreshWalkInput()
    }

    func setKey(_ key: WalkKey, pressed: Bool) {
        if pressed { heldKeys.insert(key) } else { heldKeys.remove(key) }
        refreshWalkInput()
    }

    func setStick(_ vector: SIMD2<Double>) {
        let len = simd_length(vector)
        if len < 0.15 {
            stick = .zero
        } else {
            stick = len > 1 ? vector / len : vector
        }
        refreshWalkInput()
    }

    private func refreshWalkInput() {
        var key = SIMD2<Double>(0, 0)
        if heldKeys.contains(.forward) { key.y += 1 }
        if heldKeys.contains(.back) { key.y -= 1 }
        if heldKeys.contains(.right) { key.x += 1 }
        if heldKeys.contains(.left) { key.x -= 1 }
        var total = key + stick
        let len = simd_length(total)
        if len > 1 { total /= len }
        walkInput = total
        startWalkLoopIfNeeded()
    }

    func startWalkLoopIfNeeded() {
        guard mode == .inside, walkLoop == nil, walkInput != .zero || walk.isStrolling else { return }
        walkLoop = Task { @MainActor [weak self] in
            var last = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled, let self else { return }
                let now = ContinuousClock.now
                let dt = min((now - last) / .seconds(1), 0.1)
                last = now
                guard self.mode == .inside else { break }
                if self.walkInput != .zero {
                    self.walk.walk(input: self.walkInput, dt: dt, on: self.floor)
                } else if self.walk.isStrolling {
                    self.walk.advance(dt: dt, on: self.floor)
                } else {
                    break
                }
            }
            self?.walkLoop = nil
        }
    }

    /// A tap on bare floor strolls there; a point off the floor is ignored.
    func tapFloor(at tap: SIMD2<Double>, viewSize: SIMD2<Double>) {
        guard mode == .inside, glide == nil,
              let point = WalkCamera.floorPoint(pose: walk.pose, tap: tap, viewSize: viewSize) else { return }
        if walk.stroll(to: point, on: floor) { startWalkLoopIfNeeded() }
    }

    // MARK: Selection

    func select(_ entity: Entity?) {
        var cursor = entity
        while let e = cursor {
            if let s = e.components[SelectableComponent.self] {
                let kind = StoreLayout.plumCorner.fixtures.first { $0.id == s.nodeName }?.kind.displayName ?? ""
                selection = Selection(nodeName: s.nodeName, displayName: s.displayName, kindName: kind)
                selectedEntity = e
                updateTag()
                return
            }
            cursor = e.parent
        }
        clearSelection()
    }

    func clearSelection() {
        selection = nil
        selectedEntity = nil
        tag?.hide()
    }

    // MARK: Applying state to entities

    func apply() {
        let pose = self.pose
        cameraEntity?.look(at: SIMD3<Float>(pose.target), from: SIMD3<Float>(pose.eye), relativeTo: nil as Entity?)
        if let root { EntityBuilder.applyRoofOpacity(root: root, camera: camera) }
        let hidden = InteriorVisibility.hiddenNames(mode: visibilityMode, candidates: Array(shellCandidates.keys),
                                                    eye: pose.eye, lot: StoreLayout.plumCorner.lot)
        EntityBuilder.applyShellVisibility(hidden: hidden, in: shellCandidates)
        // The eye crosses the doorway during a glide; keep it from passing through a door leaf.
        if let door = entranceDoor {
            let on = glide == nil
            if door.isEnabled != on { door.isEnabled = on }
        }
        updateTag()
    }

    private func updateTag() {
        guard let selection, let entity = selectedEntity, let tag else { return }
        let bounds = entity.visualBounds(relativeTo: nil)
        let distance = pose.distance(to: SIMD3<Double>(bounds.center))
        tag.show(over: bounds, text: selection.displayName,
                 cameraYaw: Float(pose.heading), scale: Float(max(0.6, distance / 22)))
    }
}
