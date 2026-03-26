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
