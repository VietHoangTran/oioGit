# Phase 1: MVP -- Menu Bar & Dashboard

## Context Links

- **Parent**: [plan.md](./plan.md)
- **Dependencies**: None (first phase)
- **Research**: [SwiftUI Menu Bar](./research/researcher-01-swiftui-menubar-report.md), [System APIs](./research/researcher-02-system-apis-report.md)
- **Standards**: `docs/code-standards.md`

---

## Overview

- **Date**: 2026-03-25
- **Description**: Establish menu bar app scaffold, git CLI integration, manual repo add, basic popover dashboard with repo cards
- **Priority**: Critical
- **Implementation Status**: Complete
- **Review Status**: Reviewed & approved (2026-03-26)

---

## Key Insights (from research)

- Use `MenuBarExtra` with `.window` style for native popover
- `LSUIElement = YES` hides dock icon; no `WindowGroup` in scene
- Init `ModelContainer` in `@main` struct, not lazily
- Process API + serial queue for git commands; 5s default timeout
- Security-scoped bookmarks for persistent directory access via NSOpenPanel

---

## Requirements

### Functional
- FR-01: App appears only in menu bar (no dock icon, no main window)
- FR-02: Menu bar icon shows aggregate status color (green/yellow/red)
- FR-03: Click icon opens popover with scrollable repo card list
- FR-04: User adds repos via NSOpenPanel folder picker
- FR-05: Each repo card shows: name, branch, status summary, last updated
- FR-06: Repos persist across app restarts (SwiftData)
- FR-07: Manual refresh button to re-scan all repos

### Non-Functional
- NFR-01: macOS 14+ (Sonoma) minimum
- NFR-02: Git commands timeout at 5s (configurable)
- NFR-03: Max 200 lines per source file
- NFR-04: Support system dark/light mode

---

## Architecture

### Component Design
```
oioGitApp (@main)
├── MenuBarExtra(.window)
│   └── DashboardView
│       └── RepoCardView (ForEach)
├── ModelContainer (SwiftData)
└── Services
    ├── GitCommandRunner (Process API)
    └── GitOutputParser (parse porcelain output)
```

### Data Flow
```
User adds repo (NSOpenPanel)
  → RepoConfig saved to SwiftData + security-scoped bookmark
  → GitCommandRunner runs `git status --porcelain`, `git branch --show-current`
  → GitOutputParser creates GitStatus
  → RepoState updated (@Observable)
  → DashboardView re-renders
  → Menu bar icon color updates based on aggregate status
```

---

## Related Code Files

### Create
| Path | Purpose |
|------|---------|
| `oioGit/App/oioGitApp.swift` | Replace existing; @main with MenuBarExtra scene |
| `oioGit/App/AppDelegate.swift` | NSApplicationDelegateAdaptor for lifecycle |
| `oioGit/Models/RepoConfig.swift` | SwiftData @Model: path, alias, bookmark, dateAdded |
| `oioGit/Models/RepoState.swift` | @Observable runtime state: branch, status, lastUpdated |
| `oioGit/Models/GitStatus.swift` | Struct: modified/added/deleted/conflicted counts, isClean |
| `oioGit/Services/GitCommandRunner.swift` | Process wrapper; async func run(command:at:) -> String |
| `oioGit/Utilities/GitOutputParser.swift` | Parse `git status --porcelain` output to GitStatus |
| `oioGit/Utilities/Constants.swift` | Default git path, timeout, SF Symbol names |
| `oioGit/Views/MenuBarPopover/DashboardView.swift` | Main popover: repo list, add button, refresh |
| `oioGit/Views/MenuBarPopover/RepoCardView.swift` | Single repo card UI |
| `oioGit/Views/MenuBarPopover/StatusBadgeView.swift` | Color-coded status indicator |

### Modify
| Path | Purpose |
|------|---------|
| `oioGit/Info.plist` | Add LSUIElement = YES |

### Delete
| Path | Purpose |
|------|---------|
| `oioGit/ContentView.swift` | Default template, replaced by DashboardView |

---

## Implementation Steps

