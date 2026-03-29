# Bugfix Plan: Code Review Issues

**Date:** 2026-03-28
**Scope:** 10 issues (1 BLOCKER, 4 HIGH, 4 MEDIUM, 1 FEATURE)
**Estimated effort:** ~4 hours

---

## Execution Order

Four batches ordered by dependency and severity. Batch 1 must complete before Batch 2 (entitlements are a prerequisite). Batch 2, 3, and 4 are independent.

| Batch | Issues | Rationale |
|-------|--------|-----------|
| 1 | #2 Entitlements | Infrastructure - everything else depends on this |
| 2 | #3 fetchInterval, #4 staleChanges, #5 gitBinaryPath, #6 security scope leak | HIGH - core service fixes, no interdependencies |
| 3 | #7 HotkeyRecorder leak, #8 scanDirectory threading, #9 WidgetRepoData id, #10 HotkeyConfig.matches | MEDIUM - isolated fixes |
| 4 | #11 macOS distributable build | FEATURE - build script + DMG packaging |

---

## Batch 1: Infrastructure (BLOCKER)

### Issue #2: App Group entitlement missing

**Problem:** `SharedDataService` uses `UserDefaults(suiteName: "group.com.oioGit.shared")` but no `.entitlements` file exists. On sandboxed apps, this silently returns nil.

**Fix - create two entitlements files:**

**File: `oioGit/oioGit.entitlements`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.oioGit.shared</string>
    </array>
</dict>
</plist>
```

**File: `oioGitWidget/oioGitWidget.entitlements`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.oioGit.shared</string>
    </array>
</dict>
</plist>
```

**Xcode config:** Set `CODE_SIGN_ENTITLEMENTS` build setting for each target to point to its entitlements file.

**Apple Developer Portal:** Register the App Group `group.com.oioGit.shared` under Identifiers > App Groups. Add it to both app IDs' capabilities.

---

## Batch 2: Core Service Fixes (HIGH)

### Issue #3: fetchInterval hardcoded to 300s

**Problem:** `RepoMonitorService.swift` line 14 declares `let fetchInterval: TimeInterval = 300`. The `startFetchTimer()` method uses this constant, ignoring `AppSettings.shared.pollingInterval`.

**File:** `oioGit/Services/RepoMonitorService.swift`

**Change:** Remove the hardcoded constant and read from settings dynamically. Also restart timer when setting changes.

```swift
// REMOVE this line (line 14):
let fetchInterval: TimeInterval = 300 // 5 minutes

// REPLACE with computed property:
var fetchInterval: TimeInterval {
    AppSettings.shared.pollingInterval
}
```

**File:** `oioGit/Services/RepoMonitorService+Refresh.swift`

Add timer restart capability. In `startFetchTimer()`, the interval is already read from `fetchInterval` so the computed property fix above handles new timer creation. But the timer must also be restarted when the user changes the setting.

Add a public method:

```swift
/// Call when polling interval changes in settings
func restartFetchTimer() {
    startFetchTimer()
}
```

**File:** `oioGit/Views/Settings/GeneralSettingsView.swift`

Add `.onChange` to the polling picker to restart the timer:

```swift
Picker("Fetch interval", selection: $settings.pollingInterval) {
    ForEach(pollingOptions, id: \.1) { option in
        Text(option.0).tag(option.1)
    }
}
.onChange(of: settings.pollingInterval) {
    // Timer will use new interval on next start via computed property
    // Posting notification so RepoMonitorService can restart timer
    NotificationCenter.default.post(name: .pollingIntervalChanged, object: nil)
}
```

Alternatively (simpler): since `RepoMonitorService` is `@Observable` and referenced in the view hierarchy, expose a method and call it. The cleanest approach depends on how the view accesses the service. If accessed via `DashboardViewModel`, add a pass-through.

**Simplest approach** - just ensure `startFetchTimer()` reads the setting each time. The computed property fix above is sufficient for new timer starts. The existing timer will continue at old interval until next app restart or manual refresh. This is acceptable for an MVP fix.

