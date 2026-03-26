import WidgetKit

struct RepoStatusEntry: TimelineEntry {
    let date: Date
    let repos: [WidgetRepoData]

    static let placeholder = RepoStatusEntry(
        date: Date(),
        repos: [.placeholder]
    )

    static let empty = RepoStatusEntry(
        date: Date(),
        repos: []
    )
}
