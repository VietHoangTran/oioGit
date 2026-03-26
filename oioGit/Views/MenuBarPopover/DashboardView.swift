import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RepoConfig.dateAdded) private var repoConfigs: [RepoConfig]
    @State private var viewModel = DashboardViewModel()
    @State private var selectedRepo: RepoState?

    var body: some View {
        Group {
            if let repo = selectedRepo {
                RepoDetailView(repoState: repo) {
                    selectedRepo = nil
                }
            } else {
                dashboardContent
            }
        }
        .task { await viewModel.start(configs: repoConfigs) }
        .onChange(of: repoConfigs.count) {
            Task { await viewModel.start(configs: repoConfigs) }
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK") { viewModel.errorMessage = nil } },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }

    private var dashboardContent: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .frame(width: 340, height: 420)
    }

    private var headerView: some View {
        HStack {
            Text(AppConstants.appName)
                .font(.headline)
            Spacer()
            Button(action: { Task { await viewModel.refreshAll() } }) {
                Image(systemName: SFSymbols.refresh)
                    .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                    .animation(
                        viewModel.isRefreshing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isRefreshing
                    )
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isRefreshing)

            Button(action: addRepo) {
                Image(systemName: SFSymbols.addRepo)
            }
            .buttonStyle(.borderless)

            Button(action: openSettings) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var contentView: some View {
        Group {
            if viewModel.repoStates.isEmpty {
                emptyStateView
            } else {
                repoListView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: SFSymbols.folder)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No repositories")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Click + to add a Git repository")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var repoListView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.repoStates) { state in
                    RepoCardView(repoState: state)
                        .onTapGesture { selectedRepo = state }
                        .contextMenu {
                            repoContextMenu(for: state)
                        }
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private func repoContextMenu(for state: RepoState) -> some View {
        Button("Open in Terminal") {
            QuickActionService.openTerminal(at: state.repoConfig.directoryURL)
        }
        Button("Open in IDE") {
            QuickActionService.openIDE(at: state.repoConfig.directoryURL)
        }
        Divider()
        Button("Copy Branch Name") {
            QuickActionService.copyToClipboard(state.currentBranch)
        }
        Button("Copy Path") {
            QuickActionService.copyToClipboard(state.repoConfig.path)
        }
        Divider()
        Button("Remove", role: .destructive) {
            viewModel.removeRepo(
                repoId: state.id, modelContext: modelContext,
                configs: repoConfigs
            )
        }
    }

    private func addRepo() {
        let panel = NSOpenPanel()
        panel.title = "Select a Git Repository"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try viewModel.addRepo(
                url: url, modelContext: modelContext, configs: repoConfigs
            )
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func openSettings() {
        if #available(macOS 14, *) {
            NSApp.sendAction(
                Selector(("showSettingsWindow:")), to: nil, from: nil
            )
        } else {
            NSApp.sendAction(
                Selector(("showPreferencesWindow:")), to: nil, from: nil
            )
        }
    }
}
