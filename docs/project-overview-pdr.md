# oioGit — Project Overview & Product Development Requirements

**Version**: 1.0.0
**Status**: Release Complete (v1.0)
**Platform**: macOS 14+ — menu bar app (NOT iOS)
**Author**: Vince Tran
**Created**: 2026-03-25
**Last Updated**: 2026-03-26

---

## Executive Summary

oioGit is a native macOS menu bar application that monitors multiple local Git repositories simultaneously. It runs as a lightweight background process (no Dock icon), surfacing real-time repo status — branch, changed files, ahead/behind remote, stash count, conflicts — via a `MenuBarExtra` popover. Developers get at-a-glance awareness of all their repos without switching to a terminal or Git client.

v1.0 is production-ready. All five planned phases are complete or substantially complete (Phase 5 at 60%: global hotkey and inline diff implemented; WidgetKit and GitHub API deferred).

---

## Target Users

- Developers managing multiple repos simultaneously (freelancers, team leads, side-project authors)
- Developers who want passive Git awareness without context-switching to a terminal
- macOS power users who prefer menu bar utilities over persistent app windows

---

## Implemented Features

### 1. Menu Bar Icon

`NSStatusItem` with an SF Symbol icon. No Dock icon (`.accessory` activation policy). Clicking opens the popover dashboard.

### 2. Popover Dashboard (DashboardView, 340 × 420 pt)

Scrollable list of repo cards. Each card shows:
- Repo name (alias if set, otherwise folder name)
- Current branch
- Status indicator: clean / N changed files / conflict
- Ahead ↑ / behind ↓ remote counts
- Stash count
- Last-updated timestamp
- Color-coded status dot (`StatusBadgeView`)

Right-click context menu per card: open Terminal, open in IDE, copy branch name, copy repo path, pull latest, hide repo.

### 3. Repo Detail View

Tapped from a repo card. Three tabs (segmented control):
- **Changed Files** — staged and unstaged files grouped by status; tap file to view inline diff (`MiniDiffView`)
- **Commit Log** — 20 most recent commits with hash, author, message, relative time
- **Branches** — local and remote branches; current branch highlighted

### 4. Quick Actions

Available from both the context menu (right-click on card) and the detail view toolbar:
- Open Terminal at repo root
- Open repo in configured IDE (VS Code, Xcode, etc.)
- Open in Finder
- Copy current branch name
- Copy repo path

### 5. Notification System

macOS `UNUserNotificationCenter` notifications, configurable per type:
- Merge conflict detected
- Behind remote (new commits available)
- Uncommitted changes stale for configurable duration
- Unpushed commits stale for configurable duration
- Detached HEAD state

Notification taps deep-link to the relevant repo's detail view.

### 6. Repo Management

- Add repos via `NSOpenPanel` (file picker)
- Auto-scan a parent directory to find all `.git` subdirectories (`RepoScannerService`)
- Assign custom alias and color per repo
- Sort by name, status, or last modified
- Hide/unhide repos from dashboard
- Remove repos with confirmation
- Maximum 15 repos (configurable) to cap resource usage

### 7. Settings Panel (SettingsView, 450 × 320 pt)

Separate `Settings` scene window with three tabs:
- **General** — polling interval, git binary path, preferred IDE, max repo count, launch at login
- **Repos** — add/remove/scan repos, edit aliases
- **Notifications** — per-type notification toggles

### 8. Global Hotkey

`Control + Shift + G` (⌃⇧G) registered via `NSEvent.addGlobalMonitorForEvents`. Toggles the popover from any app. Registered in `GlobalHotkeyService`.

### 9. Inline Diff Viewer

`MiniDiffView` renders unified diff output for any changed file. Accessible from the Changed Files tab in the detail view.

### 10. Custom Hotkey Recorder

Users can configure their own global keyboard shortcut in Settings > General > Keyboard Shortcut. `HotkeyRecorderView` captures key combinations, validates modifier keys (Control/Option/Command), detects conflicts with known macOS system shortcuts, and saves to UserDefaults. `GlobalHotkeyService` reads the dynamic hotkey from `AppSettings.shared`.

### 11. GitHub Token Management (Keychain)

`KeychainService` wraps the macOS Security framework for secure token storage. The GitHub tab in Settings provides:
- SecureField for PAT entry (never logged or displayed after save)
- Validate button to test token via GitHub API (`/user` endpoint)
- Masked display (`ghp_...xxxx`) showing first 4 and last 4 chars
- Delete button with confirmation

Token is stored in Keychain with service `com.oioGit.github` and account `github-pat`.

### 12. GitHub API Integration for CI/CD Status

`GitHubAPIService` fetches the latest GitHub Actions workflow run for repos with GitHub remotes:
- Parses remote URLs (HTTPS and SSH formats) via `GitHubRemoteParser`
- Polls on configurable interval (1/5/15 min) during periodic fetch
- Updates `RepoState.ciStatus` with state (success/failure/pending/running/none)
- Gracefully handles rate limiting, unauthorized tokens, and private repo access

### 13. CI/CD Status Badges

`CIStatusBadgeView` displays a color-coded indicator on each repo card:
- Green checkmark = success
- Red X = failure
- Yellow clock = running
- Gray = pending

`CIStatusDetailView` in repo detail header shows workflow name, status, last run time, and a link to open the workflow run in GitHub.

### 14. macOS Desktop Widget (WidgetKit)

`oioGitWidget` extension provides two widget sizes:
- Small (1 repo): Shows repo name, branch, status dot, changed count
- Medium (3-4 repos): Compact list with name, branch, status per row

Data shared via App Group `group.com.oioGit.shared`:
- `SharedDataService.writeSnapshots()` encodes repo states to JSON and writes to shared UserDefaults
- `RepoStatusTimelineProvider` reads snapshots and creates 15-min refresh timeline

