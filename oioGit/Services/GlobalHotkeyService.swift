import AppKit
import Carbon.HIToolbox

/// Registers a global keyboard shortcut (default: Control+Shift+G)
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

    private func handleKeyEvent(_ event: NSEvent) {
        // Control + Shift + G
        let requiredFlags: NSEvent.ModifierFlags = [.control, .shift]
        let hasFlags = event.modifierFlags.contains(requiredFlags)
        let isG = event.keyCode == UInt16(kVK_ANSI_G)

        if hasFlags && isG {
            DispatchQueue.main.async { [weak self] in
                self?.onToggle?()
            }
        }
    }

    deinit {
        unregister()
    }
}
