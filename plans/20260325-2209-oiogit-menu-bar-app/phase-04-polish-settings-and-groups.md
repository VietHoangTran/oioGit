# Phase 4: Polish, Settings & Groups

## Context Links

- **Parent**: [plan.md](./plan.md)
- **Dependencies**: Phase 3 (Notifications & Detail) must be complete
- **Research**: [SwiftUI Menu Bar](./research/researcher-01-swiftui-menubar-report.md), [System APIs](./research/researcher-02-system-apis-report.md)
- **Standards**: `docs/code-standards.md`

---

## Overview

- **Date**: 2026-03-25
- **Description**: Auto-scan parent directories for repos, repo groups/aliases, full settings panel, launch at login (SMAppService), drag-and-drop repo add, sorting, UI animations
- **Priority**: Medium
- **Implementation Status**: Not started
- **Review Status**: Pending

---

## Key Insights (from research)

- SMAppService.mainApp for launch-at-login; query `.status` as source of truth (not UserDefaults)
- Default to disabled; user opts in
- Settings window: use SwiftUI `Settings` scene or `Window` scene (separate from popover)
- NSOpenPanel can select directories for auto-scan
- Drag-and-drop via `.onDrop(of: [.fileURL])`

---

## Requirements

### Functional
- FR-01: Auto-scan: user selects parent directory, app finds all `.git` subdirectories
- FR-02: Drag-and-drop folders onto popover to add repos
- FR-03: Assign aliases to repos (editable name)
- FR-04: Group repos into categories (e.g., "Client A", "Side Projects")
- FR-05: Sort repos by: name, status, last modified
- FR-06: Full settings panel: polling interval, git path, IDE, launch at login, max repos
- FR-07: Launch at login toggle via SMAppService
- FR-08: Hide/unhide repos from dashboard
- FR-09: Remove repo from monitoring

### Non-Functional
- NFR-01: Settings changes apply immediately (no restart)
- NFR-02: Auto-scan completes in <5s for directories with <100 subdirs
- NFR-03: Smooth animations for repo card reorder/add/remove

---

## Architecture

### Component Design
```
Views/Settings/
├── SettingsView.swift             # Main settings container
├── GeneralSettingsView.swift      # Polling, git path, IDE, launch at login
├── RepoManagerView.swift          # Add/remove/group/alias repos
└── NotificationSettingsView.swift # Per-type notification toggles

Services/
└── RepoScannerService.swift       # Scan directory tree for .git folders
```

### Data Flow (Auto-scan)
```
User selects parent directory (NSOpenPanel)
  → RepoScannerService.scan(directory:)
  → FileManager enumerates subdirectories (1-2 levels deep)
  → Filters for .git presence
  → Returns [URL] of discovered repos
  → User confirms which to add
  → RepoConfigs created + bookmarks saved
  → Watchers started for each
```

---

## Related Code Files

### Create
| Path | Purpose |
|------|---------|
| `oioGit/Services/RepoScannerService.swift` | Scan directory tree for git repos |
| `oioGit/Views/Settings/SettingsView.swift` | Settings window container |
| `oioGit/Views/Settings/GeneralSettingsView.swift` | Polling, git path, IDE, login toggle |
| `oioGit/Views/Settings/RepoManagerView.swift` | Repo list management (alias, group, remove) |
| `oioGit/Views/Settings/NotificationSettingsView.swift` | Notification type toggles |
| `oioGit/Models/RepoGroup.swift` | SwiftData @Model: name, color, repoIds |
| `oioGit/Models/AppSettings.swift` | @Observable: pollingInterval, gitPath, defaultIDE, maxRepos |

### Modify
| Path | Purpose |
|------|---------|
| `oioGit/App/oioGitApp.swift` | Add Settings scene; init AppSettings |
| `oioGit/Models/RepoConfig.swift` | Add `alias`, `groupId`, `isHidden` fields |
| `oioGit/Views/MenuBarPopover/DashboardView.swift` | Add drag-and-drop, sorting picker, group headers, gear icon for settings |
| `oioGit/Services/RepoMonitorService.swift` | Use AppSettings for polling interval; respect maxRepos |

---

## Implementation Steps

