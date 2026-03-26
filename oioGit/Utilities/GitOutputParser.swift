import Foundation

enum GitOutputParser {

    /// Parse `git status --porcelain` output into GitStatus
    static func parseStatus(_ output: String) -> GitStatus {
        guard !output.isEmpty else { return GitStatus() }

        var status = GitStatus()

        for line in output.components(separatedBy: "\n") where !line.isEmpty {
            guard line.count >= 2 else { continue }
            let indexStatus = line[line.startIndex]
            let workTreeStatus = line[line.index(after: line.startIndex)]

            // Conflict indicators: both modified, added by both, etc.
            if (indexStatus == "U" || workTreeStatus == "U")
                || (indexStatus == "A" && workTreeStatus == "A")
                || (indexStatus == "D" && workTreeStatus == "D")
            {
                status.conflictCount += 1
                continue
            }

            // Index (staged) changes
            switch indexStatus {
            case "M": status.modifiedCount += 1
            case "A", "C", "R": status.addedCount += 1
            case "D": status.deletedCount += 1
            default: break
            }

            // Work tree (unstaged) changes
            switch workTreeStatus {
            case "M": status.modifiedCount += 1
            case "D": status.deletedCount += 1
            case "?": status.untrackedCount += 1
            default: break
            }
        }

        return status
    }

    /// Parse `git branch --show-current` output
    static func parseBranch(_ output: String) -> String {
        let branch = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return branch.isEmpty ? "HEAD (detached)" : branch
    }

    /// Parse `git rev-list --left-right --count HEAD...@{upstream}` output
    /// Returns (ahead, behind). Output format: "3\t5" (tab-separated)
    static func parseAheadBehind(_ output: String) -> (ahead: Int, behind: Int) {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "\t")
        guard parts.count == 2,
              let ahead = Int(parts[0]),
              let behind = Int(parts[1])
        else { return (0, 0) }
        return (ahead, behind)
    }

    /// Parse `git stash list` output — count lines
    static func parseStashCount(_ output: String) -> Int {
        guard !output.isEmpty else { return 0 }
        return output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .count
    }

    private static let iso8601 = ISO8601DateFormatter()

    /// Parse `git log --format="%H%n%s%n%an%n%aI" -N` output
    static func parseLog(_ output: String) -> [CommitInfo] {
        guard !output.isEmpty else { return [] }
        let lines = output.components(separatedBy: "\n")
        var commits: [CommitInfo] = []
        var i = 0

        while i + 3 < lines.count {
            let hash = lines[i]
            let message = lines[i + 1]
            let author = lines[i + 2]
            let dateStr = lines[i + 3]
            let date = iso8601.date(from: dateStr) ?? Date()

            commits.append(CommitInfo(
                id: String(hash.prefix(7)),
                hash: hash,
                message: message,
                author: author,
                date: date
            ))
            i += 4
        }
        return commits
    }

    /// Parse `git branch -a` output
    static func parseBranches(_ output: String) -> [BranchInfo] {
        guard !output.isEmpty else { return [] }
        return output.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line in
                let isCurrent = line.hasPrefix("*")
                var name = line
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "* ", with: "")

                // Skip detached HEAD pointer
                if name.contains("HEAD detached") { return nil }
                // Skip -> aliases like remotes/origin/HEAD -> origin/main
                if name.contains("->") { return nil }

                let isRemote = name.hasPrefix("remotes/")
                if isRemote {
                    name = String(name.dropFirst("remotes/".count))
                }

                return BranchInfo(
                    name: name, isRemote: isRemote, isCurrent: isCurrent
                )
            }
    }

    /// Parse `git status --porcelain` into FileChange array
    static func parseFileChanges(_ output: String) -> [FileChange] {
        guard !output.isEmpty else { return [] }
        var changes: [FileChange] = []

        for line in output.components(separatedBy: "\n") where line.count >= 4 {
            let indexChar = line[line.startIndex]
            let workChar = line[line.index(after: line.startIndex)]
            let path = String(line.dropFirst(3))

            // Staged change
            if indexChar != " " && indexChar != "?" {
                let status = mapCharToStatus(indexChar)
                changes.append(FileChange(
                    path: path, status: status, isStaged: true
                ))
            }

            // Unstaged change
            if workChar != " " {
                let status = mapCharToStatus(workChar)
                changes.append(FileChange(
                    path: path, status: status, isStaged: false
                ))
            }
        }
        return changes
    }

    private static func mapCharToStatus(_ char: Character) -> FileChangeStatus {
        switch char {
        case "M": return .modified
        case "A": return .added
        case "D": return .deleted
        case "R": return .renamed
        case "C": return .copied
        case "?": return .untracked
        case "U": return .conflict
        default: return .modified
        }
    }
}
