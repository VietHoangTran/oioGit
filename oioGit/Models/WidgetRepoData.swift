import Foundation

/// Shared data contract between the main app and widget extension.
/// Kept lightweight — only the fields needed for widget display.
/// NOTE: This file is duplicated in the widget target to avoid framework overhead.
struct WidgetRepoData: Codable, Identifiable {
    var id: String { repoName }
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
