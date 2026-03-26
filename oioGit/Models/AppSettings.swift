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

    private init() {}
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
