import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private weak var appState: AppState?
    private var didFinishLaunching = false
    private var cancellables = Set<AnyCancellable>()

    func configure(appState: AppState) {
        self.appState = appState
        cancellables.removeAll()
        appState.settingsStore.$configuration
            .map(\.showStatusBarItem)
            .removeDuplicates()
            .sink { [weak self] isVisible in
                self?.setStatusItemVisible(isVisible)
            }
            .store(in: &cancellables)

        if didFinishLaunching {
            appState.start()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        didFinishLaunching = true
        setStatusItemVisible(appState?.settingsStore.configuration.showStatusBarItem ?? true)
        appState?.start()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState?.stop()
    }

    private func setStatusItemVisible(_ isVisible: Bool) {
        if isVisible {
            guard statusItem == nil else { return }

            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let iconURL = Bundle.main.url(forResource: "StatusBarIcon", withExtension: "png"),
               let icon = NSImage(contentsOf: iconURL) {
                icon.isTemplate = true
                icon.size = NSSize(width: 19, height: 19)
                item.button?.image = icon
                item.button?.imagePosition = .imageOnly
                item.button?.imageScaling = .scaleProportionallyDown
                item.button?.title = ""
            } else {
                item.button?.title = "MCS"
            }

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            item.menu = menu

            statusItem = item
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
}