---

### Issue #4: staleChanges notification never fires

**Problem:** `evaluateNotifications(for:)` in `RepoMonitorService+Refresh.swift` (line 170-175) checks if `Date() - lastUpdated > 7200`. But `lastUpdated` is set to `Date()` on every refresh (line 43), so the delta is always ~0.

**Fix:** Track when dirty state was first detected using a new property on `RepoState`.

**File:** `oioGit/Models/RepoState.swift`

Add property:

```swift
/// Tracks when uncommitted changes were first detected (for stale notification)
var firstDirtyDate: Date?
```

Initialize as `nil` in `init`.

**File:** `oioGit/Services/RepoMonitorService+Refresh.swift`

After setting `gitStatus` (after line 38), add logic to track dirty onset:

```swift
// After: state.gitStatus = GitOutputParser.parseStatus(status)
if state.gitStatus.isClean {
    state.firstDirtyDate = nil
} else if state.firstDirtyDate == nil {
    state.firstDirtyDate = Date()
}
```

Fix the stale check in `evaluateNotifications` (replace lines 170-175):

```swift
// OLD:
if !state.gitStatus.isClean,
   let updated = state.lastUpdated,
   Date().timeIntervalSince(updated) > 7200
{
    current.insert(NotificationType.staleChanges.rawValue)
}

// NEW:
if !state.gitStatus.isClean,
   let dirtyDate = state.firstDirtyDate,
   Date().timeIntervalSince(dirtyDate) > 7200
{
    current.insert(NotificationType.staleChanges.rawValue)
}
```

---

### Issue #5: GitCommandRunner ignores gitBinaryPath setting

**Problem:** `GitCommandRunner` takes `gitPath` in `init` with default `GitDefaults.gitPath` (`/usr/bin/git`). `RepoMonitorService` creates runners at init time: `let gitRunner = GitCommandRunner()`. The `gitBinaryPath` setting from `AppSettings` is never passed.

**Fix:** Make `GitCommandRunner.run()` accept an optional override, or make the runner read the setting dynamically.

**Preferred approach** - read setting at call time:

**File:** `oioGit/Services/GitCommandRunner.swift`

Change `gitPath` from a stored constant to a computed property:

```swift
// REMOVE (line 23):
private let gitPath: String

// REMOVE from init:
self.gitPath = gitPath

// REPLACE init:
init(timeout: TimeInterval = GitDefaults.timeout) {
    self.timeout = timeout
}

// ADD computed property:
private var gitPath: String {
    AppSettings.shared.gitBinaryPath
}
```

Remove `gitPath` parameter from init. The `static let shared` instance and all callers using default init will automatically use the setting.

Also remove `Sendable` conformance since `AppSettings.shared` access makes it non-Sendable, or keep the access `@MainActor`-safe by caching the path at call start:

```swift
func run(_ args: [String], at directory: URL) async throws -> String {
    let resolvedGitPath = await MainActor.run { AppSettings.shared.gitBinaryPath }
    // ... use resolvedGitPath instead of self.gitPath
}
```

**Simpler alternative** - keep `Sendable`, resolve at call site:

```swift
func run(_ args: [String], at directory: URL, gitPath: String? = nil) async throws -> String {
    let effectivePath = gitPath ?? self.gitPath
    // use effectivePath throughout
}
```

Then in `RepoMonitorService+Refresh.swift`, pass the setting:

```swift
async let statusOut = gitRunner.run(
    ["status", "--porcelain"], at: url,
    gitPath: AppSettings.shared.gitBinaryPath
)
```

**Recommended:** The simpler alternative preserves `Sendable`. Apply it.

---

### Issue #6: Security scope leak in startWatcher

**Problem:** `startWatcher(for:)` in `RepoMonitorService+Refresh.swift` (line 64-86) calls `url.startAccessingSecurityScopedResource()` but never calls `stopAccessingSecurityScopedResource()`. The access remains open until process exit.

