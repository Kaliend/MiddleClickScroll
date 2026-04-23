import ApplicationServices
import AppKit
import Foundation

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var hasAccessibilityAccess = false

    init() {
        refresh(prompt: false)
    }

    func refresh(prompt: Bool) {
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        hasAccessibilityAccess = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
