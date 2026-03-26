# Phase 5 Completion Plan -- oioGit Advanced Features

**Date**: 2026-03-26
**Scope**: 5 features, ~40% remaining of Phase 5
**Estimated New Files**: 14 Swift files + 1 WidgetKit extension target
**Estimated Modified Files**: 10 existing files

---

## Implementation Order & Dependency Graph

```
Feature 1: Custom Hotkey Recorder (standalone, no deps)
    |
Feature 2: GitHub Token Management / Keychain (standalone, no deps)
    |
    v
Feature 3: GitHub API Integration for CI/CD (depends on Feature 2)
    |
    v
Feature 4: CI/CD Status Badges on Repo Cards (depends on Feature 3)

Feature 5: macOS Desktop Widget (standalone, but benefits from all above)
```

**Rationale**: Features 2-3-4 form a dependency chain (token -> API -> UI badges). Feature 1 and Feature 5 are independent. Implement Feature 1 first (smallest scope, quick win). Then the GitHub chain (2->3->4). Widget last (largest scope, needs new Xcode target).

---

## Feature 1: Custom Hotkey Recorder

### Goal
Replace hardcoded Control+Shift+G with user-configurable hotkey.

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `HotkeyRecorderView.swift` | `Views/Settings/` | SwiftUI view with key-capture overlay; displays current combo; "Record" button enters capture mode |
| `HotkeyConfig.swift` | `Models/` | Struct holding modifierFlags (UInt) + keyCode (UInt16) + display string; Codable for UserDefaults |

### Modified Files

| File | Change |
|------|--------|
| `AppSettings.swift` | Add `hotkeyModifiers: UInt` and `hotkeyKeyCode: UInt16` properties backed by UserDefaults; defaults to Control+Shift+G |
| `GlobalHotkeyService.swift` | Read keyCode/modifiers from `AppSettings.shared` instead of hardcoded values; add `updateHotkey()` method to re-register with new combo |
| `GeneralSettingsView.swift` | Add "Keyboard Shortcut" section embedding `HotkeyRecorderView` |
| `AppDelegate.swift` | No change needed -- already calls `GlobalHotkeyService.shared.register` |
| `Constants.swift` | Add `HotkeyDefaults` enum with default keyCode/modifiers |

### Implementation Tasks

- [ ] **1.1** Create `HotkeyConfig.swift` in Models/
  - Struct with `modifierFlags: UInt`, `keyCode: UInt16`
  - Computed `displayString` (e.g., "Control+Shift+G") using Carbon key code mapping
  - Static `default` returning Control+Shift+G
  - Codable conformance for UserDefaults storage
  - Helper: `matches(_ event: NSEvent) -> Bool`

- [ ] **1.2** Add `HotkeyDefaults` to `Constants.swift`
  - Default modifier mask value (Control+Shift = `NSEvent.ModifierFlags`)
  - Default key code (`kVK_ANSI_G`)
  - Known conflict prefixes (Cmd+Q, Cmd+W, Cmd+H, etc.)

- [ ] **1.3** Add hotkey properties to `AppSettings.swift`
  - `hotkeyModifiers: UInt` -- UserDefaults-backed, default = Control+Shift
  - `hotkeyKeyCode: UInt16` -- UserDefaults-backed, default = kVK_ANSI_G
  - Computed `hotkeyConfig: HotkeyConfig` getter/setter

- [ ] **1.4** Update `GlobalHotkeyService.swift`
  - `handleKeyEvent` reads keyCode/modifiers from `AppSettings.shared` instead of hardcoded
  - Add `reregister()` that calls `unregister()` then `register(onToggle:)` with stored callback
  - Keep `onToggle` closure stored for re-registration

- [ ] **1.5** Create `HotkeyRecorderView.swift` in Views/Settings/
  - Display current hotkey as styled text (e.g., "Control+Shift+G")
  - "Record" button -> enters capture mode (focus ring, "Press keys..." label)
  - Capture via `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` -- local monitor for Settings window
  - Validate: must have at least one modifier (Control/Option/Command) + one non-modifier key
  - Conflict detection: warn if combo matches known system shortcuts (Cmd+Q, Cmd+W, Cmd+Tab, etc.)
  - "Reset to Default" button
  - On save: update `AppSettings`, call `GlobalHotkeyService.shared.reregister()`
  - Include `#Preview`