---

## Technical Requirements

### Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | App must launch as a menu bar extra — no Dock icon |
| FR-02 | App must display all tracked repos in a popover dashboard |
| FR-03 | App must update repo status within 2 s of a `.git` directory change |
| FR-04 | App must fetch remote status on a background timer (default 5 min) |
| FR-05 | App must persist tracked repo list across launches (SwiftData) |
| FR-06 | App must access repo directories via security-scoped bookmarks |
| FR-07 | App must deliver macOS notifications for configured event types |
| FR-08 | App must support a global hotkey to toggle the popover |
| FR-09 | App must provide quick-action shortcuts to open terminal or IDE |
| FR-10 | App must display inline diffs for changed files |

### Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | Minimum deployment: macOS 14.0 (Sonoma) |
| NFR-02 | Language: Swift 5.9+ |
| NFR-03 | Git command timeout: 5 s (status/branch); 30 s (fetch) |
| NFR-04 | Maximum tracked repos: 15 (default) to limit subprocess overhead |
| NFR-05 | File watcher debounce: 1 s minimum between refresh triggers |
| NFR-06 | No third-party dependencies — Apple system frameworks only |
| NFR-07 | App must not store credentials or Git tokens |
| NFR-08 | All file system access must use security-scoped bookmarks when available |
| NFR-09 | Memory footprint must remain lightweight (background menu bar app) |
| NFR-10 | Distribution: direct (non-App Store); sandbox enabled |

### Technical Constraints

- Language: Swift 5.9+
- UI: SwiftUI + AppKit (`NSStatusItem`, `NSOpenPanel`, `NSWorkspace`)
- Persistence: SwiftData (`RepoConfig` @Model, SQLite-backed)
- File watching: `DispatchSource.makeFileSystemObjectSource` on `.git`
- Git operations: `Process` API (git CLI subprocess) — no libgit2
- Notifications: `UNUserNotificationCenter`
- Launch at login: `SMAppService`
- Global hotkey: `NSEvent.addGlobalMonitorForEvents` + Carbon `kVK_ANSI_G`
- Sandbox: enabled; stale bookmarks surface "re-add repository" error

---

## Architecture Decisions (Accepted)

| ADR | Decision | Rationale |
|---|---|---|
| ADR-001 | macOS menu bar app, not iOS | Product pivot; target use case is desktop multi-repo monitoring |
| ADR-002 | `MenuBarExtra` (.window style) for popover UI | Native macOS API, no NSWindow management needed |
| ADR-003 | `@Observable` (Swift 5.9 Observation) instead of `ObservableObject` | Lower boilerplate, finer-grained re-render |
| ADR-004 | Git CLI via `Process` API, no libgit2 | Zero dependencies; git always available on developer machines |
| ADR-005 | SwiftData for repo list persistence | Native SwiftUI integration; simple single-model schema |
| ADR-006 | Security-scoped bookmarks for file access | Required for sandboxed apps to survive app restarts |
| ADR-007 | `DispatchSource` for file watching (not FSEvents) | Simpler API for watching a single `.git` directory per repo |
| ADR-008 | No Dock icon (`NSApp.setActivationPolicy(.accessory)`) | Menu bar utility convention; avoids cluttering Dock |
| ADR-009 | Direct distribution (non-App Store) | Avoids Sandbox restrictions on `Process` API and file access |
| ADR-010 | No third-party dependencies | Minimises maintenance burden and supply-chain risk |

---

## Acceptance Criteria (v1.0)

### Core Functionality
- [x] Menu bar icon appears with no Dock icon on launch
- [x] Popover opens on icon click showing tracked repos
- [x] Repo status updates within 2 s of git operation in terminal
- [x] Repos persist after app restart
- [x] Security-scoped bookmarks resolve correctly after restart

### Dashboard
- [x] Each repo card shows branch, status, ahead/behind, stash count
- [x] Status dot color reflects clean/dirty/conflict state
- [x] Right-click context menu provides quick actions

### Detail View
- [x] Changed Files tab lists staged and unstaged files
- [x] Commit Log tab shows 20 recent commits
- [x] Branches tab shows local and remote branches
- [x] Tapping a changed file opens inline diff

### Settings & Management
- [x] Settings window opens from popover
- [x] User can add repos via file picker
- [x] User can auto-scan a parent directory for repos
- [x] Launch at login toggle works via SMAppService
- [x] Polling interval and git path are configurable

### Notifications
- [x] App requests notification permission on first launch
- [x] Notifications fire for conflict, behind remote, detached HEAD
- [x] Notification types are individually toggleable
- [x] Tapping notification opens the relevant repo detail

### Advanced
- [x] Global hotkey (⌃⇧G) toggles popover from any app
- [x] Inline diff viewer renders unified diff output

---

## Current State (v1.0)

All five phases implemented and complete:

| Phase | Title | Status |
|---|---|---|
| 1 | MVP: Menu Bar & Dashboard | Complete (100%) |
| 2 | File Monitoring & Auto-Refresh | Complete (100%) |
| 3 | Notifications & Detail View | Complete (100%) |
| 4 | Polish, Settings & Groups | Complete (100%) |
| 5 | Advanced Features | Complete (100%) — hotkey, CI/CD, widgets all implemented |

Codebase: ~3,770 LOC across 33 Swift source files. Zero third-party dependencies.

---

## Version History

| Version | Date | Notes |
|---|---|---|
| 0.1.0 | 2026-03-25 | Initial Xcode scaffold (iOS template, since replaced) |
| 1.0.0 | 2026-03-26 | macOS menu bar app — all phases 1–5 delivered |
