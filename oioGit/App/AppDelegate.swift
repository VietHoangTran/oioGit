import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Register default notification preferences
        UserDefaults.standard.register(defaults: [
            "notify_conflict": true,
            "notify_behind_remote": true,
            "notify_stale_changes": false,
            "notify_detached_head": true,
        ])

        // Request notification permission
        NotificationService.shared.requestPermission()

        // Register global hotkey (Control+Shift+G) to activate app
        GlobalHotkeyService.shared.register {
            NSApp.activate(ignoringOtherApps: true)
        }

        // Listen for wake-from-sleep to trigger refresh
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func handleWake() {
        // Post notification for RepoMonitorService to pick up
        NotificationCenter.default.post(
            name: .systemDidWake, object: nil
        )
    }
}

extension Notification.Name {
    static let systemDidWake = Notification.Name("oioGit.systemDidWake")
}