- [ ] **1.6** Add hotkey section to `GeneralSettingsView.swift`
  - New `Section("Keyboard Shortcut")` containing `HotkeyRecorderView()`
  - Place after "Startup" section

### Conflict Detection Strategy
Maintain a static set of known macOS system shortcuts in `HotkeyDefaults`. On record, check if the captured combo exists in that set. Show warning text below recorder but allow override (user may have remapped system shortcuts).

---

## Feature 2: GitHub Token Management (Keychain)

### Goal
Securely store/retrieve GitHub personal access token via macOS Keychain. No third-party deps -- Security framework only.

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `KeychainService.swift` | `Services/` | CRUD wrapper around Security framework's `SecItemAdd/Update/CopyMatching/Delete` |
| `GitHubAccountSettingsView.swift` | `Views/Settings/` | UI for token entry, validation status, delete token |

### Modified Files

| File | Change |
|------|--------|
| `SettingsView.swift` | Add 4th tab "GitHub" with `GitHubAccountSettingsView` |
| `Constants.swift` | Add `KeychainConstants` enum (service name, account key) |

### Implementation Tasks

- [ ] **2.1** Add `KeychainConstants` to `Constants.swift`
  - `service = "com.oioGit.github"`
  - `account = "github-pat"`

- [ ] **2.2** Create `KeychainService.swift` in Services/
  - `static func save(token: String) throws` -- `SecItemAdd` (or update if exists)
  - `static func retrieve() -> String?` -- `SecItemCopyMatching`
  - `static func delete() throws` -- `SecItemDelete`
  - `static func exists() -> Bool`
  - All methods use `kSecClassGenericPassword` with service/account from constants
  - Error type: `KeychainError` enum (duplicateItem, notFound, unexpectedStatus(OSStatus))
  - Keep it simple: no async needed, Keychain ops are synchronous and fast

- [ ] **2.3** Create `GitHubAccountSettingsView.swift` in Views/Settings/
  - SecureField for token input
  - "Save" button -> calls `KeychainService.save`
  - Status indicator: "No token", "Token saved", "Validating...", "Valid", "Invalid"
  - "Validate" button -> test API call to `https://api.github.com/user` with Bearer token
  - "Delete" button with confirmation
  - Token is NEVER displayed after save -- only "Token saved (ghp_...xxxx)" showing last 4 chars
  - Validation uses URLSession async call
  - Include `#Preview`

- [ ] **2.4** Add "GitHub" tab to `SettingsView.swift`
  - 4th tab with systemImage "person.circle" or similar
  - Contains `GitHubAccountSettingsView()`
  - Increase frame height if needed (450x380)

### Security Notes
- Token stored in macOS Keychain, never in UserDefaults or on disk
- Token never logged or displayed in full after initial entry
- Validation call uses HTTPS only
- Keychain item accessible only to this app (default kSecAttrAccessible)

---

## Feature 3: GitHub API Integration for CI/CD Status

### Goal
Fetch GitHub Actions workflow run status for repos with a GitHub remote. Poll on configurable interval.

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `CIStatus.swift` | `Models/` | Enum + struct for CI/CD state (success/failure/pending/running/none) |
| `GitHubAPIService.swift` | `Services/` | URLSession-based client; fetch latest workflow run for owner/repo |
| `GitHubRemoteParser.swift` | `Utilities/` | Parse git remote URL to extract GitHub owner/repo |

### Modified Files

| File | Change |
|------|--------|
| `RepoState.swift` | Add `ciStatus: CIStatus` property (default `.none`) |
| `RepoMonitorService.swift` | Integrate CI status fetch into periodic refresh cycle |
| `AppSettings.swift` | Add `ciPollingInterval: TimeInterval` (default 300s) and `ciStatusEnabled: Bool` |
| `GeneralSettingsView.swift` | Add CI/CD polling interval picker in settings |

### Implementation Tasks

