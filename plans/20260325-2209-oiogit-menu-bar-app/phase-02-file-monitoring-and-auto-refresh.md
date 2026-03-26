# Phase 2: File Monitoring & Auto-Refresh

## Context Links

- **Parent**: [plan.md](./plan.md)
- **Dependencies**: Phase 1 (MVP) must be complete
- **Research**: [System APIs](./research/researcher-02-system-apis-report.md)
- **Standards**: `docs/code-standards.md`

---

## Overview

- **Date**: 2026-03-25
- **Description**: Add real-time `.git` directory monitoring via DispatchSource, auto-refresh on change, ahead/behind remote counters, periodic `git fetch`
- **Priority**: High
- **Implementation Status**: Not started
- **Review Status**: Pending

---

## Key Insights (from research)

- DispatchSource.makeFileSystemObjectSource preferred over FSEvents for single-directory watching
- `.write` event mask captures file create/delete/modify in `.git/`
- Scales well to 15-20 directories; minimal GCD overhead
- Debounce via async dispatch delay (0.5-1s) to coalesce rapid events
- Serial queue for git command execution prevents race conditions

---

## Requirements

### Functional
- FR-01: Auto-detect `.git` directory changes and refresh repo status
- FR-02: Show commits ahead/behind remote on each repo card
- FR-03: Periodic `git fetch --all --quiet` (configurable interval: 1m/5m/15m)
- FR-04: Show stash count on repo card
- FR-05: Debounce rapid file changes (coalesce within 1s window)
- FR-06: Visual indicator when repo is being scanned

### Non-Functional
- NFR-01: CPU usage stays below 5% with 15 monitored repos idle
- NFR-02: File watchers clean up on repo remove or app quit
- NFR-03: Fetch operations must not block UI thread

---

## Architecture

### Component Design
```
RepoMonitorService (@Observable, singleton)
├── FileWatcherService (per-repo DispatchSource)
│   └── watches .git/ directory for .write events
├── GitCommandRunner (from Phase 1)
│   └── extended: fetchRemote(), aheadBehind(), stashCount()
└── Timer (periodic fetch)
    └── fires git fetch on configurable interval
```

### Data Flow
```
.git/ file changes detected by DispatchSource
  → debounce 1s
  → RepoMonitorService.refreshRepo(id:)
  → GitCommandRunner: status, branch, ahead/behind, stash
  → RepoState updated
  → DashboardView re-renders
  → Menu bar icon color recalculated

Timer fires (periodic fetch)
  → git fetch --all --quiet (per repo, serial)
  → triggers ahead/behind recalculation
```

---

## Related Code Files

### Create
| Path | Purpose |
|------|---------|
| `oioGit/Services/FileWatcherService.swift` | DispatchSource wrapper; start/stop watching a directory |
| `oioGit/Services/RepoMonitorService.swift` | Orchestrator: manages watchers, fetch timer, refresh logic |

### Modify
| Path | Purpose |
|------|---------|
| `oioGit/Services/GitCommandRunner.swift` | Add `fetchRemote()`, `aheadBehind()`, `stashCount()` |
| `oioGit/Utilities/GitOutputParser.swift` | Add `parseAheadBehind()`, `parseStashCount()` |
| `oioGit/Models/RepoState.swift` | Add `aheadCount`, `behindCount`, `stashCount` fields |
| `oioGit/Views/MenuBarPopover/RepoCardView.swift` | Display ahead/behind arrows, stash badge, scanning indicator |
| `oioGit/Views/MenuBarPopover/DashboardView.swift` | Inject RepoMonitorService; remove manual-only refresh |
| `oioGit/App/oioGitApp.swift` | Init RepoMonitorService at startup |

---

## Implementation Steps

