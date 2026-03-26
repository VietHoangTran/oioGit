import Foundation

enum GitHubRemoteParser {
    /// Parses a git remote URL to extract GitHub owner and repo name.
    /// Supports HTTPS (`https://github.com/owner/repo.git`)
    /// and SSH (`git@github.com:owner/repo.git`) formats.
    static func parse(_ remoteURL: String) -> (owner: String, repo: String)? {
        let trimmed = remoteURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // HTTPS format: https://github.com/owner/repo.git
        if trimmed.contains("github.com/") {
            return parseHTTPS(trimmed)
        }

        // SSH format: git@github.com:owner/repo.git
        if trimmed.hasPrefix("git@github.com:") {
            return parseSSH(trimmed)
        }

        return nil
    }

    private static func parseHTTPS(_ url: String) -> (owner: String, repo: String)? {
        // Extract path after github.com/
        guard let range = url.range(of: "github.com/") else { return nil }
        let path = String(url[range.upperBound...])
        return extractOwnerRepo(from: path)
    }

    private static func parseSSH(_ url: String) -> (owner: String, repo: String)? {
        // Extract path after git@github.com:
        let path = String(url.dropFirst("git@github.com:".count))
        return extractOwnerRepo(from: path)
    }

    private static func extractOwnerRepo(from path: String) -> (owner: String, repo: String)? {
        let cleaned = path
            .replacingOccurrences(of: ".git", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let parts = cleaned.split(separator: "/", maxSplits: 2)
        guard parts.count >= 2 else { return nil }

        let owner = String(parts[0])
        let repo = String(parts[1])
        guard !owner.isEmpty, !repo.isEmpty else { return nil }

        return (owner, repo)
    }
}
