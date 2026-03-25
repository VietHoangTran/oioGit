# oioGit — Codebase Summary

**Version**: 0.1.0
**Last Updated**: 2026-03-25
**State**: Xcode template scaffold — no business logic implemented

---

## Project Structure

```
oioGit/
├── oioGit.xcodeproj/          # Xcode project configuration
├── oioGit/                    # Main app target
│   ├── oioGitApp.swift        # App entry point (@main)
│   ├── ContentView.swift      # Root view (default template)
│   └── Assets.xcassets/       # Asset catalog
│       ├── AccentColor.colorset/
│       └── AppIcon.appiconset/
├── oioGitTests/               # Unit test target
│   └── oioGitTests.swift      # Swift Testing scaffold
├── oioGitUITests/             # UI test target
│   ├── oioGitUITests.swift    # XCTest UI test scaffold
│   └── oioGitUITestsLaunchTests.swift  # Launch screenshot test
├── docs/                      # Project documentation
├── plans/                     # Development plans
└── CLAUDE.md                  # AI assistant instructions
```

---

## Core Technologies

| Technology | Version / Notes |
|---|---|
| Swift | 5.9+ |
| SwiftUI | iOS 17+ |
| Xcode | Latest stable |
| Swift Testing | Unit tests (`import Testing`) |
| XCTest | UI tests (`import XCTest`) |
| Git | Version control |

---

## Key Components

### App Entry Point — `oioGit/oioGitApp.swift`

Defines the `oioGitApp` struct conforming to `App`. Uses `WindowGroup` to present `ContentView` as the root scene. This is the SwiftUI `@main` entry point.

### Root View — `oioGit/ContentView.swift`

Default Xcode template view. Displays a globe SF Symbol and "Hello, world!" text inside a `VStack`. Includes a `#Preview` macro for Xcode canvas previews.

This file will be replaced once real UI development begins.

### Assets — `oioGit/Assets.xcassets/`

Standard Xcode asset catalog containing:
- `AccentColor` — app tint color
- `AppIcon` — application icon (placeholder)

---

## Test Structure

### Unit Tests — `oioGitTests/oioGitTests.swift`

Uses the **Swift Testing** framework (`import Testing`). Contains a single scaffold `@Test` function. Tests import the main module via `@testable import oioGit`.

### UI Tests — `oioGitUITests/oioGitUITests.swift`

Uses **XCTest** (`import XCTest`). Standard `XCTestCase` subclass with `setUp`, `tearDown`, and a scaffold `testExample`. Also includes `testLaunchPerformance` using `XCTApplicationLaunchMetric`.

### Launch Tests — `oioGitUITests/oioGitUITestsLaunchTests.swift`

Subclass of `XCTestCase` with `runsForEachTargetApplicationUIConfiguration = true`. Launches the app, takes a screenshot, and attaches it with `keepAlways` lifetime. Useful for visual regression on multiple device configurations.

---

## Dependencies

None. No Swift Package Manager dependencies have been added yet.

---

## Build Targets

| Target | Type | Framework |
|---|---|---|
| oioGit | iOS App | SwiftUI |
| oioGitTests | Unit Test Bundle | Swift Testing |
| oioGitUITests | UI Test Bundle | XCTest |

---

## Notes

- All source files were created on 2026-03-25 by Vince Tran
- The project is at the absolute starting point — all functional development is ahead
- Git integration library has not been selected yet
