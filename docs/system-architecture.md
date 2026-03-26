# oioGit — System Architecture

**Version**: 0.5.0 (Phases 1–5)
**Last Updated**: 2026-03-26
**Platform**: macOS 14+ — menu bar app (NOT iOS)

---

## Overview

oioGit is a native macOS menu bar app that monitors local Git repositories. It uses **MVVM with `@Observable`** (Swift 5.9 Observation framework), SwiftData for persistence, and Apple-only frameworks for all I/O. No Dock icon (`NSApp.setActivationPolicy(.accessory)`); UI is a `MenuBarExtra` popover and a `Settings` window.

---

## MVVM + @Observable Layers

```
View Layer         SwiftUI Views — purely presentational, reads @Observable state
                        │ @State private var viewModel = …
ViewModel Layer    @Observable DashboardViewModel — validates input, bridges View↔Service
                        │ async/await
Service Layer      RepoMonitorService (orchestrator) · GitCommandRunner · FileWatcherService
                   NotificationService · QuickActionService · RepoScannerService · GlobalHotkeyService
                        │
Model Layer        RepoConfig (@Model/SwiftData) · RepoState (@Observable, runtime)
                   GitStatus · FileChange · CommitInfo · BranchInfo (plain Sendable value types)
```

---

## SwiftUI Scene Hierarchy

```
oioGitApp (@main)
├── MenuBarExtra (.window style)
│   └── DashboardView
│       ├── DashboardViewModel (@State) → RepoMonitorService
│       ├── RepoCardView (×N) → StatusBadgeView
│       └── RepoDetailView (pushed on tap)
│           ├── ChangedFilesView → MiniDiffView
│           ├── CommitLogView
│           └── BranchListView
└── Settings scene → SettingsView (TabView)
    ├── GeneralSettingsView
    ├── RepoManagerView
    └── NotificationSettingsView
```

---

## Data Flow

**Monitoring loop (background → UI)**
```
FileWatcherService (DispatchSource .write on .git, debounce 1 s)
  → RepoMonitorService.refreshRepo(state) @MainActor
      async let: status --porcelain · branch --show-current · stash list
  → GitOutputParser (pure static parsers)
  → RepoState updated @MainActor → SwiftUI re-render
```

**Periodic remote fetch (every 5 min)**
```
DispatchSourceTimer (utility queue)
  → fetchRunner.run(["fetch", "--all", "--quiet"])  [30 s timeout]
  → rev-list --left-right --count HEAD...@{upstream}
  → RepoState.aheadCount / behindCount
```

**User adds repository**
```
DashboardViewModel: validate .git dir, check duplicate, check max-repo limit
  → RepoConfig.createBookmark(for: url)
  → modelContext.insert(config) + save()
  → RepoMonitorService.addRepo(config)
      → FileWatcherService.startWatching + refreshRepo(state)
```

---

## Service Notes

| Service | Key Design |
|---|---|
| `GitCommandRunner` | `Process` API on private serial queue; timeout via racing `withThrowingTaskGroup` tasks; 5 s default / 30 s fetch instance |
| `FileWatcherService` | `@unchecked Sendable`; `O_EVTONLY` fd on `.git`; `DispatchSourceFileSystemObject` `.write` events; 1 s debounce |
| `RepoMonitorService` | `@Observable` orchestrator split across main file + `+Refresh` extension; transition-based notification evaluation via `activeNotifications: [String: Set<String>]` |
| `NotificationService` | Singleton; `UNUserNotificationCenter`; IDs `"\(repoName).\(type.rawValue)"` deduplicate sends |
| `GlobalHotkeyService` | Singleton; `NSEvent.addGlobalMonitorForEvents`; `Control+Shift+G` via `kVK_ANSI_G` |
| `AppSettings` | `@Observable` singleton; `UserDefaults`-backed; `launchAtLogin` delegates to `SMAppService` |

---

## Persistence & Security

| Data | Mechanism |
|---|---|
| Tracked repos | SwiftData `RepoConfig` @Model (SQLite) |
| Directory access | Security-scoped bookmarks (`bookmarkData: Data?`) |
| User preferences | `UserDefaults` / `AppSettings` |
| Notification prefs | `UserDefaults` keys (`notify_conflict`, etc.) |
| Runtime repo state | In-memory `RepoState` objects |

Security: sandboxed app; `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource` balanced at every refresh and watcher start; stale bookmarks surface "re-add repository" error; no credentials handled.

---

## State Management & Concurrency

| Scope | Mechanism |
|---|---|
| Runtime repo state | `@Observable RepoState` — mutated @MainActor |
| Orchestration | `@Observable RepoMonitorService` |
| ViewModel | `@Observable DashboardViewModel` held as `@State` |
| Global settings | `@Observable AppSettings.shared` |
| Persistence | SwiftData `@Query` + `@Environment(\.modelContext)` |
| Local view state | `@State` |

Concurrency rules: `RepoState` mutations always on `@MainActor`; `GitCommandRunner` bridges via `withCheckedThrowingContinuation`; `FileWatcherService` uses `@unchecked Sendable` with queue confinement; `withTaskGroup` parallelises per-repo git commands.