**Fix:** The watcher needs the security scope to remain active while watching. The proper fix is to stop access when the watcher stops.

**File:** `oioGit/Services/RepoMonitorService+Refresh.swift`

Track scoped URLs and stop access on watcher removal:

Add a new property to `RepoMonitorService.swift`:

```swift
/// URLs with active security-scoped access (for file watchers)
var activeScopedURLs: [String: URL] = [:]
```

**In `startWatcher(for:)`:**

```swift
func startWatcher(for state: RepoState) {
    let url = resolveURL(for: state)
    let repoId = state.id
    let hasBookmark = state.repoConfig.resolveBookmark() != nil

    if hasBookmark {
        guard url.startAccessingSecurityScopedResource() else { return }
        activeScopedURLs[repoId] = url  // <-- ADD
    }

    fileWatcher.startWatching(repoId: repoId, directory: url) { [weak self] in
        // ... existing closure unchanged
    }
}
```

**In `removeRepo(repoId:)`** (RepoMonitorService.swift):

```swift
func removeRepo(repoId: String) {
    fileWatcher.stopWatching(repoId: repoId)
    // Stop security-scoped access
    if let url = activeScopedURLs.removeValue(forKey: repoId) {
        url.stopAccessingSecurityScopedResource()
    }
    repoStates.removeAll { $0.id == repoId }
}
```

**In `stopAll()`:**

```swift
func stopAll() {
    fileWatcher.stopAll()
    fetchTimerSource?.cancel()
    fetchTimerSource = nil
    // Release all scoped resources
    for (_, url) in activeScopedURLs {
        url.stopAccessingSecurityScopedResource()
    }
    activeScopedURLs.removeAll()
}
```

---

## Batch 3: Isolated Fixes (MEDIUM)

### Issue #7: HotkeyRecorderView NSEvent monitor leak

**Problem:** If user closes Settings window while recording, `localMonitor` (an `NSEvent` local monitor) is never removed because `stopRecording()` is never called.

**File:** `oioGit/Views/Settings/HotkeyRecorderView.swift`

