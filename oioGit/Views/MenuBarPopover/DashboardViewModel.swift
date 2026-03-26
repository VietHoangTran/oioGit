import SwiftUI
import SwiftData

@Observable
final class DashboardViewModel {
    var errorMessage: String?

    let monitor: RepoMonitorService

    init(monitor: RepoMonitorService = RepoMonitorService()) {
        self.monitor = monitor
    }

    var repoStates: [RepoState] {
        monitor.repoStates
    }

    var isRefreshing: Bool {
        monitor.isRefreshing
    }

    func start(configs: [RepoConfig]) async {
        await monitor.start(configs: configs)
    }

    func refreshAll() async {
        await monitor.refreshAll()
    }

    func addRepo(
        url: URL, modelContext: ModelContext, configs: [RepoConfig]
    ) throws {
        // Validate .git directory
        let gitDir = url.appendingPathComponent(".git")
        guard FileManager.default.fileExists(atPath: gitDir.path) else {
            errorMessage = "No .git directory found"
            return
        }

        // Check duplicate
        guard !configs.contains(where: { $0.path == url.path }) else {
            errorMessage = "Repository already added"
            return
        }

        // Check max repo limit
        guard configs.count < GitDefaults.maxRepoCount else {
            errorMessage = "Maximum \(GitDefaults.maxRepoCount) repos reached"
            return
        }

        let bookmark = RepoConfig.createBookmark(for: url)
        let config = RepoConfig(path: url.path, bookmarkData: bookmark)
        modelContext.insert(config)
        try modelContext.save()

        Task { await monitor.addRepo(config) }
    }

    func removeRepo(
        repoId: String, modelContext: ModelContext, configs: [RepoConfig]
    ) {
        monitor.removeRepo(repoId: repoId)
        if let config = configs.first(where: { $0.path == repoId }) {
            modelContext.delete(config)
            try? modelContext.save()
        }
    }
}