- [ ] **3.1** Create `CIStatus.swift` in Models/
  - Enum `CIStatusState: String, Sendable` with cases: `.success`, `.failure`, `.pending`, `.running`, `.none`
  - Struct `CIStatus: Sendable` with fields: `state: CIStatusState`, `workflowName: String?`, `lastRunDate: Date?`, `htmlURL: String?`
  - Static `.none` convenience
  - Computed `color: Color` and `sfSymbol: String` for each state

- [ ] **3.2** Create `GitHubRemoteParser.swift` in Utilities/
  - `static func parseGitHubRemote(_ remoteURL: String) -> (owner: String, repo: String)?`
  - Handle HTTPS format: `https://github.com/owner/repo.git`
  - Handle SSH format: `git@github.com:owner/repo.git`
  - Strip trailing `.git` if present
  - Return nil for non-GitHub remotes

- [ ] **3.3** Create `GitHubAPIService.swift` in Services/
  - `func fetchLatestWorkflowRun(owner: String, repo: String) async throws -> CIStatus`
  - Endpoint: `GET /repos/{owner}/{repo}/actions/runs?per_page=1&branch={default_branch}`
  - Auth: Bearer token from `KeychainService.retrieve()`
  - Parse response JSON manually (no Codable models for full response -- extract only needed fields)
  - Actually, use minimal Codable structs (private, nested) for the API response subset
  - Handle: 401 (bad token), 404 (no workflows/private repo), rate limiting (403 with retry-after)
  - Return `.none` when no token configured or repo has no GitHub remote
  - Timeout: 10s per request
  - Error type: `GitHubAPIError` enum

- [ ] **3.4** Add `ciStatus` to `RepoState.swift`
  - `var ciStatus: CIStatus = .none`
  - No other changes needed (RepoState is already @Observable)

- [ ] **3.5** Add CI settings to `AppSettings.swift`
  - `ciStatusEnabled: Bool` -- UserDefaults, default false
  - `ciPollingInterval: TimeInterval` -- UserDefaults, default 300

