import SwiftUI

struct GeneralSettingsView: View {
    @State private var settings = AppSettings.shared

    private let pollingOptions: [(String, TimeInterval)] = [
        ("30 seconds", 30),
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
    ]

    private let ideOptions = [
        "Visual Studio Code",
        "Cursor",
        "Xcode",
        "Sublime Text",
        "WebStorm",
        "iTerm",
    ]

    var body: some View {
        Form {
            Section("Polling") {
                Picker("Fetch interval", selection: $settings.pollingInterval) {
                    ForEach(pollingOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
            }

            Section("Git") {
                TextField("Git binary path", text: $settings.gitBinaryPath)
                    .font(.system(.body, design: .monospaced))

                if !isValidGitPath {
                    Text("Git binary not found at this path")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("IDE") {
                Picker("Default IDE", selection: $settings.defaultIDE) {
                    ForEach(ideOptions, id: \.self) { ide in
                        Text(ide).tag(ide)
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("Limits") {
                Stepper(
                    "Max repositories: \(settings.maxRepoCount)",
                    value: $settings.maxRepoCount,
                    in: 1...25
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var isValidGitPath: Bool {
        FileManager.default.isExecutableFile(atPath: settings.gitBinaryPath)
    }
}
