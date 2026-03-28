import SwiftUI

struct RepoCardView: View {
    let repoState: RepoState
    var onRemove: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            StatusBadgeView(color: repoState.statusColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(repoState.displayName)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    branchLabel
                    statusLabel
                    aheadBehindLabel
                    stashLabel
                    CIStatusBadgeView(status: repoState.ciStatus)
                }
            }

            Spacer()

            if isHovering, let onRemove {
                Button(action: onRemove) {
                    Image(systemName: SFSymbols.remove)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .help("Remove repository")
            } else if repoState.isScanning {
                ProgressView()
                    .controlSize(.small)
            } else if let updated = repoState.lastUpdated {
                Text(relativeTime(since: updated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.5))
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    private var branchLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: SFSymbols.branch)
                .font(.caption2)
            Text(repoState.currentBranch)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var statusLabel: some View {
        Group {
            if let error = repoState.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                Text(repoState.gitStatus.summary)
                    .foregroundStyle(
                        repoState.gitStatus.isClean ? .green : .orange
                    )
            }
        }
        .font(.caption)
        .lineLimit(1)
    }

    @ViewBuilder
    private var aheadBehindLabel: some View {
        if repoState.aheadCount > 0 || repoState.behindCount > 0 {
            HStack(spacing: 2) {
                if repoState.aheadCount > 0 {
                    Text("↑\(repoState.aheadCount)")
                }
                if repoState.behindCount > 0 {
                    Text("↓\(repoState.behindCount)")
                }
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var stashLabel: some View {
        if repoState.stashCount > 0 {
            HStack(spacing: 2) {
                Image(systemName: SFSymbols.stash)
                Text("\(repoState.stashCount)")
            }
            .font(.caption2)
            .foregroundStyle(.purple)
        }
    }

    private func relativeTime(since date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}
