# Code Review Report — Phase 2: File Monitoring & Auto-Refresh

**Date**: 2026-03-26
**Reviewer**: code-reviewer
**Scope**: Phase 2 new and modified files

---

## Code Review Summary

### Scope
- Files reviewed: `FileWatcherService.swift`, `RepoMonitorService.swift`, `GitOutputParser.swift`, `RepoState.swift`, `RepoCardView.swift`, `DashboardView.swift`, `DashboardViewModel.swift`, `AppDelegate.swift`, `GitCommandRunner.swift` (context)
- Lines of code analyzed: ~500
- Review focus: Phase 2 changes — file monitoring, auto-refresh, ahead/behind, stash

### Overall Assessment
Solid implementation overall. Two critical/high issues need resolution before Phase 3: a data race on `FileWatcherService` and a missing observer for the wake-from-sleep notification. Several secondary design issues around timer scheduling and bookmark access in the file watcher path also warrant attention.

---

## Critical Issues

### C-1: Data Race on `FileWatcherService` — No Thread Isolation
**File**: `FileWatcherService.swift`

`FileWatcherService` is a plain `final class` with no actor isolation and no locks. Its mutable state (`sources`, `fileDescriptors`, `debounceItems`) is:
- Written from the caller's context (Main actor via `startWatcher(for:)` in `RepoMonitorService`)
- Read/written inside the `DispatchSource` event handler, which fires on `queue` (a background serial queue)
- Read/written in `debounce()`, also called from `queue`

The event handler closure captures `self` and calls `debounce()`, which mutates `debounceItems` on `queue`. Meanwhile, `stopWatching` / `stopAll` can be called from Main actor at any time, mutating the same dictionaries. This is a classic TOCTOU data race — not just theoretical, Swift's strict concurrency (`-strict-concurrency=complete`) would flag it.

**Impact**: Crash / undefined behavior under concurrent add/remove while events fire.

**Fix direction**: Confine all mutations to `queue` (make the class dispatch-queue-isolated) or convert to an `actor`.

---

## High Priority Findings

### H-1: Wake-from-Sleep Notification Never Observed
**Files**: `AppDelegate.swift`, `RepoMonitorService.swift`

`AppDelegate.handleWake()` posts `Notification.Name.systemDidWake` to `NotificationCenter.default`, but no code in the codebase subscribes to it. `RepoMonitorService` has no `addObserver` call for this notification. The wake-from-sleep requirement (plan step 11, TODO "Handle wake-from-sleep re-init") is half-implemented — the notification is posted but never consumed. Repos will not refresh after wake.

**Impact**: Functional regression — FR-01 broken after system sleep/wake.

### H-2: `Timer.scheduledTimer` Requires a RunLoop — Called from `async` Context
**File**: `RepoMonitorService.swift` L139

`startFetchTimer()` calls `Timer.scheduledTimer(withTimeInterval:repeats:block:)`. This adds the timer to the calling thread's RunLoop. `startFetchTimer()` is called from `start(configs:)`, which is an `async` function. Swift async functions run on the cooperative thread pool — those threads have no RunLoop, so the timer silently never fires.

**Impact**: Periodic `git fetch` never executes. FR-03 broken entirely.

**Fix direction**: Schedule on `RunLoop.main` explicitly:
```swift
RunLoop.main.add(timer, forMode: .common)
```
or create via `DispatchSourceTimer` on `queue` instead.

### H-3: Security-Scoped Resource Not Accessed Before File Watcher Opens fd
**File**: `RepoMonitorService.swift` L124–134, `FileWatcherService.swift` L27

`startWatcher(for:)` calls `resolveURL(for:)` and passes the URL to `FileWatcherService.startWatching()`, which calls `open(gitDir.path, O_EVTONLY)` — but without calling `url.startAccessingSecurityScopedResource()` first. The `refreshRepo` path correctly guards bookmark access; the file watcher path does not.

**Impact**: On sandboxed builds, `open()` returns -1 for bookmark-backed repos. Watcher silently fails (guarded by `fd >= 0` check), so auto-refresh never works for repos added via file picker. The symptom is no automatic refresh — no error surfaced to the user.

### H-4: `fetchAllRemotes()` Instantiates `GitCommandRunner` Per Repo Per Cycle
**File**: `RepoMonitorService.swift` L151

```swift
let fetchRunner = GitCommandRunner(timeout: 30)
```
This is inside a `for state in repoStates` loop. Each iteration allocates a new runner (plus its internal `DispatchQueue`) on every 5-minute fetch cycle. With 15 repos, that's 15 new `DispatchQueue` instances every 5 minutes, which are non-trivial OS resources and are never explicitly cleaned up (they just get released). Use a single long-timeout runner stored as a property.

---

## Medium Priority Improvements

### M-1: `start(configs:)` Is Re-Entrant — Double-Starts Timer and Watchers
**File**: `RepoMonitorService.swift` L21–26, `DashboardView.swift` L17–19

