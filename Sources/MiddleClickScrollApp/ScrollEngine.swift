import ApplicationServices
import CoreGraphics
import Foundation
import QuartzCore

final class ScrollEngine: @unchecked Sendable {
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "MiddleClickScroll.ScrollEngine", qos: .userInteractive)

    private var configuration = ScrollConfiguration()
    private var anchor = CGPoint.zero
    private var current = CGPoint.zero
    private var velocity = CGPoint.zero
    private var lastTick = CACurrentMediaTime()

    var isActive = false
    var onActiveChanged: ((Bool) -> Void)?

    func updateConfiguration(_ configuration: ScrollConfiguration) {
        queue.async {
            self.configuration = configuration
            if self.isActive {
                self.restartTimer()
            }
        }
    }

    func activate(at point: CGPoint) {
        queue.async {
            self.anchor = point
            self.current = point
            self.velocity = .zero
            self.lastTick = CACurrentMediaTime()
            self.isActive = true
            self.restartTimer()
            let onActiveChanged = self.onActiveChanged
            DispatchQueue.main.async {
                onActiveChanged?(true)
            }
        }
    }

    func deactivate() {
        queue.async {
            self.isActive = false
            self.velocity = .zero
            self.timer?.cancel()
            self.timer = nil
            let onActiveChanged = self.onActiveChanged
            DispatchQueue.main.async {
                onActiveChanged?(false)
            }
        }
    }

    func updatePointer(_ point: CGPoint) {
        queue.async {
            self.current = point
        }
    }

    private func restartTimer() {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        let interval = max(1.0 / max(configuration.frameRate, 30), 1.0 / 240.0)
        timer?.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        timer?.setEventHandler { [weak self] in
            self?.tick()
        }
        timer?.resume()
    }

    private func tick() {
        guard isActive else { return }

        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTick, 1.0 / 240.0), 0.05)
        lastTick = now

        let targetVelocity = computeTargetVelocity()
        let smoothing = min(max(configuration.smoothing, 0.01), 0.95)
        let blend = 1 - pow(1 - smoothing, dt * configuration.frameRate)
        velocity.x += (targetVelocity.x - velocity.x) * blend
        velocity.y += (targetVelocity.y - velocity.y) * blend

        let dx = Int32((velocity.x * dt).rounded())
        let dy = Int32((velocity.y * dt).rounded())

        guard dx != 0 || dy != 0 else { return }
        postScroll(deltaX: dx, deltaY: dy)
    }

    private func computeTargetVelocity() -> CGPoint {
        let deltaX = current.x - anchor.x
        let deltaY = current.y - anchor.y

        let velocityX = configuration.allowHorizontalScroll
            ? velocityComponent(for: deltaX, inverted: configuration.invertHorizontal)
            : 0
        let velocityY = velocityComponent(for: deltaY, inverted: !configuration.invertVertical)

        return CGPoint(x: velocityX, y: velocityY)
    }

    private func velocityComponent(for delta: CGFloat, inverted: Bool) -> CGFloat {
        let distance = Double(abs(delta))
        let deadZone = max(configuration.deadZone, 0)
        guard distance > deadZone else { return 0 }

        let normalized = min((distance - deadZone) / 240.0, 1.0)
        let shaped = pow(normalized, max(configuration.accelerationExponent, 0.2))
        let signed = CGFloat(shaped * configuration.maxVelocity * configuration.scrollScale)
        let direction: CGFloat = (delta >= 0 ? 1 : -1) * (inverted ? -1 : 1)
        return signed * direction
    }

    private func postScroll(deltaX: Int32, deltaY: Int32) {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let event = CGEvent(
                scrollWheelEvent2Source: source,
                units: .pixel,
                wheelCount: 2,
                wheel1: deltaY,
                wheel2: deltaX,
                wheel3: 0
              ) else {
            return
        }

        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)
        event.post(tap: .cghidEventTap)
    }
}
