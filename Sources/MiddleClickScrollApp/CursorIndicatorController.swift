import AppKit
import Foundation

enum CursorIndicatorKind {
    case hidden
    case neutral
    case north
    case south
}

struct CursorIndicatorState {
    var kind: CursorIndicatorKind
    var anchor: CGPoint
}

@MainActor
final class CursorIndicatorController {
    private let imageView = NSImageView()
    private lazy var window: NSWindow = makeWindow()

    func update(state: CursorIndicatorState, configuration: ScrollConfiguration) {
        guard configuration.showCursorHint, state.kind != .hidden else {
            deactivate()
            return
        }

        imageView.image = image(for: state.kind)
        positionWindow(around: state.anchor)
        window.orderFrontRegardless()
    }

    func deactivate() {
        guard window.isVisible else { return }
        window.orderOut(nil)
    }

    private func makeWindow() -> NSWindow {
        let frame = NSRect(x: 0, y: 0, width: 48, height: 48)
        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.contentView = imageView

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true

        return window
    }

    private func positionWindow(around point: CGPoint) {
        let screenPoint = screenPoint(fromEventPoint: point)
        let size = window.frame.size
        let origin = CGPoint(x: screenPoint.x - size.width / 2, y: screenPoint.y - size.height / 2)
        window.setFrame(CGRect(origin: origin, size: size), display: true)
    }

    private func screenPoint(fromEventPoint point: CGPoint) -> CGPoint {
        let desktopBounds = NSScreen.screens.reduce(into: CGRect.null) { partialResult, screen in
            partialResult = partialResult.union(screen.frame)
        }

        guard !desktopBounds.isNull else { return point }
        return CGPoint(x: point.x, y: desktopBounds.maxY - point.y)
    }

    private func image(for kind: CursorIndicatorKind) -> NSImage {
        switch kind {
        case .hidden:
            return NSImage()
        case .neutral:
            return NSCursor.resizeUpDown.image
        case .north:
            return NSCursor.resizeUp.image
        case .south:
            return NSCursor.resizeDown.image
        }
    }
}
