# Phase 5: Advanced Features

## Context Links

- **Parent**: [plan.md](./plan.md)
- **Dependencies**: Phase 4 (Polish, Settings & Groups) must be complete
- **Research**: [SwiftUI Menu Bar](./research/researcher-01-swiftui-menubar-report.md), [System APIs](./research/researcher-02-system-apis-report.md)
- **Standards**: `docs/code-standards.md`

---

## Overview

- **Date**: 2026-03-25
- **Description**: Global keyboard shortcuts, macOS desktop widgets, GitHub CI/CD status via API, inline mini diff viewer
- **Priority**: Low (nice-to-have)
- **Implementation Status**: Not started
- **Review Status**: Pending

---

## Key Insights (from research)

- Global hotkeys via `NSEvent.addGlobalMonitorForEvents` or `HotKey` package
- WidgetKit for macOS widgets (macOS 14+); timeline-based updates
- GitHub REST API `/repos/:owner/:repo/actions/runs` for CI/CD status
- Diff parsing: `git diff --stat` for summary, `git diff` for full patch

---

## Requirements

### Functional
- FR-01: Global keyboard shortcut to toggle popover (e.g., ⌃⇧G)
- FR-02: macOS widget showing top repos status at a glance
- FR-03: GitHub CI/CD status per repo (last workflow run: pass/fail/running)
- FR-04: Inline mini diff viewer in Changed Files tab (staged/unstaged)

### Non-Functional
- NFR-01: Widget updates every 15-30 min (WidgetKit timeline)
- NFR-02: GitHub API rate-limited; cache responses for 60s
- NFR-03: Diff viewer handles files up to 5000 lines without lag
- NFR-04: Global shortcut must not conflict with system shortcuts

---

## Architecture

### Component Design
```
oioGit/
├── Services/
│   ├── GlobalHotkeyService.swift    # NSEvent global monitor
│   └── GitHubAPIService.swift       # REST API for CI/CD status
├── Views/
│   └── Detail/
│       └── MiniDiffView.swift       # Inline diff renderer
├── Widgets/
│   ├── oioGitWidget.swift           # Widget entry point
│   ├── RepoStatusEntry.swift        # Timeline entry model
│   └── RepoStatusWidgetView.swift   # Widget SwiftUI view
└── oioGitWidgetExtension/           # Separate target for WidgetKit
```

### Data Flow (GitHub CI/CD)
```
RepoConfig has optional `githubRemoteURL`
  → GitHubAPIService extracts owner/repo from remote URL
  → GET /repos/:owner/:repo/actions/runs?per_page=1
  → Parse: conclusion (success/failure), status (in_progress), updated_at
  → CIStatus model stored in RepoState
  → RepoCardView shows CI badge (✓ green / ✗ red / ⟳ yellow)
```

### Data Flow (Widget)
```
WidgetKit timeline provider
  → Reads shared App Group container (UserDefaults suite)
  → RepoMonitorService writes summary data to shared container
  → Widget displays: repo name, branch, status color, CI badge
  → Refreshes every 15-30 min via timeline
```

---

## Related Code Files

### Create
| Path | Purpose |
|------|---------|
| `oioGit/Services/GlobalHotkeyService.swift` | Register/unregister global keyboard shortcut |
| `oioGit/Services/GitHubAPIService.swift` | GitHub REST API client for CI/CD status |
| `oioGit/Models/CIStatus.swift` | CI run data: conclusion, status, updatedAt, url |
| `oioGit/Views/Detail/MiniDiffView.swift` | Syntax-highlighted inline diff |
| `oioGitWidget/oioGitWidget.swift` | WidgetKit entry point + timeline provider |
| `oioGitWidget/RepoStatusEntry.swift` | Timeline entry: repo name, branch, status |
| `oioGitWidget/RepoStatusWidgetView.swift` | Widget view: compact repo status list |

### Modify
| Path | Purpose |
|------|---------|
| `oioGit/App/oioGitApp.swift` | Init GlobalHotkeyService; register App Group |
| `oioGit/Models/RepoConfig.swift` | Add `githubRemoteURL: String?` |
| `oioGit/Models/RepoState.swift` | Add `ciStatus: CIStatus?` |
| `oioGit/Views/MenuBarPopover/RepoCardView.swift` | Add CI badge |
| `oioGit/Views/Detail/ChangedFilesView.swift` | Add inline diff toggle per file |
| `oioGit/Views/Settings/GeneralSettingsView.swift` | Add hotkey config, GitHub token |
| `oioGit/Services/RepoMonitorService.swift` | Write summary to App Group container |

