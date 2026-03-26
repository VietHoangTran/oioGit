import AppKit
import Carbon.HIToolbox

/// Registers a global keyboard shortcut (configurable, default: Control+Shift+G)
/// to toggle the menu bar popover.
final class GlobalHotkeyService {
    static let shared = GlobalHotkeyService()

    private var eventMonitor: Any?
    private var onToggle: (() -> Void)?

    private init() {}

    func register(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        unregister()

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            self?.handleKeyEvent(event)
        }
    }

    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Re-register with updated hotkey from AppSettings
    func reregister() {
        guard let callback = onToggle else { return }
        register(onToggle: callback)
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let config = AppSettings.shared.hotkeyConfig
        if config.matches(event) {
            DispatchQueue.main.async { [weak self] in
                self?.onToggle?()
            }
        }
    }

    deinit {
        unregister()
    }
}
