import SwiftUI

struct CommitLogView: View {
    let commits: [CommitInfo]

    var body: some View {
        if commits.isEmpty {
            emptyView
        } else {
            commitListView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "clock")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No commits found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var commitListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(commits) { commit in
                    CommitRow(commit: commit)
                    if commit.id != commits.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .padding(8)
        }
    }
}

struct CommitRow: View {
    let commit: CommitInfo

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(commit.shortHash)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.blue)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(commit.message)
                    .font(.caption)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(commit.author)
                    Text("·")
                    Text(commit.date, style: .relative)
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
    }
}
