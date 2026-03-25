# Testing Standards

**Applies To**: `oioGitTests/` and `oioGitUITests/` targets
**Last Updated**: 2026-03-25

---

## Unit Tests (Swift Testing framework)

- Location: `oioGitTests/`
- Import: `import Testing` + `@testable import oioGit`
- Use `@Test` for individual test functions
- Use `#expect(...)` for assertions
- Name tests descriptively: `fetchBranches_returnsEmptyOnNewRepo()`

```swift
@Test func fetchBranches_returnsEmptyOnNewRepo() async throws {
    let service = GitService(path: emptyRepoPath)
    let branches = try await service.fetchBranches()
    #expect(branches.isEmpty)
}
```

---

## UI Tests (XCTest)

- Location: `oioGitUITests/`
- Import: `import XCTest`
- Set `continueAfterFailure = false` in `setUpWithError`
- Launch tests use `runsForEachTargetApplicationUIConfiguration = true` for multi-device coverage

---

## Coverage Targets

| Scope | Target |
|---|---|
| Services | 80%+ |
| ViewModels | 80%+ |
| Views | Covered by UI tests and `#Preview` |
| Scaffold / boilerplate | No requirement |
