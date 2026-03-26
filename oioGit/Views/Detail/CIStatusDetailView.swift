import SwiftUI

struct CIStatusDetailView: View {
    let status: CIStatus
    var onRefresh: (() -> Void)?

    var body: some View {
        if status.state != .none {
            HStack(spacing: 8) {
                Image(systemName: status.state.sfSymbol)
                    .foregroundStyle(status.state.color)

                VStack(alignment: .leading, spacing: 2) {
                    if let name = status.workflowName {
                        Text(name)
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 4) {
                        Text(status.state.label)
                            .font(.caption2)
                            .foregroundStyle(status.state.color)

                        if let date = status.lastRunDate {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if let htmlURL = status.htmlURL,
                   let url = URL(string: htmlURL) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .help("Open in browser")
                }

                if let onRefresh {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh CI status")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3))
        }
    }
}

#Preview {
    VStack {
        CIStatusDetailView(status: CIStatus(
            state: .success,
            workflowName: "CI Pipeline",
            lastRunDate: Date().addingTimeInterval(-1800),
            htmlURL: "https://github.com/owner/repo/actions/runs/123"
        ))

        CIStatusDetailView(status: CIStatus(
            state: .failure,
            workflowName: "Tests",
            lastRunDate: Date().addingTimeInterval(-60)
        ))

        CIStatusDetailView(status: .none)
    }
    .frame(width: 340)
}
