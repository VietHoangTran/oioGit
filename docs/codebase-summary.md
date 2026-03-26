# oioGit — Codebase Summary

**Version**: 0.5.0 (Phases 1–5)
**Last Updated**: 2026-03-26
**Platform**: macOS 14+ — menu bar app (NOT iOS)
**Language**: Swift 5.9+ / SwiftUI + AppKit
**Total**: ~2,490 LOC across 26 Swift source files

---

## Project Structure

```
oioGit/
├── oioGit.xcodeproj/
├── oioGit/
│   ├── App/
│   │   ├── oioGitApp.swift          # @main — MenuBarExtra + Settings scenes
│   │   └── AppDelegate.swift        # NSApplicationDelegate lifecycle
│   ├── Models/
│   │   ├── RepoConfig.swift         # SwiftData @Model — persisted repo entry
│   │   ├── RepoState.swift          # @Observable runtime state per repo
│   │   ├── GitStatus.swift          # Value type: change counts + flags
│   │   ├── FileChange.swift         # FileChangeStatus enum + FileChange struct
│   │   ├── CommitInfo.swift         # Commit record (hash, message, author, date)
│   │   ├── BranchInfo.swift         # Branch record (name, isRemote, isCurrent)
│   │   └── AppSettings.swift        # @Observable singleton, UserDefaults-backed
│   ├── Services/
│   │   ├── GitCommandRunner.swift           # Process API wrapper + timeout
│   │   ├── FileWatcherService.swift         # DispatchSource .git dir watcher
│   │   ├── RepoMonitorService.swift         # @Observable orchestrator
│   │   ├── RepoMonitorService+Refresh.swift # Refresh logic extension
│   │   ├── NotificationService.swift        # UNUserNotificationCenter wrapper
│   │   ├── QuickActionService.swift         # Terminal / IDE / Finder launch
│   │   ├── RepoScannerService.swift         # Recursive .git directory scanner
│   │   └── GlobalHotkeyService.swift        # NSEvent global monitor (Ctrl+Shift+G)
│   ├── Views/
│   │   ├── MenuBarPopover/
│   │   │   ├── DashboardView.swift      # Root popover view (340×420 pt)
│   │   │   ├── DashboardViewModel.swift # @Observable VM bridging monitor→view
│   │   │   ├── RepoCardView.swift       # Per-repo summary row
│   │   │   └── StatusBadgeView.swift    # Colored dot status indicator
│   │   ├── Detail/
│   │   │   ├── RepoDetailView.swift     # Segmented tab container
│   │   │   ├── ChangedFilesView.swift   # Staged/unstaged file list
│   │   │   ├── CommitLogView.swift      # Recent commits list
│   │   │   ├── BranchListView.swift     # Local + remote branch list
│   │   │   └── MiniDiffView.swift       # Inline diff display
│   │   └── Settings/
│   │       ├── SettingsView.swift           # TabView container (450×320 pt)
│   │       ├── GeneralSettingsView.swift    # Polling, git path, IDE, launch
│   │       ├── RepoManagerView.swift        # Add / remove / scan repos
│   │       └── NotificationSettingsView.swift # Per-type notification toggles
│   └── Utilities/
│       ├── Constants.swift          # AppConstants, GitDefaults, SFSymbols, StatusColor
│       └── GitOutputParser.swift    # Pure parser for all git command outputs
├── oioGitTests/
│   └── oioGitTests.swift
├── oioGitUITests/
│   ├── oioGitUITests.swift
│   └── oioGitUITestsLaunchTests.swift
└── docs/
```

---

## File Size Reference

| File | Lines |
|---|---|
| RepoMonitorService+Refresh.swift | 179 |
| DashboardView.swift | 171 |
| GitOutputParser.swift | 167 |
| RepoManagerView.swift | 152 |
| ChangedFilesView.swift | 139 |
| RepoDetailView.swift | 132 |
| MiniDiffView.swift | 116 |
| BranchListView.swift | 106 |
| GitCommandRunner.swift | 101 |
| RepoCardView.swift | 97 |
| FileWatcherService.swift | 90 |
| RepoMonitorService.swift | 82 |
| All others | < 80 each |

---

## Core Technologies