1. **Create FileWatcherService.swift**: Class with `func startWatching(directory: URL, onChange: @escaping () -> Void)`; uses `DispatchSource.makeFileSystemObjectSource(fileDescriptor:eventMask:.write, queue:)`; stores active sources keyed by repo ID; `func stopWatching(repoId:)` and `func stopAll()`
2. **Implement debounce**: In FileWatcherService, coalesce events using `DispatchWorkItem` with 1s delay; cancel previous work item on new event
3. **Create RepoMonitorService.swift**: @Observable singleton; owns FileWatcherService instance; on init, starts watchers for all saved RepoConfigs; `func refreshRepo(_ config: RepoConfig) async`; `func refreshAll() async`
4. **Add periodic fetch timer**: `Timer.publish(every: interval)` or DispatchSource timer; runs `git fetch --all --quiet` per repo sequentially; interval stored in UserDefaults (default 5 minutes)
5. **Extend GitCommandRunner**: Add `func fetchRemote(at: URL) async throws`; `func aheadBehind(at: URL) async throws -> (ahead: Int, behind: Int)` using `git rev-list --left-right --count HEAD...@{upstream}`; `func stashCount(at: URL) async throws -> Int`
6. **Extend GitOutputParser**: `static func parseAheadBehind(_ output: String) -> (Int, Int)` -- parse tab-separated left/right counts; `static func parseStashCount(_ output: String) -> Int`
7. **Update RepoState**: Add `aheadCount: Int`, `behindCount: Int`, `stashCount: Int`, `isScanning: Bool`
8. **Update RepoCardView**: Show `"^2 v5"` style ahead/behind; stash icon + count; subtle spinner when `isScanning`
9. **Wire RepoMonitorService into app**: Init in oioGitApp; pass as environment; start watchers after ModelContainer loads
10. **Handle repo add/remove**: When repo added, start watcher; when removed, stop watcher + clean up
11. **Handle app lifecycle**: Stop watchers on `applicationWillTerminate`; restart on wake from sleep via `NSWorkspace.shared.notificationCenter`

---

## Todo List

- [ ] Create FileWatcherService with DispatchSource
- [ ] Implement 1s debounce for rapid changes
- [ ] Create RepoMonitorService orchestrator
- [ ] Add periodic git fetch timer
- [ ] Extend GitCommandRunner with fetch/ahead-behind/stash
- [ ] Extend GitOutputParser for new outputs
- [ ] Update RepoState model with new fields
- [ ] Update RepoCardView with ahead/behind and stash
- [ ] Wire monitoring into app lifecycle
- [ ] Handle wake-from-sleep re-init
- [ ] Test: modify file in repo, card updates automatically
- [ ] Test: 15 repos monitored, CPU usage acceptable
- [ ] Test: ahead/behind shows correctly after fetch

---

## Success Criteria

- Repo cards auto-update within 2s of `.git` directory change
- Ahead/behind counts display correctly
- Stash count visible when stashes exist
- Periodic fetch runs in background without UI freeze
- File watchers properly cleaned up on repo removal
- CPU usage reasonable with 15 repos idle

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| DispatchSource file descriptor leak | High | Ensure stopWatching cancels source + closes fd |
| Rapid git operations overwhelm Process | Med | Serial queue + debounce; one command at a time per repo |
| `git fetch` hangs on network issue | Med | 30s timeout on fetch; skip on failure, retry next cycle |
| ahead/behind fails (no upstream) | Low | Catch error; show "no remote" instead of counts |

---

## Security Considerations

- Fetch operations use existing git credentials (system keychain)
- No credential storage by oioGit
- DispatchSource file descriptors must be properly closed
- Security-scoped bookmark access started before watcher init

---

## Next Steps

Phase 3 adds repo detail view (changed files, commit log, branches), notification system, and quick actions.

---

## Unresolved Questions

- Optimal debounce interval? (1s proposed, needs testing with rapid commits)
- Should fetch interval be per-repo or global? (global simpler, per-repo in Phase 4)
- Wake-from-sleep: restart all watchers or just trigger refresh?
