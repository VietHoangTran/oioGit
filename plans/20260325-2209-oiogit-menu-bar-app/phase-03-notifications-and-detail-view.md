# Phase 3: Notifications & Detail View

## Context Links

- **Parent**: [plan.md](./plan.md)
- **Dependencies**: Phase 2 (Monitoring) must be complete
- **Research**: [System APIs](./research/researcher-02-system-apis-report.md)
- **Standards**: `docs/code-standards.md`

---

## Overview

- **Date**: 2026-03-25
- **Description**: Add repo detail view with changed files, commit log, branch list. Implement notification system for conflicts, behind remote, stale changes. Add quick actions (open terminal/IDE, copy path/branch).
- **Priority**: High
- **Implementation Status**: Complete
- **Review Status**: Reviewed & fixes applied (2026-03-26)

---

## Key Insights (from research)

- UNUserNotificationCenter fully supported on macOS; needs explicit permission
- Request `[.alert, .sound]` authorization on first launch
- Action buttons via UNNotificationAction for "Open Repo" action
- Deep navigation in MenuBarExtra.window is awkward; keep flat (detail replaces dashboard, back button)
- NSWorkspace.shared.open for terminal/IDE launch

---

## Requirements

### Functional
- FR-01: Click repo card navigates to detail view within popover
- FR-02: Detail view tabs: Changed Files, Commit Log, Branches
- FR-03: Changed Files shows staged/unstaged groups with file names + status
- FR-04: Commit Log shows 20 recent commits (hash, message, author, time)
- FR-05: Branches tab lists local/remote branches, highlights current
- FR-06: Quick actions: open in Terminal, open in IDE, copy branch name, copy path
- FR-07: Right-click context menu on repo card for quick actions
- FR-08: Notifications for: merge conflict, behind remote, stale uncommitted (2hr), detached HEAD
- FR-09: User can enable/disable notification types globally

### Non-Functional
- NFR-01: Detail view loads within 1s for repos with <1000 files
- NFR-02: Notifications respect system Do Not Disturb
- NFR-03: Notification permission gracefully degrades if denied

---

## Architecture

### Component Design
```
Views/Detail/
├── RepoDetailView.swift       # Container with back button + TabView
├── ChangedFilesView.swift     # Staged/unstaged file list
├── CommitLogView.swift        # Scrollable commit list
└── BranchListView.swift       # Local/remote branch list

Services/
├── NotificationService.swift  # UNUserNotificationCenter wrapper
└── QuickActionService.swift   # Open terminal/IDE, clipboard ops
```

### Data Flow (Detail)
```
User taps repo card
  → DashboardView pushes RepoDetailView(repoState)
  → RepoDetailView fetches detailed data:
      - git status --porcelain (full file list)
      - git log --oneline -20
      - git branch -a
  → Populates tab views
```

### Data Flow (Notifications)
```
RepoMonitorService detects state change
  → Evaluates notification rules (conflict? behind? stale?)
  → NotificationService.send(type, repoName, message)
  → UNUserNotificationCenter delivers system notification
  → User taps notification → app opens popover to that repo
```

---

## Related Code Files

### Create
| Path | Purpose |
|------|---------|
| `oioGit/Models/CommitInfo.swift` | Struct: hash, message, author, date |
| `oioGit/Models/FileChange.swift` | Struct: path, status (modified/added/deleted/untracked), staged |
| `oioGit/Models/BranchInfo.swift` | Struct: name, isRemote, isCurrent |
| `oioGit/Models/NotificationRule.swift` | SwiftData @Model: type, enabled, threshold |
| `oioGit/Views/Detail/RepoDetailView.swift` | TabView container with back navigation |
| `oioGit/Views/Detail/ChangedFilesView.swift` | Staged/unstaged sections with FileChange rows |
| `oioGit/Views/Detail/CommitLogView.swift` | List of CommitInfo rows |
| `oioGit/Views/Detail/BranchListView.swift` | Local/remote branch sections |
| `oioGit/Services/NotificationService.swift` | UNUserNotificationCenter wrapper |
| `oioGit/Services/QuickActionService.swift` | Terminal/IDE launch, clipboard copy |

### Modify
| Path | Purpose |
|------|---------|
| `oioGit/Services/GitCommandRunner.swift` | Add `commitLog()`, `branchList()`, `conflictFiles()` |
| `oioGit/Utilities/GitOutputParser.swift` | Add `parseLog()`, `parseBranches()`, `parseFileChanges()` |
| `oioGit/Views/MenuBarPopover/DashboardView.swift` | Add navigation to detail; right-click context menu |
| `oioGit/Views/MenuBarPopover/RepoCardView.swift` | Add tap gesture + context menu |
| `oioGit/Services/RepoMonitorService.swift` | Add notification rule evaluation after state change |
| `oioGit/App/oioGitApp.swift` | Init NotificationService; request permission |

