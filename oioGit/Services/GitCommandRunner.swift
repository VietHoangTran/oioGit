import Foundation

enum GitError: LocalizedError {
    case timeout
    case notFound(String)
    case executionFailed(String)
    case invalidDirectory(String)

    var errorDescription: String? {
        switch self {
        case .timeout: return "Git command timed out"
        case .notFound(let path): return "Git not found at \(path)"
        case .executionFailed(let msg): return "Git error: \(msg)"
        case .invalidDirectory(let path): return "Invalid directory: \(path)"
        }
    }
}

final class GitCommandRunner: Sendable {
    /// Shared instance for views to avoid per-view allocation
    static let shared = GitCommandRunner()

    private let gitPath: String
    private let timeout: TimeInterval
    private let queue = DispatchQueue(label: "com.oioGit.git", qos: .utility)

    init(
        gitPath: String = GitDefaults.gitPath,
        timeout: TimeInterval = GitDefaults.timeout
    ) {
        self.gitPath = gitPath
        self.timeout = timeout
    }

    func run(_ args: [String], at directory: URL, gitPath override: String? = nil) async throws -> String {
        let effectivePath = override ?? self.gitPath
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw GitError.invalidDirectory(directory.path)
        }
        guard FileManager.default.isExecutableFile(atPath: effectivePath) else {
            throw GitError.notFound(effectivePath)
        }

        let gitPath = effectivePath
        let queue = self.queue

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    queue.async {
                        do {
                            let result = try Self.executeProcess(
                                gitPath, args, at: directory
                            )
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            group.addTask {
                try await Task.sleep(for: .seconds(self.timeout))
                throw GitError.timeout
            }

            guard let result = try await group.next() else {
                throw GitError.timeout
            }
            group.cancelAll()
            return result
        }
    }

    private static func executeProcess(
        _ gitPath: String, _ args: [String], at directory: URL
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitPath)
        process.arguments = args
        process.currentDirectoryURL = directory

        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8) ?? ""
            throw GitError.executionFailed(
                errMsg.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
