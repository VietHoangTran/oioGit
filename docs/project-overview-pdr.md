# oioGit — Project Overview & Product Development Requirements

**Version**: 0.1.0
**Status**: Early Development
**Platform**: iOS
**Author**: Vince Tran
**Created**: 2026-03-25
**Last Updated**: 2026-03-25

---

## Executive Summary

oioGit is a native iOS Git client built with SwiftUI. The goal is to provide developers with a clean, mobile-first interface for managing Git repositories directly from an iPhone or iPad — covering core workflows such as viewing commit history, managing branches, staging changes, and performing push/pull operations.

The project is in its earliest stage: Xcode scaffold only. No Git integration or UI beyond the default template exists yet.

---

## Target Users

- iOS developers who want to manage Git repos on the go
- Anyone who needs lightweight Git access without a desktop machine
- Students and learners tracking personal projects from mobile

---

## Planned Key Features

| Feature | Priority | Status |
|---|---|---|
| Repository browser (local/remote) | High | Planned |
| Commit history viewer | High | Planned |
| Branch management (create, switch, merge) | High | Planned |
| Stage / unstage changes | High | Planned |
| Push / pull / fetch | High | Planned |
| Diff viewer | Medium | Planned |
| Clone repository via URL | Medium | Planned |
| SSH / HTTPS authentication | Medium | Planned |
| Commit authoring | Medium | Planned |
| Conflict resolution UI | Low | Planned |

---

## Technical Requirements

### Functional Requirements

- FR-01: App must launch on iOS 17+ without crashes
- FR-02: App must display a repository list view as home screen
- FR-03: App must support reading local Git repositories stored on device
- FR-04: App must display commit history with author, date, and message
- FR-05: App must allow users to switch branches
- FR-06: App must support staging files and creating commits
- FR-07: App must support push/pull via HTTPS or SSH

### Non-Functional Requirements

- NFR-01: App must target iOS 17.0 minimum deployment
- NFR-02: All views must support Dark Mode and Dynamic Type
- NFR-03: App must follow Apple Human Interface Guidelines
- NFR-04: App must not store credentials in plaintext

### Technical Constraints

- Language: Swift 5.9+
- UI Framework: SwiftUI
- Minimum iOS: 17.0
- Git operations: To be determined (libgit2 binding, custom shell wrapper, or Swift package)
- No third-party dependencies at this stage

---

## Architecture Decision Records (Planned)

| ADR | Decision | Status |
|---|---|---|
| ADR-001 | Use SwiftUI as the sole UI framework | Accepted |
| ADR-002 | Git backend library selection (libgit2 vs. other) | Pending |
| ADR-003 | Local storage strategy for cloned repos | Pending |
| ADR-004 | Authentication / credential storage approach | Pending |

---

## Acceptance Criteria (v0.1.0 — Scaffold)

- [x] Xcode project builds without errors
- [x] Default SwiftUI template runs on simulator
- [x] Unit test target configured (Swift Testing)
- [x] UI test target configured (XCTest)
- [x] Git repository initialized with initial commit

---

## Current State

This is the initial commit. The project contains only:
- Xcode project template files
- Default `ContentView` with globe icon and "Hello, world!" text
- Empty unit test and UI test scaffolds

No Git integration, networking, or business logic has been implemented.

---

## Version History

| Version | Date | Notes |
|---|---|---|
| 0.1.0 | 2026-03-25 | Initial Xcode scaffold |
