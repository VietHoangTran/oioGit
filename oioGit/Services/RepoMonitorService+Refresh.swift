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

        let userGitPath = AppSettings.shared.gitBinaryPath

        do {
            async let statusOut = gitRunner.run(
                ["status", "--porcelain"], at: url, gitPath: userGitPath
            )
            async let branchOut = gitRunner.run(
                ["branch", "--show-current"], at: url, gitPath: userGitPath
            )
            async let stashOut = gitRunner.run(
                ["stash", "list"], at: url, gitPath: userGitPath
            )

            let status = try await statusOut
            let branch = try await branchOut
            let stash = try await stashOut

            state.gitStatus = GitOutputParser.parseStatus(status)
            state.currentBranch = GitOutputParser.parseBranch(branch)
            state.stashCount = GitOutputParser.parseStashCount(stash)

            // Track when dirty state was first detected
            if state.gitStatus.isClean {
                state.firstDirtyDate = nil
            } else if state.firstDirtyDate == nil {
                state.firstDirtyDate = Date()
            }

            await fetchAheadBehind(state, at: url, gitPath: userGitPath)
            state.lastUpdated = Date()
            evaluateNotifications(for: state)
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isScanning = false
        lastRefreshEnd[state.id] = Date()

        // Update widget data after each refresh
        SharedDataService.writeSnapshots(repoStates)
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
            activeScopedURLs[repoId] = url
        }

        fileWatcher.startWatching(repoId: repoId, directory: url) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard let s = self.repoStates.first(where: { $0.id == repoId }),
                      !s.isScanning else { return }
                // Skip if within cooldown — our own git commands triggered this
                if let lastEnd = self.lastRefreshEnd[repoId],
                   Date().timeIntervalSince(lastEnd) < self.watcherCooldown {
                    return
                }
                await self.refreshRepo(s)
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
        let userGitPath = AppSettings.shared.gitBinaryPath
        for state in repoStates {
            let url = resolveURL(for: state)
            let hasBookmark = state.repoConfig.resolveBookmark() != nil
            if hasBookmark {
                guard url.startAccessingSecurityScopedResource() else { continue }
            }
            _ = try? await fetchRunner.run(
                ["fetch", "--all", "--quiet"], at: url, gitPath: userGitPath
            )
            if hasBookmark { url.stopAccessingSecurityScopedResource() }
            await fetchAheadBehind(state, at: url, gitPath: userGitPath)
        }

        // Piggyback CI/CD status fetch on periodic remote fetch
        await fetchAllCIStatuses()
    }

    private func fetchAheadBehind(_ state: RepoState, at url: URL, gitPath: String = GitDefaults.gitPath) async {
        do {
            let abOutput = try await gitRunner.run(
                ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"],
                at: url, gitPath: gitPath
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
        let repoKey = state.id // unique path, not displayName
        let repoName = state.displayName
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
        // Stale: uncommitted changes older than 2 hours
        if !state.gitStatus.isClean,
           let dirtyDate = state.firstDirtyDate,
           Date().timeIntervalSince(dirtyDate) > 7200
        {
            current.insert(NotificationType.staleChanges.rawValue)
        }

        let previous = activeNotifications[repoKey] ?? []

        for typeStr in current.subtracting(previous) {
            guard let type = NotificationType(rawValue: typeStr),
                  defaults.bool(forKey: "notify_\(typeStr)")
            else { continue }

            let msg = type == .behindRemote
                ? "\(state.behindCount) commit(s) behind remote"
                : nil
            notifier.send(type: type, repoName: repoName, message: msg)
        }

        for typeStr in previous.subtracting(current) {
            guard let type = NotificationType(rawValue: typeStr) else { continue }
            notifier.removeNotification(repoName: repoName, type: type)
        }

        activeNotifications[repoKey] = current
    }
}