| Technology | Usage |
|---|---|
| SwiftUI | All UI rendering |
| AppKit | NSApp, NSOpenPanel, NSEvent, NSWorkspace |
| SwiftData | RepoConfig persistence (SQLite-backed) |
| Foundation / Process | Git subprocess execution |
| DispatchSource | File system event watching |
| UNUserNotificationCenter | macOS notification delivery |
| ServiceManagement / SMAppService | Launch-at-login registration |
| Carbon.HIToolbox | Key code constants for global hotkey |

---

## Key Components

### App Entry — `oioGitApp.swift`

`@main` struct. Creates a `ModelContainer` for `RepoConfig`. Declares two scenes:
- `MenuBarExtra` with `.window` style — hosts `DashboardView`
- `Settings` scene — hosts `SettingsView`

Uses `@NSApplicationDelegateAdaptor(AppDelegate.self)`.

### AppDelegate — `AppDelegate.swift`

Sets `.accessory` activation policy (no Dock icon). Registers UserDefaults notification defaults, requests notification permission via `NotificationService.shared`, registers global hotkey via `GlobalHotkeyService.shared`, and observes `NSWorkspace.didWakeNotification` to post `.systemDidWake`.

### RepoConfig — `Models/RepoConfig.swift`

SwiftData `@Model`. Fields: `path: String`, `alias: String?`, `bookmarkData: Data?`, `dateAdded: Date`. Provides `resolveBookmark()` (returns security-scoped URL or nil if stale) and `createBookmark(for:)` static factory.

### RepoState — `Models/RepoState.swift`

`@Observable` runtime object per tracked repository. Fields: `currentBranch`, `gitStatus: GitStatus`, `aheadCount`, `behindCount`, `stashCount`, `lastUpdated`, `isScanning`, `errorMessage`. Derives `statusColor: Color` from conflict/clean state. `id` equals `repoConfig.path`.

### GitStatus — `Models/GitStatus.swift`

Value type (`struct`, `Equatable`, `Sendable`). Counts: `modifiedCount`, `addedCount`, `deletedCount`, `untrackedCount`, `conflictCount`. Computed: `isClean`, `hasConflict`, `totalChanges`, `summary` string.

### GitCommandRunner — `Services/GitCommandRunner.swift`

`final class`, `Sendable`. Runs git subprocess on a private `DispatchQueue`. Implements timeout via racing two tasks in `withThrowingTaskGroup`. Throws `GitError` (`.timeout`, `.notFound`, `.executionFailed`, `.invalidDirectory`). Separate `fetchRunner` instance uses 30 s timeout.

### FileWatcherService — `Services/FileWatcherService.swift`

`final class`, `@unchecked Sendable` (state confined to private `queue`). Opens `.git` directory with `O_EVTONLY` and creates `DispatchSourceFileSystemObject` on `.write` events. Debounces callbacks by 1 s before calling the `onChange` closure.

### RepoMonitorService — `Services/RepoMonitorService.swift` + `+Refresh.swift`

`@Observable` orchestrator. Owns `FileWatcherService`, two `GitCommandRunner` instances, a `DispatchSourceTimer` (5-min fetch cycle), and a wake observer. Public API: `start(configs:)`, `addRepo(_:)`, `removeRepo(repoId:)`, `refreshAll()`. Refresh extension runs parallel git commands (`status --porcelain`, `branch --show-current`, `stash list`) then evaluates notifications on state transitions.

### DashboardViewModel — `Views/MenuBarPopover/DashboardViewModel.swift`

`@Observable`. Holds and proxies `RepoMonitorService`. Handles add/remove repo logic including `.git` validation, duplicate check, bookmark creation, SwiftData insert/save, and max-repo-count enforcement.

### GitOutputParser — `Utilities/GitOutputParser.swift`

Stateless `enum` with static methods: `parseStatus`, `parseBranch`, `parseAheadBehind`, `parseStashCount`, `parseLog`, `parseFileChanges`, `parseBranches`. All inputs are raw git stdout strings.

### Constants — `Utilities/Constants.swift`

- `AppConstants` — `appName`
- `nonisolated enum GitDefaults` — `gitPath`, `timeout`, `maxRepoCount`
- `enum SFSymbols` — SF Symbol name strings
- `enum StatusColor` — `Color` values for status states

---

## Dependencies

None. All functionality uses Apple system frameworks only.
