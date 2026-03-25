# SwiftUI Patterns

**Applies To**: All SwiftUI views in oioGit
**Last Updated**: 2026-03-25

---

## View Protocol

All views conform to `View` and implement `body`. Keep `body` under 50 lines. Extract sub-views for readability.

```swift
struct RepositoryListView: View {
    @StateObject private var viewModel = RepositoryListViewModel()

    var body: some View {
        List(viewModel.repositories) { repo in
            RepositoryRow(repository: repo)
        }
        .navigationTitle("Repositories")
        .task { await viewModel.load() }
    }
}
```

## State Management

| Property Wrapper | Use Case |
|---|---|
| `@State` | Local, view-owned value types |
| `@Binding` | Value passed from parent for two-way mutation |
| `@StateObject` | View-owned reference type (ViewModel) |
| `@ObservedObject` | Reference type owned externally, passed in |
| `@EnvironmentObject` | Shared state injected from ancestor |
| `@Environment` | System values (colorScheme, dismiss, etc.) |

## Previews

Always include `#Preview` for every view.

```swift
#Preview {
    RepositoryListView()
}
```

## Async Operations

Use `.task { }` for async data loading. Avoid `onAppear` for async work.

```swift
.task {
    await viewModel.fetchRepositories()
}
```

## SwiftUI-Specific Rules

- Do not use `UIKit` views unless no SwiftUI equivalent exists
- Extract views larger than 50 lines into separate files
- Use `ViewBuilder` for complex conditional rendering
- Prefer `List` over `ScrollView + ForEach` for data collections
- Use `NavigationStack` (not deprecated `NavigationView`)
