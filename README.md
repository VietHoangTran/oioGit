# oioGit

A native macOS menu bar app for monitoring multiple Git repositories at a glance.

**Status**: v1.0 — Production Ready
**Platform**: macOS 14+ (Sonoma, Sequoia)
**Language**: Swift 5.9+ / SwiftUI + AppKit
**Author**: Vince Tran

---

## About

oioGit runs in the macOS menu bar (no Dock icon). It watches local Git repositories in real time — surfacing branch, dirty file count, ahead/behind remote, stash count, and conflicts — so developers never need to switch to a terminal just to check repo state.

---

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI + AppKit |
| Platform | macOS 14+ |
| Persistence | SwiftData (SQLite) |
| File Watching | DispatchSource (`makeFileSystemObjectSource`) |
| Git Operations | Process API (git CLI subprocess) |
| Notifications | UNUserNotificationCenter |
| Launch at Login | SMAppService |
| Global Hotkey | NSEvent global monitor + Carbon key codes |
| Unit Testing | Swift Testing (`import Testing`) |
| UI Testing | XCTest |
| Dependencies | None — Apple system frameworks only |

---

## Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 15+ (latest stable)
- Git installed at `/usr/bin/git` or a custom path configured in Settings

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd oioGit
   ```

2. Open the Xcode project:
   ```bash
   open oioGit.xcodeproj
   ```

3. Select **My Mac** as the run destination and press `Cmd+R` to build and run.

4. The app appears in the menu bar (top-right). Click the icon to open the dashboard.

5. Run tests with `Cmd+U`.

> **Note**: App Sandbox is enabled. On first launch, use the Settings > Repos panel to add repositories so the app can create security-scoped bookmarks for persistent access.

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
│   │   └── GlobalHotkeyService.swift        # NSEvent global monitor (⌃⇧G)
│   ├── Views/
│   │   ├── MenuBarPopover/
│   │   │   ├── DashboardView.swift          # Root popover (340×420 pt)
│   │   │   ├── DashboardViewModel.swift     # @Observable VM
│   │   │   ├── RepoCardView.swift           # Per-repo summary row
│   │   │   └── StatusBadgeView.swift        # Colored status dot
│   │   ├── Detail/
│   │   │   ├── RepoDetailView.swift         # Segmented tab container
│   │   │   ├── ChangedFilesView.swift       # Staged/unstaged file list
│   │   │   ├── CommitLogView.swift          # Recent commits list
│   │   │   ├── BranchListView.swift         # Local + remote branches
│   │   │   └── MiniDiffView.swift           # Inline unified diff
│   │   └── Settings/
│   │       ├── SettingsView.swift               # TabView (450×320 pt)
│   │       ├── GeneralSettingsView.swift         # Polling, git path, IDE, launch
│   │       ├── RepoManagerView.swift             # Add / remove / scan repos
│   │       └── NotificationSettingsView.swift    # Per-type notification toggles
│   └── Utilities/
│       ├── Constants.swift          # AppConstants, GitDefaults, SFSymbols, StatusColor
│       └── GitOutputParser.swift    # Pure static parsers for git CLI output
├── oioGitTests/
├── oioGitUITests/
└── docs/
```

---

## Documentation

| Document | Description |
|---|---|
| [Project Overview & PDR](docs/project-overview-pdr.md) | Requirements, features, architecture decisions, acceptance criteria |
| [Codebase Summary](docs/codebase-summary.md) | File structure, component descriptions, LOC reference |
| [Code Standards](docs/code-standards.md) | Swift/SwiftUI conventions, patterns, thread safety rules |
| [System Architecture](docs/system-architecture.md) | MVVM layers, data flow diagrams, concurrency model |
| [Project Roadmap](docs/project-roadmap.md) | Phase breakdown, completion status, future enhancements |

---

## Development Guidelines

- MVVM pattern — Views are purely presentational; no business logic in View files
- One type per file; max 200 lines per Swift source file
- Use `@Observable` (not `ObservableObject`); ViewModels held as `@State`
- No force unwrap (`!`) — use `guard let` or `if let`
- `RepoState` mutations must occur on `@MainActor`
- All new views must include a `#Preview` macro
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

See [docs/code-standards.md](docs/code-standards.md) for full guidelines.

---

## Current Status

**v1.0 — Production Ready**

All planned phases complete (Phase 5 at 60% — global hotkey and inline diff implemented; WidgetKit and GitHub CI intentionally deferred per YAGNI).

Key features delivered:
- Real-time menu bar Git status for up to 15 repos
- Popover dashboard with repo cards and context menus
- Detail view: changed files, commit log, branch list, inline diff
- macOS notifications for conflicts, behind-remote, detached HEAD
- Full settings panel with launch-at-login, polling config, IDE selection
- Global hotkey ⌃⇧G to toggle popover from any app

---

## License

TBD
