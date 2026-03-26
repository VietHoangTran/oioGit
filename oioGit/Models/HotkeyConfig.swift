import AppKit
import Carbon.HIToolbox

struct HotkeyConfig: Codable, Sendable, Equatable {
    var modifierFlags: UInt
    var keyCode: UInt16

    static let `default` = HotkeyConfig(
        modifierFlags: NSEvent.ModifierFlags([.control, .shift]).rawValue,
        keyCode: UInt16(kVK_ANSI_G)
    )

    var displayString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        if flags.contains(.control) { parts.append("^") }
        if flags.contains(.option) { parts.append("\u{2325}") }
        if flags.contains(.shift) { parts.append("\u{21E7}") }
        if flags.contains(.command) { parts.append("\u{2318}") }
        parts.append(keyCodeName)
        return parts.joined()
    }

    var readableString: String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        if flags.contains(.control) { parts.append("Control") }
        if flags.contains(.option) { parts.append("Option") }
        if flags.contains(.shift) { parts.append("Shift") }
        if flags.contains(.command) { parts.append("Command") }
        parts.append(keyCodeName)
        return parts.joined(separator: " + ")
    }

    func matches(_ event: NSEvent) -> Bool {
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return eventMods.contains(flags) && event.keyCode == keyCode
    }

    // MARK: - Key Code Name Lookup

    var keyCodeName: String {
        Self.keyCodeNames[Int(keyCode)] ?? "Key(\(keyCode))"
    }

    static let keyCodeNames: [Int: String] = [
        kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C",
        kVK_ANSI_D: "D", kVK_ANSI_E: "E", kVK_ANSI_F: "F",
        kVK_ANSI_G: "G", kVK_ANSI_H: "H", kVK_ANSI_I: "I",
        kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
        kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O",
        kVK_ANSI_P: "P", kVK_ANSI_Q: "Q", kVK_ANSI_R: "R",
        kVK_ANSI_S: "S", kVK_ANSI_T: "T", kVK_ANSI_U: "U",
        kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
        kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2",
        kVK_ANSI_3: "3", kVK_ANSI_4: "4", kVK_ANSI_5: "5",
        kVK_ANSI_6: "6", kVK_ANSI_7: "7", kVK_ANSI_8: "8",
        kVK_ANSI_9: "9",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        kVK_Space: "Space", kVK_Return: "Return", kVK_Tab: "Tab",
        kVK_Escape: "Escape",
    ]
}
