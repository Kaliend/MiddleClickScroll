import CoreGraphics
import Foundation

struct ScrollConfiguration: Codable {
    var activationButton: Int64 = 2
    var deadZone: Double = 16
    var maxVelocity: Double = 2200
    var accelerationExponent: Double = 1.65
    var smoothing: Double = 0.18
    var scrollScale: Double = 1.0
    var allowHorizontalScroll: Bool = true
    var invertVertical: Bool = false
    var invertHorizontal: Bool = false
    var stopOnExternalClick: Bool = true
    var showCursorHint: Bool = true
    var showStatusBarItem: Bool = true
    var launchAtLogin: Bool = false
    var frameRate: Double = 120

    static let `default` = ScrollConfiguration()
}

@MainActor
final class SettingsStore: ObservableObject {
    static let storageKey = "scrollConfiguration"

    @Published var configuration: ScrollConfiguration {
        didSet { persist() }
    }

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ScrollConfiguration.self, from: data) {
            configuration = decoded
        } else {
            configuration = ScrollConfiguration()
        }
    }

    private func persist(defaults: UserDefaults = .standard) {
        guard let encoded = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(encoded, forKey: Self.storageKey)
    }
}
