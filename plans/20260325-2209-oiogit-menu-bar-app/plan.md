# oioGit Implementation Plan

**Project**: oioGit -- macOS Menu Bar Git Repository Monitor
**Date**: 2026-03-25
**Status**: Complete
**Target**: macOS 14+ (Sonoma), Swift 5.9+

---

## Phases

| # | Phase | Status | Progress | File |
|---|-------|--------|----------|------|
| 1 | MVP: Menu Bar & Dashboard | Done | 100% | [phase-01](./phase-01-mvp-menu-bar-and-dashboard.md) |
| 2 | File Monitoring & Auto-Refresh | Done | 100% | [phase-02](./phase-02-file-monitoring-and-auto-refresh.md) |
| 3 | Notifications & Detail View | Done | 100% | [phase-03](./phase-03-notifications-and-detail-view.md) |
| 4 | Polish, Settings & Groups | Done | 100% | [phase-04](./phase-04-polish-settings-and-groups.md) |
| 5 | Advanced Features | Done | 100% | [phase-05](./phase-05-advanced-features.md) |

---

## Key Dependencies

- **No external packages required for MVP** -- all Apple frameworks
- MenuBarExtraAccess (optional, Phase 2+) for programmatic popover control
- Security-Scoped Bookmarks for persistent directory access
- SwiftData `ModelContainer` must init at app startup (not lazily)
- `LSUIElement = YES` in Info.plist to hide dock icon
- Git CLI binary must be accessible (default `/usr/bin/git`, configurable)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI + MenuBarExtra (.window style) |
| Persistence | SwiftData |
| File Monitoring | DispatchSource (GCD) |
| Git Operations | Process API (git CLI) |
| Data Flow | @Observable / Combine |
| Notifications | UNUserNotificationCenter |
| Login Item | SMAppService |

---

## Architecture

- **Pattern**: MVVM with @Observable (not ObservableObject)
- **Distribution**: Outside App Store (avoids sandbox constraints)
- **Repo limit**: 15-20 max for performance
- **File size rule**: Max 200 lines per file

---

## High-Level Timeline

| Phase | Estimated Duration | Depends On |
|-------|--------------------|------------|
| Phase 1 (MVP) | 1-2 weeks | -- |
| Phase 2 (Monitoring) | 1 week | Phase 1 |
| Phase 3 (Notifications & Detail) | 1-2 weeks | Phase 2 |
| Phase 4 (Polish) | 1 week | Phase 3 |
| Phase 5 (Advanced) | 2+ weeks | Phase 4 |

---

## Research Reports

- [SwiftUI Menu Bar Patterns](./research/researcher-01-swiftui-menubar-report.md)
- [System APIs for Git Monitoring](./research/researcher-02-system-apis-report.md)

---

## Unresolved Questions

- SwiftData implicit save timing with menu bar app backgrounding
- Exact debounce threshold for rapid `.git` file changes
- Deep navigation pattern within MenuBarExtra.window popovers
- App Store vs direct distribution (affects sandbox strategy)
