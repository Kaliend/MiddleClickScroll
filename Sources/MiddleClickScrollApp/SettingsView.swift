import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 18) {
                header
                permissionSection
                launchSection
                tuningSection
                behaviorSection
                footer
            }
            .padding(20)
            .frame(minWidth: 460, idealWidth: 520, maxWidth: 640, minHeight: 680, alignment: .topLeading)
        }
        .frame(minWidth: 420, minHeight: 560)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Middle Click Scroll")
                .font(.system(size: 28, weight: .semibold))

            Text(appState.isScrollModeActive ? "Scroll mode is active." : "Press the middle mouse button to toggle auto-scroll mode.")
                .foregroundStyle(appState.isScrollModeActive ? .green : .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var permissionSection: some View {
        GroupBox("Permissions") {
            VStack(alignment: .leading, spacing: 10) {
                Text(appState.permissionManager.hasAccessibilityAccess
                     ? "Accessibility access is granted."
                     : "Grant Accessibility access so the app can intercept the middle mouse button and send smooth scroll events.")
                    .foregroundStyle(appState.permissionManager.hasAccessibilityAccess ? .green : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("Re-check Permission") {
                        appState.retryPermissions()
                    }

                    if !appState.permissionManager.hasAccessibilityAccess {
                        Button("Open System Settings") {
                            appState.permissionManager.openAccessibilitySettings()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var launchSection: some View {
        GroupBox("Launch") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Launch at login", isOn: binding(\.launchAtLogin))

                Text(settingsStore.configuration.launchAtLogin
                     ? "MiddleClickScroll will try to start automatically when you log in."
                     : "Enable this to start MiddleClickScroll automatically after login.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let error = appState.launchAtLoginManager.lastErrorMessage {
                    Text("Launch at login update failed: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Open Login Items Settings") {
                        appState.launchAtLoginManager.openLoginItemsSettings()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var tuningSection: some View {
        GroupBox("Scroll Tuning") {
            VStack(spacing: 14) {
                sliderRow(
                    title: "Dead Zone",
                    value: binding(\.deadZone),
                    range: 0...80,
                    format: "%.0f px",
                    help: "How far the cursor must move before scrolling starts."
                )

                sliderRow(
                    title: "Max Speed",
                    value: binding(\.maxVelocity),
                    range: 200...6000,
                    format: "%.0f px/s",
                    help: "Upper limit for generated scroll velocity."
                )

                sliderRow(
                    title: "Acceleration",
                    value: binding(\.accelerationExponent),
                    range: 0.4...3.0,
                    format: "%.2f",
                    help: "Higher values make slow motion gentler and strong motion ramp faster."
                )

                sliderRow(
                    title: "Smoothing",
                    value: binding(\.smoothing),
                    range: 0.02...0.8,
                    format: "%.2f",
                    help: "How quickly the engine follows pointer movement."
                )

                sliderRow(
                    title: "Scale",
                    value: binding(\.scrollScale),
                    range: 0.2...2.5,
                    format: "%.2f×",
                    help: "Global multiplier applied after acceleration."
                )

                sliderRow(
                    title: "Frame Rate",
                    value: binding(\.frameRate),
                    range: 30...240,
                    format: "%.0f Hz",
                    help: "Higher values make synthetic scrolling smoother but use more CPU."
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var behaviorSection: some View {
        GroupBox("Behavior") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Activation button", selection: binding(\.activationButton)) {
                    Text("Middle Button").tag(Int64(2))
                    Text("Button 4").tag(Int64(3))
                    Text("Button 5").tag(Int64(4))
                }

                Toggle("Allow horizontal scrolling", isOn: binding(\.allowHorizontalScroll))
                Toggle("Invert vertical direction", isOn: binding(\.invertVertical))
                Toggle("Invert horizontal direction", isOn: binding(\.invertHorizontal))
                Toggle("Show global resize cursor overlay while auto-scroll is active", isOn: binding(\.showCursorHint))
                Toggle("Show status bar item", isOn: binding(\.showStatusBarItem))
                Toggle("Stop auto-scroll when another mouse button is pressed", isOn: binding(\.stopOnExternalClick))

                HStack {
                    Spacer()
                    Button("Reset Defaults") {
                        settingsStore.configuration = .default
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("Version 1.0  •  Vibecoded by Philip A. Kiulpekidis")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.top, 6)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ScrollConfiguration, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.configuration[keyPath: keyPath] },
            set: { newValue in
                var updated = settingsStore.configuration
                updated[keyPath: keyPath] = newValue
                settingsStore.configuration = updated
            }
        )
    }

    private func sliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        help: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: value, in: range)
            Text(help)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
