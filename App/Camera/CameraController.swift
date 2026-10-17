import Foundation
import Observation
import RealityKit
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
    var selection: Selection?
    /// The Picker binds to this; changing it glides the camera to that view's preset.
    var mode: ViewMode = .outside {
        didSet { if oldValue != mode { switchMode() } }
    }

    @ObservationIgnored private var cameraEntity: PerspectiveCamera?
    @ObservationIgnored private var root: Entity?
    @ObservationIgnored private var tag: NameTagEntity?
    @ObservationIgnored private var selectedEntity: Entity?
    @ObservationIgnored private var shellCandidates: [String: Entity] = [:]
    @ObservationIgnored private var animation: Task<Void, Never>?

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
        apply()
    }

    // MARK: Gestures (deltas, in points or ratios)

    func pan(by delta: CGSize) {
        cancelAnimation()
        let k = camera.distance * panFactor
        camera.pan(by: SIMD2(-Double(delta.width) * k, Double(delta.height) * k))
    }

    func zoom(by ratio: Double) {
        cancelAnimation()
        guard ratio.isFinite, ratio > 0 else { return }
        camera.zoom(by: 1 / ratio)
    }

    func scroll(by dy: Double) {
        cancelAnimation()
        camera.zoom(by: exp(-dy * 0.01))
    }

    func rotate(by radians: Double) {
        cancelAnimation()
        camera.rotate(by: -radians)
    }

    func spin(by delta: CGSize) {
        cancelAnimation()
        camera.rotate(by: -Double(delta.width) * 0.008)
        camera.tilt(by: Double(delta.height) * 0.005)
    }

    func tilt(by points: Double) {
        cancelAnimation()
        camera.tilt(by: points * 0.005)
    }

    // MARK: Turning and view modes

    func turnLeft() { animate(to: camera.turned(by: 1), duration: 0.35) }
    func turnRight() { animate(to: camera.turned(by: -1), duration: 0.35) }

    private func switchMode() {
        animate(to: .preset(for: mode, lot: StoreLayout.plumCorner.lot), duration: 0.6)
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
        cameraEntity?.look(at: SIMD3<Float>(camera.target), from: SIMD3<Float>(camera.position), relativeTo: nil as Entity?)
        if let root { EntityBuilder.applyRoofOpacity(root: root, camera: camera) }
        let hidden = InteriorVisibility.hiddenNames(mode: mode, candidates: Array(shellCandidates.keys),
                                                    camera: camera, lot: StoreLayout.plumCorner.lot)
        EntityBuilder.applyShellVisibility(hidden: hidden, in: shellCandidates)
        updateTag()
    }

    private func updateTag() {
        guard let selection, let entity = selectedEntity, let tag else { return }
        let scale = Float(max(0.6, camera.distance / 22))
        tag.show(over: entity.visualBounds(relativeTo: nil), text: selection.displayName,
                 cameraYaw: Float(camera.yaw), scale: scale)
    }
}
