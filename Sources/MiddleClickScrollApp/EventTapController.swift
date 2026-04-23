import ApplicationServices
import CoreGraphics
import Foundation

final class EventTapController {
    private let engine: ScrollEngine
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var configuration = ScrollConfiguration()
    private var isScrollModeActive = false
    private var anchorPoint = CGPoint.zero

    var onIndicatorStateChanged: (@MainActor (CursorIndicatorState) -> Void)?

    init(engine: ScrollEngine) {
        self.engine = engine
    }

    func updateConfiguration(_ configuration: ScrollConfiguration) {
        self.configuration = configuration
    }

    func start() {
        stop()

        let mask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let controller = Unmanaged<EventTapController>.fromOpaque(refcon).takeUnretainedValue()
            return controller.handle(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        engine.deactivate()
        isScrollModeActive = false
        publishIndicatorState(kind: .hidden)

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        let location = event.location
        let configuration = configuration

        switch type {
        case .otherMouseDown where button == configuration.activationButton:
            if isScrollModeActive {
                isScrollModeActive = false
                engine.deactivate()
                publishIndicatorState(kind: .hidden)
            } else {
                isScrollModeActive = true
                anchorPoint = location
                engine.activate(at: location)
                publishIndicatorState(kind: .neutral, anchor: location)
            }
            return nil

        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            if isScrollModeActive {
                engine.updatePointer(location)
                publishIndicatorState(kind: indicatorKind(for: location), anchor: anchorPoint)
            }
            return Unmanaged.passUnretained(event)

        case .leftMouseDown, .rightMouseDown:
            if isScrollModeActive && configuration.stopOnExternalClick {
                isScrollModeActive = false
                engine.deactivate()
                publishIndicatorState(kind: .hidden)
                return nil
            }
            return Unmanaged.passUnretained(event)

        case .otherMouseDown:
            if isScrollModeActive && configuration.stopOnExternalClick {
                isScrollModeActive = false
                engine.deactivate()
                publishIndicatorState(kind: .hidden)
                return nil
            }
            return Unmanaged.passUnretained(event)

        case .otherMouseUp where button == configuration.activationButton:
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func indicatorKind(for point: CGPoint) -> CursorIndicatorKind {
        let deltaY = point.y - anchorPoint.y
        if deltaY > 1 {
            return .north
        }
        if deltaY < -1 {
            return .south
        }
        return .neutral
    }

    private func publishIndicatorState(kind: CursorIndicatorKind, anchor: CGPoint? = nil) {
        guard let onIndicatorStateChanged else { return }
        let state = CursorIndicatorState(kind: kind, anchor: anchor ?? anchorPoint)
        DispatchQueue.main.async {
            onIndicatorStateChanged(state)
        }
    }
}
