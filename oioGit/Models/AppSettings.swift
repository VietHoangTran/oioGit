import Foundation
import ServiceManagement

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var pollingInterval: TimeInterval {
        get { UserDefaults.standard.double(forKey: "pollingInterval").nonZero ?? 300 }
        set { UserDefaults.standard.set(newValue, forKey: "pollingInterval") }
    }

    var gitBinaryPath: String {
        get { UserDefaults.standard.string(forKey: "gitBinaryPath") ?? GitDefaults.gitPath }
        set { UserDefaults.standard.set(newValue, forKey: "gitBinaryPath") }
    }

    var defaultIDE: String {
        get { UserDefaults.standard.string(forKey: "defaultIDE") ?? "Visual Studio Code" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultIDE") }
    }

    var maxRepoCount: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: "maxRepoCount")
            return val > 0 ? val : GitDefaults.maxRepoCount
        }
        set { UserDefaults.standard.set(newValue, forKey: "maxRepoCount") }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — user can retry
            }
        }
    }

    // MARK: - Hotkey

    var hotkeyModifiers: UInt {
        get {
            let val = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt
            return val ?? HotkeyConfig.default.modifierFlags
        }
        set { UserDefaults.standard.set(newValue, forKey: "hotkeyModifiers") }
    }

    var hotkeyKeyCode: UInt16 {
        get {
            let val = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? Int
            return val.map { UInt16($0) } ?? HotkeyConfig.default.keyCode
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: "hotkeyKeyCode") }
    }

    var hotkeyConfig: HotkeyConfig {
        get { HotkeyConfig(modifierFlags: hotkeyModifiers, keyCode: hotkeyKeyCode) }
        set {
            hotkeyModifiers = newValue.modifierFlags
            hotkeyKeyCode = newValue.keyCode
        }
    }

    // MARK: - CI/CD

    var ciStatusEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "ciStatusEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "ciStatusEnabled") }
    }

    var ciPollingInterval: TimeInterval {
        get {
            let val = UserDefaults.standard.double(forKey: "ciPollingInterval")
            return val > 0 ? val : CIDefaults.pollingInterval
        }
        set { UserDefaults.standard.set(newValue, forKey: "ciPollingInterval") }
    }

    private init() {}
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
