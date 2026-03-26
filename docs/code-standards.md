# oioGit — Code Standards

**Version**: 2.0.0
**Last Updated**: 2026-03-26
**Platform**: macOS 14+ (NOT iOS)
**Applies To**: All Swift source code in oioGit

---

## Guiding Principles

- **YAGNI** — implement only what is currently required
- **KISS** — prefer the simplest solution that works
- **DRY** — extract shared logic into reusable components
- **Single Responsibility** — one type per file, one concern per type

---

## File Organization

```
oioGit/
├── App/               # @main entry point + NSApplicationDelegate
├── Models/            # Value types (struct/enum) and @Observable state types
├── Services/          # All I/O — git, file watching, notifications, hotkeys
├── Views/
│   ├── MenuBarPopover/    # Popover dashboard and its ViewModel
│   ├── Detail/            # Per-repo detail views
│   └── Settings/          # Settings window tabs
└── Utilities/         # Pure helpers — parsers, constants, extensions
```

**One type per file.** Filename must match the primary type. Extensions that add significant functionality live in a separate file named `TypeName+Concern.swift` (e.g., `RepoMonitorService+Refresh.swift`).

**200 line maximum per file.** If a file approaches the limit, split by concern using extensions or extract a new type.

---

## Naming Conventions

- Types: `PascalCase` — `RepoMonitorService`, `GitStatus`, `DashboardViewModel`
- Variables, functions, parameters: `camelCase`
- Constants: static members on a `nonisolated enum` — `GitDefaults.timeout`
- Boolean properties: `is`/`has` prefix — `isScanning`, `hasConflict`
- SF Symbol strings: in `enum SFSymbols` static members only — never inline strings
- `UserDefaults` keys: `snake_case` strings — `"notify_conflict"`, `"pollingInterval"`

---

## Swift Patterns

### Observable State — Use @Observable, not ObservableObject

```swift
// Correct
@Observable
final class RepoMonitorService { … }

// Wrong — do not use
class RepoMonitorService: ObservableObject {
    @Published var repoStates: [RepoState] = []
}
```

ViewModels are instantiated as `@State` in the owning view, not `@StateObject`.

### Constants — nonisolated enum

```swift
nonisolated enum GitDefaults: Sendable {
    static let gitPath = "/usr/bin/git"
    static let timeout: TimeInterval = 5.0
    static let maxRepoCount = 15
}
```

Use `nonisolated enum` (not struct or class) for namespace-style constant groups.

### Thread Safety — @unchecked Sendable with queue confinement

Use `@unchecked Sendable` only when all mutable state is strictly confined to a single serial `DispatchQueue`. Document the confinement in a comment.

```swift
final class FileWatcherService: @unchecked Sendable {
    // All mutable state below is confined to `queue`
    private var sources: [String: DispatchSourceFileSystemObject] = [:]
    private let queue = DispatchQueue(label: "com.oioGit.fileWatcher", qos: .utility)
}
```

Never use `@unchecked Sendable` without explicit queue confinement.

### Security-Scoped Bookmarks

All repository directory access must go through security-scoped bookmarks when a bookmark is available. Pattern:

```swift
let hasBookmark = state.repoConfig.resolveBookmark() != nil
let url = state.repoConfig.resolveBookmark() ?? state.repoConfig.directoryURL
if hasBookmark {
    guard url.startAccessingSecurityScopedResource() else { return }
}
defer { if hasBookmark { url.stopAccessingSecurityScopedResource() } }
```

`startAccessingSecurityScopedResource` and `stopAccessingSecurityScopedResource` must always be balanced.

### Error Handling

- Services throw typed errors conforming to `LocalizedError`
- No force unwrap (`!`) — use `guard let` or `if let`
- ViewModels catch errors and expose `errorMessage: String?` to the View
- Fire-and-forget operations (e.g., `NSPasteboard`) may use `try?` with a comment

### Async / Concurrency

- `RepoState` mutations must occur on `@MainActor`
- Use `async let` for parallel independent git commands within a single refresh
- Use `withTaskGroup` when fanning out across multiple repos
- Bridge `DispatchQueue`-based code to async/await via `withCheckedThrowingContinuation`
- Implement timeouts by racing tasks inside `withThrowingTaskGroup`

---

## SwiftUI Patterns

- Views are purely presentational — no business logic, no direct service calls
- Use `@State private var viewModel = ViewModel()` for view-owned observable objects
- Pass data down via `let` properties; pass actions up via closures or environment
- Every new view must include a `#Preview` macro
- Fixed-size popover frames: `DashboardView` 340×420 pt, `SettingsView` 450×320 pt

---

## Git Commit Conventions

Format: `type(scope): description`

| Type | Use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructure, no behavior change |
| `docs` | Documentation only |
| `test` | Test additions or changes |
| `chore` | Build, config, tooling |

Branch naming: `feat/short-description`, `fix/short-description`

---

## Testing

- Unit tests use **Swift Testing** (`import Testing`, `@Test`, `#expect`)
- UI tests use **XCTest**
- Pure logic (parsers, validators) targets 90%+ coverage
- Service classes are tested via protocol abstractions or dependency injection
- No network or file system calls in unit tests — use fakes/stubs
