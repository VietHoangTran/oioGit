# Git Standards & Code Style

**Applies To**: All contributors to oioGit
**Last Updated**: 2026-03-25

---

## Commit Messages (Conventional Commits)

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`

Examples:
```
feat(repo-list): add repository browser view
fix(git-service): handle missing .git directory gracefully
docs(code-standards): add SwiftUI patterns section
test(git-service): add unit tests for branch listing
```

---

## Branch Naming

```
feature/<short-description>
fix/<short-description>
docs/<short-description>
chore/<short-description>
```

---

## Commit Rules

- Atomic commits — one logical change per commit
- No commented-out code
- All Swift files must compile before committing
- Do not commit `.DS_Store`, `*.xcuserstate`, or derived data

---

## Code Style

- Indent with **4 spaces** (Xcode default)
- Opening brace on same line as declaration
- Trailing commas in multi-line collections
- Explicit `self.` only when required (closures, init assignment)
- Prefer `let` over `var` unless mutation is needed
- Avoid force unwrap (`!`) — use `guard let`, `if let`, or `?? default`
- Mark classes `final` unless inheritance is explicitly needed
- Access control: default to `private`/`internal`, expose only what is necessary
