# Research: macOS System APIs for Git Monitoring
**Date**: 2026-03-25
**Researcher**: Agent 02

## Summary
FSEvents monitoring via DispatchSource is viable and performant for watching `.git` directories with 15-20 repos. Swift's async/await with cooperative cancellation handles git CLI execution reliably. Security-scoped bookmarks enable persistent multi-directory access. SMAppService (macOS 13+) and UNUserNotificationCenter provide launch-at-login and notification functionality for menu bar apps.

## Findings

### 1. FSEvents API in Swift
**DispatchSource.makeFileSystemObjectSource vs FSEvents:**
- DispatchSource (lower-level, less resource-intensive) preferred for single-directory monitoring
- FSEvents reserved for hierarchy monitoring; higher overhead but better for directory trees
- `.write` event mask captures new files, deletions, and modifications

**Debouncing & Performance:**
- DispatchSource naturally throttles frequent events; no built-in debouncing needed for typical file changes
- Scales well to 15-20 directories with minimal overhead on queue threads
- Libraries available (Witness, SFSMonitor, FSEvents Swift wrappers) reduce boilerplate

**Recommendation:** Use DispatchSource + GCD queue for `.git` monitoring; debounce via queue coalescing or async dispatch delays if rapid bursts occur.

### 2. Process API for Git Commands
**Swift Concurrency Integration:**
- `Process` + async/await pattern: wrap `Process.run()` in `Task { }` with timeout wrapper
- Cooperative cancellation model: check `Task.isCancelled` in loop; throwing from async context unwinds stack and releases resources
- Timeout mechanism: race two tasks (work task vs timer); whichever completes first determines outcome

**Best Practices:**
- Serial queue for git commands to avoid race conditions on `.git` state
- Timeout recommended 10-30s for typical repos; configurable per operation
- Stdout/stderr parsing via `Pipe()` + `availableData` or streaming delegates
- Libraries exist (swift-async-timeout) but native Task racing pattern sufficient

**Recommendation:** Serial DispatchQueue for command execution; implement timeout via `withTaskGroup` racing pattern; ~5s default timeout with 30s max for large repos.

### 3. Security-Scoped Bookmarks
**Persistent Access Flow:**
1. User selects folder via NSOpenPanel
2. Create bookmark: `url.bookmarkData(options: .withSecurityScope, ...)`
3. Store in UserDefaults or file
4. On launch: resolve bookmark, call `startAccessingSecurityScopedResource()` before use
5. Call `stopAccessingSecurityScopedResource()` when done

**Sandbox Implications:**
- Outside sandbox: direct access; bookmarks optional but recommended for UX
- Inside App Store sandbox: bookmarks **mandatory** for non-sandboxed paths
- Bookmark survives app restart; eliminates per-launch permission dialogs

**Recommendation:** Implement bookmarks for all user-selected repositories regardless of distribution model; start/stop scopes around file operations.

### 4. SMAppService (macOS 13+)
**API Usage:**
- `SMAppService.mainApp` registers app for launch-at-login
- Replaces deprecated SMLoginItemSetEnabled (macOS <13)
- Call `.register()` and `.unregister()`; check `.status` property to read actual system state

**Best Practices:**
- Default to disabled; let user opt-in (App Store review requirement)
- Query status from SMAppService, not local UserDefaults (system source of truth)
- Menu bar apps confirmed working with SMAppService (PtionsPlus, Stockbar, PrivacyShieldMac)

**Recommendation:** Add Settings toggle for launch-at-login using SMAppService; read status on app init to sync UI with system state.

### 5. UserNotifications for macOS
**UNUserNotificationCenter on macOS:**
- Fully supported; requires explicit permission request (System Settings > Notifications)
- Scheduling via `UNNotificationRequest` + `add(_:withCompletionHandler:)`
- Menu bar apps receive delegate callbacks when user interacts with notifications
- Action buttons supported; requires UNNotificationAction registration

**Permission Handling:**
- Call `requestAuthorization(options: [.alert, .badge, .sound])` on first app launch
- Users can revoke permission in System Settings at any time
- App should gracefully degrade if permission denied

**Recommendation:** Request notification permission on first launch with explanation ("Notify you of repo changes"). Use notifications for commit/branch events, large status changes.

## Recommendations
1. **Monitoring Stack**: FSEvents via DispatchSource + GCD queue for `.git` changes
2. **Git Execution**: Serial queue + Process + async/await with 5-30s timeout wrapper
3. **Directory Access**: NSOpenPanel + security-scoped bookmarks (all platforms)
4. **Launch at Login**: SMAppService for macOS 13+ (no fallback needed for menu bar app)
5. **User Alerts**: UNUserNotificationCenter with permission request on first launch

## Unresolved Questions
- Exact debounce threshold for coalescing rapid git file changes? (Suggest testing with synthetic rapid commits)
- Should timeout be user-configurable per repo or global? (Lean global with advanced settings)
- Notification grouping strategy for 15+ simultaneous repo updates?