1. **Create AppSettings.swift**: @Observable class; properties: `pollingInterval: TimeInterval` (default 300), `gitBinaryPath: String` (default "/usr/bin/git"), `defaultIDE: String` (default "Visual Studio Code"), `maxRepoCount: Int` (default 15), `launchAtLogin: Bool`; backed by @AppStorage
2. **Create RepoGroup.swift**: SwiftData @Model with `name: String`, `colorHex: String`
3. **Update RepoConfig.swift**: Add `alias: String?`, `groupId: PersistentIdentifier?`, `isHidden: Bool` (default false), `sortOrder: Int`
4. **Create RepoScannerService.swift**: `func scan(directory: URL, maxDepth: Int = 2) -> [URL]`; uses FileManager.enumerator with depth limit; checks `.git` directory existence; returns sorted list
5. **Create SettingsView.swift**: TabView with General, Repos, Notifications tabs
6. **Create GeneralSettingsView.swift**: Form with: polling interval picker (30s/1m/5m/15m), git path text field with validation, IDE picker, launch at login toggle (SMAppService), max repo slider
7. **Implement launch at login**: `SMAppService.mainApp.register()` / `.unregister()` on toggle; read `.status` on init to sync UI
8. **Create RepoManagerView.swift**: List of all repos; inline edit alias; assign to group via picker; toggle hidden; remove button with confirmation
9. **Create NotificationSettingsView.swift**: Toggle switches for each notification type (conflict, behind, stale, detached); stale threshold picker
10. **Add Settings scene to oioGitApp**: `Settings { SettingsView() }` scene alongside MenuBarExtra
11. **Update DashboardView**: Add gear icon button that opens settings; add `.onDrop` handler for folder URLs; add sorting Picker in toolbar; group repos by RepoGroup with section headers; filter out isHidden repos
12. **Implement drag-and-drop**: `.onDrop(of: [.fileURL])` on DashboardView; validate dropped URL has `.git`; create RepoConfig + start watcher
13. **Add auto-scan UI**: Button in RepoManagerView opens NSOpenPanel; calls RepoScannerService; shows discovered repos in sheet; user checkmarks which to add
14. **Wire AppSettings into RepoMonitorService**: Polling timer reads interval from settings; git path passed to GitCommandRunner; maxRepos enforced on add
15. **Animations**: `.animation(.default)` on repo list changes; `.transition(.slide)` for card add/remove

---

## Todo List

- [ ] Create AppSettings model with @AppStorage
- [ ] Create RepoGroup SwiftData model
- [ ] Update RepoConfig with alias/group/hidden fields
- [ ] Create RepoScannerService
- [ ] Create SettingsView container
- [ ] Create GeneralSettingsView with all controls
- [ ] Implement SMAppService launch at login
- [ ] Create RepoManagerView
- [ ] Create NotificationSettingsView
- [ ] Add Settings scene to app
- [ ] Add drag-and-drop to dashboard
- [ ] Add sorting picker
- [ ] Add group section headers
- [ ] Add auto-scan directory flow
- [ ] Add animations for list changes
- [ ] Test: settings changes apply immediately
- [ ] Test: drag folder onto dashboard adds repo
- [ ] Test: auto-scan finds nested repos

---

## Success Criteria

- Settings window opens from gear icon with all tabs functional
- Launch at login toggle works via SMAppService
- Drag-and-drop folder adds repo to dashboard
- Auto-scan discovers repos in nested directories
- Repos can be aliased, grouped, hidden, removed
- Sorting works across all modes (name, status, modified)
- Polling interval change takes effect without restart
- Max repo limit enforced with clear message

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| SMAppService fails silently | Low | Check .status after register; show error |
| Auto-scan too slow on deep trees | Med | Limit depth to 2; show progress indicator |
| SwiftData migration on model changes | Med | Use lightweight migration; test upgrade path |
| Settings scene conflicts with popover | Low | Settings is separate window; independent lifecycle |

---

## Security Considerations

- Git binary path validation: check file exists and is executable
- Auto-scan: only scan user-selected directories (bookmark-scoped)
- No sensitive data in settings (git path, IDE name are safe)
- SMAppService: system-managed, no custom launch agents

---

## Next Steps

Phase 5 adds global keyboard shortcuts, macOS widgets, GitHub API integration, and mini diff viewer.

---

## Unresolved Questions

- Should groups be drag-and-drop reorderable?
- Auto-scan: scan 2 levels deep or let user configure depth?
- How to handle SwiftData schema migration if Phase 1 data exists?
