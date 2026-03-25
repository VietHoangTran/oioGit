# Swift Naming Conventions

**Applies To**: All Swift source files in oioGit
**Last Updated**: 2026-03-25

---

## Types (PascalCase)

```swift
struct RepositoryListView: View { }
class GitService { }
enum AuthMethod { }
protocol Committable { }
```

## Variables, Functions, Parameters (camelCase)

```swift
var commitMessage: String
func fetchBranches() async throws -> [Branch]
func stage(file: FileChange) { }
```

## Constants

```swift
enum Constants {
    static let defaultBranchName = "main"
    static let maxLogEntries = 200
}
```

## Booleans — positive, descriptive names

```swift
var isLoading: Bool
var hasUncommittedChanges: Bool
var canPush: Bool
```

## Files

- One type per file
- Filename must match the primary type name exactly
- Max file length: **200 lines** — refactor into sub-files if exceeded
