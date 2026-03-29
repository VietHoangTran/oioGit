import Foundation

/// Shared data contract between the main app and widget extension.
/// Kept lightweight — only the fields needed for widget display.
struct WidgetRepoData: Codable, Identifiable {
    let repoPath: String
    var id: String { repoPath }
    let repoName: String
    let branch: String
    let changedCount: Int
    let isClean: Bool
    let hasConflict: Bool
    let aheadCount: Int
    let behindCount: Int
    let ciState: String?
    let lastUpdated: Date

    static let placeholder = WidgetRepoData(
        repoPath: "/Users/dev/my-project",
        repoName: "my-project",
        branch: "main",
        changedCount: 3,
        isClean: false,
        hasConflict: false,
        aheadCount: 1,
        behindCount: 0,
        ciState: "success",
        lastUpdated: Date()
    )
}
