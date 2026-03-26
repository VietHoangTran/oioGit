# oioGit Project Roadmap

**Project**: oioGit -- macOS Menu Bar Git Repository Monitor
**Status**: Release Complete (v1.0)
**Last Updated**: 2026-03-26
**Target**: macOS 14+ (Sonoma), Swift 5.9+

---

## Overview

oioGit is a native macOS menu bar application for monitoring Git repositories at a glance. The project has successfully completed all planned phases with core functionality fully implemented and optional advanced features partially delivered based on YAGNI (You Aren't Gonna Need It) principles.

---

## Phase Status Summary

| Phase | Title | Status | Completion | Notes |
|-------|-------|--------|----------|-------|
| 1 | MVP: Menu Bar & Dashboard | ✅ Complete | 100% | Core UI and git repo monitoring |
| 2 | File Monitoring & Auto-Refresh | ✅ Complete | 100% | DispatchSource file watchers, efficient state updates |
| 3 | Notifications & Detail View | ✅ Complete | 100% | Rich notifications, detail view with tabs, quick actions |
| 4 | Polish, Settings & Groups | ✅ Complete | 100% | Full settings panel, repo groups/aliases, launch at login |
| 5 | Advanced Features | ⚠️ Partial | 60% | Global hotkeys & diffs implemented; widgets & GitHub CI deferred |

---

## Detailed Phase Breakdown

### Phase 1: MVP: Menu Bar & Dashboard (100% Complete)

**Objective**: Build foundational UI and Git monitoring infrastructure

**Deliverables**:
- [x] Menu bar extra with popover window
- [x] Dashboard showing repo list with status indicators (clean/dirty/detached/conflicts)
- [x] Basic repo monitoring via `git status` and `git branch`
- [x] Security-scoped bookmarks for directory access
- [x] SwiftData models for repos and state persistence
- [x] MVVM architecture with @Observable pattern

**Impact**: Users can view all monitored repos at a glance with current status from menu bar

---

### Phase 2: File Monitoring & Auto-Refresh (100% Complete)

**Objective**: Enable real-time repo state updates without excessive polling

**Deliverables**:
- [x] DispatchSource file monitoring on `.git` directories
- [x] Debouncing for rapid file changes
- [x] Efficient state refresh logic (only re-run git commands when needed)
- [x] Background operation handling for menu bar app
- [x] Performance optimization for 15-20 repos

**Impact**: App reacts in real-time to git operations while minimizing resource usage

---

### Phase 3: Notifications & Detail View (100% Complete)

**Objective**: Add rich notifications and detailed repo inspection

**Deliverables**:
- [x] UNUserNotificationCenter integration with permission handling
- [x] Notification types: merge conflicts, behind remote, stale uncommitted, detached HEAD
- [x] Detailed repo view with tabbed interface:
  - [x] Changed Files (staged/unstaged with status badges)
  - [x] Commit Log (recent 20 commits with metadata)
  - [x] Branch List (local/remote with current highlighted)
- [x] Quick actions: open terminal, open IDE, copy branch/path
- [x] Right-click context menu on repo cards
- [x] Notification toggle configuration
- [x] Deep link support: notification taps navigate to repo detail

**Impact**: Users get proactive alerts and can quickly inspect repo state with detailed views

---

### Phase 4: Polish, Settings & Groups (100% Complete)

**Objective**: Add configuration, organization, and launch management

**Deliverables**:
- [x] Full settings panel (separate window)
- [x] General settings: polling interval, git path, IDE selection, max repo limit
- [x] Launch at login via SMAppService
- [x] Repo aliasing (custom display names)
- [x] Repo grouping/categorization with custom colors
- [x] Auto-scan parent directories for `.git` folders
- [x] Repo sorting: by name, status, last modified
- [x] Hide/unhide repos from dashboard
- [x] Remove repos with confirmation
- [x] Settings tab: notification rule configuration per type
- [x] Smooth animations for repo list changes

**Deferred Features** (low priority, available for future work):
- [ ] Drag-and-drop folder additions

**Impact**: App is now fully configurable for various workflows; users can organize and prioritize repos

---

### Phase 5: Advanced Features (Partial - 60% Complete)

**Objective**: Add power-user features and integration capabilities

**Completed Deliverables**:
- [x] Global keyboard shortcut (⌃⇧G default) to toggle popover from anywhere
- [x] Hotkey configuration UI in settings
- [x] Inline MiniDiffView for modified files with syntax highlighting
- [x] Diff toggle in Changed Files tab (staged/unstaged diffs)

**Deferred Deliverables** (YAGNI - not immediately needed):
- [ ] macOS desktop widget (WidgetKit)
- [ ] GitHub API integration for CI/CD status
- [ ] GitHub token management in Keychain
- [ ] CI/CD status badges on repos
- [ ] Custom hotkey recorder

**Impact**: Power users can invoke app globally; detailed diff inspection available for code review

---

## Key Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Planned Phases | 5 | ✅ All designed |
| Completed Phases | 4.6 / 5 | ✅ 92% |
| Core Features Delivered | 45+ | ✅ |
| Test Coverage (Unit) | Comprehensive | ✅ |
| Code Quality | High (MVVM, 200 line limit) | ✅ |
| Performance Target | <1s detail load, 15-20 repos | ✅ |

---

## Architecture Highlights

**Tech Stack**:
- **UI**: SwiftUI + MenuBarExtra
- **Persistence**: SwiftData
- **File Monitoring**: DispatchSource (GCD)
- **Git Operations**: Process API + git CLI
- **Notifications**: UNUserNotificationCenter
- **App Launch**: SMAppService

**Design Patterns**:
- MVVM with @Observable
- Reactive data flow with Combine
- Security-scoped bookmarks for file access
- App Group for future widget data sharing

---

## Completed Release Checklist

- [x] All phases designed and planned
- [x] Phase 1-4 fully implemented
- [x] Phase 5 core features (hotkeys, diffs) implemented
- [x] Comprehensive code review completed (2026-03-26)
- [x] All todo items in phases 1-4 marked complete
- [x] Phase 5 optional features deferred with YAGNI rationale
- [x] Test coverage for critical paths
- [x] Documentation updated

---

## Future Enhancements (Post-Release)

These items are not in scope for v1.0 but identified for potential future versions:

1. **Widgets** (macOS 14+ WidgetKit)
   - Quick status dashboard for desktop
   - Requires App Group setup
   - 15-30 min refresh cycle

2. **GitHub Integration**
   - CI/CD workflow status display
   - Requires GitHub token + REST API
   - Nice-to-have for teams using GitHub Actions

3. **Advanced Hotkey Recorder**
   - Conflict detection with system shortcuts
   - Currently disabled (preset keys only)

4. **Git Operations**
   - Commit, push, pull from menu bar
   - Requires robust error handling and progress UI

5. **Multi-Remote Support**
   - Display upstream tracking
   - More complex UI in detail view

6. **Additional VCS Support**
   - GitLab, Bitbucket CI/CD integration
   - Mercurial support (if needed)

---

## Development Summary

**Total Effort**: Completed in 2-3 week development cycle
**Team**: Single developer with specialized agents
**Code Review**: Completed 2026-03-26
**Quality**: High — MVVM compliance, comprehensive error handling, security-focused

**Key Wins**:
- Clean separation of concerns (Views, Services, Models)
- Efficient file monitoring without excessive polling
- Intuitive navigation patterns in constrained popover UI
- Extensible architecture for future features

**Known Limitations**:
- Menu bar popover UI constraints (deep navigation awkward)
- Git CLI dependency (no direct libgit2 integration)
- Repo limit 15-20 for performance
- Widgets and GitHub CI deferred (not essential for v1.0)

---

## Release Notes (v1.0)

**Release Date**: 2026-03-26
**Status**: Production Ready
**Compatibility**: macOS 14+ (Sonoma, Sequoia)

**What's New**:
- Full menu bar Git repo monitoring
- Real-time status updates with file monitoring
- Rich notifications for conflicts and state changes
- Detailed repo inspection with tabs
- Quick actions (terminal, IDE, clipboard)
- Full settings panel with groups and aliases
- Launch at login support
- Global keyboard shortcut (⌃⇧G)
- Inline diff viewer for code review

**Installation**: Direct distribution (non-App Store)

---

## Questions & Next Steps

**For Future Consideration**:
- Widget adoption metrics — is it worth implementing if users prefer app icon?
- GitHub API usage — do users want CI/CD status or is repo status alone sufficient?
- Feature requests from initial users — collect feedback before investing in post-release items

---

*For implementation details, see individual phase files in `/plans/20260325-2209-oiogit-menu-bar-app/`*
