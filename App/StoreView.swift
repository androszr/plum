import RealityKit
import StoreSimKit
import StoreSimRender
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct StoreView: View {
    @State private var controller = CameraController()
    @GestureState private var lastDrag: CGSize = .zero
    @GestureState private var lastMagnification: Double = 1
    @GestureState private var lastRotation: Angle = .zero
    @State private var viewSize: CGSize = .zero
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var compact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            scene
                .ignoresSafeArea()
            HUDLayer(controller: controller, compact: compact)
        }
    }

    private var scene: some View {
        RealityView { content in
            content.camera = .virtual

            let usdz = (Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "Models") ?? [])
                + (Bundle.main.urls(forResourcesWithExtension: "usdz", subdirectory: "Characters") ?? [])
            let png = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Models") ?? []
            let catalogue = AssetCatalogue(modelURLs: usdz + png)
            // Already registered by StoreSimApp.init; a second call is harmless and covers previews.
            TrafficDriver.register()
            let node = SceneComposer.compose(layout: .plumCorner, detail: .platformDefault, catalogue: catalogue)
            let root = EntityBuilder.entity(for: node, loader: ModelLoader(catalogue: catalogue))
            content.add(root)
            TrafficDriver.startWalkCycles(in: root)

            // A wide, flat pick surface so a click on bare ground clears the selection.
            let ground = Entity()
            ground.name = "ground_pick"
            ground.position = SIMD3(14, -0.1, 10.5)
            ground.components.set(CollisionComponent(shapes: [.generateBox(size: SIMD3(60, 0.2, 50))]))
            ground.components.set(InputTargetComponent())
            content.add(ground)

            let camera = PerspectiveCamera()
            camera.camera.fieldOfViewInDegrees = 45
            camera.camera.far = 400
            content.add(camera)

            let tag = NameTagEntity()
            content.add(tag)
            controller.attach(camera: camera, root: root, tag: tag)
        } update: { _ in
            // Camera moves also apply from the controller itself (didSet); reading it here is a backstop.
            _ = controller.camera
            controller.apply()
        }
        .gesture(
            SpatialTapGesture().targetedToAnyEntity().onEnded { value in
                controller.select(value.entity)
                // Inside, a tap that selected nothing (bare floor, a wall) strolls there.
                if controller.mode == .inside, controller.selection == nil {
                    controller.tapFloor(at: SIMD2(Double(value.location.x), Double(value.location.y)),
                                        viewSize: SIMD2(Double(viewSize.width), Double(viewSize.height)))
                }
            }
        )
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewSize = $0 }
        .simultaneousGesture(dragGesture)
        .simultaneousGesture(magnifyGesture)
        .simultaneousGesture(rotateGesture)
        .background(platformInputCatchers)
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            controller.releaseAllInput()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            controller.releaseAllInput()
        }
        #endif
    }

    // MARK: Gestures

    // The previous value lives in a @GestureState, which resets by itself when a
    // gesture ends or is cancelled, so a cancelled gesture cannot cause a jump.

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($lastDrag) { value, last, _ in
                let delta = CGSize(width: value.translation.width - last.width,
                                   height: value.translation.height - last.height)
                last = value.translation
                #if os(macOS)
                if NSEvent.modifierFlags.contains(.option) {
                    controller.spin(by: delta)
                    return
                }
                #endif
                controller.pan(by: delta)
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($lastMagnification) { value, last, _ in
                controller.zoom(by: value.magnification / last)
                last = value.magnification
            }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .updating($lastRotation) { value, last, _ in
                controller.rotate(by: (value.rotation - last).radians)
                last = value.rotation
            }
    }

    @ViewBuilder private var platformInputCatchers: some View {
        #if os(macOS)
        ScrollZoomCatcher { dy in controller.scroll(by: dy) }
        KeyWalkCatcher(isInside: { controller.mode == .inside },
                       onKey: { key, pressed in controller.setKey(key, pressed: pressed) })
        #elseif os(iOS)
        TwoFingerTiltCatcher { dy in controller.tilt(by: dy) }
            .allowsHitTesting(false)
        #endif
    }
}

