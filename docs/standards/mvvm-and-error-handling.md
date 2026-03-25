# MVVM Pattern & Error Handling

**Applies To**: ViewModels and Services in oioGit
**Last Updated**: 2026-03-25

---

## MVVM Rules

- Views are purely presentational — no business logic
- ViewModels are `@MainActor` classes conforming to `ObservableObject`
- Services handle external I/O (Git operations, file system, network)
- Models are plain value types (`struct`)

```swift
@MainActor
final class RepositoryListViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let gitService: GitService

    init(gitService: GitService = GitService()) {
        self.gitService = gitService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            repositories = try await gitService.listRepositories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## Error Handling

- Define domain-specific error enums conforming to `Error` and `LocalizedError`
- Never silently swallow errors — surface to ViewModel, then to View
- Use `Result<T, E>` or `throws` consistently within a module; do not mix

```swift
enum GitError: LocalizedError {
    case repositoryNotFound(path: String)
    case authenticationFailed
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .repositoryNotFound(let path): return "No repository at \(path)"
        case .authenticationFailed: return "Authentication failed"
        case .networkUnavailable: return "No network connection"
        }
    }
}
```
