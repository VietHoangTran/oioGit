import SwiftUI

enum AppConstants: Sendable {
    static let appName = "oioGit"
}

nonisolated enum GitDefaults: Sendable {
    static let gitPath = "/usr/bin/git"
    static let timeout: TimeInterval = 5.0
    static let maxRepoCount = 15
}

enum SFSymbols {
    static let menuBarIcon = "arrow.triangle.branch"
    static let addRepo = "plus"
    static let refresh = "arrow.clockwise"
    static let folder = "folder"
    static let branch = "arrow.triangle.branch"
    static let modified = "pencil.circle.fill"
    static let clean = "checkmark.circle.fill"
    static let conflict = "exclamationmark.triangle.fill"
    static let stash = "archivebox"
    static let remove = "trash"
}

enum StatusColor {
    static let clean = Color.green
    static let modified = Color.yellow
    static let conflict = Color.red
    static let unknown = Color.gray
}

nonisolated enum HotkeyDefaults: Sendable {
    /// Known macOS system shortcuts that should trigger a conflict warning
    static let systemConflicts: Set<String> = [
        "Command+Q", "Command+W", "Command+H", "Command+M",
        "Command+Tab", "Command+Space", "Command+Shift+3",
        "Command+Shift+4", "Command+Shift+5",
    ]
}

nonisolated enum KeychainConstants: Sendable {
    static let service = "com.oioGit.github"
    static let account = "github-pat"
}

nonisolated enum CIDefaults: Sendable {
    static let pollingInterval: TimeInterval = 300
    static let githubAPIBase = "https://api.github.com"
}
