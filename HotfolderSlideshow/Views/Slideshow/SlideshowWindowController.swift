import AppKit
import AVFoundation
import AVKit

/// Manages the fullscreen slideshow window displayed on the target monitor.
/// Uses AppKit directly for precise multi-monitor control.
@MainActor
final class SlideshowWindowController {
    private var window: NSWindow?
    private var slideshowView: SlideshowContainerView?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Window Lifecycle

    func showOnScreen(_ screen: NSScreen) {
        if window == nil {
            createWindow()
        }

        guard let window = window else { return }

        // Position the window on the target screen
        window.setFrame(screen.frame, display: true)
        window.makeKeyAndOrderFront(nil)

        // Enter fullscreen (kiosk-style: borderless covering the entire screen)
        // We use a borderless window at screen size rather than native fullscreen
        // to avoid the macOS fullscreen animation and space-switching behavior
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func moveToScreen(_ screen: NSScreen) {
        window?.setFrame(screen.frame, display: true, animate: false)
    }

    func close() {
        slideshowView?.cleanup()
        window?.orderOut(nil)
        window = nil
        slideshowView = nil
    }

    // MARK: - Content Display

    func displayImage(_ image: NSImage, transitionDuration: Double) {
        slideshowView?.showImage(image, transitionDuration: transitionDuration)
    }

    func displayVideo(player: AVPlayer, transitionDuration: Double) {
        slideshowView?.showVideo(player: player, transitionDuration: transitionDuration)
    }

    // MARK: - Private

    private func createWindow() {
        let containerView = SlideshowContainerView(frame: .zero)
        containerView.appState = appState
        self.slideshowView = containerView

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.contentView = containerView
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.acceptsMouseMovedEvents = false
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false

        // Hide cursor when hovering over the slideshow
        window.contentView?.addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: containerView,
            userInfo: nil
        ))

        self.window = window
    }
}

// MARK: - SlideshowContainerView

/// The NSView that hosts slideshow content with crossfade transitions.
final class SlideshowContainerView: NSView {
    weak var appState: AppState?

    private var currentImageLayer: CALayer?
    private var playerView: AVPlayerView?
    private var isShowingVideo: Bool = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    // MARK: - Keyboard Handling

    override func keyDown(with event: NSEvent) {
        guard let appState = appState else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case 49: // Space
            Task { @MainActor in appState.togglePlayPause() }
        case 124: // Right arrow
            Task { @MainActor in appState.nextSlide() }
        case 123: // Left arrow
            Task { @MainActor in appState.previousSlide() }
        case 53: // Escape
            Task { @MainActor in appState.stop() }
        case 46: // M key
            Task { @MainActor in appState.videoAudioEnabled.toggle() }
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Cursor Hiding

    override func mouseEntered(with event: NSEvent) {
        NSCursor.hide()
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.unhide()
    }

    // MARK: - Content Display

    func showImage(_ image: NSImage, transitionDuration: Double) {
        // Remove video view if showing
        if isShowingVideo {
            removeVideoView(animated: true, duration: transitionDuration)
            isShowingVideo = false
        }

        // Create new image layer
        let newLayer = CALayer()
        newLayer.contentsGravity = .resizeAspect
        newLayer.contents = image
        newLayer.frame = bounds
        newLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        newLayer.opacity = 0

        layer?.addSublayer(newLayer)

        // Crossfade: fade in new, fade out old
        CATransaction.begin()
        CATransaction.setAnimationDuration(transitionDuration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))

        newLayer.opacity = 1

        let oldLayer = currentImageLayer
        oldLayer?.opacity = 0

        CATransaction.setCompletionBlock {
            oldLayer?.removeFromSuperlayer()
        }
        CATransaction.commit()

        currentImageLayer = newLayer
    }

    func showVideo(player: AVPlayer, transitionDuration: Double) {
        // Fade out current image
        if let imageLayer = currentImageLayer {
            CATransaction.begin()
            CATransaction.setAnimationDuration(transitionDuration)
            imageLayer.opacity = 0
            CATransaction.setCompletionBlock {
                imageLayer.removeFromSuperlayer()
            }
            CATransaction.commit()
            currentImageLayer = nil
        }

        // Remove old player view
        removeVideoView(animated: false, duration: 0)

        // Create new AVPlayerView
        let pv = AVPlayerView()
        pv.player = player
        pv.controlsStyle = .none
        pv.videoGravity = .resizeAspect
        pv.frame = bounds
        pv.autoresizingMask = [.width, .height]
        pv.alphaValue = 0

        addSubview(pv)

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = transitionDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pv.animator().alphaValue = 1
        }

        playerView = pv
        isShowingVideo = true
    }

    func cleanup() {
        currentImageLayer?.removeFromSuperlayer()
        currentImageLayer = nil
        removeVideoView(animated: false, duration: 0)
        NSCursor.unhide()
    }

    // MARK: - Private

    private func removeVideoView(animated: Bool, duration: Double) {
        guard let pv = playerView else { return }

        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = duration
                pv.animator().alphaValue = 0
            }, completionHandler: {
                pv.player = nil
                pv.removeFromSuperview()
            })
        } else {
            pv.player = nil
            pv.removeFromSuperview()
        }
        playerView = nil
    }
}
