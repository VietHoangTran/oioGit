import Foundation
import WidgetKit

enum SharedDataService {
    private static let suiteName = "group.com.oioGit.shared"
    private static let repoDataKey = "widget_repo_data"
    private static let lastUpdatedKey = "widget_last_updated"

    /// Write repo state snapshots to App Group UserDefaults for widget consumption.
    static func writeSnapshots(_ states: [RepoState]) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }

        let data = states.map { state in
            WidgetRepoData(
                repoName: state.displayName,
                branch: state.currentBranch,
                changedCount: state.gitStatus.totalChanges,
                isClean: state.gitStatus.isClean,
                hasConflict: state.gitStatus.hasConflict,
                aheadCount: state.aheadCount,
                behindCount: state.behindCount,
                ciState: state.ciStatus.state == .none ? nil : state.ciStatus.state.rawValue,
                lastUpdated: state.lastUpdated ?? Date()
            )
        }

        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: repoDataKey)
            defaults.set(Date(), forKey: lastUpdatedKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Read repo snapshots from App Group UserDefaults (used by widget).
    static func readSnapshots() -> [WidgetRepoData] {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: repoDataKey),
              let repos = try? JSONDecoder().decode([WidgetRepoData].self, from: data)
        else {
            return []
        }
        return repos
    }
}
