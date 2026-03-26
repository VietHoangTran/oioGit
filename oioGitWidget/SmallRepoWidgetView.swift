import SwiftUI
import WidgetKit

struct SmallRepoWidgetView: View {
    let entry: RepoStatusEntry

    var body: some View {
        if let repo = entry.repos.first {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    statusDot(for: repo)
                    Text(repo.repoName)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                }

                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption2)
                    Text(repo.branch)
                        .font(.caption)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    if repo.isClean {
                        Label("Clean", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Label("\(repo.changedCount) changed", systemImage: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                if repo.aheadCount > 0 || repo.behindCount > 0 {
                    HStack(spacing: 4) {
                        if repo.aheadCount > 0 {
                            Text("\u{2191}\(repo.aheadCount)")
                                .font(.caption2)
                        }
                        if repo.behindCount > 0 {
                            Text("\u{2193}\(repo.behindCount)")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(.blue)
                }

                if let ciState = repo.ciState {
                    ciLabel(ciState)
                }
            }
            .padding(4)
        } else {
            emptyView
        }
    }

    private func statusDot(for repo: WidgetRepoData) -> some View {
        Circle()
            .fill(repo.hasConflict ? .red : (repo.isClean ? .green : .orange))
            .frame(width: 8, height: 8)
    }

    private func ciLabel(_ state: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: ciSymbol(state))
                .font(.caption2)
            Text(state.capitalized)
                .font(.caption2)
        }
        .foregroundStyle(ciColor(state))
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
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No repos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview(as: .systemSmall) {
    RepoStatusWidget()
} timeline: {
    RepoStatusEntry.placeholder
    RepoStatusEntry.empty
}