---

## Implementation Steps

1. **Global Hotkey**: Create `GlobalHotkeyService` using `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)`; default ⌃⇧G; store custom combo in AppSettings; toggle popover via `MenuBarExtraAccess` or NSStatusItem button action
2. **Hotkey Settings**: Add keyboard shortcut recorder in GeneralSettingsView; save modifier + key code to AppSettings
3. **CIStatus Model**: Struct with `conclusion: String?` (success/failure/cancelled), `status: String` (completed/in_progress/queued), `updatedAt: Date`, `htmlURL: URL?`
4. **GitHubAPIService**: Parse remote URL to extract owner/repo; `func fetchLatestRun(owner:repo:token:) async throws -> CIStatus`; use URLSession; cache 60s in-memory; handle rate limiting (403) gracefully
5. **GitHub Token**: Store in Keychain (not UserDefaults); add token field in Settings (SecureField); optional — CI features disabled if no token
6. **CI Badge in RepoCardView**: Small circle/icon: green checkmark (success), red X (failure), yellow spinner (in_progress), gray dash (no CI / no token)
7. **MiniDiffView**: Run `git diff -- <filepath>` for unstaged or `git diff --cached -- <filepath>` for staged; parse unified diff format; render with SwiftUI Text + AttributedString; green/red line highlighting; monospace font
8. **Diff toggle**: In ChangedFilesView, disclosure triangle per file to expand inline MiniDiffView
9. **Widget Target**: Add `oioGitWidgetExtension` target to Xcode project; configure App Group (e.g., `group.com.vincetran.oioGit`)
10. **Shared Data**: RepoMonitorService writes `[RepoSummary]` (name, branch, statusColor) to UserDefaults(suiteName: appGroup) as JSON
11. **Widget Timeline Provider**: Read shared UserDefaults; create TimelineEntry with repo summaries; policy: `.after(Date().addingTimeInterval(900))` (15 min)
12. **Widget View**: Compact list of top 3-5 repos with name, branch, status dot; supports `.systemSmall` and `.systemMedium` families

---

## Todo List

- [ ] Create GlobalHotkeyService with NSEvent monitor
- [ ] Add hotkey recorder in settings
- [ ] Create CIStatus model
- [ ] Create GitHubAPIService with caching
- [ ] Add GitHub token to Keychain + settings UI
- [ ] Add CI badge to RepoCardView
- [ ] Create MiniDiffView with syntax highlighting
- [ ] Add diff toggle in ChangedFilesView
- [ ] Create Widget extension target
- [ ] Set up App Group shared container
- [ ] Create widget timeline provider
- [ ] Create widget view (small + medium)
- [ ] Test: global hotkey toggles popover
- [ ] Test: CI status fetches and displays correctly
- [ ] Test: diff view renders for modified files
- [ ] Test: widget shows current repo status

---

## Success Criteria

- Global shortcut (⌃⇧G default) toggles popover from anywhere
- CI/CD badge visible on repos with GitHub remotes + configured token
- Inline diff expands per file in Changed Files tab
- macOS widget shows top repos with correct status colors
- Widget refreshes automatically every 15 min
- GitHub API failures degrade gracefully (badge hidden, no crash)
- Hotkey is configurable in settings

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Global hotkey conflicts with other apps | Med | Let user customize; detect conflicts |
| GitHub API rate limit (60/hr unauthenticated) | High | Require token; cache aggressively; 60s TTL |
| WidgetKit data sharing complexity | Med | Simple JSON in UserDefaults; no SwiftData in widget |
| Diff rendering slow for large files | Med | Truncate to first 200 lines; show "open in IDE" fallback |
| App Group provisioning for widget | Low | Document setup; non-App Store simplifies signing |

---

## Security Considerations

- GitHub personal access token stored in Keychain only
- Token requires minimal scope: `repo:status` or `actions:read`
- API requests use HTTPS; no plaintext credentials in URLs
- Global hotkey: no keylogging — only monitors specific key combo
- Widget reads shared container: no sensitive data (names, branches, colors only)

---

## Next Steps

This is the final planned phase. Future work could include:
- Git operations from menu bar (commit, push, pull)
- Multiple remote support
- Bitbucket / GitLab CI/CD integration
- Custom menu bar icon themes

---

## Unresolved Questions

- Should hotkey be recordable (like Raycast) or preset choices only?
- Widget: show all repos or just "needs attention" repos?
- GitHub API: support GitHub Enterprise Server (custom base URL)?
- Diff view: syntax highlighting by file extension or plain colored lines?
