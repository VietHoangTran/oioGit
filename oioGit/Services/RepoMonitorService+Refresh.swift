import Foundation

extension RepoMonitorService {

    // MARK: - Repo Refresh

    @MainActor func refreshRepo(_ state: RepoState) async {
        state.isScanning = true
        state.errorMessage = nil

        let url = resolveURL(for: state)
        let hasBookmark = state.repoConfig.resolveBookmark() != nil

        if hasBookmark {
            guard url.startAccessingSecurityScopedResource() else {
                state.errorMessage = "Access denied — re-add repository"
                state.isScanning = false
                return
            }
        }
        defer { if hasBookmark { url.stopAccessingSecurityScopedResource() } }

        do {
            async let statusOut = gitRunner.run(
                ["status", "--porcelain"], at: url
            )
            async let branchOut = gitRunner.run(
                ["branch", "--show-current"], at: url
            )
            async let stashOut = gitRunner.run(
                ["stash", "list"], at: url
            )

            let status = try await statusOut
            let branch = try await branchOut
            let stash = try await stashOut

            state.gitStatus = GitOutputParser.parseStatus(status)
            state.currentBranch = GitOutputParser.parseBranch(branch)
            state.stashCount = GitOutputParser.parseStashCount(stash)

            await fetchAheadBehind(state, at: url)
            state.lastUpdated = Date()
            evaluateNotifications(for: state)
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isScanning = false
    }

    // MARK: - File Watchers

    func startWatchers() {
        for state in repoStates {
            startWatcher(for: state)
        }
    }

    func startWatcher(for state: RepoState) {
        let url = resolveURL(for: state)
        let repoId = state.id
        let hasBookmark = state.repoConfig.resolveBookmark() != nil

        if hasBookmark {
            guard url.startAccessingSecurityScopedResource() else { return }
        }

        fileWatcher.startWatching(repoId: repoId, directory: url) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                if let s = self.repoStates.first(where: { $0.id == repoId }) {
                    await self.refreshRepo(s)
                }
            }
        }
    }

    // MARK: - Periodic Fetch

    func startFetchTimer() {
        fetchTimerSource?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(
            deadline: .now() + fetchInterval,
            repeating: fetchInterval
        )
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            Task { await self.fetchAllRemotes() }
        }
        fetchTimerSource = timer
        timer.resume()
    }

    func subscribeToWake() {
        guard wakeObserver == nil else { return }
        wakeObserver = NotificationCenter.default.addObserver(
            forName: .systemDidWake, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshAll() }
        }
    }

    // MARK: - Private Helpers

    private func fetchAllRemotes() async {
        for state in repoStates {
            let url = resolveURL(for: state)
            let hasBookmark = state.repoConfig.resolveBookmark() != nil
            if hasBookmark {
                guard url.startAccessingSecurityScopedResource() else { continue }
            }
            _ = try? await fetchRunner.run(
                ["fetch", "--all", "--quiet"], at: url
            )
            if hasBookmark { url.stopAccessingSecurityScopedResource() }
            await fetchAheadBehind(state, at: url)
        }
    }

    private func fetchAheadBehind(_ state: RepoState, at url: URL) async {
        do {
            let abOutput = try await gitRunner.run(
                ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"],
                at: url
            )
            let (ahead, behind) = GitOutputParser.parseAheadBehind(abOutput)
            state.aheadCount = ahead
            state.behindCount = behind
        } catch {
            state.aheadCount = 0
            state.behindCount = 0
        }
    }

    // MARK: - Notification Evaluation

    private func evaluateNotifications(for state: RepoState) {
        let name = state.displayName
        let notifier = NotificationService.shared
        let defaults = UserDefaults.standard

        var current: Set<String> = []

        if state.gitStatus.hasConflict {
            current.insert(NotificationType.conflict.rawValue)
        }
        if state.behindCount > 0 {
            current.insert(NotificationType.behindRemote.rawValue)
        }
        if state.currentBranch == "HEAD (detached)" {
            current.insert(NotificationType.detachedHead.rawValue)
        }

        let previous = activeNotifications[name] ?? []

        // Only notify on new transitions (false→true) & respect prefs
        for typeStr in current.subtracting(previous) {
            guard let type = NotificationType(rawValue: typeStr),
                  defaults.bool(forKey: "notify_\(typeStr)")
            else { continue }

            let msg = type == .behindRemote
                ? "\(state.behindCount) commit(s) behind remote"
                : nil
            notifier.send(type: type, repoName: name, message: msg)
        }

        // Remove cleared notifications
        for typeStr in previous.subtracting(current) {
            guard let type = NotificationType(rawValue: typeStr) else { continue }
            notifier.removeNotification(repoName: name, type: type)
        }

        activeNotifications[name] = current
    }
}
