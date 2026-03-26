import SwiftUI

struct ChangedFilesView: View {
    let fileChanges: [FileChange]
    let repoState: RepoState

    private var stagedFiles: [FileChange] {
        fileChanges.filter { $0.isStaged }
    }

    private var unstagedFiles: [FileChange] {
        fileChanges.filter { !$0.isStaged }
    }

    var body: some View {
        if fileChanges.isEmpty {
            emptyView
        } else {
            fileListView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: SFSymbols.clean)
                .font(.title)
                .foregroundStyle(.green)
            Text("Working tree clean")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var fileListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !stagedFiles.isEmpty {
                    sectionHeader("Staged (\(stagedFiles.count))")
                    ForEach(stagedFiles) { file in
                        FileChangeRow(file: file, repoState: repoState)
                    }
                }

                if !unstagedFiles.isEmpty {
                    sectionHeader("Unstaged (\(unstagedFiles.count))")
                    ForEach(unstagedFiles) { file in
                        FileChangeRow(file: file, repoState: repoState)
                    }
                }
            }
            .padding(8)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

struct FileChangeRow: View {
    let file: FileChange
    let repoState: RepoState
    @State private var showDiff = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { showDiff.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: showDiff ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 10)

                    Text(file.status.symbol)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(statusColor)
                        .frame(width: 16)

                    Image(systemName: fileIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(file.path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 3)
            .padding(.horizontal, 6)

            if showDiff {
                let repoURL = repoState.repoConfig.resolveBookmark()
                    ?? repoState.repoConfig.directoryURL
                MiniDiffView(
                    filePath: file.path,
                    isStaged: file.isStaged,
                    repoURL: repoURL
                )
                .padding(.leading, 32)
                .padding(.trailing, 6)
                .padding(.bottom, 4)
            }
        }
    }

    private var statusColor: Color {
        switch file.status {
        case .modified: return .orange
        case .added: return .green
        case .deleted: return .red
        case .conflict: return .red
        case .untracked: return .secondary
        default: return .blue
        }
    }

    private var fileIcon: String {
        switch file.status {
        case .deleted: return "minus.circle"
        case .added: return "plus.circle"
        case .conflict: return "exclamationmark.triangle"
        default: return "doc"
        }
    }
}
