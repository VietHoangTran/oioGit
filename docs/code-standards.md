# oioGit — Code Standards

**Version**: 1.0.0
**Last Updated**: 2026-03-25
**Applies To**: All Swift/SwiftUI source code in oioGit

---

## Guiding Principles

- **YAGNI** — Only implement what is currently required.
- **KISS** — Prefer the simplest solution that works.
- **DRY** — Extract shared logic into reusable components.
- **Single Responsibility** — Each type, file, and function does one thing.

---

## Planned File Organization

```
oioGit/
├── App/               # App entry point and root configuration
├── Views/             # SwiftUI views, grouped by feature
│   └── FeatureName/
│       ├── FeatureView.swift
│       └── FeatureSubview.swift
├── ViewModels/        # ObservableObject ViewModels
├── Models/            # Plain Swift value types
├── Services/          # Git, file system, network I/O
├── Utilities/         # Shared helpers and extensions
└── Resources/         # Fonts, localization, static config
```

---

## Standards Reference

Detailed standards are split into focused documents:

| Document | Contents |
|---|---|
| [swift-naming-conventions.md](standards/swift-naming-conventions.md) | PascalCase types, camelCase vars, booleans, file rules |
| [swiftui-patterns.md](standards/swiftui-patterns.md) | View protocol, state wrappers, previews, async, rules |
| [mvvm-and-error-handling.md](standards/mvvm-and-error-handling.md) | ViewModel pattern, service layer, error enums |
| [testing-standards.md](standards/testing-standards.md) | Swift Testing, XCTest, coverage targets |
| [git-and-style-rules.md](standards/git-and-style-rules.md) | Conventional commits, branch naming, code style |
