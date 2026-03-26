import SwiftUI
import WidgetKit

struct MediumRepoWidgetView: View {
    let entry: RepoStatusEntry

    private var displayRepos: [WidgetRepoData] {
        Array(entry.repos.prefix(4))
    }

    var body: some View {
        if displayRepos.isEmpty {
            emptyView
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(displayRepos) { repo in
                    repoRow(repo)
                    if repo.id != displayRepos.last?.id {
                        Divider().padding(.horizontal, 4)
                    }
                }
            }
            .padding(4)
        }
    }

    private func repoRow(_ repo: WidgetRepoData) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor(for: repo))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(repo.repoName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 8))
                    Text(repo.branch)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 6) {
                if !repo.isClean {
                    Text("\(repo.changedCount)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                if repo.aheadCount > 0 {
                    Text("\u{2191}\(repo.aheadCount)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }

                if repo.behindCount > 0 {
                    Text("\u{2193}\(repo.behindCount)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }

                if let ciState = repo.ciState {
                    Image(systemName: ciSymbol(ciState))
                        .font(.caption2)
                        .foregroundStyle(ciColor(ciState))
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }

    private func statusColor(for repo: WidgetRepoData) -> Color {
        if repo.hasConflict { return .red }
        if repo.isClean { return .green }
        return .orange
    }

    private func ciSymbol(_ state: String) -> String {
        switch state {
        case "success": return "checkmark.circle.fill"
        case "failure": return "xmark.circle.fill"
        case "running": return "arrow.triangle.2.circlepath"
        default: return "clock.fill"
        }
    }

    private func ciColor(_ state: String) -> Color {
        switch state {
        case "success": return .green
        case "failure": return .red
        case "running": return .yellow
        default: return .gray
        }
    }

    private var emptyView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No repositories configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview(as: .systemMedium) {
    RepoStatusWidget()
} timeline: {
    RepoStatusEntry(date: Date(), repos: [
        .placeholder,
        WidgetRepoData(
            repoName: "backend-api",
            branch: "feat/auth",
            changedCount: 0,
            isClean: true,
            hasConflict: false,
            aheadCount: 0,
            behindCount: 2,
            ciState: "failure",
            lastUpdated: Date()
        ),
        WidgetRepoData(
            repoName: "ios-app",
            branch: "develop",
            changedCount: 5,
            isClean: false,
            hasConflict: false,
            aheadCount: 3,
            behindCount: 0,
            ciState: nil,
            lastUpdated: Date()
        ),
    ])
    RepoStatusEntry.empty
}
