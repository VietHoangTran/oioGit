# oioGit — Codebase Summary

**Version**: 1.0.0 (Phases 1–5 Complete)
**Last Updated**: 2026-03-26
**Platform**: macOS 14+ — menu bar app (NOT iOS)
**Language**: Swift 5.9+ / SwiftUI + AppKit + WidgetKit
**Total**: ~3,770 LOC across 33 Swift source files + 7 widget files

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
│   │   ├── AppSettings.swift        # @Observable singleton, UserDefaults-backed
│   │   ├── HotkeyConfig.swift       # Hotkey configuration (modifiers + keyCode)
│   │   ├── CIStatus.swift           # CI/CD state enum + struct
│   │   └── WidgetRepoData.swift     # Shared data contract for widget
│   ├── Services/
│   │   ├── GitCommandRunner.swift           # Process API wrapper + timeout
│   │   ├── FileWatcherService.swift         # DispatchSource .git dir watcher
│   │   ├── RepoMonitorService.swift         # @Observable orchestrator
│   │   ├── RepoMonitorService+Refresh.swift # Refresh logic extension
│   │   ├── RepoMonitorService+CI.swift      # CI status fetch extension
│   │   ├── NotificationService.swift        # UNUserNotificationCenter wrapper
│   │   ├── QuickActionService.swift         # Terminal / IDE / Finder launch
│   │   ├── RepoScannerService.swift         # Recursive .git directory scanner
│   │   ├── GlobalHotkeyService.swift        # NSEvent global monitor (configurable)
│   │   ├── KeychainService.swift           # Security framework wrapper
│   │   ├── GitHubAPIService.swift           # GitHub Actions API client
│   │   └── SharedDataService.swift         # App Group data for widget
│   ├── Views/
│   │   ├── MenuBarPopover/
│   │   │   ├── DashboardView.swift      # Root popover view (340×420 pt)
│   │   │   ├── DashboardViewModel.swift # @Observable VM bridging monitor→view
│   │   │   ├── RepoCardView.swift       # Per-repo summary row
│   │   │   ├── StatusBadgeView.swift    # Colored dot status indicator
│   │   │   └── CIStatusBadgeView.swift  # CI/CD status badge
│   │   ├── Detail/
│   │   │   ├── RepoDetailView.swift     # Segmented tab container
│   │   │   ├── ChangedFilesView.swift   # Staged/unstaged file list
│   │   │   ├── CommitLogView.swift      # Recent commits list
│   │   │   ├── BranchListView.swift     # Local + remote branch list
│   │   │   ├── MiniDiffView.swift       # Inline diff display
│   │   │   └── CIStatusDetailView.swift # Expanded CI info
│   │   └── Settings/
│   │       ├── SettingsView.swift           # TabView container (450×380 pt)
│   │       ├── GeneralSettingsView.swift    # Polling, git path, IDE, launch
│   │       ├── HotkeyRecorderView.swift    # Custom hotkey recording UI
│   │       ├── GitHubAccountSettingsView.swift # GitHub token management
│   │       ├── RepoManagerView.swift        # Add / remove / scan repos
│   │       └── NotificationSettingsView.swift # Per-type notification toggles
│   └── Utilities/
│       ├── Constants.swift          # AppConstants, GitDefaults, SFSymbols, StatusColor
│       ├── GitOutputParser.swift    # Pure parser for all git command outputs
│       └── GitHubRemoteParser.swift # GitHub URL parser (HTTPS + SSH)
├── oioGitWidget/                    # WidgetKit extension
│   ├── RepoStatusWidget.swift         # Widget definition (small/medium)
│   ├── RepoStatusTimelineProvider.swift # Timeline provider (15-min refresh)
│   ├── RepoStatusEntry.swift           # Timeline entry type
│   ├── SmallRepoWidgetView.swift       # Small widget (1 repo)
│   ├── MediumRepoWidgetView.swift      # Medium widget (3-4 repos)
│   ├── WidgetRepoData.swift           # Shared data contract (duplicate)
│   └── oioGitWidgetBundle.swift        # @main widget bundle
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
| RepoMonitorService+Refresh.swift | 186 |
| DashboardView.swift | 171 |
| GitOutputParser.swift | 167 |
| RepoManagerView.swift | 152 |
| ChangedFilesView.swift | 139 |
| RepoDetailView.swift | 131 |
| MiniDiffView.swift | 116 |
| GitHubAPIService.swift | 115 |
| HotkeyRecorderView.swift | 108 |
| MediumRepoWidgetView.swift | 106 |
| BranchListView.swift | 106 |
| SmallRepoWidgetView.swift | 99 |
| GitCommandRunner.swift | 101 |
| GitHubAccountSettingsView.swift | 97 |
| RepoCardView.swift | 103 |
| RepoStatusTimelineProvider.swift | 95 |
| FileWatcherService.swift | 90 |
| RepoMonitorService.swift | 83 |
| CIStatusDetailView.swift | 78 |
| RepoStatusWidget.swift | 54 |
| All others | < 80 each |

---

## Core Technologies

