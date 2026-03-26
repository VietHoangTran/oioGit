import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notify_conflict") private var conflictEnabled = true
    @AppStorage("notify_behind_remote") private var behindEnabled = true
    @AppStorage("notify_stale_changes") private var staleEnabled = false
    @AppStorage("notify_detached_head") private var detachedEnabled = true

    var body: some View {
        Form {
            Section("Notification Types") {
                Toggle(isOn: $conflictEnabled) {
                    notificationRow(
                        type: .conflict,
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                }

                Toggle(isOn: $behindEnabled) {
                    notificationRow(
                        type: .behindRemote,
                        icon: "arrow.down.circle.fill",
                        color: .blue
                    )
                }

                Toggle(isOn: $staleEnabled) {
                    notificationRow(
                        type: .staleChanges,
                        icon: "clock.fill",
                        color: .orange
                    )
                }

                Toggle(isOn: $detachedEnabled) {
                    notificationRow(
                        type: .detachedHead,
                        icon: "exclamationmark.circle.fill",
                        color: .purple
                    )
                }
            }

            Section {
                Text("Notifications respect system Do Not Disturb settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func notificationRow(
        type: NotificationType, icon: String, color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(type.title)
                    .font(.body)
                Text(type.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
