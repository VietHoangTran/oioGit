import SwiftUI
import Carbon.HIToolbox

struct HotkeyRecorderView: View {
    @State private var settings = AppSettings.shared
    @State private var isRecording = false
    @State private var conflictWarning: String?
    @State private var localMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                hotkeyDisplay
                Spacer()
                recordButton
                resetButton
            }

            if let warning = conflictWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var hotkeyDisplay: some View {
        Text(settings.hotkeyConfig.displayString)
            .font(.system(.title2, design: .rounded, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isRecording ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRecording ? Color.accentColor : .clear, lineWidth: 2)
                    )
            )
    }

    private var recordButton: some View {
        Button(isRecording ? "Press keys..." : "Record") {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }
        .buttonStyle(.bordered)
    }

    private var resetButton: some View {
        Button("Reset") {
            settings.hotkeyConfig = .default
            conflictWarning = nil
            GlobalHotkeyService.shared.reregister()
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
    }

    private func startRecording() {
        isRecording = true
        conflictWarning = nil

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleRecordedKey(event)
            return nil // consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleRecordedKey(_ event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Escape cancels recording
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }

        // Must have at least one modifier (Control, Option, or Command)
        let hasModifier = mods.contains(.control)
            || mods.contains(.option)
            || mods.contains(.command)

        guard hasModifier else {
            conflictWarning = "Shortcut must include Control, Option, or Command"
            return
        }

        // Must not be a pure modifier key press
        guard HotkeyConfig.keyCodeNames[Int(event.keyCode)] != nil else {
            return
        }

        let newConfig = HotkeyConfig(
            modifierFlags: mods.rawValue,
            keyCode: event.keyCode
        )

        // Check for known system conflicts
        let readable = newConfig.readableString
        if HotkeyDefaults.systemConflicts.contains(readable) {
            conflictWarning = "Warning: \(readable) may conflict with a system shortcut"
        } else {
            conflictWarning = nil
        }

        settings.hotkeyConfig = newConfig
        GlobalHotkeyService.shared.reregister()
        stopRecording()
    }
}

#Preview {
    HotkeyRecorderView()
        .padding()
        .frame(width: 400)
}
