import SwiftUI

@Observable
final class RepoState: Identifiable {
    let id: String
    let repoConfig: RepoConfig
    var currentBranch: String
    var gitStatus: GitStatus
    var aheadCount: Int
    var behindCount: Int
    var stashCount: Int
    var lastUpdated: Date?
    /// Tracks when uncommitted changes were first detected (for stale notification)
    var firstDirtyDate: Date?
    var ciStatus: CIStatus
    var isScanning: Bool
    var errorMessage: String?

    init(repoConfig: RepoConfig) {
        self.id = repoConfig.path
        self.repoConfig = repoConfig
        self.currentBranch = "—"
        self.gitStatus = .empty
        self.aheadCount = 0
        self.behindCount = 0
        self.stashCount = 0
        self.ciStatus = .none
        self.lastUpdated = nil
        self.firstDirtyDate = nil
        self.isScanning = false
        self.errorMessage = nil
    }

    var displayName: String {
        repoConfig.displayName
    }

    var statusColor: Color {
        if errorMessage != nil { return StatusColor.unknown }
        if gitStatus.hasConflict { return StatusColor.conflict }
        if gitStatus.isClean { return StatusColor.clean }
        return StatusColor.modified
    }
}
