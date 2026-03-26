import Foundation

extension RepoMonitorService {

    /// Fetch CI/CD status for all repos that have a GitHub remote.
    /// Called from the periodic fetch timer, not from file-watcher refreshes.
    func fetchAllCIStatuses() async {
        let settings = AppSettings.shared
        guard settings.ciStatusEnabled else { return }
        guard KeychainService.exists() else { return }

        let api = GitHubAPIService.shared

        for state in repoStates {
            let url = resolveURL(for: state)
            let hasBookmark = state.repoConfig.resolveBookmark() != nil
            if hasBookmark {
                guard url.startAccessingSecurityScopedResource() else { continue }
            }
            defer { if hasBookmark { url.stopAccessingSecurityScopedResource() } }

            // Get remote origin URL
            guard let remoteURL = try? await gitRunner.run(
                ["remote", "get-url", "origin"], at: url
            ) else { continue }

            // Parse GitHub owner/repo
            guard let remote = GitHubRemoteParser.parse(remoteURL) else { continue }

            // Fetch CI status for current branch
            let branch = state.currentBranch == "HEAD (detached)" ? nil : state.currentBranch

            do {
                let ciStatus = try await api.fetchLatestWorkflowRun(
                    owner: remote.owner,
                    repo: remote.repo,
                    branch: branch
                )
                await MainActor.run { state.ciStatus = ciStatus }
            } catch {
                // Silently skip — CI status is best-effort
            }
        }
    }
}
