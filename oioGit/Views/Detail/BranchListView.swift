import SwiftUI

struct BranchListView: View {
    let branches: [BranchInfo]

    private var localBranches: [BranchInfo] {
        branches.filter { !$0.isRemote }
    }

    private var remoteBranches: [BranchInfo] {
        branches.filter { $0.isRemote }
    }

    var body: some View {
        if branches.isEmpty {
            emptyView
        } else {
            branchListView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: SFSymbols.branch)
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No branches found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var branchListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !localBranches.isEmpty {
                    sectionHeader("Local (\(localBranches.count))")
                    ForEach(localBranches) { branch in
                        BranchRow(branch: branch)
                    }
                }

                if !remoteBranches.isEmpty {
                    sectionHeader("Remote (\(remoteBranches.count))")
                    ForEach(remoteBranches) { branch in
                        BranchRow(branch: branch)
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

struct BranchRow: View {
    let branch: BranchInfo

    var body: some View {
        HStack(spacing: 6) {
            if branch.isCurrent {
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .frame(width: 14)
            } else {
                Color.clear.frame(width: 14)
            }

            Image(systemName: SFSymbols.branch)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(branch.name)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)

            Spacer()

            if branch.isRemote {
                Text("remote")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(.quaternary)
                    )
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
    }
}