1. **Configure Info.plist**: Add `LSUIElement = YES` to hide dock icon
2. **Replace oioGitApp.swift**: Remove WindowGroup, add MenuBarExtra(.window) scene; init ModelContainer for SwiftData
3. **Create AppDelegate.swift**: Use `@NSApplicationDelegateAdaptor`; handle app lifecycle (applicationDidFinishLaunching)
4. **Create Constants.swift**: Define `defaultGitPath = "/usr/bin/git"`, `gitTimeout = 5.0`, SF Symbol names for status colors
5. **Create RepoConfig.swift**: SwiftData @Model with `path: String`, `alias: String?`, `bookmarkData: Data?`, `dateAdded: Date`
6. **Create GitStatus.swift**: Struct with `modifiedCount`, `addedCount`, `deletedCount`, `conflictCount`, `isClean` computed property, `statusColor` computed (green/yellow/red)
7. **Create RepoState.swift**: @Observable class holding `repoConfig: RepoConfig`, `currentBranch: String`, `gitStatus: GitStatus`, `lastUpdated: Date?`, `isScanning: Bool`
8. **Create GitCommandRunner.swift**: `func run(_ args: [String], at directory: URL) async throws -> String` using Process + Pipe; serial DispatchQueue; timeout via Task racing pattern
9. **Create GitOutputParser.swift**: `static func parseStatus(_ output: String) -> GitStatus`; parse porcelain format (M/A/D/?? prefixes)
10. **Create StatusBadgeView.swift**: Circle with color (green/yellow/red) based on GitStatus
11. **Create RepoCardView.swift**: HStack with repo name, branch pill, status badge, last updated timestamp
12. **Create DashboardView.swift**: ScrollView + LazyVStack of RepoCardView; toolbar with "+" button (NSOpenPanel) and refresh button; inject ModelContainer via @Query
13. **Wire menu bar icon**: Use SF Symbol `"arrow.triangle.branch"` with dynamic tint color based on worst-status-across-all-repos
14. **Implement repo add flow**: NSOpenPanel → validate `.git` exists → create security-scoped bookmark → save RepoConfig → trigger initial scan
15. **Implement refresh**: Iterate all RepoConfigs, run git status + git branch for each, update RepoState array
16. **Delete ContentView.swift**: Remove default template file

---

## Todo List

- [ ] Configure Info.plist with LSUIElement
- [ ] Create MenuBarExtra app entry point
- [ ] Create SwiftData model (RepoConfig)
- [ ] Create GitCommandRunner service
- [ ] Create GitOutputParser utility
- [ ] Create GitStatus and RepoState models
- [ ] Create DashboardView with repo card list
- [ ] Create RepoCardView and StatusBadgeView
- [ ] Implement NSOpenPanel repo add flow
- [ ] Implement security-scoped bookmark save/restore
- [ ] Implement manual refresh
- [ ] Wire menu bar icon color to aggregate status
- [ ] Remove ContentView.swift
- [ ] Test: app launches as menu bar only
- [ ] Test: add repo, see status card
- [ ] Test: manual refresh updates status

---

## Success Criteria

- App appears only in menu bar; no dock icon
- Clicking menu bar icon opens popover dashboard
- User can add Git repos via folder picker
- Each repo shows branch name and clean/modified status
- Repos persist across restarts
- Menu bar icon changes color based on aggregate status
- Git commands fail gracefully with timeout

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| MenuBarExtra.window limited API | Med | Use basic popover; defer advanced state control to Phase 2 |
| SwiftData lifecycle in menu bar app | Med | Init ModelContainer eagerly in @main; test save/restore |
| Git not found at default path | Low | Validate on first launch; show error with config link |
| Security-scoped bookmark failure | Med | Fallback to re-prompt via NSOpenPanel |

---

## Security Considerations

- Never store repo paths in plaintext UserDefaults; use SwiftData
- Security-scoped bookmarks for file access persistence
- Git commands run with user-level permissions only
- No shell injection: use Process with argument array, not shell string
- Validate `.git` directory exists before adding repo

---

## Next Steps

Phase 2 adds FSEvents file watching, automatic refresh, ahead/behind counters, and periodic remote fetch.

---

## Unresolved Questions

- Should we use `MenuBarExtraAccess` package from Phase 1, or defer?
- Best UX for "git not found" error on first launch?
- Should repo add validate branch existence or just `.git` directory?
