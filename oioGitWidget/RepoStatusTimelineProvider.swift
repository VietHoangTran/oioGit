import WidgetKit

struct RepoStatusTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> RepoStatusEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (RepoStatusEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        let repos = SharedDataReader.readSnapshots()
        completion(RepoStatusEntry(date: Date(), repos: repos))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RepoStatusEntry>) -> Void) {
        let repos = SharedDataReader.readSnapshots()
        let entry = RepoStatusEntry(date: Date(), repos: repos)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

/// Reads shared data from App Group UserDefaults.
/// Mirrors SharedDataService.readSnapshots() but lives in the widget target.
private enum SharedDataReader {
    private static let suiteName = "group.com.oioGit.shared"
    private static let repoDataKey = "widget_repo_data"

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
