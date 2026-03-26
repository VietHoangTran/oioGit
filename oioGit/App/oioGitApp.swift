import SwiftUI
import SwiftData

@main
struct oioGitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([RepoConfig.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .modelContainer(sharedModelContainer)
        } label: {
            Image(systemName: SFSymbols.menuBarIcon)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
    }
}
