# oioGit — System Architecture

**Version**: 0.1.0
**Last Updated**: 2026-03-25
**Status**: Planned — no implementation beyond scaffold

---

## Overview

oioGit is a single-target SwiftUI iOS application. It follows the **MVVM** (Model-View-ViewModel) pattern, which aligns naturally with SwiftUI's reactive data-binding model. The architecture is designed to remain simple at early stages and scale incrementally as features are added.

---

## Architectural Pattern: MVVM

```
┌─────────────────────────────────────────────┐
│                   View Layer                │
│  SwiftUI Views (ContentView, RepositoryView)│
│  Purely presentational, no business logic   │
└────────────────┬────────────────────────────┘
                 │ @StateObject / @ObservedObject
                 ▼
┌─────────────────────────────────────────────┐
│               ViewModel Layer               │
│  @MainActor ObservableObject classes        │
│  Orchestrates data loading, user actions    │
│  Exposes @Published state to views          │
└────────────────┬────────────────────────────┘
                 │ async/await calls
                 ▼
┌─────────────────────────────────────────────┐
│               Service Layer                 │
│  GitService, FileService, AuthService       │
│  Handles I/O, Git operations, networking    │
│  Returns domain models; throws on error     │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│               Model Layer                   │
│  Repository, Commit, Branch, FileChange     │
│  Plain Swift structs — no UI dependencies   │
└─────────────────────────────────────────────┘
```

---

## SwiftUI View Hierarchy (Planned)

```
oioGitApp (@main)
└── WindowGroup
    └── ContentView (root — to be replaced)
        └── NavigationStack
            ├── RepositoryListView          # Home: list of local repos
            │   └── RepositoryRow
            └── RepositoryDetailView        # Per-repo hub
                ├── CommitHistoryView       # Log / timeline
                │   └── CommitDetailView
                ├── BranchListView          # Branch management
                ├── ChangesView             # Staging area
                │   └── FileChangeRow
                └── RemoteView              # Push / pull / fetch
```

---

## Data Flow

SwiftUI's unidirectional data flow:

```
User Action
    │
    ▼
View calls ViewModel method
    │
    ▼
ViewModel calls Service (async/await)
    │
    ▼
Service performs Git operation
    │
    ▼
Service returns Model or throws Error
    │
    ▼
ViewModel updates @Published properties
    │
    ▼
SwiftUI re-renders affected Views
```

No bidirectional data binding between Views and Services. Services are stateless where possible.

---

## Git Integration (Pending Decision)

The Git backend library has not been selected. Candidates:

| Option | Pros | Cons |
|---|---|---|
| **libgit2** (via SwiftLibgit2 or ObjectiveGit) | Full Git API, battle-tested | C dependency, build complexity |
| **SwiftGit2** | Swift-native wrapper over libgit2 | Maintenance status uncertain |
| **Process / Shell** | Simple, no dependency | Security risk, limited API |
| **Custom Swift Git parser** | Full control | Very high effort |

Decision: ADR-002 (pending). Will be resolved before first feature implementation.

---

## State Management Strategy

| Scope | Mechanism |
|---|---|
| Local view state (loading, text input) | `@State` |
| ViewModel binding | `@StateObject` / `@ObservedObject` |
| App-wide shared state (current user, settings) | `@EnvironmentObject` |
| Navigation state | `NavigationStack` path binding |
| Persistent settings | `UserDefaults` via `@AppStorage` |
| Credentials | Keychain (via Security framework) |

No third-party state management library is planned. SwiftUI's built-in mechanisms are sufficient.

---

## Persistence

| Data Type | Storage |
|---|---|
| Cloned repository paths | `UserDefaults` or Core Data (TBD) |
| User preferences | `UserDefaults` / `@AppStorage` |
| Credentials (tokens, SSH keys) | Keychain |
| Repository data (commits, branches) | In-memory (sourced live from Git) |

---

## Security Considerations

- Credentials stored exclusively in iOS Keychain — never in `UserDefaults` or files
- No analytics or telemetry in initial versions
- SSH keys will require Secure Enclave or file-based storage (TBD)
- App sandbox enforces file access boundaries

---

## Module Boundaries

```
oioGit (main target)
├── App/           — entry point and app lifecycle
├── Views/         — all SwiftUI views
├── ViewModels/    — all ObservableObject ViewModels
├── Models/        — domain structs (Repository, Commit, Branch, etc.)
├── Services/      — Git, File, Auth, Network services
└── Utilities/     — extensions, helpers, shared constants
```

No separate Swift packages or modules at this stage. Modularity will be introduced when the codebase grows beyond 20 files or when clear reusability emerges.

---

## Deployment Architecture

oioGit is a standalone iOS app with no backend server.

```
User Device (iPhone / iPad)
└── oioGit.app
    ├── Local Git repositories (in app sandbox or Files app)
    └── Remote Git servers (GitHub, GitLab, Gitea, etc.) via HTTPS/SSH
```

All Git operations run on-device. Remote operations communicate directly with Git hosting providers using standard Git protocols.

---

## Current Architecture State

As of v0.1.0, only the default Xcode template exists:

- `oioGitApp` — `@main` entry point with `WindowGroup { ContentView() }`
- `ContentView` — placeholder globe + "Hello, world!" view

All architecture described above is **planned**, not implemented.
