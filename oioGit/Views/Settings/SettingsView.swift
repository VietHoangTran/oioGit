import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            RepoManagerView()
                .tabItem {
                    Label("Repositories", systemImage: "folder")
                }

            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            GitHubAccountSettingsView()
                .tabItem {
                    Label("GitHub", systemImage: "person.circle")
                }
        }
        .frame(width: 450, height: 380)
    }
}
