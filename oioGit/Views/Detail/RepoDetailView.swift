import SwiftUI

struct RepoDetailView: View {
    let repoState: RepoState
    let onBack: () -> Void

    @State private var selectedTab = DetailTab.changedFiles
    @State private var commits: [CommitInfo] = []
    @State private var fileChanges: [FileChange] = []
    @State private var branches: [BranchInfo] = []
    @State private var isLoading = true

    private let gitRunner = GitCommandRunner.shared

    var body: some View {
        VStack(spacing: 0) {
            headerView
            CIStatusDetailView(status: repoState.ciStatus)
            Divider()
            tabPicker
            Divider()
            tabContent
        }
        .frame(width: 340, height: 420)
        .task { await loadDetailData() }
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            StatusBadgeView(color: repoState.statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(repoState.displayName)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: SFSymbols.branch)
                        .font(.caption2)
                    Text(repoState.currentBranch)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: { Task { await loadDetailData() } }) {
                Image(systemName: SFSymbols.refresh)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(DetailTab.allCases) { tab in
                Text(tab.label).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var tabContent: some View {
        if isLoading {
            Spacer()
            ProgressView()
            Spacer()
        } else {
            switch selectedTab {
            case .changedFiles:
                ChangedFilesView(
                    fileChanges: fileChanges, repoState: repoState
                )
            case .commitLog:
                CommitLogView(commits: commits)
            case .branches:
                BranchListView(branches: branches)
            }
        }
    }

    private func loadDetailData() async {
        isLoading = true
        let bookmark = repoState.repoConfig.resolveBookmark()
        let url = bookmark ?? repoState.repoConfig.directoryURL
        let hasBookmark = bookmark != nil
        if hasBookmark {
            guard url.startAccessingSecurityScopedResource() else {
                isLoading = false
                return
            }
        }
        defer { if hasBookmark { url.stopAccessingSecurityScopedResource() } }

        async let statusOut = try? gitRunner.run(
            ["status", "--porcelain"], at: url
        )
        async let logOut = try? gitRunner.run(
            ["log", "--format=%H%n%s%n%an%n%aI", "-20"], at: url
        )
        async let branchOut = try? gitRunner.run(
            ["branch", "-a"], at: url
        )

        let s = await statusOut ?? ""
        let l = await logOut ?? ""
        let b = await branchOut ?? ""

        fileChanges = GitOutputParser.parseFileChanges(s)
        commits = GitOutputParser.parseLog(l)
        branches = GitOutputParser.parseBranches(b)
        isLoading = false
    }
}

enum DetailTab: String, CaseIterable, Identifiable {
    case changedFiles = "Files"
    case commitLog = "Commits"
    case branches = "Branches"

    var id: String { rawValue }
    var label: String { rawValue }
}