`DashboardView` calls `viewModel.start(configs:)` both in `.task {}` (on appear) and in `.onChange(of: repoConfigs.count)`. `start()` calls `startFetchTimer()`, which calls `fetchTimer?.invalidate()` before creating a new one — that part is fine. However, `startWatchers()` calls `startWatcher(for:)` for every state unconditionally. `FileWatcherService.startWatching()` does call `stopWatching` first, so there's no fd leak, but it's unnecessary churn: every repo watcher is torn down and recreated on any count change (including removal of a different repo). Use diffing instead.

### M-2: `DashboardView.onChange` Only on `.count`, Misses Renames / Reorders
**File**: `DashboardView.swift` L17

```swift
.onChange(of: repoConfigs.count) {
```
If the user renames a repo's display name or reorders configs (Phase 4 feature), count stays the same and `start()` is not called. A more robust trigger would be `repoConfigs` identity or a hash. Low risk for Phase 2 but worth noting before Phase 4 work.

### M-3: `fetchAllRemotes()` Does Not Re-Acquire Security-Scoped Resource
**File**: `RepoMonitorService.swift` L149

`fetchAllRemotes()` calls `resolveURL(for:)` and passes the URL directly to `fetchRunner.run()` without acquiring the security-scoped resource. Same class of issue as H-3 but for the periodic fetch path.

---

## Low Priority Suggestions

### L-1: `GitOutputParser.parseStatus` Double-Counts Files with Both Staged and Unstaged Changes
**File**: `GitOutputParser.swift` L26–39

A file with both a staged modification (`M` in index position) and an unstaged modification (`M` in work-tree position) is counted twice in `modifiedCount`. The porcelain format presents one line per file; the current logic increments for both columns independently. This inflates counts. Whether intentional ("total changes") or a bug depends on design intent, but worth documenting.

### L-2: `debounce` Reschedules on `queue` — `onChange` Closure Runs on Background Queue
**File**: `FileWatcherService.swift` L74–78

The debounced `action()` closure executes on `queue` (background). The caller (`startWatcher`) wraps it in `Task { @MainActor in ... }`, so this is handled. But the contract is implicit — the closure signature (`@escaping () -> Void`) does not communicate threading requirements. A comment on `onChange` parameter would help.

---

## Positive Observations

- `FileWatcherService`: Clean separation of concerns, fd lifecycle via `setCancelHandler { close(fd) }` is correct, `stopWatching` removes the fd dict entry separately (safe since cancel handler owns the close).
- `GitOutputParser`: Pure static functions, easy to unit test, correct `--left-right` output format parsing.
- `refreshRepo()` correctly uses `async let` to parallelize status + branch + stash calls.
- `RepoState` `@Observable` — no manual `objectWillChange`, clean.
- `DashboardViewModel` is a thin passthrough — good KISS, avoids duplication with `RepoMonitorService`.
- `GitCommandRunner` timeout via racing two tasks is correct and handles the blocking `waitUntilExit` cleanly.

---

## Recommended Actions (Prioritized)

1. **[C-1] Fix thread safety on `FileWatcherService`** — Confine all state mutations to its internal `queue` using `queue.sync {}` for reads, `queue.async {}` for writes, or convert to `actor`. This is the most severe issue.
2. **[H-1] Subscribe to `systemDidWake` in `RepoMonitorService`** — Add `NotificationCenter.default.addObserver` in `start()` or `init`, call `refreshAll()` in the handler.
3. **[H-2] Fix `Timer` RunLoop scheduling** — Use `RunLoop.main` or `DispatchSourceTimer`; verify fetch actually fires.
4. **[H-3 + M-3] Acquire security-scoped resource before `open()` in file watcher and before `fetchAllRemotes()`** — Mirror the pattern already in `refreshRepo`.
5. **[H-4] Extract fetch runner as a property** — Single `GitCommandRunner(timeout: 30)` at the class level.

---

## Task Completeness

| Phase 2 TODO | Status |
|---|---|
| Create FileWatcherService with DispatchSource | Done |
| Implement 1s debounce | Done |
| Create RepoMonitorService orchestrator | Done |
| Add periodic git fetch timer | Done (but broken — H-2) |
| Extend GitCommandRunner with fetch/ahead-behind/stash | Done (via parser, not new methods on runner) |
| Extend GitOutputParser for new outputs | Done |
| Update RepoState model with new fields | Done |
| Update RepoCardView with ahead/behind and stash | Done |
| Wire monitoring into app lifecycle | Done |
| Handle wake-from-sleep re-init | **Incomplete** (H-1: notification posted but never consumed) |
| Tests | Not implemented (manual testing only) |

**Implementation Status**: Mostly complete; 2 functional defects (H-1, H-2) mean two requirements are not met.

---

## Unresolved Questions

1. Is `parseStatus` intentionally double-counting files with both staged and unstaged changes (L-1)?
2. Should `FileWatcherService` also watch the working tree (not just `.git/`) to catch untracked file creation? Currently only `.git/` write events are monitored.
3. Wake-from-sleep: plan says "restart all watchers or just trigger refresh?" — current code posts notification but has no subscriber; decision needed.