---

## Implementation Steps

1. **Create data models**: `CommitInfo` (hash, message, author, date), `FileChange` (path, status enum, isStaged), `BranchInfo` (name, isRemote, isCurrent)
2. **Extend GitCommandRunner**: `func commitLog(at: URL, count: Int) async throws -> String`; `func branchList(at: URL) async throws -> String`; `func conflictFiles(at: URL) async throws -> String`
3. **Extend GitOutputParser**: `parseLog()` splits `--oneline` output; `parseBranches()` parses `branch -a` output (strip remotes/origin/, detect `*` current); `parseFileChanges()` creates FileChange array from porcelain
4. **Create RepoDetailView**: NavigationStack or custom back-button pattern; `Picker` for tab selection (Changed Files / Commit Log / Branches); loads data on appear
5. **Create ChangedFilesView**: Two sections (Staged, Unstaged); each row shows file icon + path + status badge (M/A/D/?)
6. **Create CommitLogView**: List of rows: short hash (monospace), message (truncated), relative time
7. **Create BranchListView**: Sections for Local/Remote; current branch highlighted with checkmark
8. **Update DashboardView**: Wrap in NavigationStack; repo card tap navigates to RepoDetailView; add back button
9. **Add context menu to RepoCardView**: `.contextMenu { }` with: Open Terminal, Open IDE, Copy Branch, Copy Path, Pull Latest
10. **Create QuickActionService**: `openTerminal(at: URL)` via NSWorkspace + AppleScript/Terminal URL scheme; `openIDE(at: URL)` via `open -a "Visual Studio Code"` Process; `copyToClipboard(_ string: String)` via NSPasteboard
11. **Create NotificationService**: Request authorization on init; `func send(title:body:identifier:)` wraps UNNotificationRequest; register "Open Repo" action
12. **Create NotificationRule model**: SwiftData @Model with `notificationType: String` enum (conflict/behind/stale/detached), `isEnabled: Bool`, `thresholdMinutes: Int?`
13. **Wire notification evaluation**: In RepoMonitorService, after each refresh compare old vs new state; trigger notification if: conflict count > 0 (new), behind > 0 (new), uncommitted > 2hr, HEAD detached
14. **Handle notification tap**: UNUserNotificationCenterDelegate in AppDelegate; on tap, open popover and navigate to repo

---

## Todo List

- [x] Create CommitInfo, FileChange, BranchInfo models
- [x] Extend GitCommandRunner for log/branches/conflicts
- [x] Extend GitOutputParser for new formats
- [x] Create RepoDetailView with tab selection
- [x] Create ChangedFilesView
- [x] Create CommitLogView
- [x] Create BranchListView
- [x] Add navigation from dashboard to detail
- [x] Add right-click context menu to repo cards
- [x] Create QuickActionService (terminal, IDE, clipboard)
- [x] Create NotificationService with permission request
- [x] Create NotificationRule SwiftData model
- [x] Wire notification evaluation into monitor service
- [x] Handle notification tap (open popover to repo)
- [x] Test: navigate to detail, see changed files
- [x] Test: notification fires on conflict detection

---

## Success Criteria

- Clicking repo card shows detail view with back navigation
- Changed Files tab shows correct staged/unstaged files
- Commit Log shows 20 recent commits with correct data
- Branch list shows local/remote with current highlighted
- Right-click context menu works (open terminal, copy branch, etc.)
- Notifications fire for conflict, behind, stale, detached states
- Notification tap opens app to relevant repo

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Navigation inside popover is clunky | Med | Keep flat: detail replaces dashboard; single back button |
| Notification permission denied | Low | Show in-app banner; degrade gracefully |
| Terminal/IDE open fails (app not installed) | Low | Catch error; show alert with install hint |
| git log slow on large repos | Med | Limit to 20 commits; timeout applies |

---

## Security Considerations

- Notification content should not expose sensitive file paths (show repo name only)
- QuickActionService: use Process argument array, no shell injection
- Clipboard operations: only copy what user explicitly requested
- No credential handling in quick actions

---

## Next Steps

Phase 4 adds auto-scan directories, repo groups/aliases, full settings panel, launch at login, and UI polish.

---

## Unresolved Questions

- Best pattern for navigation inside MenuBarExtra.window? (NavigationStack vs manual view swap)
- Should "Pull Latest" quick action show progress/result?
- Stale uncommitted threshold: fixed 2hr or user-configurable?