#if os(macOS)
/// Reports scroll-wheel and two-finger-scroll movement over the window so it can zoom.
struct ScrollZoomCatcher: NSViewRepresentable {
    var onScroll: @MainActor (Double) -> Void

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) { nsView.onScroll = onScroll }

    final class MonitorView: NSView {
        var onScroll: (@MainActor (Double) -> Void)?
        nonisolated(unsafe) private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                let dy = Double(event.scrollingDeltaY)
                MainActor.assumeIsolated { self?.onScroll?(event.hasPreciseScrollingDeltas ? dy * 0.4 : dy) }
                return event
            }
        }

        deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    }
}

/// W, A, S, D and the arrow keys walk while Inside; a handled key is swallowed so it does not beep.
struct KeyWalkCatcher: NSViewRepresentable {
    var isInside: @MainActor () -> Bool
    var onKey: @MainActor (CameraController.WalkKey, Bool) -> Void

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.isInside = isInside
        view.onKey = onKey
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.isInside = isInside
        nsView.onKey = onKey
    }

    final class MonitorView: NSView {
        var isInside: (@MainActor () -> Bool)?
        var onKey: (@MainActor (CameraController.WalkKey, Bool) -> Void)?
        nonisolated(unsafe) private var monitor: Any?

        private static func walkKey(for code: UInt16) -> CameraController.WalkKey? {
            switch code {
            case 13, 126: .forward   // W, up arrow
            case 1, 125: .back       // S, down arrow
            case 0, 123: .left       // A, left arrow
            case 2, 124: .right      // D, right arrow
            default: nil
            }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
                // Every store window installs a monitor; each one walks only its own window.
                guard event.window === self?.window, let key = Self.walkKey(for: event.keyCode) else { return event }
                let down = event.type == .keyDown
                // Command, Control and Option chords belong to the menus (Cmd-W closes the window).
                if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                    if !down { MainActor.assumeIsolated { self?.onKey?(key, false) } }
                    return event
                }
                let repeated = event.isARepeat
                let handled = MainActor.assumeIsolated { () -> Bool in
                    guard let self, self.isInside?() == true else {
                        // Leaving Inside with a key held must not leave it stuck.
                        if !down { self?.onKey?(key, false) }
                        return false
                    }
                    if !repeated { self.onKey?(key, down) }
                    return true
                }
                return handled ? nil : event
            }
        }

        deinit { if let monitor { NSEvent.removeMonitor(monitor) } }
    }
}
#elseif os(iOS)
/// Two-finger vertical drag tilts the camera; attached to the window's root view so it
/// runs alongside pinch, twist and the one-finger drag.
struct TwoFingerTiltCatcher: UIViewRepresentable {
    var onTilt: @MainActor (Double) -> Void

    func makeUIView(context: Context) -> TiltView {
        let view = TiltView()
        view.onTilt = onTilt
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: TiltView, context: Context) { uiView.onTilt = onTilt }

    final class TiltView: UIView, UIGestureRecognizerDelegate {
        var onTilt: (@MainActor (Double) -> Void)?
        private var pan: UIPanGestureRecognizer?
        private weak var host: UIView?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let pan { host?.removeGestureRecognizer(pan) }
            pan = nil
            guard let host = window?.rootViewController?.view else { return }
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
            recognizer.minimumNumberOfTouches = 2
            recognizer.maximumNumberOfTouches = 2
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            host.addGestureRecognizer(recognizer)
            self.host = host
            pan = recognizer
        }

        @objc private func handle(_ g: UIPanGestureRecognizer) {
            let t = g.translation(in: g.view)
            g.setTranslation(.zero, in: g.view)
            onTilt?(Double(t.y))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
#endif