| Technology | Usage |
|---|---|
| SwiftUI | All UI rendering + Widget views |
| AppKit | NSApp, NSOpenPanel, NSEvent, NSWorkspace |
| WidgetKit | Desktop widget extension (small/medium) |
| SwiftData | RepoConfig persistence (SQLite-backed) |
| Foundation / Process | Git subprocess execution |
| DispatchSource | File system event watching |
| UNUserNotificationCenter | macOS notification delivery |
| ServiceManagement / SMAppService | Launch-at-login registration |
| Security framework | Keychain storage for GitHub PAT |
| URLSession | GitHub API calls for CI/CD status |
| App Groups | Shared data between app and widget |
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
- `nonisolated enum HotkeyDefaults` — System conflict shortcuts
- `nonisolated enum KeychainConstants` — Service/account names
- `nonisolated enum CIDefaults` — GitHub API URL, polling interval
- `enum SFSymbols` — SF Symbol name strings
- `enum StatusColor` — `Color` values for status states

### HotkeyConfig — `Models/HotkeyConfig.swift`

- Struct storing `modifierFlags: UInt` and `keyCode: UInt16`
- Computed `displayString` and `readableString` for UI
- Static `default` (Control+Shift+G)
- `matches(_:)` method to test against NSEvent

### AppSettings Updates — `Models/AppSettings.swift`

- Added `hotkeyModifiers`, `hotkeyKeyCode` with UserDefaults backing
- Added `hotkeyConfig` computed property
- Added `ciStatusEnabled`, `ciPollingInterval` with UserDefaults backing

### KeychainService — `Services/KeychainService.swift`

- Security framework wrapper using `SecItemAdd/CopyMatching/Delete`
- `save(token:)`, `retrieve()`, `delete()`, `exists()` static methods
- `maskedToken()` for UI display (`ghp_...xxxx`)
- `KeychainError` enum for localized errors

### GitHubAPIService — `Services/GitHubAPIService.swift`

- `fetchLatestWorkflowRun(owner:repo:branch:)` async method
- Endpoint: `/repos/{owner}/{repo}/actions/runs?per_page=1`
- Bearer token auth from Keychain
- Handles 401 (unauthorized), 403 (rate limited), 404 (not found)
- Returns `CIStatus` struct with state, workflowName, lastRunDate, htmlURL

### GitHubRemoteParser — `Utilities/GitHubRemoteParser.swift`

- `parse(_:)` static method handling HTTPS and SSH URL formats
- Returns `(owner: String, repo: String)?` tuple or nil for non-GitHub remotes

### CIStatus — `Models/CIStatus.swift`

- `CIStatusState` enum (success/failure/pending/running/none)
- `CIStatus` struct with state, workflowName, lastRunDate, htmlURL
- Computed `color`, `sfSymbol`, `label` for UI

### RepoState Updates — `Models/RepoState.swift`

- Added `ciStatus: CIStatus` property

### RepoMonitorService+CI — `Services/RepoMonitorService+CI.swift`

- `fetchAllCIStatuses()` async method
- Parses remote URL, calls GitHubAPIService for each repo
- Guarded by `ciStatusEnabled` and Keychain token existence

### CIStatusBadgeView — `Views/MenuBarPopover/CIStatusBadgeView.swift`

- Small color-coded circle with SF Symbol overlay
- `.help()` tooltip showing workflow name, state, relative time
- Hidden when state is `.none`

### CIStatusDetailView — `Views/Detail/CIStatusDetailView.swift`

- Compact row showing workflow name, status, time
- Browser link to GitHub workflow run
- Refresh button to re-fetch CI status

### HotkeyRecorderView — `Views/Settings/HotkeyRecorderView.swift`

- "Record" button entering key-capture mode via `NSEvent.addLocalMonitorForEvents`
- Validates modifier keys (Control/Option/Command required)
- Detects system conflicts, shows warning
- "Reset to Default" button

### GitHubAccountSettingsView — `Views/Settings/GitHubAccountSettingsView.swift`

- SecureField for PAT entry
- Save/Validate/Delete buttons
- Validation via GitHub `/user` endpoint
- Status indicator (None/Saved/Validating/Valid/Invalid)
- Masked display after save (`ghp_...xxxx`)

### SharedDataService — `Services/SharedDataService.swift`

- `writeSnapshots(_:)` encodes `[WidgetRepoData]` to JSON
- Writes to App Group UserDefaults (`group.com.oioGit.shared`)
- Calls `WidgetCenter.shared.reloadAllTimelines()`

### WidgetRepoData — `Models/WidgetRepoData.swift` + `oioGitWidget/WidgetRepoData.swift`

- Codable struct with subset of RepoState fields for widget consumption
- Duplicated in both targets (simpler than shared framework)

### RepoStatusWidget — `oioGitWidget/RepoStatusWidget.swift`

- Widget definition with `StaticConfiguration`
- Supports `.systemSmall` and `.systemMedium` families
- Uses `RepoStatusTimelineProvider`

### RepoStatusTimelineProvider — `oioGitWidget/RepoStatusTimelineProvider.swift`

- `TimelineProvider` conformance
- `placeholder`, `getSnapshot`, `getTimeline` methods
- Reads data from `SharedDataReader` (App Group UserDefaults)
- 15-minute refresh via `.after(date)` policy

### SmallRepoWidgetView — `oioGitWidget/SmallRepoWidgetView.swift`

- Shows single repo: name, branch, status dot, changed count
- CI badge if available
- Empty state when no repos

### MediumRepoWidgetView — `oioGitWidget/MediumRepoWidgetView.swift`

- Shows 3-4 repos in compact list
- Each row: status dot, name, branch, counts, CI badge

---

## Dependencies

None. All functionality uses Apple system frameworks only.
