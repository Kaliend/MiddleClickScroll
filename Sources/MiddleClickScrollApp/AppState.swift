import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    let settingsStore = SettingsStore()
    let permissionManager = PermissionManager()
    let launchAtLoginManager = LaunchAtLoginManager()
    let scrollEngine = ScrollEngine()
    let cursorIndicator = CursorIndicatorController()

    @Published private(set) var isScrollModeActive = false

    private var eventTapController: EventTapController?
    private var cancellables = Set<AnyCancellable>()

    init() {
        eventTapController = EventTapController(engine: scrollEngine)
        eventTapController?.onIndicatorStateChanged = { [weak self] state in
            guard let self else { return }
            self.cursorIndicator.update(state: state, configuration: self.settingsStore.configuration)
        }

        scrollEngine.onActiveChanged = { [weak self] isActive in
            guard let self else { return }
            self.isScrollModeActive = isActive
            if !isActive {
                self.cursorIndicator.deactivate()
            }
        }

        settingsStore.$configuration
            .sink { [weak self] configuration in
                self?.scrollEngine.updateConfiguration(configuration)
                self?.eventTapController?.updateConfiguration(configuration)
                if let self, !configuration.showCursorHint || !self.isScrollModeActive {
                    self.cursorIndicator.deactivate()
                }
            }
            .store(in: &cancellables)

        settingsStore.$configuration
            .map(\.launchAtLogin)
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.launchAtLoginManager.apply(enabled: isEnabled)
            }
            .store(in: &cancellables)

        scrollEngine.updateConfiguration(settingsStore.configuration)
        eventTapController?.updateConfiguration(settingsStore.configuration)
        launchAtLoginManager.refresh()

        if settingsStore.configuration.launchAtLogin != launchAtLoginManager.isEnabled {
            var updated = settingsStore.configuration
            updated.launchAtLogin = launchAtLoginManager.isEnabled
            settingsStore.configuration = updated
        }
    }

    func start() {
        permissionManager.refresh(prompt: true)
        guard permissionManager.hasAccessibilityAccess else { return }
        eventTapController?.start()
    }

    func retryPermissions() {
        permissionManager.refresh(prompt: true)
        if permissionManager.hasAccessibilityAccess {
            eventTapController?.start()
        }
    }

    func stop() {
        eventTapController?.stop()
        cursorIndicator.deactivate()
    }
}
