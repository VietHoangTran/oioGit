import Foundation
import SwiftData

@Observable
final class RepoMonitorService {
    var repoStates: [RepoState] = []
    var isRefreshing = false

    let gitRunner = GitCommandRunner()
    let fetchRunner = GitCommandRunner(timeout: 30)
    let fileWatcher = FileWatcherService()
    var fetchTimerSource: DispatchSourceTimer?
    var wakeObserver: NSObjectProtocol?
    let fetchInterval: TimeInterval = 300 // 5 minutes
    /// Track active notification states to only notify on transition
    var activeNotifications: [String: Set<String>] = [:]

    deinit {
        fileWatcher.stopAll()
        fetchTimerSource?.cancel()
        if let obs = wakeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Public API

    func start(configs: [RepoConfig]) async {
        syncStates(with: configs)
        startWatchers()
        startFetchTimer()
        subscribeToWake()
        await refreshAll()
    }

    func addRepo(_ config: RepoConfig) async {
        let state = RepoState(repoConfig: config)
        repoStates.append(state)
        startWatcher(for: state)
        await refreshRepo(state)
    }

    func removeRepo(repoId: String) {
        fileWatcher.stopWatching(repoId: repoId)
        repoStates.removeAll { $0.id == repoId }
    }

    func refreshAll() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await withTaskGroup(of: Void.self) { group in
            for state in repoStates {
                group.addTask { @MainActor in await self.refreshRepo(state) }
            }
        }
    }

    func stopAll() {
        fileWatcher.stopAll()
        fetchTimerSource?.cancel()
        fetchTimerSource = nil
    }

    // MARK: - Internal

    func syncStates(with configs: [RepoConfig]) {
        var stateMap: [String: RepoState] = [:]
        for state in repoStates { stateMap[state.id] = state }

        var updated: [RepoState] = []
        for config in configs {
            let state = stateMap[config.path] ?? RepoState(repoConfig: config)
            updated.append(state)
        }
        repoStates = updated
    }

    func resolveURL(for state: RepoState) -> URL {
        state.repoConfig.resolveBookmark() ?? state.repoConfig.directoryURL
    }
}
