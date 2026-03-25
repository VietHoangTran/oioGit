# oioGit

A native iOS Git client built with SwiftUI.

**Status**: Early Development (v0.1.0 — Xcode scaffold)
**Platform**: iOS 17+
**Language**: Swift / SwiftUI
**Author**: Vince Tran

---

## About

oioGit aims to be a clean, mobile-first Git client for iPhone and iPad. The goal is to support core Git workflows — browsing repositories, viewing commit history, managing branches, staging changes, and pushing/pulling — entirely from an iOS device.

The project is in its earliest stage. Only the Xcode template scaffold exists today.

---

## Tech Stack

| Component | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Platform | iOS 17+ |
| Unit Testing | Swift Testing (`import Testing`) |
| UI Testing | XCTest |
| Version Control | Git |
| IDE | Xcode (latest stable) |

---

## Prerequisites

- macOS (Apple Silicon or Intel)
- Xcode (latest stable release)
- Git

No additional tools or package managers are required at this stage.

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd oioGit
   ```

2. Open the Xcode project:
   ```bash
   open oioGit.xcodeproj
   ```

3. Select a simulator or connected device and press `Cmd+R` to build and run.

4. Run tests with `Cmd+U`.

---

## Project Structure

```
oioGit/
├── oioGit/                    # Main app source
│   ├── oioGitApp.swift        # App entry point
│   ├── ContentView.swift      # Root view (placeholder)
│   └── Assets.xcassets/       # App icons and colors
├── oioGitTests/               # Unit tests (Swift Testing)
├── oioGitUITests/             # UI tests (XCTest)
├── docs/                      # Project documentation
└── oioGit.xcodeproj/          # Xcode project config
```

---

## Documentation

| Document | Description |
|---|---|
| [Project Overview & PDR](docs/project-overview-pdr.md) | Requirements, features, and acceptance criteria |
| [Codebase Summary](docs/codebase-summary.md) | Current file structure and component overview |
| [Code Standards](docs/code-standards.md) | Swift/SwiftUI conventions and development rules |
| [System Architecture](docs/system-architecture.md) | MVVM architecture, data flow, and planned structure |

---

## Development Guidelines

- Follow the MVVM pattern — Views are presentational only
- One type per file, max 200 lines per file
- Use `@State`, `@StateObject`, `@Binding` appropriately (see code-standards.md)
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
- No force unwrap (`!`) — use `guard let` or `if let`
- All new views must include a `#Preview`

See [docs/code-standards.md](docs/code-standards.md) for the full guidelines.

---

## Current Status

v0.1.0 — Initial commit. Xcode template only. No Git integration or real UI implemented.

Planned next steps:
- Evaluate and select a Git backend library
- Implement repository list view
- Implement commit history viewer

---

## License

TBD
