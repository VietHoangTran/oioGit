import Foundation

enum RepoScannerService {

    /// Scan directory for git repositories up to maxDepth levels deep
    static func scan(directory: URL, maxDepth: Int = 2) -> [URL] {
        let fm = FileManager.default
        var repos: [URL] = []

        scanRecursive(
            directory: directory, fileManager: fm,
            currentDepth: 0, maxDepth: maxDepth, results: &repos
        )

        return repos.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func scanRecursive(
        directory: URL, fileManager fm: FileManager,
        currentDepth: Int, maxDepth: Int, results: inout [URL]
    ) {
        guard currentDepth <= maxDepth else { return }

        let gitDir = directory.appendingPathComponent(".git")
        if fm.fileExists(atPath: gitDir.path) {
            results.append(directory)
            return // Don't scan inside git repos
        }

        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for item in contents {
            let isDir = (try? item.resourceValues(
                forKeys: [.isDirectoryKey]
            ).isDirectory) ?? false
            guard isDir else { continue }
            scanRecursive(
                directory: item, fileManager: fm,
                currentDepth: currentDepth + 1, maxDepth: maxDepth,
                results: &results
            )
        }
    }
}