Add `.onDisappear` to the body:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            hotkeyDisplay
            Spacer()
            recordButton
            resetButton
        }

        if let warning = conflictWarning {
            Text(warning)
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
    .onDisappear {       // <-- ADD
        stopRecording()
    }
}
```

---

### Issue #8: RepoManagerView.scanDirectory() blocks main thread

**Problem:** `scanDirectory()` calls `RepoScannerService.scan(directory:)` synchronously on the main thread. Large directories freeze the UI.

**File:** `oioGit/Views/Settings/RepoManagerView.swift`

Replace `scanDirectory()`:

```swift
private func scanDirectory() {
    let panel = NSOpenPanel()
    panel.title = "Select Directory to Scan"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false

    guard panel.runModal() == .OK, let url = panel.url else { return }

    isScanning = true
    Task.detached(priority: .userInitiated) {
        let results = RepoScannerService.scan(directory: url)
        await MainActor.run {
            self.scanResults = results
            self.isScanning = false
            if !results.isEmpty { self.showingScanSheet = true }
        }
    }
}
```

Optional: show a `ProgressView` while `isScanning` is true (in `bottomBar`):

```swift
private var bottomBar: some View {
    HStack {
        Button("Scan Directory...") { scanDirectory() }
            .disabled(isScanning)
        if isScanning {
            ProgressView()
                .controlSize(.small)
        }
        Spacer()
        Text("\(repoConfigs.count) repos")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding(8)
}
```

---

### Issue #9: WidgetRepoData.id uses repoName - duplicate id collision

**Problem:** `var id: String { repoName }`. Two repos with the same folder name (e.g., two `api/` repos from different orgs) produce the same `id`, causing SwiftUI/Widget to display the wrong data or crash.

**Fix:** Use the full repo path as the id. Since the widget doesn't have the path, include it in the data contract.

**File:** `oioGit/Models/WidgetRepoData.swift` AND `oioGitWidget/WidgetRepoData.swift` (both copies must match)

```swift
struct WidgetRepoData: Codable, Identifiable {
    let repoPath: String          // <-- ADD (unique identifier)
    var id: String { repoPath }   // <-- CHANGE from repoName
    let repoName: String
    let branch: String
    let changedCount: Int
    let isClean: Bool
    let hasConflict: Bool
    let aheadCount: Int
    let behindCount: Int
    let ciState: String?
    let lastUpdated: Date

    static let placeholder = WidgetRepoData(
        repoPath: "/Users/dev/my-project",  // <-- ADD
        repoName: "my-project",
        branch: "main",
        changedCount: 3,
        isClean: false,
        hasConflict: false,
        aheadCount: 1,
        behindCount: 0,
        ciState: "success",
        lastUpdated: Date()
    )
}
```

**File:** `oioGit/Services/SharedDataService.swift`

Update the mapping in `writeSnapshots`:

```swift
let data = states.map { state in
    WidgetRepoData(
        repoPath: state.repoConfig.path,  // <-- ADD
        repoName: state.displayName,
        // ... rest unchanged
    )
}
```

---

### Issue #10: HotkeyConfig.matches uses .contains instead of ==

**Problem:** `matches(_:)` uses `eventMods.contains(flags)`, meaning Ctrl+Shift+G also matches when the user presses Ctrl+Shift+Cmd+G (superset). Should require exact modifier match.

**File:** `oioGit/Models/HotkeyConfig.swift`

Replace the `matches` method (line 35-39):

```swift
// OLD:
func matches(_ event: NSEvent) -> Bool {
    let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
    let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    return eventMods.contains(flags) && event.keyCode == keyCode
}

// NEW:
func matches(_ event: NSEvent) -> Bool {
    let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
    let eventMods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    return eventMods == flags && event.keyCode == keyCode
}
```

Single character change: `.contains(flags)` -> `== flags`.

---

## Batch 4: macOS Distributable Build (FEATURE)

### Issue #11: Build as distributable macOS app

**Problem:** Currently the app can only be built and run via Xcode. No CLI build script or packaging exists for distributing `oioGit.app` as a standalone macOS application (DMG/ZIP).

**Approach:** Create a `scripts/build.sh` that builds a Release `.app`, code-signs it, and packages into a DMG for distribution.

**File: `scripts/build.sh`** (NEW)

```bash
#!/bin/bash
set -euo pipefail

# --- Config ---
SCHEME="oioGit"
PROJECT="oioGit.xcodeproj"
BUILD_DIR="build"
APP_NAME="oioGit"
DMG_NAME="oioGit"
VERSION=$(defaults read "$(pwd)/$BUILD_DIR/Release/$APP_NAME.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")

# --- Clean & Build ---
echo "▸ Cleaning..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "▸ Building Release..."
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    | tail -5

# --- Export .app from archive ---
echo "▸ Exporting app..."
ARCHIVE_APP="$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"
RELEASE_DIR="$BUILD_DIR/Release"
mkdir -p "$RELEASE_DIR"
cp -R "$ARCHIVE_APP" "$RELEASE_DIR/"

# --- Re-read version after build ---
VERSION=$(defaults read "$(pwd)/$RELEASE_DIR/$APP_NAME.app/Contents/Info.plist" CFBundleShortVersionString)

# --- Ad-hoc codesign (for local distribution without Developer ID) ---
echo "▸ Code signing (ad-hoc)..."
codesign --force --deep --sign - "$RELEASE_DIR/$APP_NAME.app"

# --- Create DMG ---
echo "▸ Creating DMG..."
DMG_PATH="$BUILD_DIR/${DMG_NAME}-v${VERSION}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$RELEASE_DIR/$APP_NAME.app" \
    -ov -format UDZO \
    "$DMG_PATH"

echo ""
echo "✅ Build complete!"
echo "   App: $RELEASE_DIR/$APP_NAME.app"
echo "   DMG: $DMG_PATH"
echo "   Version: $VERSION"
```

**File: `scripts/export-options.plist`** (NEW — for `xcodebuild -exportArchive` if using Developer ID signing)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

**Usage:**

```bash
# Ad-hoc build (no Apple Developer account needed)
chmod +x scripts/build.sh
./scripts/build.sh

# Output: build/oioGit-v1.0.dmg
```

**Optional — Developer ID signed build (for Gatekeeper-approved distribution):**

Replace the ad-hoc codesign step in `build.sh` with:

```bash
# Replace ad-hoc signing with:
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    -exportOptionsPlist scripts/export-options.plist \
    -exportPath "$RELEASE_DIR"

# Notarize (requires Apple Developer account):
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "@keychain:AC_PASSWORD" \
    --wait

xcrun stapler staple "$DMG_PATH"
```

**Files created:**
- `scripts/build.sh`
- `scripts/export-options.plist`

**Build matrix:**

| Method | Requirement | Gatekeeper | Distribution |
|--------|------------|------------|--------------|
| Ad-hoc (`--sign -`) | None | Warning on open | Direct share / GitHub Releases |
| Developer ID | Apple Developer ($99/yr) | Passes | Anywhere |
| Developer ID + Notarization | Apple Developer + notarytool | Full pass | App Store / Web |

---

## Summary of All File Changes

| File | Issues | Change Type |
|------|--------|-------------|
| `oioGit/oioGit.entitlements` | #2 | **NEW** |
| `oioGitWidget/oioGitWidget.entitlements` | #2 | **NEW** |
| `oioGit.xcodeproj/project.pbxproj` | #2 | MODIFY (via Xcode UI) |
| `oioGit/Services/RepoMonitorService.swift` | #3, #6 | MODIFY |
| `oioGit/Services/RepoMonitorService+Refresh.swift` | #4, #6 | MODIFY |
| `oioGit/Services/GitCommandRunner.swift` | #5 | MODIFY |
| `oioGit/Models/RepoState.swift` | #4 | MODIFY |
| `oioGit/Models/HotkeyConfig.swift` | #10 | MODIFY |
| `oioGit/Models/WidgetRepoData.swift` | #9 | MODIFY |
| `oioGitWidget/WidgetRepoData.swift` | #9 | MODIFY |
| `oioGit/Services/SharedDataService.swift` | #9 | MODIFY |
| `oioGit/Views/Settings/HotkeyRecorderView.swift` | #7 | MODIFY |
| `oioGit/Views/Settings/RepoManagerView.swift` | #8 | MODIFY |
| `oioGit/Views/Settings/GeneralSettingsView.swift` | #3 | MODIFY (optional) |
| `scripts/build.sh` | #11 | **NEW** |
| `scripts/export-options.plist` | #11 | **NEW** |

## Testing Checklist

- [ ] Change polling interval in Settings, verify timer uses new value
- [ ] Leave dirty repo for 2+ hours, verify stale notification fires
- [ ] Set custom git path in Settings, verify git commands use it
- [ ] Remove a repo, verify no security scope warnings in Console
- [ ] Open Settings, start hotkey recording, close Settings window, verify no crash/leak
- [ ] Scan a large directory (~1000 dirs), verify UI stays responsive
- [ ] Add two repos with same folder name, verify widget shows both correctly
- [ ] Set hotkey to Ctrl+Shift+G, press Ctrl+Shift+Cmd+G, verify it does NOT trigger
- [ ] Run `./scripts/build.sh`, verify DMG is created and app launches from DMG

## Unresolved Questions

1. **Issue #5 (gitBinaryPath):** The "pass gitPath at call site" approach requires touching every `gitRunner.run()` call. The "computed property" approach breaks `Sendable`. Which trade-off does the team prefer?
2. **Issue #3 (fetchInterval):** Should changing the polling interval immediately restart the timer, or take effect on next timer cycle? Current plan uses computed property (next cycle). Immediate restart requires notification plumbing.
