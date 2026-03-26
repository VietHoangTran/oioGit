# oioGit — System Architecture

**Version**: 0.5.0 (Phases 1–5)
**Last Updated**: 2026-03-26
**Platform**: macOS 14+ — menu bar app (NOT iOS)

---

## Overview

oioGit is a native macOS menu bar application that monitors multiple local Git repositories in the background. It uses **MVVM with `@Observable`** (Swift 5.9 Observation framework), SwiftData for persistence, and Apple-only system frameworks for all I/O.

The app has no Dock icon (`NSApp.setActivationPolicy(.accessory)`). UI is exposed exclusively via a `MenuBarExtra` popover and a `Settings` window.

---

## Architectural Pattern: MVVM + @Observable

```
┌──────────────────────────────────────────────────────────┐
│                       View Layer                         │
│  SwiftUI Views — DashboardView, RepoDetailView, etc.     │
│  Purely presentational; reads @Observable state          │
└────────────────────┬─────────────────────────────────────┘
                     │ @State private var viewModel = …
                     ▼
┌──────────────────────────────────────────────────────────┐
│                   ViewModel Layer                        │
│  @Observable classes — DashboardViewModel                │
│  Validates user input, bridges View ↔ Service            │
│  Owns or proxies service instances                       │
└────────────────────┬─────────────────────────────────────┘
                     │ async/await
                     ▼
┌──────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  RepoMonitorService (orchestrator, @Observable)          │
│  GitCommandRunner · FileWatcherService                   │
│  NotificationService · QuickActionService                │
│  RepoScannerService · GlobalHotkeyService                │
└────────────────────┬─────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────┐
│                    Model Layer                           │
│  RepoConfig (@Model/SwiftData) — persisted               │
│  RepoState (@Observable) — runtime, per repo             │
│  GitStatus · FileChange · CommitInfo · BranchInfo        │
│  Plain Swift value types (struct/enum), Sendable         │
└──────────────────────────────────────────────────────────┘
```

---

## SwiftUI Scene Hierarchy

```
oioGitApp (@main)
├── MenuBarExtra (.window style)          ← menu bar icon
│   └── DashboardView
│       ├── DashboardViewModel (@State)
│       │   └── RepoMonitorService
│       ├── RepoCardView (×N)
│       │   └── StatusBadgeView
│       └── RepoDetailView (pushed on tap)
│           ├── ChangedFilesView
│           │   └── MiniDiffView
│           ├── CommitLogView
│           └── BranchListView
└── Settings scene
    └── SettingsView (TabView)
        ├── GeneralSettingsView
        ├── RepoManagerView
        └── NotificationSettingsView
```

---

## Data Flow

### Monitoring Loop (background → UI)

```
FileWatcherService (DispatchSource on .git)
    │  debounce 1 s
    ▼
RepoMonitorService.refreshRepo(state)   @MainActor
    │  async let parallel git commands
    ├─ GitCommandRunner.run(["status", "--porcelain"])
    ├─ GitCommandRunner.run(["branch", "--show-current"])
    └─ GitCommandRunner.run(["stash", "list"])
    │
    ▼
GitOutputParser (pure, static)
    │
    ▼
RepoState properties updated (@MainActor)
    │
    ▼
SwiftUI re-renders DashboardView / RepoCardView
```

### Periodic Remote Fetch (every 5 min)

```
DispatchSourceTimer (global utility queue)
    │
    ▼
RepoMonitorService.fetchAllRemotes()
    │  fetchRunner (30 s timeout)
    ▼
GitCommandRunner.run(["fetch", "--all", "--quiet"])
    │
    ▼
fetchAheadBehind → rev-list --left-right --count HEAD...@{upstream}
    │
    ▼
RepoState.aheadCount / behindCount
```

### User Action Flow