- [ ] **3.6** Integrate CI fetch into `RepoMonitorService.swift`
  - In periodic refresh (not file-watcher refresh -- CI status doesn't change on local file edits)
  - For each repo: get remote URL via `git remote get-url origin`, parse with `GitHubRemoteParser`
  - If GitHub remote found + token exists + ciStatusEnabled: call `GitHubAPIService`
  - Update `repoState.ciStatus` on @MainActor
  - Separate timer or piggyback on existing fetch timer (prefer piggyback to keep it simple)
  - Guard: skip CI fetch if no token in Keychain

- [ ] **3.7** Add CI settings to `GeneralSettingsView.swift`
  - New Section("CI/CD Status") with:
    - Toggle "Show CI/CD status" bound to `ciStatusEnabled`
    - Picker for CI polling interval (1 min, 5 min, 15 min) -- only shown when enabled

---

## Feature 4: CI/CD Status Badges on Repo Cards

### Goal
Display CI/CD status visually on repo cards and in the detail view.

### New Files

| File | Location | Purpose |
|------|----------|---------|
| `CIStatusBadgeView.swift` | `Views/MenuBarPopover/` | Small color-coded CI badge with tooltip |
| `CIStatusDetailView.swift` | `Views/Detail/` | Expanded CI info for repo detail view |

### Modified Files

| File | Change |
|------|--------|
| `RepoCardView.swift` | Add `CIStatusBadgeView` inline after status indicators |
| `RepoDetailView.swift` | Add CI status section or badge in header area |

### Implementation Tasks

- [ ] **4.1** Create `CIStatusBadgeView.swift` in Views/MenuBarPopover/
  - Small circle (8pt) with color from `CIStatus.color`
  - SF Symbol overlay (checkmark.circle.fill, xmark.circle.fill, clock.fill, etc.)
  - `.help()` tooltip: "{workflowName} - {state} ({relative time})"
  - Hidden when `ciStatus.state == .none`
  - Include `#Preview` with all states

- [ ] **4.2** Create `CIStatusDetailView.swift` in Views/Detail/
  - Shows workflow name, status with colored badge, last run date
  - Link to open workflow run in browser (using `htmlURL`)
  - "Refresh" button to re-fetch
  - Compact layout -- this sits in the detail view header, not a full tab
  - Include `#Preview`

- [ ] **4.3** Add badge to `RepoCardView.swift`
  - Insert `CIStatusBadgeView(status: repoState.ciStatus)` in the HStack
  - Place after `stashLabel` in the info row, or as a small indicator next to `StatusBadgeView`
  - Only renders when CI status is not `.none`

- [ ] **4.4** Add CI section to `RepoDetailView.swift`
  - Add `CIStatusDetailView` below the repo header / above the segmented tabs
  - Only shown when `ciStatus.state != .none`
  - Compact, single-line layout

---

## Feature 5: macOS Desktop Widget (WidgetKit)

### Goal
WidgetKit extension with small (single repo) and medium (3-4 repos) widgets. App Group for data sharing.

### Prerequisites
- New Xcode target: `oioGitWidget` (Widget Extension)
- App Group entitlement: `group.com.oioGit.shared`
- App Group added to both main app target AND widget target

### New Files (Widget Extension Target)

| File | Location | Purpose |
|------|----------|---------|
| `oioGitWidgetBundle.swift` | `oioGitWidget/` | @main WidgetBundle entry point |
| `RepoStatusWidget.swift` | `oioGitWidget/` | Widget definition (small + medium families) |
| `RepoStatusTimelineProvider.swift` | `oioGitWidget/` | TimelineProvider: reads shared data, builds timeline entries |
| `RepoStatusEntry.swift` | `oioGitWidget/` | TimelineEntry with repo snapshot data |
| `SmallRepoWidgetView.swift` | `oioGitWidget/` | Small widget: single repo status |
| `MediumRepoWidgetView.swift` | `oioGitWidget/` | Medium widget: 3-4 repo summary |
| `WidgetRepoData.swift` | `oioGitWidget/` | Codable struct for shared data (subset of RepoState) |

### New Shared File (Both Targets)

| File | Location | Purpose |
|------|----------|---------|
| `SharedDataService.swift` | `Services/` | Writes repo snapshots to App Group UserDefaults for widget consumption |

### Modified Files

| File | Change |
|------|--------|
| `RepoMonitorService.swift` | Call `SharedDataService.writeSnapshots()` after each refresh cycle |
| Main app entitlements | Add App Group `group.com.oioGit.shared` |

### Implementation Tasks

- [ ] **5.1** Create Xcode widget extension target
  - Target name: `oioGitWidget`
  - Add to existing project
  - Add App Group entitlement (`group.com.oioGit.shared`) to BOTH targets
  - Deployment target: macOS 14.0

- [ ] **5.2** Create `WidgetRepoData.swift` -- shared between targets
  - Codable struct: `repoName: String`, `branch: String`, `changedCount: Int`, `isClean: Bool`, `hasConflict: Bool`, `aheadCount: Int`, `behindCount: Int`, `ciState: String?`, `lastUpdated: Date`
  - This is the data contract between app and widget
  - Place in a shared group or duplicate in widget target (simpler than framework for 1 file)

- [ ] **5.3** Create `SharedDataService.swift` in Services/
  - `static func writeSnapshots(_ states: [RepoState])`
  - Encodes `[WidgetRepoData]` to JSON, writes to `UserDefaults(suiteName: "group.com.oioGit.shared")`
  - Key: `"widget_repo_data"`
  - Also writes `lastUpdated` timestamp
  - `static func readSnapshots() -> [WidgetRepoData]` (used by widget)

- [ ] **5.4** Create `RepoStatusEntry.swift` in widget target
  - Conforms to `TimelineEntry`
  - Properties: `date: Date`, `repos: [WidgetRepoData]`

- [ ] **5.5** Create `RepoStatusTimelineProvider.swift`
  - Conforms to `TimelineProvider`
  - `placeholder`: returns mock data
  - `getSnapshot`: reads from shared UserDefaults, returns current entry
  - `getTimeline`: reads shared data, creates entry, sets next refresh in 15-30 min via `.after(date)`
  - Refresh policy: `.atEnd`

- [ ] **5.6** Create `SmallRepoWidgetView.swift`
  - Single repo display: name, branch, status dot, changed file count
  - Uses `.systemSmall` family
  - Handles empty state ("No repos configured")
  - Include `#Preview` with `.systemSmall`

- [ ] **5.7** Create `MediumRepoWidgetView.swift`
  - Shows 3-4 repos in a compact list: name + branch + status dot per row
  - Uses `.systemMedium` family
  - Handles empty state
  - Include `#Preview` with `.systemMedium`

- [ ] **5.8** Create `RepoStatusWidget.swift`
  - Widget definition with `kind: "RepoStatusWidget"`
  - Supports `.systemSmall` and `.systemMedium`
  - Uses `RepoStatusTimelineProvider`
  - `body`: switch on widget family to select `SmallRepoWidgetView` or `MediumRepoWidgetView`

- [ ] **5.9** Create `oioGitWidgetBundle.swift`
  - `@main` struct conforming to `WidgetBundle`
  - Contains `RepoStatusWidget()`

- [ ] **5.10** Integrate `SharedDataService` into `RepoMonitorService.swift`
  - After each refresh cycle completes, call `SharedDataService.writeSnapshots(repoStates)`
  - Lightweight -- just JSON encode + UserDefaults write
  - Also trigger `WidgetCenter.shared.reloadAllTimelines()` after write (import WidgetKit in main app)

### Widget Configuration (Future Enhancement -- Not in Scope)
AppIntent-based configuration for selecting which repo to show in small widget. For v1, show the first repo (small) or first 4 repos (medium) sorted by most recently updated. This keeps scope minimal. Can add StaticConfiguration for now, upgrade to AppIntentConfiguration later.

---

## Summary: Full Task Execution Order

### Batch 1 -- Standalone (no cross-feature deps)

| # | Task | Feature | Est. LOC |
|---|------|---------|----------|
| 1 | 1.1 HotkeyConfig model | Hotkey Recorder | ~40 |
| 2 | 1.2 HotkeyDefaults constants | Hotkey Recorder | ~15 |
| 3 | 1.3 AppSettings hotkey props | Hotkey Recorder | ~15 |
| 4 | 1.4 GlobalHotkeyService update | Hotkey Recorder | ~20 |
| 5 | 1.5 HotkeyRecorderView | Hotkey Recorder | ~120 |
| 6 | 1.6 GeneralSettingsView section | Hotkey Recorder | ~10 |

### Batch 2 -- GitHub Token Foundation

| # | Task | Feature | Est. LOC |
|---|------|---------|----------|
| 7 | 2.1 KeychainConstants | Token Mgmt | ~5 |
| 8 | 2.2 KeychainService | Token Mgmt | ~80 |
| 9 | 2.3 GitHubAccountSettingsView | Token Mgmt | ~120 |
| 10 | 2.4 SettingsView GitHub tab | Token Mgmt | ~10 |

### Batch 3 -- GitHub API

| # | Task | Feature | Est. LOC |
|---|------|---------|----------|
| 11 | 3.1 CIStatus model | CI/CD API | ~45 |
| 12 | 3.2 GitHubRemoteParser | CI/CD API | ~35 |
| 13 | 3.3 GitHubAPIService | CI/CD API | ~120 |
| 14 | 3.4 RepoState ciStatus prop | CI/CD API | ~3 |
| 15 | 3.5 AppSettings CI props | CI/CD API | ~10 |
| 16 | 3.6 RepoMonitorService CI integration | CI/CD API | ~40 |
| 17 | 3.7 GeneralSettingsView CI section | CI/CD API | ~15 |

### Batch 4 -- CI/CD Badge UI

| # | Task | Feature | Est. LOC |
|---|------|---------|----------|
| 18 | 4.1 CIStatusBadgeView | CI Badges | ~60 |
| 19 | 4.2 CIStatusDetailView | CI Badges | ~80 |
| 20 | 4.3 RepoCardView badge | CI Badges | ~10 |
| 21 | 4.4 RepoDetailView CI section | CI Badges | ~10 |

### Batch 5 -- Widget Extension

| # | Task | Feature | Est. LOC |
|---|------|---------|----------|
| 22 | 5.1 Xcode target setup | Widget | manual |
| 23 | 5.2 WidgetRepoData | Widget | ~30 |
| 24 | 5.3 SharedDataService | Widget | ~50 |
| 25 | 5.4 RepoStatusEntry | Widget | ~15 |
| 26 | 5.5 RepoStatusTimelineProvider | Widget | ~60 |
| 27 | 5.6 SmallRepoWidgetView | Widget | ~70 |
| 28 | 5.7 MediumRepoWidgetView | Widget | ~80 |
| 29 | 5.8 RepoStatusWidget | Widget | ~30 |
| 30 | 5.9 oioGitWidgetBundle | Widget | ~10 |
| 31 | 5.10 SharedDataService integration | Widget | ~15 |

**Total estimated new LOC**: ~1,280
**Total tasks**: 31

---

## File Inventory

### New Files (14 in main target + 7 in widget target = 21 total)

**Main Target:**
1. `oioGit/Models/HotkeyConfig.swift`
2. `oioGit/Models/CIStatus.swift`
3. `oioGit/Services/KeychainService.swift`
4. `oioGit/Services/GitHubAPIService.swift`
5. `oioGit/Services/SharedDataService.swift`
6. `oioGit/Utilities/GitHubRemoteParser.swift`
7. `oioGit/Views/Settings/HotkeyRecorderView.swift`
8. `oioGit/Views/Settings/GitHubAccountSettingsView.swift`
9. `oioGit/Views/MenuBarPopover/CIStatusBadgeView.swift`
10. `oioGit/Views/Detail/CIStatusDetailView.swift`

**Widget Target:**
11. `oioGitWidget/oioGitWidgetBundle.swift`
12. `oioGitWidget/RepoStatusWidget.swift`
13. `oioGitWidget/RepoStatusTimelineProvider.swift`
14. `oioGitWidget/RepoStatusEntry.swift`
15. `oioGitWidget/SmallRepoWidgetView.swift`
16. `oioGitWidget/MediumRepoWidgetView.swift`
17. `oioGitWidget/WidgetRepoData.swift`

### Modified Files (10)

1. `oioGit/Utilities/Constants.swift` -- add HotkeyDefaults, KeychainConstants
2. `oioGit/Models/AppSettings.swift` -- add hotkey, CI polling properties
3. `oioGit/Models/RepoState.swift` -- add `ciStatus` property
4. `oioGit/Services/GlobalHotkeyService.swift` -- read dynamic hotkey from settings
5. `oioGit/Services/RepoMonitorService.swift` -- CI fetch + widget data sync
6. `oioGit/Views/Settings/SettingsView.swift` -- add GitHub tab, adjust frame
7. `oioGit/Views/Settings/GeneralSettingsView.swift` -- hotkey + CI sections
8. `oioGit/Views/MenuBarPopover/RepoCardView.swift` -- CI badge
9. `oioGit/Views/Detail/RepoDetailView.swift` -- CI detail section
10. `oioGit/App/oioGitApp.swift` -- (only if App Group entitlement needs code change)

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Keychain access denied in sandbox | Token feature broken | Test with sandbox enabled early; use correct `kSecAttrAccessGroup` |
| GitHub API rate limiting (60/hr unauthenticated, 5000/hr authenticated) | CI status stale | Default to 5-min polling; show "rate limited" status; exponential backoff |
| Widget cannot run git commands | Stale widget data | Widget reads pre-computed JSON from App Group -- never runs git |
| NSEvent global monitor requires Accessibility permission | Hotkey doesn't work | Show guidance in Settings if hotkey fails; this is existing behavior |
| SettingsView exceeds frame height with 4 tabs | UI overflow | Increase frame to 450x380; each tab scrolls independently |
| RepoMonitorService file grows past 200 lines | Code standard violation | Extract CI integration into `RepoMonitorService+CI.swift` extension |

---

## Unresolved Questions

1. **Widget configuration intent**: Should v1 support user-selectable repos via AppIntent, or just show the most-recently-updated repos? Plan assumes no AppIntent for simplicity (YAGNI).
2. **GitHub Enterprise**: Should `GitHubRemoteParser` support custom GitHub Enterprise domains? Plan assumes github.com only. Easy to add later.
3. **Multiple GitHub tokens**: One token per user or per-repo tokens? Plan assumes single global token -- sufficient for personal use.
4. **CI status for non-default branches**: Should we fetch CI for the currently checked-out branch, or always the default branch? Plan assumes current branch, falling back to default.