```
User taps action in DashboardView / DashboardViewModel
    │
    ▼
DashboardViewModel validates (duplicate, .git check, limit)
    │
    ▼
SwiftData insert + modelContext.save()   (RepoConfig)
    │
    ▼
RepoMonitorService.addRepo(config)
    │
    ├─ FileWatcherService.startWatching(repoId:directory:)
    └─ refreshRepo(state)
```

---

## Service Design

### GitCommandRunner

Wraps Foundation `Process` API. Runs on a private serial `DispatchQueue`. Timeout via `withThrowingTaskGroup`: races the git task against a `Task.sleep` cancellation task. Two instances: default (5 s timeout) and `fetchRunner` (30 s timeout).

### FileWatcherService

`@unchecked Sendable` — all mutable state (`sources`, `debounceItems`) is confined to a private serial queue. Opens the `.git` subdirectory with `O_EVTONLY` and creates a `DispatchSourceFileSystemObject` for `.write` events. On event, debounces the callback by 1 s using a cancellable `DispatchWorkItem`.

### RepoMonitorService

`@Observable` class that acts as the central orchestrator. Split across two files:
- `RepoMonitorService.swift` — public API, state, `syncStates`, `deinit`
- `RepoMonitorService+Refresh.swift` — `refreshRepo`, file watcher setup, fetch timer, wake subscription, notification evaluation

Notification evaluation is transition-based: stores the previous `Set<String>` of active notification types per repo in `activeNotifications`, only fires on `false→true` transitions, and clears delivered notifications on `true→false`.

### NotificationService

Singleton. Wraps `UNUserNotificationCenter`. Notification identifiers are `"\(repoName).\(type.rawValue)"` — this deduplicates repeated sends. `NotificationType` cases: `conflict`, `behindRemote`, `staleChanges`, `detachedHead`.

### GlobalHotkeyService

Singleton. Registers a global `NSEvent` monitor for `.keyDown` events. Fires callback when `Control+Shift+G` is detected (using `kVK_ANSI_G` from `Carbon.HIToolbox`). Dispatches to main queue.

### AppSettings

`@Observable` singleton backed entirely by `UserDefaults`. `launchAtLogin` read/write delegates to `SMAppService.mainApp.register()` / `.unregister()`.

---

## Persistence

| Data | Mechanism |
|---|---|
| Tracked repository list | SwiftData (`RepoConfig` @Model, SQLite) |
| Security-scoped access | `bookmarkData: Data?` in `RepoConfig` |
| User preferences | `UserDefaults` via `AppSettings` |
| Notification toggles | `UserDefaults` keys (`notify_conflict`, etc.) |
| Runtime repo state | In-memory `RepoState` objects |

---

## Security Model

- **Sandboxed macOS app** — file access via security-scoped bookmarks
- `RepoConfig.resolveBookmark()` returns `nil` if bookmark is stale; UI surfaces "re-add repository" error
- `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` are balanced in every `refreshRepo` and `startWatcher` call
- No credentials, tokens, or SSH keys are handled — git operations use the user's existing credential helpers

---

## State Management Summary

| Scope | Mechanism |
|---|---|
| Runtime repo state | `@Observable RepoState` (updated @MainActor) |
| Service orchestration | `@Observable RepoMonitorService` |
| ViewModel | `@Observable DashboardViewModel` (@State in View) |
| Global settings | `@Observable AppSettings.shared` |
| Persistent config | SwiftData `@Query` + `ModelContext` |
| Local view state | `@State` |
| Cross-view data | `@Environment(\.modelContext)` |

---

## Concurrency Model

- All `RepoState` mutations happen on `@MainActor`
- `GitCommandRunner` executes `Process` on a private serial `DispatchQueue`; results bridge back via `withCheckedThrowingContinuation`
- `FileWatcherService` confines all mutable state to its own `DispatchQueue`; uses `@unchecked Sendable`
- Service singletons (`NotificationService`, `GlobalHotkeyService`) are `final` with immutable state or confined mutation
- `withTaskGroup` enables parallel git command execution per repo refresh
